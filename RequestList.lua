local _, GBB = GroupBulletinBoard_Loader.Main()

local tconcat = table.concat
local wipe = GBB.api.wipe
local RAID_CLASS_COLORS_HEX = GBB.api.RAID_CLASS_COLORS_HEX

--ScrollList / Request
-------------------------------------------------------------------------------------
local LastDungeon
local lastIsFolded
local requestNil = { dungeon = "NIL", start = 0, last = 0, name = "" }

local function requestSort_TOP_TOTAL( a, b )
  --a=a or requestNil
  --b=b or requestNil
  if GBB.dungeonSort[ a.dungeon ] < GBB.dungeonSort[ b.dungeon ] then
    return true
  elseif GBB.dungeonSort[ a.dungeon ] == GBB.dungeonSort[ b.dungeon ] then
    if a.start > b.start then
      return true
    elseif (a.start == b.start and a.name > b.name) then
      return true
    end
  end
  return false
end
local function requestSort_TOP_nTOTAL( a, b )
  --a=a or requestNil
  --b=b or requestNil
  if not b then return false end

  if GBB.dungeonSort[ a.dungeon ] < GBB.dungeonSort[ b.dungeon ] then
    return true
  elseif GBB.dungeonSort[ a.dungeon ] == GBB.dungeonSort[ b.dungeon ] then
    if a.last > b.last then
      return true
    elseif (a.start == b.start and a.name > b.name) then
      return true
    end
  end
  return false
end
local function requestSort_nTOP_TOTAL( a, b )
  --a=a or requestNil
  --b=b or requestNil
  if GBB.dungeonSort[ a.dungeon ] < GBB.dungeonSort[ b.dungeon ] then
    return true
  elseif GBB.dungeonSort[ a.dungeon ] == GBB.dungeonSort[ b.dungeon ] then
    if a.start < b.start then
      return true
    elseif (a.start == b.start and a.name > b.name) then
      return true
    end
  end
  return false
end
local function requestSort_nTOP_nTOTAL( a, b )
  --a=a or requestNil
  --b=b or requestNil
  if GBB.dungeonSort[ a.dungeon ] < GBB.dungeonSort[ b.dungeon ] then
    return true
  elseif GBB.dungeonSort[ a.dungeon ] == GBB.dungeonSort[ b.dungeon ] then
    if a.last < b.last then
      return true
    elseif (a.start == b.start and a.name > b.name) then
      return true
    end
  end
  return false
end

local function CreateHeader( yy, dungeon )
  local AnchorTop = "GroupBulletinBoardFrame_ScrollChildFrame"
  local AnchorRight = "GroupBulletinBoardFrame_ScrollChildFrame"
  local ItemFrameName = "GBB.Dungeon_" .. dungeon

  if GBB.FramesEntries[ dungeon ] == nil then
    GBB.FramesEntries[ dungeon ] = CreateFrame( "Frame", ItemFrameName, GroupBulletinBoardFrame_ScrollChildFrame,
      "GroupBulletinBoard_TmpHeader" )
    GBB.FramesEntries[ dungeon ]:SetPoint( "RIGHT", _G[ AnchorRight ], "RIGHT", 0, 0 )
    _G[ ItemFrameName .. "_name" ]:SetPoint( "RIGHT", GBB.FramesEntries[ dungeon ], "RIGHT", 0, 0 )
    local fname, h = _G[ ItemFrameName .. "_name" ]:GetFont()
    _G[ ItemFrameName .. "_name" ]:SetHeight( h )
    _G[ ItemFrameName ]:SetHeight( h + 5 )
    _G[ ItemFrameName .. "_name" ]:SetFontObject( GBB.DB.FontSize )
  end

  local colTXT
  if GBB.DB.ColorOnLevel and GBB.dungeonLevel[ dungeon ] then
    if GBB.dungeonLevel[ dungeon ][ 1 ] == 0 then
      colTXT = "|r"
    elseif GBB.dungeonLevel[ dungeon ][ 2 ] < GBB.UserLevel then
      colTXT = "|cFFAAAAAA"
    elseif GBB.UserLevel < GBB.dungeonLevel[ dungeon ][ 1 ] then
      colTXT = "|cffff4040"
    else
      colTXT = "|cff00ff00"
    end
  else
    colTXT = "|r"
  end

  -- Add consistent spacing between dungeon groups
  if LastDungeon ~= "" then
    yy = yy + 3
  end

  if GBB.FoldedDungeons[ dungeon ] == true then
    colTXT = colTXT .. "[+] "
    lastIsFolded = true
  else
    lastIsFolded = false
  end

  _G[ ItemFrameName .. "_name" ]:SetText( colTXT .. GBB.dungeonNames[ dungeon ] ..
    " |cFFAAAAAA" .. GBB.LevelRange( dungeon ) .. "|r" )
  _G[ ItemFrameName .. "_name" ]:SetFontObject( GBB.DB.FontSize )
  GBB.FramesEntries[ dungeon ]:SetPoint( "TOPLEFT", _G[ AnchorTop ], "TOPLEFT", 0, -yy )
  GBB.FramesEntries[ dungeon ]:Show()

  yy = yy + _G[ ItemFrameName ]:GetHeight()
  LastDungeon = dungeon
  return yy
end


local function CreateSubHeader( yy, subheaderText )
  local AnchorTop = "GroupBulletinBoardFrame_ScrollChildFrame"
  local SubHeaderFrameName = "GBB.SubHeader_" .. yy .. "_" .. time()

  -- Create a simple subheader frame
  local subHeaderFrame = CreateFrame( "Frame", SubHeaderFrameName, GroupBulletinBoardFrame_ScrollChildFrame )
  subHeaderFrame:SetSize( GroupBulletinBoardFrame:GetWidth() - 40, 16 )
  subHeaderFrame:SetPoint( "TOPLEFT", _G[ AnchorTop ], "TOPLEFT", 10, -yy )

  -- Create text for subheader
  local subHeaderText = subHeaderFrame:CreateFontString(nil, "OVERLAY")
  subHeaderText:SetFontObject( "GameFontNormalSmall" )
  subHeaderText:SetText( "  " .. subheaderText )
  subHeaderText:SetPoint( "LEFT", subHeaderFrame, "LEFT", 0, 0 )
  subHeaderText:SetTextColor( 0.8, 0.8, 0.8, 1 )

  subHeaderFrame:Show()

  -- Store reference for cleanup
  if not GBB.SubHeaders then
    GBB.SubHeaders = {}
  end
  table.insert( GBB.SubHeaders, subHeaderFrame )

  return yy + 16
end

