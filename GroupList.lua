local _, GBB = GroupBulletinBoard_Loader.Main()

local IsInRaid = GBB.api.IsInRaid
local RAID_CLASS_COLORS_HEX = GBB.api.RAID_CLASS_COLORS_HEX

local MAXGROUP = 500
local guildcache = {}
local friendcache = {}
local pastplayercache = {}

GBB.GroupTrans = {}

local AllowedInstanceType = { "party", "scenario", "raid" }

function GBB.GetPlayerList()
  local count, prefix
  local ret = {}

  if IsInRaid() then
    prefix = "raid"
    count = MAX_RAID_MEMBERS
  else
    prefix = "party"
    count = MAX_PARTY_MEMBERS
  end


  for index = 1, count do
    local id = prefix .. index
    local name = GetUnitName( id )
    local localizedClass, englishClass, classIndex = UnitClass( id )

    if name and englishClass and not UnitIsUnit( id, "player" ) then
      ret[ name ] = {
        [ "name" ] = name,
        [ "class" ] = englishClass,
        [ "guid" ] = UnitGUID( id ),
      }
    end
  end

  return ret
end

function GBB.AddGroupList( entry )
  local note
  if entry.Note then
    note = GBB.Tool.RGBtoEscape( GBB.DB.PlayerNoteColor ) .. entry.Note .. "|r"
  else
    note = ""
  end

  if guildcache[ entry.name ] == nil then
    -- IsGuildMember doesn't exist in Classic/Wrath, use alternative method
    local isGuildMember = false
    if entry.guid and IsInGuild() then
      -- Check if the player is in our guild by comparing guild names
      local playerGuild = GetGuildInfo("player")
      if playerGuild then
        -- For now, we'll assume they're not a guild member since we can't easily check
        -- This is a limitation of Classic/Wrath API
        isGuildMember = false
      end
    end
    guildcache[ entry.name ] = isGuildMember
  end
  if friendcache[ entry.name ] == nil then
    -- C_FriendList.IsFriend doesn't exist in Classic/Wrath, use alternative method
    local isFriend = false
    if entry.guid then
      -- For Classic/Wrath, we'll use a simpler approach
      -- This is a limitation of the Classic/Wrath API
      isFriend = false
    end
    friendcache[ entry.name ] = isFriend
  end

  if pastplayercache[ entry.name ] == nil then
    pastplayercache[ entry.name ] = entry.name and GBB.GroupTrans[ entry.name ] ~= nil
  end
  GroupBulletinBoardFrame_GroupFrame:AddMessage(
    "|Hplayer:" .. entry.name .. "|h" ..
    GBB.Tool.IconClass[ entry.class ] ..
    "|c" .. RAID_CLASS_COLORS_HEX[ entry.class ] ..
    entry.name ..

    (friendcache[ entry.name ] and "|cffecda90*|r" or "") ..
    (guildcache[ entry.name ] and "|cffb4fe2c•|r" or "") ..

    "|r " .. note .. "|h"
  )
end

function GBB.UpdateGroupList()
  if not (GBB.DB and GBB.DB.EnableGroup) then
    return
  end


  --local dname, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID =
  --GetInstanceInfo()

  --if tContains(AllowedInstanceType, instanceType) then
  local group = GBB.GetPlayerList()

  for i, member in pairs( group ) do
    if GBB.GroupTrans[ member.name ] then
      local entry = GBB.GroupTrans[ member.name ]
      entry.lastSeen = time()
      if not entry.guid then
        entry.guid = group[ entry.name ].guid
      end
      entry.dungeon = dname
    else
      GBB.GroupTrans[ member.name ] = {
        name = member.name,
        class = member.class,
        lastSeen = time(),
        guid = member.guid,
        dungeon = dname,
      }

      tinsert( GBB.DBChar.GroupList, GBB.GroupTrans[ member.name ] )
    end
  end

  table.sort( GBB.DBChar.GroupList, function( a, b ) return a.lastSeen < b.lastSeen end )
  --end

  if not GroupBulletinBoardFrame:IsVisible() or GBB.Tool.GetSelectedTab( GroupBulletinBoardFrame ) ~= 2 then
    return
  end
  GBB.EditNote( nil )

  GroupBulletinBoardFrame_GroupFrame:Clear()
  for i, entry in ipairs( GBB.DBChar.GroupList ) do
    GBB.AddGroupList( entry )
  end
end

local EditEntry
function GBB.EditNote( entry )
  StaticPopup_Hide( "GroupBulletinBoard_AddNote" )
  if entry then
    EditEntry = entry
    StaticPopup_Show( "GroupBulletinBoard_AddNote", entry.name )
  end
end