local function CreateItem( yy, i, doCompact, req, forceHight )
  local AnchorTop = "GroupBulletinBoardFrame_ScrollChildFrame"
  local AnchorRight = "GroupBulletinBoardFrame_ScrollChildFrame"
  local ItemFrameName = "GBB.Item_" .. i .. "_" .. GetTime()

  -- ALWAYS destroy and recreate to prevent overlapping
  if GBB.FramesEntries[ i ] then
    GBB.FramesEntries[ i ]:Hide()
    GBB.FramesEntries[ i ]:ClearAllPoints()
    GBB.FramesEntries[ i ]:SetParent(nil)
    GBB.FramesEntries[ i ] = nil
  end

  -- Clean up any existing global frame with this name
  local existingFrame = _G[ItemFrameName]
  if existingFrame then
    existingFrame:Hide()
    existingFrame:ClearAllPoints()
    existingFrame:SetParent(nil)
    _G[ItemFrameName] = nil
    _G[ItemFrameName .. "_name"] = nil
    _G[ItemFrameName .. "_message"] = nil
    _G[ItemFrameName .. "_time"] = nil
  end

  -- Additional cleanup: remove any frames that might have the old naming pattern
  local oldFrameName = "GBB.Item_" .. i
  local oldFrame = _G[oldFrameName]
  if oldFrame then
    oldFrame:Hide()
    oldFrame:ClearAllPoints()
    oldFrame:SetParent(nil)
    _G[oldFrameName] = nil
    _G[oldFrameName .. "_name"] = nil
    _G[oldFrameName .. "_message"] = nil
    _G[oldFrameName .. "_time"] = nil
  end

  -- Create fresh frame
  GBB.FramesEntries[ i ] = CreateFrame( "Frame", ItemFrameName, GroupBulletinBoardFrame_ScrollChildFrame,
    "GroupBulletinBoard_TmpRequest" )

  -- Set up child frames
  if _G[ ItemFrameName .. "_name" ] then
    _G[ ItemFrameName .. "_name" ]:SetPoint( "TOPLEFT" )
  end
  if _G[ ItemFrameName .. "_time" ] then
    _G[ ItemFrameName .. "_time" ]:SetPoint( "TOP", _G[ ItemFrameName .. "_name" ], "TOP", 0, 0 )
  end

  if _G[ ItemFrameName .. "_message" ] then
    _G[ ItemFrameName .. "_message" ]:SetNonSpaceWrap( true )
    _G[ ItemFrameName .. "_message" ]:SetFontObject( GBB.DB.FontSize )
    -- Word wrapping is enabled to show full messages across multiple lines
  end
  if _G[ ItemFrameName .. "_name" ] then
    _G[ ItemFrameName .. "_name" ]:SetFontObject( GBB.DB.FontSize )
  end
  if _G[ ItemFrameName .. "_time" ] then
    _G[ ItemFrameName .. "_time" ]:SetFontObject( GBB.DB.FontSize )
  end
  if GBB.DontTrunicate then
    GBB.ClearNeeded = true
  end
  GBB.Tool.EnableHyperlink( GBB.FramesEntries[ i ] )

  -- Set initial height to a reasonable default instead of 999
  GBB.FramesEntries[ i ]:SetHeight( 20 )
  if _G[ ItemFrameName .. "_message" ] then
    _G[ ItemFrameName .. "_message" ]:SetHeight( 20 )
  end

  if GBB.DB.DontTrunicate then
    --_G[ItemFrameName .. "_message"]:SetMaxLines(99)
    if _G[ ItemFrameName .. "_message" ] then
      _G[ ItemFrameName .. "_message" ]:SetText( " " )
    end
  else
    --_G[ItemFrameName .. "_message"]:SetMaxLines(1)
    if _G[ ItemFrameName .. "_message" ] then
      _G[ ItemFrameName .. "_message" ]:SetText( " " )
    end
  end


  --_G[ItemFrameName .. "_name"]:SetScale(doCompact)
  --_G[ItemFrameName .. "_time"]:SetScale(doCompact)

  if doCompact < 1 then
    if _G[ ItemFrameName .. "_message" ] and _G[ ItemFrameName .. "_name" ] then
      _G[ ItemFrameName .. "_message" ]:SetPoint( "TOPLEFT", _G[ ItemFrameName .. "_name" ], "BOTTOMLEFT", 0, 0 )
    end
    if _G[ ItemFrameName .. "_message" ] and _G[ ItemFrameName .. "_time" ] then
      _G[ ItemFrameName .. "_message" ]:SetPoint( "RIGHT", _G[ ItemFrameName .. "_time" ], "RIGHT", 0, 0 )
    end
  else
    if _G[ ItemFrameName .. "_message" ] and _G[ ItemFrameName .. "_name" ] then
      _G[ ItemFrameName .. "_message" ]:SetPoint( "TOPLEFT", _G[ ItemFrameName .. "_name" ], "TOPRIGHT", 10, 0 )
    end
    if _G[ ItemFrameName .. "_message" ] and _G[ ItemFrameName .. "_time" ] then
      _G[ ItemFrameName .. "_message" ]:SetPoint( "RIGHT", _G[ ItemFrameName .. "_time" ], "LEFT", -10, 0 )
    end
  end

  if req then
    local prefix
    if GBB.DB.ColorByClass and req.class and RAID_CLASS_COLORS_HEX[ req.class ] then
      prefix = "|c" .. RAID_CLASS_COLORS_HEX[ req.class ]
    else
      prefix = "|r"
    end
    local ClassIcon = ""
    if GBB.DB.ShowClassIcon and req.class and GBB.Tool.IconClass[ req.class ] then
      if doCompact < 1 or GBB.DB.ChatStyle then
        ClassIcon = GBB.Tool.IconClass[ req.class ]
      else
        ClassIcon = GBB.Tool.IconClassBig[ req.class ]
      end
    end

    -- Add level display at the end of name
    local LevelText = ""
    if GBB.RealLevel[ req.name ] then
      LevelText = " |cff888888[" .. GBB.RealLevel[ req.name ] .. "]|r"
    end

    local FriendIcon = (req.IsFriend and string.format( GBB.TxtEscapePicture, GBB.FriendIcon ) or "") ..
        (req.IsGuildMember and string.format( GBB.TxtEscapePicture, GBB.GuildIcon ) or "") ..
        (req.IsPastPlayer and string.format( GBB.TxtEscapePicture, GBB.PastPlayerIcon ) or "")

    local suffix = "|r"

    -- Level and class info is now handled by icons and name colors
    -- Removed redundant [level CLASS] display

    local ti
    if GBB.DB.ShowTotalTime then
      ti = GBB.formatTime( time() - req.start )
    else
      ti = GBB.formatTime( time() - req.last )
    end

    local typePrefix
    if req.IsHeroic == true then
      local colorHex = GBB.Tool.RGBPercToHex( GBB.DB.HeroicDungeonColor.r, GBB.DB.HeroicDungeonColor.g,
        GBB.DB.HeroicDungeonColor.b )
      typePrefix = "|c00" .. colorHex .. "[" .. GBB.L[ "heroicAbr" ] .. "]     "
    elseif req.IsRaid == true then
      typePrefix = "|c00ffff00" .. "[" .. GBB.L[ "raidAbr" ] .. "]     "
    else
      local colorHex = GBB.Tool.RGBPercToHex( GBB.DB.NormalDungeonColor.r, GBB.DB.NormalDungeonColor.g,
        GBB.DB.NormalDungeonColor.b )
      typePrefix = "|c00" .. colorHex .. "[" .. GBB.L[ "normalAbr" ] .. "]    "
    end

    if GBB.DB.ChatStyle then
      if _G[ ItemFrameName .. "_name" ] then
        _G[ ItemFrameName .. "_name" ]:SetText()
      end
      if _G[ ItemFrameName .. "_message" ] then
        _G[ ItemFrameName .. "_message" ]:SetText( ClassIcon ..
          "[" .. prefix .. req.name .. suffix .. "]" .. FriendIcon .. ": " .. req.message )
      end
    else
      if _G[ ItemFrameName .. "_name" ] then
        _G[ ItemFrameName .. "_name" ]:SetText( ClassIcon .. prefix .. req.name .. LevelText .. suffix .. FriendIcon )
      end
      if _G[ ItemFrameName .. "_message" ] then
        _G[ ItemFrameName .. "_message" ]:SetText( typePrefix .. suffix .. req.message )
      end
      if _G[ ItemFrameName .. "_time" ] then
        _G[ ItemFrameName .. "_time" ]:SetText( ti )
      end
    end

    if _G[ ItemFrameName .. "_message" ] then
      _G[ ItemFrameName .. "_message" ]:SetTextColor( GBB.DB.EntryColor.r, GBB.DB.EntryColor.g, GBB.DB.EntryColor.b,
        GBB.DB.EntryColor.a )
    end
    if _G[ ItemFrameName .. "_time" ] then
      _G[ ItemFrameName .. "_time" ]:SetTextColor( GBB.DB.TimeColor.r, GBB.DB.TimeColor.g, GBB.DB.TimeColor.b,
        GBB.DB.TimeColor.a )
    end
  else
    if _G[ ItemFrameName .. "_name" ] then
      _G[ ItemFrameName .. "_name" ]:SetText( "Aag " )
    end
    if _G[ ItemFrameName .. "_message" ] then
      _G[ ItemFrameName .. "_message" ]:SetText( "Aag " )
    end
    if _G[ ItemFrameName .. "_time" ] then
      _G[ ItemFrameName .. "_time" ]:SetText( "Aag " )
    end
  end


  if GBB.DB.ChatStyle then
    if _G[ ItemFrameName .. "_time" ] then
      _G[ ItemFrameName .. "_time" ]:Hide()
    end
    if _G[ ItemFrameName .. "_name" ] then
      _G[ ItemFrameName .. "_name" ]:Hide()
      _G[ ItemFrameName .. "_name" ]:SetWidth( 1 )
    end
    if _G[ ItemFrameName .. "_time" ] then
      _G[ ItemFrameName .. "_time" ]:SetPoint( "LEFT", _G[ AnchorRight ], "RIGHT", 0, 0 )
    end
  else
    if _G[ ItemFrameName .. "_time" ] then
      _G[ ItemFrameName .. "_time" ]:Show()
    end
    if _G[ ItemFrameName .. "_name" ] then
      _G[ ItemFrameName .. "_name" ]:Show()
      -- Use precomputed widths for this render pass to avoid mid-pass reflow
      local nameWidth = (GBB.DB.widthNames and GBB.DB.widthNames > 0) and GBB.DB.widthNames or (_G[ ItemFrameName .. "_name" ]:GetStringWidth() + 10)
      _G[ ItemFrameName .. "_name" ]:SetWidth( nameWidth )
    end
    if _G[ ItemFrameName .. "_time" ] then
      local timeWidth = (GBB.DB.widthTimes and GBB.DB.widthTimes > 0) and GBB.DB.widthTimes or (_G[ ItemFrameName .. "_time" ]:GetStringWidth() + 10)
      _G[ ItemFrameName .. "_time" ]:SetPoint( "RIGHT", GBB.FramesEntries[ i ], "RIGHT", -10, 0 )
    end
  end

  -- Set message frame width BEFORE calculating height so wrapping works correctly
  if _G[ ItemFrameName .. "_message" ] then
    local frameWidth = GroupBulletinBoardFrame:GetWidth() - 40
    if doCompact >= 1 then
      -- In compact mode, account for name and time columns
      frameWidth = frameWidth - 150
    end
    _G[ ItemFrameName .. "_message" ]:SetWidth( frameWidth )
  end

  local h
  if GBB.DB.ChatStyle then
    if _G[ ItemFrameName .. "_message" ] then
      h = _G[ ItemFrameName .. "_message" ]:GetStringHeight()
    else
      h = 16
    end
  else
    if doCompact < 1 then
      h = 0
      if _G[ ItemFrameName .. "_name" ] then
        h = h + _G[ ItemFrameName .. "_name" ]:GetStringHeight()
      end
      if _G[ ItemFrameName .. "_message" ] then
        h = h + _G[ ItemFrameName .. "_message" ]:GetStringHeight()
      end
    elseif GBB.DB.DontTrunicate then
      if _G[ ItemFrameName .. "_message" ] then
        h = _G[ ItemFrameName .. "_message" ]:GetStringHeight()
      else
        h = 16
      end
    else
      -- In compact mode, include both name and message height for wrapped messages
      h = 0
      if _G[ ItemFrameName .. "_name" ] then
        h = h + _G[ ItemFrameName .. "_name" ]:GetStringHeight()
      end
      if _G[ ItemFrameName .. "_message" ] and req and req.message then
        h = h + _G[ ItemFrameName .. "_message" ]:GetStringHeight()
      end
      if h == 0 then
        h = 16
      end
    end
  end

  if not GBB.DB.DontTrunicate and forceHight then
    h = forceHight
  end

  -- Ensure minimum height to prevent overlapping
  h = math.max(h, 16)

  -- Indent entries slightly to the right for visual clarity
  GBB.FramesEntries[ i ]:SetPoint( "TOPLEFT", _G[ AnchorTop ], "TOPLEFT", 10, -yy )
  if _G[ ItemFrameName .. "_message" ] then
    _G[ ItemFrameName .. "_message" ]:SetHeight( h )
  end
  GBB.FramesEntries[ i ]:SetHeight( h )

  -- Ensure the frame has proper width and is visible
  GBB.FramesEntries[ i ]:SetWidth( GroupBulletinBoardFrame:GetWidth() - 40 )
  GBB.FramesEntries[ i ]:SetAlpha( 1 )

  -- Ensure frame is properly parented to prevent floating
  if GBB.FramesEntries[ i ]:GetParent() ~= GroupBulletinBoardFrame_ScrollChildFrame then
    GBB.FramesEntries[ i ]:SetParent(GroupBulletinBoardFrame_ScrollChildFrame)
  end

  if req then
    GBB.FramesEntries[ i ]:Show()
  else
    GBB.FramesEntries[ i ]:Hide()
  end

  return h
end

function GBB.WhoRequest( name )
  -- Check if we already have class data for this player
  local hasClassData = false
  for i, req in pairs(GBB.RequestList) do
    if type(req) == "table" and req.name == name and req.class and req.class ~= "" then
      hasClassData = true
      break
    end
  end

  -- Also check if we have level data (though we might still want to refresh it)
  local hasLevelData = GBB.RealLevel[name] and GBB.RealLevel[name] > 0

  -- If we already have both class and level, skip the lookup
  if hasClassData and hasLevelData then
    return  -- Already have all the data we need
  end

  -- Store the name we're looking for
  GBB.PendingWhoRequest = name

  -- Use SendWho API instead of slash command to avoid chat spam
  if SendWho then
    SendWho( name )
  else
    -- Fallback to slash command if SendWho doesn't exist
    GBB.Tool.RunSlashCmd( "/who " .. name )
  end

  -- Directly check results after a short delay (more reliable than waiting for event)
  -- This is faster and ensures we get the data even if event doesn't fire
  local attempts = 0
  local maxAttempts = 2  -- Reduced attempts for speed

  local function checkWhoResults()
    attempts = attempts + 1
    local numWhos = GetNumWhoResults()

    if numWhos > 0 then
      for j = 1, numWhos do
        local whoName, guild, level, race, class, zone, classFileName, area, isOnline = GetWhoInfo(j)

        if whoName and whoName == name then
          -- Extract class once
          local newClass = nil
          if classFileName and classFileName ~= "" and classFileName ~= "UNKNOWN" then
            newClass = classFileName
          elseif class and class ~= "" and class ~= "Unknown" then
            -- Convert class name to file name format
            local classUpper = string.upper(string.gsub(class, "%s+", ""))
            local classMap = {
              ["WARRIOR"] = "WARRIOR", ["PALADIN"] = "PALADIN", ["HUNTER"] = "HUNTER",
              ["ROGUE"] = "ROGUE", ["PRIEST"] = "PRIEST", ["DEATHKNIGHT"] = "DEATHKNIGHT",
              ["SHAMAN"] = "SHAMAN", ["MAGE"] = "MAGE", ["WARLOCK"] = "WARLOCK", ["DRUID"] = "DRUID"
            }
            newClass = classMap[classUpper] or classUpper
          end

          -- Update all requests for this player (use pairs to ensure we get all entries)
          local updated = false

          for i, req in pairs(GBB.RequestList) do
            if type(req) == "table" and req.name == name then
              -- Always update class if we have new data (force update)
              if newClass and newClass ~= "" then
                req.class = newClass
                updated = true
              end

              -- Update level (shared across all entries for this name)
              if level and level > 0 then
                GBB.RealLevel[req.name] = level
                updated = true
              end
            end
          end

          -- Force update display to ensure all entries show the new class
          if updated then
            GBB.UpdateList()
          end
          return -- Found and processed, exit
        end
      end
    end

    -- If we didn't find the player and haven't exceeded max attempts, try again
    if attempts < maxAttempts then
      C_Timer.After(0.2, checkWhoResults)  -- Reduced delay for speed
    end
  end

  -- Start checking after a very short delay
  C_Timer.After(0.1, checkWhoResults)  -- Faster initial check
end

local function WhisperRequest( name )
  ChatFrame_OpenChat( "/w " .. name .. " " )
end

local function InviteRequest( name )
  GBB.Tool.RunSlashCmd( "/invite " .. name )
end

local function IgnoreRequest( name )
  for ir, req in pairs( GBB.RequestList ) do
    if type( req ) == "table" and req.name == name then
      req.last = 0
    end
  end
  GBB.ClearNeeded = true
  C_FriendList.AddIgnore( name )
end