local function EnterHyperlink( self, link, text )
  local part = GBB.Tool.Split( link, ":" )
  if part[ 1 ] == "player" then
    for i, entry in ipairs( GBB.DBChar.GroupList ) do
      if entry.name == part[ 2 ] then
        GameTooltip_SetDefaultAnchor( GameTooltip, UIParent )
        GameTooltip:SetOwner( GroupBulletinBoardFrame, "ANCHOR_BOTTOM", 0, -25 )
        GameTooltip:ClearLines()
        GameTooltip:AddLine( GBB.Tool.IconClass[ entry.class ] ..
          "|c" .. RAID_CLASS_COLORS_HEX[ entry.class ] ..
          entry.name )
        if entry.dungeon then
          GameTooltip:AddLine( entry.dungeon )
        end
        if entry.Note then
          GameTooltip:AddLine( entry.Note )
        end
        GameTooltip:AddLine( SecondsToTime( time() - entry.lastSeen ) )
        GameTooltip:Show()
        break
      end
    end
  end
end

local function LeaveHyperlink( self )
  GameTooltip:Hide()
end

local function ClickHyperlink( self, link )
  local part = GBB.Tool.Split( link, ":" )
  if part[ 1 ] == "player" then
    for i, entry in ipairs( GBB.DBChar.GroupList ) do
      if entry.name == part[ 2 ] then
        GBB.EditNote( entry )
        break
      end
    end
  end
end

function GBB.InitGroupList()
  if GBB.DBChar.GroupList == nil then
    GBB.DBChar.GroupList = {}
  end

  StaticPopupDialogs[ "GroupBulletinBoard_AddNote" ] = {
    text = GBB.L.msgAddNote,
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = 1,
    maxLetters = 48,
    countInvisibleLetters = true,
    editBoxWidth = 350,
    OnAccept = function( self )
      EditEntry.Note = self.editBox:GetText()
      GBB.UpdateGroupList()
    end,
    OnShow = function( self )
      self.editBox:SetText( EditEntry.Note or "" );
      self.editBox:SetFocus();
    end,
    OnHide = function( self )
      ChatEdit_FocusActiveWindow();
      self.editBox:SetText( "" );
    end,
    EditBoxOnEnterPressed = function( self )
      local parent = self:GetParent();
      EditEntry.Note = parent.editBox:GetText()
      GBB.UpdateGroupList()
      parent:Hide();
    end,
    EditBoxOnEscapePressed = function( self )
      self:GetParent():Hide();
    end,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1
  }



  GroupBulletinBoardFrame_GroupFrame:SetFading( false );
  GroupBulletinBoardFrame_GroupFrame:SetFontObject( GBB.DB.FontSize );
  GroupBulletinBoardFrame_GroupFrame:SetJustifyH( "LEFT" );
  -- Unsupported?
  --GroupBulletinBoardFrame_GroupFrame:SetHyperlinksEnabled(true);
  GroupBulletinBoardFrame_GroupFrame:SetScript( "OnHyperlinkClick", ClickHyperlink )
  GroupBulletinBoardFrame_GroupFrame:SetScript( "OnHyperlinkEnter", EnterHyperlink )
  GroupBulletinBoardFrame_GroupFrame:SetScript( "OnHyperlinkLeave", LeaveHyperlink )
  -- Unsupported?
  --GroupBulletinBoardFrame_GroupFrame:SetTextCopyable(true);
  GroupBulletinBoardFrame_GroupFrame:Clear()
  GroupBulletinBoardFrame_GroupFrame:SetMaxLines( MAXGROUP )
  --GroupBulletinBoardFrame_GroupFrame:SetInsertMode("TOP")
  --[[for i=1,200 do
		GBB.DBChar.GroupList[i]={
			name="rnd"..i,
			class=GBB.Tool.Classes[ random(1,#GBB.Tool.Classes)],
			lastSeen=time()-random(1,400000),
		}
	end
	--]]

  table.sort( GBB.DBChar.GroupList, function( a, b ) return a.lastSeen < b.lastSeen end )
  while #GBB.DBChar.GroupList >= MAXGROUP do
    tremove( GBB.DBChar.GroupList, 1 )
  end

  for i, entry in ipairs( GBB.DBChar.GroupList ) do
    GBB.GroupTrans[ entry.name ] = entry
  end

  GBB.UpdateGroupList()
end

function GBB.ScrollGroupList( self, delta )
  -- ScrollingMessageFrame doesn't have GetScrollOffset in Classic/Wrath
  -- Use a simple approach that works with ScrollingMessageFrame
  if delta > 0 then
    -- Scroll up
    for i = 1, 5 do
      self:PageUp()
    end
  else
    -- Scroll down
    for i = 1, 5 do
      self:PageDown()
    end
  end
  -- ResetAllFadeTimes doesn't exist in Classic/Wrath, skip it
  -- self:ResetAllFadeTimes()
end