function GBB.Clear()
  if GBB.ClearNeeded or GBB.ClearTimer < time() then
    local newRequest = {}
    GBB.ClearTimer = GBB.MAXTIME

    for i, req in pairs( GBB.RequestList ) do
      if type( req ) == "table" and req.last then
        if req.last + GBB.DB.TimeOut * 3 > time() then
          if req.last < GBB.ClearTimer then
            GBB.ClearTimer = req.last
          end
          newRequest[ #newRequest + 1 ] = req
        end
      end
    end
    GBB.RequestList = newRequest
    GBB.ClearTimer = GBB.ClearTimer + GBB.DB.TimeOut * 3
    GBB.ClearNeeded = false
  end
end

local ownRequestDungeons = {}
function GBB.UpdateList()
  -- COMPLETE RESET: Destroy all existing frames to prevent overlapping
  if GBB.FramesEntries then
    for i = 1, 100 do
      if GBB.FramesEntries[i] then
        GBB.FramesEntries[i]:Hide()
        GBB.FramesEntries[i]:ClearAllPoints()
        GBB.FramesEntries[i]:SetParent(nil)
        GBB.FramesEntries[i] = nil
      end
    end
  end

  -- Clean up ALL global frames
  for i = 1, 1000 do
    local frame = _G["GBB.Item_" .. i]
    if frame then
      frame:Hide()
      frame:ClearAllPoints()
      frame:SetParent(nil)
      _G["GBB.Item_" .. i] = nil
      _G["GBB.Item_" .. i .. "_name"] = nil
      _G["GBB.Item_" .. i .. "_message"] = nil
      _G["GBB.Item_" .. i .. "_time"] = nil
    end
  end

  GBB.Clear()

  if not GroupBulletinBoardFrame:IsVisible() then
    -- Don't return early - we still want to process requests even if frame is not visible
    -- return
  end

  -- Check if we need to update after /who command
  if GBB.WhoUpdateTimer and time() >= GBB.WhoUpdateTimer then
    GBB.WhoUpdateTimer = nil
    -- Force a refresh of the display
  end

  GBB.UserLevel = UnitLevel( "player" )

  -- Disable sorting to prevent list shuffling
  -- if GBB.DB.OrderNewTop then
  --   if GBB.DB.ShowTotalTime then
  --     table.sort( GBB.RequestList, requestSort_TOP_TOTAL )
  --   else
  --     -- BUG: invalid order function for sorting
  --     table.sort( GBB.RequestList, requestSort_TOP_nTOTAL )
  --   end
  -- else
  --   if GBB.DB.ShowTotalTime then
  --     table.sort( GBB.RequestList, requestSort_nTOP_TOTAL )
  --   else
  --     table.sort( GBB.RequestList, requestSort_nTOP_nTOTAL )
  --   end
  -- end






  local AnchorTop = "GroupBulletinBoardFrame_ScrollChildFrame"
  local AnchorRight = "GroupBulletinBoardFrame_ScrollChildFrame"
  local yy = 10  -- Start with small top margin
  LastDungeon = ""
  local count = 0
  local doCompact = 1
  local cEntrys = 0

  local w = GroupBulletinBoardFrame:GetWidth() - 20 - 10 - 10
  if GBB.DB.CompactStyle and not GBB.DB.ChatStyle then
    doCompact = 0.85
  end

  lastIsFolded = false

  wipe( ownRequestDungeons )
  if GBB.DBChar.DontFilterOwn then
    local playername = (GBB.api.UnitFullName( "player" ))

    for i, req in pairs( GBB.RequestList ) do
      if type( req ) == "table" and req.name == playername and req.last and req.last + GBB.DB.TimeOut * 2 > time() then
        ownRequestDungeons[ req.dungeon ] = true
      end
    end
  end

  local itemHight = CreateItem( yy, 0, doCompact, nil )

  -- Hide all frames first and reset their positions
  for i = 1, 100 do
    if GBB.FramesEntries[i] then
      GBB.FramesEntries[i]:Hide()
      GBB.FramesEntries[i]:ClearAllPoints()
      -- Reset height to prevent accumulation
      GBB.FramesEntries[i]:SetHeight(1)
    end
  end

  -- Hide all subheaders and clear their points
  if GBB.SubHeaders then
    for _, subHeader in ipairs( GBB.SubHeaders ) do
      if subHeader then
        subHeader:Hide()
        subHeader:ClearAllPoints()
        subHeader:SetParent(nil)
      end
    end
    GBB.SubHeaders = {}
  end

  -- Also clean up any orphaned subheaders by searching for them
  for i = 1, 1000 do
    local frame = _G["GBB.SubHeader_" .. i]
    if frame then
      frame:Hide()
      frame:ClearAllPoints()
      frame:SetParent(nil)
    end
  end

  -- First, collect all valid requests organized by dungeon and LFG/LFM type
  local dungeonRequests = {}
  for i, req in pairs( GBB.RequestList ) do
    if type( req ) == "table" then
      -- Skip Miscellaneous category entirely
      if req.dungeon == "MISC" then
        -- do not render or count
      elseif req.dungeon ~= "TRADE" and (ownRequestDungeons[ req.dungeon ] == true or GBB.FilterDungeon( req.dungeon, req.IsHeroic, req.IsRaid )) and req.last and req.last + GBB.DB.TimeOut > time() then
        count = count + 1

        -- Detect LFG vs LFM based on message content
        local isLFG = false
        local isLFM = false
        if req.message then
          local msg = string.lower(req.message)
          -- Look for LFM indicators first (looking for members) - more specific
          if string.find(msg, "lfm") or
             string.find(msg, "looking for members") or
             string.find(msg, "looking for more") or
             string.find(msg, "need members") or
             string.find(msg, "need dps") or
             string.find(msg, "need healer") or
             string.find(msg, "need tank") or
             string.find(msg, "need %d+") or
             string.find(msg, "looking for %d+") then
            isLFM = true
          -- Look for LFG indicators (looking for group)
          elseif string.find(msg, "lfg") or
                 string.find(msg, "looking for group") or
                 string.find(msg, "need group") or
                 string.find(msg, "need invite") or
                 string.find(msg, "want to join") then
            isLFG = true
          else
            -- Default to LFG if no clear indicator
            isLFG = true
          end
        else
          isLFG = true
        end

        if not dungeonRequests[ req.dungeon ] then
          dungeonRequests[ req.dungeon ] = { lfg = {}, lfm = {} }
        end

        local requestData = { req = req, index = i, isLFG = isLFG, isLFM = isLFM }
        if isLFG then
          table.insert( dungeonRequests[ req.dungeon ].lfg, requestData )
        else
          table.insert( dungeonRequests[ req.dungeon ].lfm, requestData )
        end
      end
    end
  end

  -- Track which dungeons are being shown (have entries)
  local shownDungeons = {}

  -- Now process each dungeon in order
  for dungeonIndex = 1, GBB.TBCMAXDUNGEON do
    local dungeon = GBB.dungeonSort[ dungeonIndex ]
    if dungeon and dungeonRequests[ dungeon ] then
      local dungeonData = dungeonRequests[ dungeon ]
      local hasLFG = #dungeonData.lfg > 0
      local hasLFM = #dungeonData.lfm > 0

      -- Only show dungeon if it has requests
      if hasLFG or hasLFM then
        -- Mark this dungeon as shown
        shownDungeons[ dungeon ] = true
        -- Create header for this dungeon
        yy = CreateHeader( yy, dungeon )
        cEntrys = 0

        local isFolded = GBB.FoldedDungeons[ dungeon ] == true

        if not isFolded then
          -- Process LFG entries first
          if hasLFG then
            -- Render LFG entries directly (no subheader for compact view)
            for _, entryData in ipairs( dungeonData.lfg ) do
              local i = entryData.index
              -- Get the current req from GBB.RequestList to ensure we have the latest data
              local req = GBB.RequestList[i]

              if not GBB.DB.EnableShowOnly or cEntrys < GBB.DB.ShowOnlyNb then
                local itemHeight = CreateItem( yy, i, doCompact, req, itemHight )
                yy = yy + itemHeight + 1
                cEntrys = cEntrys + 1
              else
                if GBB.FramesEntries[i] then
                  GBB.FramesEntries[i]:Hide()
                end
              end
            end
          end

          -- Process LFM entries (no subheader for compact view)
          if hasLFM then
            for _, entryData in ipairs( dungeonData.lfm ) do
              local i = entryData.index
              -- Get the current req from GBB.RequestList to ensure we have the latest data
              local req = GBB.RequestList[i]

              if not GBB.DB.EnableShowOnly or cEntrys < GBB.DB.ShowOnlyNb then
                local itemHeight = CreateItem( yy, i, doCompact, req, itemHight )
                yy = yy + itemHeight + 1
                cEntrys = cEntrys + 1
              else
                if GBB.FramesEntries[i] then
                  GBB.FramesEntries[i]:Hide()
                end
              end
            end
          end
        else
          -- Hide all frames if dungeon is folded
          for _, entryData in ipairs( dungeonData.lfg ) do
            if GBB.FramesEntries[entryData.index] then
              GBB.FramesEntries[entryData.index]:Hide()
            end
          end
          for _, entryData in ipairs( dungeonData.lfm ) do
            if GBB.FramesEntries[entryData.index] then
              GBB.FramesEntries[entryData.index]:Hide()
            end
          end
        end
      end
    end
  end

  -- Hide all dungeon headers that don't have entries
  for dungeonIndex = 1, GBB.TBCMAXDUNGEON do
    local dungeon = GBB.dungeonSort[ dungeonIndex ]
    if dungeon and GBB.FramesEntries[ dungeon ] then
      -- If this dungeon wasn't shown (no entries), hide its header
      if not shownDungeons[ dungeon ] then
        GBB.FramesEntries[ dungeon ]:Hide()
        GBB.FramesEntries[ dungeon ]:ClearAllPoints()
      end
    end
  end

  -- ROBUST SPACING: Ensure proper spacing between entries
  local totalHeight = yy + 50  -- Extra padding to prevent overlapping

  -- Set the scroll child frame height to accommodate all content
  GroupBulletinBoardFrame_ScrollChildFrame:SetHeight( totalHeight )

  -- Force multiple layout updates to prevent overlapping
  GroupBulletinBoardFrame_ScrollFrame:UpdateScrollChildRect()
  if GroupBulletinBoardFrame_ScrollChildFrame then
    GroupBulletinBoardFrame_ScrollChildFrame:GetParent():UpdateScrollChildRect()
  end

  -- Additional layout update after a short delay
  C_Timer.After(0.01, function()
    if GroupBulletinBoardFrame_ScrollFrame then
      GroupBulletinBoardFrame_ScrollFrame:UpdateScrollChildRect()
    end
  end)

  GroupBulletinBoardFrameStatusText:SetText( string.format( GBB.L[ "msgNbRequest" ], count ) )

  -- No periodic cleanup needed - we do complete resets every time
end

local nonLfgHyperlinks = {
  [ "|Hglyph:" ] = true,
  [ "|Hspell:" ] = true,
  [ "|Henchant:" ] = true,
  [ "|Htalent:" ] = true,
  [ "|Htrade:" ] = true,
}

local function hasNonLfgHyperlinks( msg )
  for k, v in pairs( nonLfgHyperlinks ) do
    -- literal string match, not pattern
    if strfind( msg, k, 1, true ) then
      return true
    end
  end
  return false
end

function GBB.GetDungeons( msg, name )
  if msg == nil then return {} end
  local dungeons = {}

  local isBad = false
  local isGood = false
  local isHeroic = false

  local runrequired = false
  local hasrun = false
  local runDungeon = ""

  local wordcount = 0

  if GBB.DB.TagsZhtw then
    for key, v in pairs( GBB.tagList ) do
      if strfind( msg:lower(), key ) then
        if v == GBB.TAGSEARCH then
          isGood = true
        elseif v == GBB.TAGBAD then
          break
        elseif v ~= nil then
          dungeons[ v ] = true
        end
      end
    end
    for key, v in pairs( GBB.HeroicKeywords ) do
      if strfind( msg:lower(), key ) then
        isHeroic = true
      end
    end
    wordcount = string.len( msg )
  else
    local parts = GBB.SplitNoNb( msg )
    for _, p in pairs( parts ) do
      if p == "run" or p == "runs" then
        hasrun = true
      end

      local x = GBB.tagList[ p ]

      if GBB.HeroicKeywords[ p ] ~= nil then
        isHeroic = true
      end

      if x == nil then
        if GBB.tagList[ p .. "run" ] ~= nil then
          runDungeon = GBB.tagList[ p .. "run" ]
          runrequired = true
        end
      elseif x == GBB.TAGBAD then
        isBad = true
        break
      elseif x == GBB.TAGSEARCH then
        isGood = true
      else
        dungeons[ x ] = true
      end
    end
    wordcount = #(parts)
  end

  if runrequired and hasrun and runDungeon and isBad == false then
    dungeons[ runDungeon ] = true
  end

  local nameLevel = 0
  if name ~= nil then
    if GBB.RealLevel[ name ] then
      nameLevel = GBB.RealLevel[ name ]
    else
      for dungeon, id in pairs( dungeons ) do
        if GBB.dungeonLevel[ dungeon ] and GBB.dungeonLevel[ dungeon ][ 1 ] > 0 and nameLevel < GBB.dungeonLevel[ dungeon ][ 1 ] then
          nameLevel = GBB.dungeonLevel[ dungeon ][ 1 ]
        end
      end
    end
  end

  if dungeons[ "DEADMINES" ] and not dungeons[ "DMW" ] and not dungeons[ "DME" ] and not dungeons[ "DME" ] and name ~= nil then
    if nameLevel > 0 and nameLevel < 40 then
      dungeons[ "DM" ] = true
      dungeons[ "DM2" ] = false
    else
      dungeons[ "DM" ] = false
      dungeons[ "DM2" ] = true
    end
  end

  -- Irrelevant hyperlinks in lfg messages invalidate message
  if not dungeons [ "MISC" ]
      and hasNonLfgHyperlinks( msg ) then
    isBad = true
    isGood = false
  end

  if isBad then
    --dungeons={}
  elseif isGood then
    for ip, p in pairs( GBB.dungeonSecondTags ) do
      local ok = false
      if dungeons[ ip ] == true then
        for it, t in ipairs( p ) do
          if string.sub( t, 1, 1 ) == "-" then
            if dungeons[ string.sub( t, 2 ) ] == true then
              ok = true
            end
          elseif dungeons[ t ] == true then
            ok = true
          end
        end
        if ok == false then
          for it, t in ipairs( p ) do
            if string.sub( t, 1, 1 ) ~= "-" then
              dungeons[ t ] = true
            end
          end
        end
      end
    end

    if next( dungeons ) == nil then
      dungeons[ "MISC" ] = true
    end
  end
  -- Remove TRADE handling entirely

  -- remove all secondtags-dungeons
  for ip, p in pairs( GBB.dungeonSecondTags ) do
    if dungeons[ ip ] == true then
      dungeons[ ip ] = nil
    end
  end

  if GBB.DB.CombineSubDungeons then
    for ip, p in pairs( GBB.dungeonSecondTags ) do
      if ip ~= "DEATHMINES" then
        for is, subDungeon in pairs( p ) do
          if dungeons[ subDungeon ] then
            dungeons[ ip ] = true
            dungeons[ subDungeon ] = nil
          end
        end
      end
    end
  end


  -- Finally, drop MISC entirely so it never appears or gets created
  dungeons[ "MISC" ] = nil
  return dungeons, isGood, isBad, wordcount, isHeroic
end

local function is_non_ascii( text )
  if not text then return false end

  for i = 1, #text do
    if text:byte( i ) > 127 then return true end
  end

  return false
end

-- LFG addon integration
function GBB.ParseLFGMessage( msg, name, channel )
  -- Check if this is an LFG addon message
  if string.sub(msg, 1, 4) == 'LFG:' then
    if GBB.DB.OnDebug then
      print("GBB: Parsing LFG addon message from " .. tostring(name))
    end

    local requestTime = time()
    local doUpdate = false

    -- Parse LFG format: "LFG:dungeoncode:role dungeoncode:role ..."
    local lfgEx = GBB.Tool.Split(msg, ' ')

    for _, lfg in ipairs(lfgEx) do
      local spamSplit = GBB.Tool.Split(lfg, ':')
      local mDungeonCode = spamSplit[2]
      local mRole = spamSplit[3]

      if mDungeonCode and mRole then
        local dungeonName = GBB.GetDungeonNameFromLFGCode(mDungeonCode)
        if dungeonName then
          -- Create a synthetic message for GBB processing
          -- The role indicates what the person is PROVIDING, so they're looking for a group
          local syntheticMsg = "LFG " .. dungeonName .. " " .. mRole

          if GBB.DB.OnDebug then
            print("GBB: LFG -> " .. tostring(name) .. " providing " .. mRole .. " for " .. dungeonName)
          end

          -- Process as regular GBB message
          local dungeonList, isGood, isBad, wordcount, isHeroic = GBB.GetDungeons( syntheticMsg, name )

          if type( dungeonList ) == "table" and next( dungeonList ) then
            for dungeon, id in pairs( dungeonList ) do
              if id == true and dungeon ~= nil and dungeon ~= "TRADE" and dungeon ~= "MISC" then
                local index = 0

                -- Check if entry already exists
                for ir, req in pairs( GBB.RequestList ) do
                  if type( req ) == "table" and req.name == name and req.dungeon == dungeon then
                    index = ir
                    break
                  end
                end

                local isRaid = GBB.RaidList[ dungeon ] ~= nil

                if index == 0 then
                  index = #GBB.RequestList + 1
                  GBB.RequestList[ index ] = {}
                  GBB.RequestList[ index ].name = name
                  -- Try to preserve class from existing entries for this player
                  local existingClass = nil
                  for ir, existingReq in pairs(GBB.RequestList) do
                    if type(existingReq) == "table" and existingReq.name == name and existingReq.class then
                      existingClass = existingReq.class
                      break
                    end
                  end
                  GBB.RequestList[ index ].class = existingClass
                  GBB.RequestList[ index ].start = requestTime
                  GBB.RequestList[ index ].dungeon = dungeon
                  GBB.RequestList[ index ].IsGuildMember = false
                  GBB.RequestList[ index ].IsFriend = false
                  GBB.RequestList[ index ].IsPastPlayer = GBB.GroupTrans[ name ] ~= nil
                end

                if GBB.FilterDungeon( dungeon, isHeroic, isRaid ) then
                  GBB.RequestList[ index ].message = syntheticMsg
                  GBB.RequestList[ index ].IsHeroic = isHeroic
                  GBB.RequestList[ index ].IsRaid = isRaid
                  GBB.RequestList[ index ].last = requestTime
                  doUpdate = true
                end
              end
            end
          end
        end
      end
    end

    if doUpdate then
      GBB.UpdateList()
    end

    return true -- Message was processed as LFG
  end

  -- Check for LFM messages (Looking for More)
  if string.sub(msg, 1, 4) == 'LFM:' then
    if GBB.DB.OnDebug then
      print("GBB: Parsing LFM addon message from " .. tostring(name))
    end

    local requestTime = time()
    local doUpdate = false

    -- Parse LFM format: "LFM:dungeoncode:tankcount:healercount:damagecount"
    local lfmEx = GBB.Tool.Split(msg, ':')
    local mDungeonCode = lfmEx[2]
    local lfmTank = tonumber(lfmEx[3]) or 0
    local lfmHealer = tonumber(lfmEx[4]) or 0
    local lfmDamage = tonumber(lfmEx[5]) or 0

    if mDungeonCode then
      local dungeonName = GBB.GetDungeonNameFromLFGCode(mDungeonCode)
      if dungeonName then
        -- Create synthetic message for LFM (Looking for More)
        local syntheticMsg = "LFM " .. dungeonName
        if lfmTank > 0 then
          syntheticMsg = syntheticMsg .. " need " .. lfmTank .. " tank"
        end
        if lfmHealer > 0 then
          syntheticMsg = syntheticMsg .. " need " .. lfmHealer .. " healer"
        end
        if lfmDamage > 0 then
          syntheticMsg = syntheticMsg .. " need " .. lfmDamage .. " dps"
        end

        -- Process the synthetic LFM message
        local dungeonList, isGood, isBad, wordcount, isHeroic = GBB.GetDungeons( syntheticMsg, name )

        if type( dungeonList ) == "table" and next( dungeonList ) then
          for dungeon, id in pairs( dungeonList ) do
            if id == true and dungeon ~= nil and dungeon ~= "TRADE" and dungeon ~= "MISC" then
              local index = 0

              -- Check if entry already exists
              for ir, req in pairs( GBB.RequestList ) do
                if type( req ) == "table" and req.name == name and req.dungeon == dungeon then
                  index = ir
                  break
                end
              end

              local isRaid = GBB.RaidList[ dungeon ] ~= nil

              if index == 0 then
                index = #GBB.RequestList + 1
                GBB.RequestList[ index ] = {}
                GBB.RequestList[ index ].name = name
                -- Try to preserve class from existing entries for this player
                local existingClass = nil
                for ir, existingReq in pairs(GBB.RequestList) do
                  if type(existingReq) == "table" and existingReq.name == name and existingReq.class then
                    existingClass = existingReq.class
                    break
                  end
                end
                GBB.RequestList[ index ].class = existingClass
                GBB.RequestList[ index ].start = requestTime
                GBB.RequestList[ index ].dungeon = dungeon
                GBB.RequestList[ index ].IsGuildMember = false
                GBB.RequestList[ index ].IsFriend = false
                GBB.RequestList[ index ].IsPastPlayer = GBB.GroupTrans[ name ] ~= nil
              end

              if GBB.FilterDungeon( dungeon, isHeroic, isRaid ) then
                GBB.RequestList[ index ].message = syntheticMsg
                GBB.RequestList[ index ].IsHeroic = isHeroic
                GBB.RequestList[ index ].IsRaid = isRaid
                GBB.RequestList[ index ].last = requestTime
                doUpdate = true
              end
            end
          end
        end

        if GBB.DB.OnDebug then
          print("GBB: LFM -> " .. tostring(name) .. " needs " .. (lfmTank + lfmHealer + lfmDamage) .. " for " .. dungeonName)
        end
      end
    end

    if doUpdate then
      GBB.UpdateList()
    end

    return true -- Message was processed as LFM
  end

  return false -- Not an LFG message
end

function GBB.GetDungeonNameFromLFGCode( code )
  -- Map LFG addon codes to GBB dungeon names
  local lfgToGBB = {
    -- Regular dungeons
    ['rfc'] = 'Ragefire Chasm',
    ['wc'] = 'Wailing Caverns',
    ['dm'] = 'Deadmines',
    ['sfk'] = 'Shadowfang Keep',
    ['stocks'] = 'The Stockade',
    ['bfd'] = 'Blackfathom Deeps',
    ['smgy'] = 'Scarlet Monastery Graveyard',
    ['smlib'] = 'Scarlet Monastery Library',
    ['gnomer'] = 'Gnomeregan',
    ['rfk'] = 'Razorfen Kraul',
    ['smarmory'] = 'Scarlet Monastery Armory',
    ['smcath'] = 'Scarlet Monastery Cathedral',
    ['rfd'] = 'Razorfen Downs',
    ['ggm'] = 'Glittermurk Mines',
    ['ulda'] = 'Uldaman',
    ['zf'] = 'Zul\'Farrak',
    ['maraorange'] = 'Maraudon Orange',
    ['marapurple'] = 'Maraudon Purple',
    ['maraprincess'] = 'Maraudon Princess',
    ['st'] = 'Temple of Atal\'Hakkar',
    ['brd'] = 'Blackrock Depths',
    ['brdarena'] = 'Blackrock Depths Arena',
    ['brdemp'] = 'Blackrock Depths Emperor',
    ['lbrs'] = 'Lower Blackrock Spire',
    ['bh'] = 'Baradin Hold',
    ['scholo'] = 'Scholomance',
    ['stratud'] = 'Stratholme: Undead District',
    ['stratlive'] = 'Stratholme: Scarlet Bastion',
    ['ubrs'] = 'Upper Blackrock Spire',

    -- Elite encounters
    ['ja'] = 'Jintha\'Alor',
    ['ff'] = 'Felstone Fortress',
    ['silithusd'] = 'Silithus Dailies'
  }

  return lfgToGBB[code]
end

function GBB.ParseMessage( msg, name, channel )
  if GBB.Initalized == false or name == nil or name == "" or msg == nil or msg == "" or string.len( msg ) < 4 then
    if GBB.DB.OnDebug then
      print("GBB: ParseMessage rejected - Initalized: " .. tostring(GBB.Initalized) .. ", name: " .. tostring(name) .. ", msg: " .. tostring(msg))
    end
    return
  end

  if GBB.DB.OnDebug then
    print("GBB: " .. tostring(name) .. ": " .. tostring(msg))
  end

  if GBB.DB.FilterNonAsciiMessages and is_non_ascii( msg ) then
    if GBB.DB.OnDebug then
      print("GBB: Message filtered out - contains non-ASCII characters")
    end
    return
  end

  -- Check if this is an LFG addon message and parse it
  if GBB.ParseLFGMessage( msg, name, channel ) then
    return
  end

  local requestTime = time()
  local doUpdate = false

  --name = GBB.Tool.Split( name, "-" )[ 1 ] -- remove GBB.ServerName

  if GBB.DB.RemoveRaidSymbols then
    msg = string.gsub( msg, "{.-}", "*" )
  else
    msg = string.gsub( msg, "{.-}", GBB.Tool.GetRaidIcon )
  end

  local updated = false

  for _, req in pairs( GBB.RequestList ) do
    if type( req ) == "table" and req.name == name and req.last and req.last + GBB.COMBINEMSGTIMER >= requestTime then
      if req.dungeon == "TRADE" then
        updated = true
        if msg ~= req.message then
          req.message = req.message .. "|n" .. msg
        end
      elseif req.dungeon ~= "DEBUG" and req.dungeon ~= "BAD" then
        if msg ~= req.message then
          msg = req.message .. "|n" .. msg
        end
        break
      end
    end
  end

  if updated == true then return end

  --flm RFD need healer and 3 dps
  local dungeonList, isGood, isBad, wordcount, isHeroic = GBB.GetDungeons( msg, name )

  if GBB.DB.OnDebug and (isGood or isBad or next(dungeonList)) then
    local dungeonCount = 0
    for k, v in pairs(dungeonList) do
      if v then dungeonCount = dungeonCount + 1 end
    end
    print("GBB: " .. tostring(name) .. " -> " .. dungeonCount .. " dungeons (good:" .. tostring(isGood) .. ", bad:" .. tostring(isBad) .. ")")
  end

  if type( dungeonList ) ~= "table" then
    if GBB.DB and GBB.DB.OnDebug then
      print("GBB: GetDungeons returned non-table for message: " .. msg)
    end
    return
  end


  local dungeonTXT = ""

  if GBB.DB.UseAllInLFG and isBad == false and isGood == false and
     (string.lower( GBB.L[ "world_channel" ] ) == string.lower( channel ) or
      string.lower( GBB.L[ "lfg_channel" ] ) == string.lower( channel )) then
    isGood = true
    if GBB.DB.OnDebug then
      print("GBB: " .. tostring(name) .. " -> marked good (UseAllInLFG)")
    end
    if next( dungeonList ) == nil then
      -- Previously defaulted to MISC; we now skip creating MISC entirely
    end
  elseif isGood == false or isBad == true then
    if GBB.DB.OnDebug then
      print("GBB: " .. tostring(name) .. " -> filtered out (good:" .. tostring(isGood) .. ", bad:" .. tostring(isBad) .. ")")
    end
    dungeonList = {}
  end


  if wordcount > 1 then
    for dungeon, id in pairs( dungeonList ) do
      local index = 0
      if id == true and dungeon ~= nil then
        if dungeon ~= "TRADE" then
          for ir, req in pairs( GBB.RequestList ) do
            if type( req ) == "table" and req.name == name and req.dungeon == dungeon then
              index = ir
              break
            end
          end
        end

        local isRaid = GBB.RaidList[ dungeon ] ~= nil

        if index == 0 then
          index = #GBB.RequestList + 1
          GBB.RequestList[ index ] = {}
          GBB.RequestList[ index ].name = name
          -- Try to preserve class from existing entries for this player
          local existingClass = nil
          for ir, existingReq in pairs(GBB.RequestList) do
            if type(existingReq) == "table" and existingReq.name == name and existingReq.class then
              existingClass = existingReq.class
              break
            end
          end
          GBB.RequestList[ index ].class = existingClass
          GBB.RequestList[ index ].start = requestTime
          GBB.RequestList[ index ].dungeon = dungeon
          GBB.RequestList[ index ].IsGuildMember = false --IsInGuild() and IsGuildMember( guid )
          GBB.RequestList[ index ].IsFriend = false      --C_FriendList.IsFriend( guid )
          GBB.RequestList[ index ].IsPastPlayer = GBB.GroupTrans[ name ] ~= nil

          if GBB.FilterDungeon( dungeon, isHeroic, isRaid ) and dungeon ~= "TRADE" then
            if dungeonTXT == "" then
              dungeonTXT = GBB.dungeonNames[ dungeon ]
            else
              dungeonTXT = GBB.dungeonNames[ dungeon ] .. ", " .. dungeonTXT
            end
            if GBB.DB.OnDebug then
              print("GBB: " .. tostring(name) .. " -> added " .. dungeon)
            end
          else
            if GBB.DB.OnDebug then
              print("GBB: " .. tostring(name) .. " -> " .. dungeon .. " filtered out")
            end
          end
        else
          if GBB.DB.OnDebug then
            print("GBB: " .. tostring(name) .. " -> updated " .. dungeon)
          end
        end

        -- Do not store entries as MISC; skip adding them entirely
        if dungeon == "MISC" then
          -- Skip
        else
          GBB.RequestList[ index ].message = msg
          GBB.RequestList[ index ].IsHeroic = isHeroic
          GBB.RequestList[ index ].IsRaid = isRaid
          GBB.RequestList[ index ].last = requestTime
          doUpdate = true
        end
      end
    end
  else
    if GBB.DB.OnDebug then
      print("GBB: " .. tostring(name) .. " -> filtered out (wordcount: " .. wordcount .. ")")
    end
  end

  if dungeonTXT ~= "" and GBB.AllowInInstance() then
    if GBB.DB.NotifyChat then
      --local FriendIcon = (C_FriendList.IsFriend( guid ) and string.format( GBB.TxtEscapePicture, GBB.FriendIcon ) or "") ..
      --((IsInGuild() and IsGuildMember( guid )) and string.format( GBB.TxtEscapePicture, GBB.GuildIcon ) or "") ..
      --(GBB.GroupTrans[ name ] ~= nil and string.format( GBB.TxtEscapePicture, GBB.PastPlayerIcon ) or "")
      local FriendIcon = ""
      local linkname = "|Hplayer:" .. name .. "|h[" .. name .. "]|h"
      if GBB.DB.OneLineNotification then
        DEFAULT_CHAT_FRAME:AddMessage( GBB.MSGPREFIX .. linkname .. FriendIcon .. ": " .. msg, GBB.DB.NotifyColor.r,
          GBB.DB.NotifyColor.g, GBB.DB.NotifyColor.b )
      else
        DEFAULT_CHAT_FRAME:AddMessage(
          GBB.MSGPREFIX .. string.format( GBB.L[ "msgNewRequest" ], linkname .. FriendIcon, dungeonTXT ),
          GBB.DB.NotifyColor.r * .8, GBB.DB.NotifyColor.g * .8, GBB.DB.NotifyColor.b * .8 )
        DEFAULT_CHAT_FRAME:AddMessage( GBB.MSGPREFIX .. msg, GBB.DB.NotifyColor.r, GBB.DB.NotifyColor.g,
          GBB.DB.NotifyColor.b )
      end
    end
    if GBB.DB.NotifySound then
      PlaySound( GBB.NotifySound )
    end
  end


  if doUpdate then
    for i, req in pairs( GBB.RequestList ) do
      if type( req ) == "table" then
        if req.name == name and req.last ~= requestTime then
          GBB.RequestList[ i ] = nil
          GBB.ClearNeeded = true
        end
      end
    end
  elseif GBB.DB.OnDebug then
    local index = #GBB.RequestList + 1
    GBB.RequestList[ index ] = {}
    GBB.RequestList[ index ].name = name
    -- Try to preserve class from existing entries for this player
    local existingClass = nil
    for ir, existingReq in pairs(GBB.RequestList) do
      if type(existingReq) == "table" and existingReq.name == name and existingReq.class then
        existingClass = existingReq.class
        break
      end
    end
    GBB.RequestList[ index ].class = existingClass
    GBB.RequestList[ index ].start = requestTime
    if isBad then
      GBB.RequestList[ index ].dungeon = "BAD"
    else
      GBB.RequestList[ index ].dungeon = "DEBUG"
    end

    GBB.RequestList[ index ].message = msg
    GBB.RequestList[ index ].IsHeroic = isHeroic
    GBB.RequestList[ index ].last = requestTime
  end

  -- Update the UI after adding/updating requests
  GBB.UpdateList()
end

function GBB.UnfoldAllDungeon()
  wipe( GBB.FoldedDungeons )
  GBB.UpdateList()
end

function GBB.FoldAllDungeon()
  for i = 1, GBB.TBCMAXDUNGEON do
    GBB.FoldedDungeons[ GBB.dungeonSort[ i ] ] = true
  end
  GBB.UpdateList()
end

local function createMenu( DungeonID, req )
  -- Make menu name unique to prevent Wipe from returning false
  local menuName = "request" .. (DungeonID or "nil") .. (req and "request" or "nil") .. "_" .. time()
  if not GBB.PopupDynamic:Wipe( menuName ) then
    return
  end
  if req then
    GBB.PopupDynamic:AddItem( string.format( GBB.L[ "BtnWho" ], req.name ), false, GBB.WhoRequest, req.name )
    GBB.PopupDynamic:AddItem( string.format( GBB.L[ "BtnWhisper" ], req.name ), false, WhisperRequest, req.name )
    GBB.PopupDynamic:AddItem( string.format( GBB.L[ "BtnInvite" ], req.name ), false, InviteRequest, req.name )
    GBB.PopupDynamic:AddItem( string.format( GBB.L[ "BtnIgnore" ], req.name ), false, IgnoreRequest, req.name )
    GBB.PopupDynamic:AddItem( "", true )
  end
  if DungeonID then
    GBB.PopupDynamic:AddItem( GBB.L[ "BtnFold" ], false, GBB.FoldedDungeons, DungeonID )
    GBB.PopupDynamic:AddItem( GBB.L[ "BtnFoldAll" ], false, GBB.FoldAllDungeon )
    GBB.PopupDynamic:AddItem( GBB.L[ "BtnUnFoldAll" ], false, GBB.UnfoldAllDungeon )
    GBB.PopupDynamic:AddItem( "", true )
  end
  GBB.PopupDynamic:AddItem( GBB.L[ "CboxShowTotalTime" ], false, GBB.DB, "ShowTotalTime" )
  GBB.PopupDynamic:AddItem( GBB.L[ "CboxOrderNewTop" ], false, GBB.DB, "OrderNewTop" )
  GBB.PopupDynamic:AddItem( GBB.L[ "CboxEnableShowOnly" ], false, GBB.DB, "EnableShowOnly" )
  GBB.PopupDynamic:AddItem( GBB.L[ "CboxChatStyle" ], false, GBB.DB, "ChatStyle" )
  GBB.PopupDynamic:AddItem( GBB.L[ "CboxCompactStyle" ], false, GBB.DB, "CompactStyle" )
  GBB.PopupDynamic:AddItem( GBB.L[ "CboxDontTrunicate" ], false, GBB.DB, "DontTrunicate" )
  GBB.PopupDynamic:AddItem( "", true )
  GBB.PopupDynamic:AddItem( GBB.L[ "CboxNotifySound" ], false, GBB.DB, "NotifySound" )
  GBB.PopupDynamic:AddItem( GBB.L[ "CboxNotifyChat" ], false, GBB.DB, "NotifyChat" )
  GBB.PopupDynamic:AddItem( "", true )
  GBB.PopupDynamic:AddItem( GBB.L[ "HeaderSettings" ], false, GBB.Options.Open, 1 )

  GBB.PopupDynamic:AddItem( GBB.L[ "PanelAbout" ], false, GBB.Options.Open, 6 )
  GBB.PopupDynamic:AddItem( GBB.L[ "BtnCancel" ], false )
  GBB.PopupDynamic:Show()
end

function GBB.ClickFrame( self, button )
  if button == "LeftButton" then
  else
    createMenu()
  end
end

function GBB.ClickDungeon( self, button )
  local id = string.match( self:GetName(), "GBB.Dungeon_(.+)" )
  if id == nil or id == 0 then return end

  if button == "LeftButton" then
    if IsShiftKeyDown() then
      -- Shift-click: refresh all players listed for this dungeon via /who batching
      if GBB.RefreshDungeonPlayers then
        GBB.RefreshDungeonPlayers( id )
      end
      return
    end
    if GBB.FoldedDungeons[ id ] then
      GBB.FoldedDungeons[ id ] = false
    else
      GBB.FoldedDungeons[ id ] = true
    end
    GBB.UpdateList()
  else
    createMenu( id )
  end
end

function GBB.ClickRequest( self, button )
  local id = string.match( self:GetName(), "GBB.Item_(%d+)_" )
  if id == nil or id == 0 then return end

  local req = GBB.RequestList[ tonumber( id ) ]
  if button == "LeftButton" then
    if IsShiftKeyDown() then
      GBB.WhoRequest( req.name )
      --SendWho( req.name )
    elseif IsControlKeyDown() then
      InviteRequest( req.name )
    else
      WhisperRequest( req.name )
    end
  else
    createMenu( nil, req )
  end
end

function GBB.RequestShowTooltip( self )
  for id in string.gmatch( self:GetName(), "GBB.Item_(%d+)_" ) do
    local n = _G[ self:GetName() .. "_message" ]
    local req = GBB.RequestList[ tonumber( id ) ]
    if not req then return end

    GameTooltip_SetDefaultAnchor( GameTooltip, UIParent )
    GameTooltip:SetOwner( GroupBulletinBoardFrame, "ANCHOR_TOP", 0, 0 )
    GameTooltip:ClearLines()

    GameTooltip:AddLine( req.message, 0.9, 0.9, 0.9, 1 )

    if GBB.DB.ChatStyle then
      GameTooltip:AddLine( string.format( GBB.L[ "msgLastTime" ], GBB.formatTime( time() - req.last ) ) ..
        "|n" .. string.format( GBB.L[ "msgTotalTime" ], GBB.formatTime( time() - req.start ) ) )
    elseif GBB.DB.ShowTotalTime then
      GameTooltip:AddLine( string.format( GBB.L[ "msgLastTime" ], GBB.formatTime( time() - req.last ) ) )
    else
      GameTooltip:AddLine( string.format( GBB.L[ "msgTotalTime" ], GBB.formatTime( time() - req.start ) ) )
    end

    if GBB.DB.EnableGroup and GBB.GroupTrans and GBB.GroupTrans[ req.name ] then
      local entry = GBB.GroupTrans[ req.name ]

      GameTooltip:AddLine( GBB.Tool.IconClass[ entry.class ] ..
        "|c" .. RAID_CLASS_COLORS_HEX[ entry.class ] ..
        entry.name )
      if entry.dungeon then
        GameTooltip:AddLine( entry.dungeon )
      end
      if entry.Note then
        GameTooltip:AddLine( entry.Note )
      end
      GameTooltip:AddLine( SecondsToTime( GetServerTime() - entry.lastSeen ) )
    end

    -- Integration with LogTracker addon (if addon is present and loaded)
    if LogTracker then
      LogTracker:AddPlayerInfoToTooltip( req.name );
    end

    GameTooltip:Show()
  end
end

function GBB.RequestHideTooltip( self )
  GameTooltip:Hide()
end

-- Batch /who for all unique players currently listed for a dungeon
function GBB.RefreshDungeonPlayers( dungeon )
  if not dungeon then return end
  local unique = {}
  local names = {}
  for i, req in pairs( GBB.RequestList ) do
    if type( req ) == "table" and req.dungeon == dungeon and req.name and req.last and req.last + GBB.DB.TimeOut > time() then
      if not unique[ req.name ] then
        unique[ req.name ] = true
        names[ #names + 1 ] = req.name
      end
    end
  end

  if #names == 0 then return end

  local delay = 0
  for _, name in ipairs( names ) do
    C_Timer.After( delay, function()
      -- Use WhoRequest which now uses SendWho API to avoid chat spam
      if GBB.WhoRequest then
        GBB.WhoRequest( name )
      elseif SendWho then
        -- Direct fallback if WhoRequest doesn't exist
        SendWho( name )
      else
        -- Last resort fallback (shouldn't happen in Classic/Wrath)
        GBB.Tool.RunSlashCmd( "/who " .. name )
      end
    end )
    delay = delay + 0.6 -- simple throttle between /who calls
  end
end
