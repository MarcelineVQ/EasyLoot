-- || Made by and for Weird Vibes of Turtle WoW || --

local function print(msg)
  DEFAULT_CHAT_FRAME:AddMessage(msg)
end

local function debug_print(msg)
  if DEBUG then DEFAULT_CHAT_FRAME:AddMessage(msg) end
end

local function el_print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cffffff00EasyLoot:|r "..msg)
end

-- Addon ---------------------

-- /// Util functions /// --

local function ItemLinkToName(link)
  if ( link ) then
    return gsub(link,"^.*%[(.*)%].*$","%1");
  end
end

local function PostHookFunction(original,hook)
  return function(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10)
    original(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10)
    hook(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10)
  end
end

local function InGroup()
  return (GetNumPartyMembers() + GetNumRaidMembers() > 0)
end

local function PlayerCanRaidMark()
  return InGroup() and (IsRaidOfficer() or IsPartyLeader())
end

-- You may mark when you're a lead, assist, or you're doing soloplay
local function PlayerCanMark()
  return PlayerCanRaidMark() or not InGroup()
end

local function Capitalize(str)
  return (string.upper(string.sub(str,1,1)) .. string.lower(string.sub(str,2)))
end

-- lazypigs
function IsGuildMate(name)
	if IsInGuild() then
		local ngm = GetNumGuildMembers()
		for i=1, ngm do
			n, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName = GetGuildRosterInfo(i);
			if strlower(n) == strlower(name) then
			  return true
			end
		end
	end
	return nil
end

-- lazypigs
function IsFriend(name)
	for i = 1, GetNumFriends() do
    -- print(GetFriendInfo(i))
    -- print(name)

		if strlower(GetFriendInfo(i)) == strlower(name) then
			return true
		end
	end
	return nil
end



------------------------------
-- Vars
------------------------------

local EasyLoot = CreateFrame("Frame","EasyLoot")

EasyLoot.OFF = -1
EasyLoot.PASS = 0
EasyLoot.NEED = 1
EasyLoot.GREED = 2
local OFF,PASS,NEED,GREED = EasyLoot.OFF,EasyLoot.PASS,EasyLoot.NEED,EasyLoot.GREED

local binds = {}

------------------------------
-- Table Functions
------------------------------

local function elem(t,item)
  for _,k in pairs(t) do
    if item == k then
      return true
    end
  end
  return false
end

local function fuzzy_elem(t,item)
  if type(item) == "string" then
    item = string.lower(item)
    for _,v in pairs(t) do
      if string.find(string.lower(v),item,nil,false) then -- false, don't use regex
        return true
      end
    end
  end
  return elem(t,item)
end

local function key(t,key)
  for k,_ in pairs(t) do
    if item == k then
      return true
    end
  end
  return false
end

local function tsize(t)
  local c = 0
  for _ in pairs(t) do c = c + 1 end
  return c
end

function deepcopy(original)
  local copy = {}
  for k, v in pairs(original) do
      if type(v) == "table" then
          copy[k] = deepcopy(v)  -- Recursively copy nested tables
      else
          copy[k] = v
      end
  end
  return copy
end

-- Function to return an iterator that sorts a table by its keys (low to high)
function ixpairs(t)
  -- Create a list of keys
  local keys = {}
  for k in pairs(t) do
      table.insert(keys, k)
  end

  -- Sort the keys
  table.sort(keys)

  -- Iterator function
  local i = 0
  return function()
      i = i + 1
      local key = keys[i]
      if key then
          return key, t[key]
      end
  end
end

-- don't skip trainer, they're often used for untalenting
-- skip spirit healer, it has a confirmation anyway
local gossips = { "taxi", --[["trainer",--]] "battlemaster", "vendor", "banker", "healer" }
local gossips_skip_lines = {
  bwl = "my hand on the orb",
  mc = "me to the Molten Core",
  wv = "Happy Winter Veil",
  nef1 = "made no mistakes",
  nef2 = "have lost your mind",
  rag1 = "challenged us and we have come",
  rag2 = "else do you have to say",
  ironbark = "Thank you, Ironbark",
  pusilin1 = "Game %? Are you crazy %?",
  pusilin2 = "Why you little",
  pusilin3 = "DIE!",
  meph = "Touch the Portal",
  kara = "Teleport me back to Kara",
  mizzle1 = "^I'm the new king%?",
  mizzle2 = "^It's good to be King!",
}

------------------------------
-- Loot Data
------------------------------

local zg_coin = {
  "Bloodscalp Coin",
  "Gurubashi Coin",
  "Hakkari Coin",
  "Razzashi Coin",
  "Sandfury Coin",
  "Skullsplitter Coin",
  "Vilebranch Coin",
  "Witherbark Coin",
  "Zulian Coin",
}

local zg_bijou = {
  "Blue Hakkari Bijou",
  "Bronze Hakkari Bijou",
  "Gold Hakkari Bijou",
  "Green Hakkari Bijou",
  "Orange Hakkari Bijou",
  "Purple Hakkari Bijou",
  "Red Hakkari Bijou",
  "Silver Hakkari Bijou",
  "Yellow Hakkari Bijou",
}

local scarab = {
  "Bone Scarab",
  "Bronze Scarab",
  "Clay Scarab",
  "Crystal Scarab",
  "Gold Scarab",
  "Ivory Scarab",
  "Silver Scarab",
  "Stone Scarab",
}

local idol_aq20 = {
  "Azure Idol",
  "Onyx Idol",
  "Lambent Idol",
  "Amber Idol",
  "Jasper Idol",
  "Obsidian Idol",
  "Vermillion Idol",
  "Alabaster Idol",
}

local mc_mat = {
  "Fiery Core",
  "Lava Core",
  "Blood of the Mountain",
  "Essence of Fire",
  "Essence of Earth",
}

local idol_aq40 = {
  "Idol of the Sun",
  "Idol of Night",
  "Idol of Death",
  "Idol of the Sage",
  "Idol of Rebirth",
  "Idol of Life",
  "Idol of Strife",
  "Idol of War",
}

local scrap = {
  "Wartorn Chain Scrap",
  "Wartorn Cloth Scrap",
  "Wartorn Leather Scrap",
  "Wartorn Plate Scrap",
}


------------------------------
-- Loot Functions
------------------------------

local function prettify_roll_type(roll_type)
  if roll_type == NEED then
    return "Need"
  elseif roll_type == GREED then
    return "Greed"
  elseif roll_type == PASS then
    return "Pass"
  end
  return "Off"
end

local default_settings = {
  zg_coin = NEED,
  zg_bijou = NEED,
  zg_boe = NEED,
  aq20_scarab = NEED,
  aq20_idol = NEED,
  aq20_boe = NEED,
  aq40_scarab = NEED,
  aq40_idol = PASS,
  aq40_boe = NEED,
  naxx_scrap = PASS,
  naxx_boe = NEED,
  mc_mat = NEED,
  mc_boe = NEED,

  pass_greys = false,
  only_holy = false,
  general_boe_rule = GREED,
  auto_repair = true,
  auto_invite = true,
  auto_gossip = true,
  auto_dismount = true,
  auto_stand = true,
}

local default_need_list = {
  "Corrupted Sand",
  "Arcane Essence",
  "Righteous Orb",
  "Fashion Coin",
}

local default_greed_list = {
}

local default_pass_list = {
}

local item_classes = {
  "Bijou",
  "Coin",
  "Scarab",
  "IdolAQ20",
  "IdolAQ40",
  "ScrapCloth",
  "ScrapLeather",
  "ScrapChain",
  "ScrapPlate",
}

-- Determine what kind of roll we want for the item and do the pass, or roll of need or greed
-- returns the roll type and if it was in an explicit list
function EasyLoot:HandleItem(name,explicit_only)
  -- check specific lists first
  if fuzzy_elem(EasyLootDB.needlist,name) then
    return NEED,true
  elseif fuzzy_elem(EasyLootDB.greedlist,name) then
    return GREED,true
  elseif fuzzy_elem(EasyLootDB.passlist,name) then
    return PASS,true
  end

  if explicit_only then return OFF end
  -- now check more general things like zone items:
  if GetRealZoneText() == "Zul'Gurub" then
    if elem(zg_coin,name) then
      return EasyLootDB.settings.zg_coin
    elseif elem(zg_bijou,name) then
      return EasyLootDB.settings.zg_bijou
    else
      return EasyLootDB.settings.zg_boe
    end
  elseif GetRealZoneText() == "Ruins of Ahn'Qiraj" then
    if elem(scarab,name) then
      return EasyLootDB.settings.aq20_scarab
    elseif elem(idol_aq20,name) then
      return EasyLootDB.settings.aq20_idol
    else
      return EasyLootDB.settings.aq20_boe
    end
  elseif GetRealZoneText() == "Molten Core" then
    if elem(mc_mat,name) then
      return EasyLootDB.settings.mc_mat
    else
      return EasyLootDB.settings.mc_boe
    end
  elseif GetRealZoneText() == "Ahn'Qiraj" then
    if elem(scarab,name) then
      return EasyLootDB.settings.aq40_scarab
    elseif elem(idol_aq40,name) then
      return EasyLootDB.settings.aq40_idol
    else
      return EasyLootDB.settings.aq40_boe
    end
  elseif GetRealZoneText() == "Naxxramas" then
    if elem(scrap,name) then
      return EasyLootDB.settings.naxx_scrap
    else
      return EasyLootDB.settings.naxx_boe
    end
  else
    return EasyLootDB.settings.general_boe_rule
  end
end

-- 0 pass, 1 need, 2 greed
function EasyLoot:START_LOOT_ROLL(roll_id,time_left)
  local _texture, name, _count, quality, bop = GetLootRollItemInfo(roll_id)
  local r = EasyLoot:HandleItem(name,bop)
  if r >= 0 then RollOnLoot(roll_id,r) end
end

function EasyLoot:LOOT_BIND_CONFIRM(slot)
  -- solo play, queue the loot for accepting
  if not InGroup() then
    debug_print("solo bind")
    table.insert(binds,slot)
    return
  end

  -- check whitelists if in group, say if everyone passed already
  -- could happen if you shift-click the boss and don't autoloot
  local _texture, item, _quantity, quality = GetLootSlotInfo(slot)
  local r = EasyLoot:HandleItem(item,true) -- we're in a group, use explicit still
  if r > 0 then
    debug_print("party bind")
    table.insert(binds,slot)
    return
  end
end

function EasyLoot:LOOT_SLOT_CLEARED(slot)
end

-- a BoP item ask, these can be autorolled but only by explicit whitelist
function EasyLoot:CONFIRM_LOOT_ROLL(roll_id,roll_type)
  local _texture, name, _count, quality, bop = GetLootRollItemInfo(roll_id)
  local r = EasyLoot:HandleItem(name,bop)

  if r == OFF then return end
  if r == roll_type then
    ConfirmLootRoll(roll_id,roll_type)
    StaticPopup_Hide("CONFIRM_LOOT_ROLL")
  elseif r == PASS then
    StaticPopup_Hide("CONFIRM_LOOT_ROLL")
  end
end


-- obnoxious hook to solve pfui not clearing itself properly
local orig_pfUI_UpdateLootFrame = function () end
if pfUI and pfUI.loot then
  orig_pfUI_UpdateLootFrame = pfUI.loot.UpdateLootFrame
  pfUI.loot.UpdateLootFrame = function () end
end

function EasyLoot:LOOT_OPENED()
  if IsShiftKeyDown() then -- skip autolooting
    orig_pfUI_UpdateLootFrame()
    return
  end
  local numLootItems = GetNumLootItems()

  -- strat chest check
  if EasyLootDB.settings.only_holy and GetRealZoneText() == "Stratholme" then
    local water = string.lower("Stratholme Holy Water")
    for slot = 1, numLootItems do
      local _texture, item, _quantity, quality = GetLootSlotInfo(slot)
      if LootSlotIsCoin(slot) then
        LootSlot(slot,true)
      elseif LootSlotIsItem(slot) and string.lower(item) == water then
        LootSlot(slot,true)
        return
      end
    end
  end

  for slot = 1, numLootItems do
    if LootSlotIsCoin(slot) then
      LootSlot(slot,true)
    elseif LootSlotIsItem(slot) then
      local loot_method = GetLootMethod()
      local _texture, item, _quantity, quality = GetLootSlotInfo(slot)
      local r,in_explicit_list = EasyLoot:HandleItem(item)
      local is_container = not (UnitExists("target") and UnitIsDead("target")) -- best we can do

      -- determine loot to skip
      if in_explicit_list and (r == PASS) then
        -- loot is on our pass list
        debug_print("passlist "..item)
      elseif (quality == 0 and EasyLootDB.settings.pass_greys) and not (r > 0 and in_explicit_list) then
        -- do nothing, unless it's a whitelist item
        debug_print("passgrey " .. item)
      elseif (r == OFF or r == PASS) and InGroup() then
        -- item handler determined this isn't loot to consider and we're in group
        debug_print("passgroup "..item)

      -- if we are looting from a chest, ignore further loot rules
      elseif is_container then
        -- container
        debug_print("conatinerloot "..item)
        LootSlot(slot,true)

      -- if we're looting a mob follow loot rules
      elseif InGroup() and (loot_method == "group" or loot_method == "needbeforegreed") then
        -- check the current threshold so it doens't try to loot something already being rolled for
        if quality >= GetLootThreshold() then
          -- a group roll will happen, don't loot the slot manually or you'll get an error
          debug_print("grouploot "..item)
        else
          debug_print("grouploot below threshhold "..item)
          LootSlot(slot,true)
        end
      elseif InGroup() and (loot_method == "master") then
        -- don't loot since masterloot is on anyway
        debug_print("masterloot on "..item)

      -- finally loot whatever wasn't handled above
      -- elseif not InGroup() then
      --   -- we're alone and we've check the skiplist already, loot
      --   debug_print("aloneloot "..item)
      --   LootSlot(slot,true)
      else
        debug_print("looting "..item)
        LootSlot(slot,true)
      end
    end
    -- it the above looting caused a bind, resolve it
    -- seems like an odd place/way to do it, but trying it any other way wasn't consistent
    if next(binds) then
      LootSlot(table.remove(binds))
      StaticPopup_Hide("LOOT_BIND")
    end
  end
  debug_print("binds left: " .. tsize(binds))

  -- we're done looting, allow pfui to try
  orig_pfUI_UpdateLootFrame()
end

function EasyLoot:LOOT_CLOSED()
  -- binds = {}
end

------------------------------
-- Other Functions
------------------------------

-- add a purchase list as well, let people link an item to add it if needed
-- e.g.: 20 [Sacred Candle]

-- toggle enemy nameplates on in combat, turn off after
function EasyLoot:TogglePlates()
  self.plate_state = self.plate_state or false
  if self.plate_state then
    ShowNameplates()
  else
    HideNameplates()
  end
  self.plate_state = not self.plate_state
end

function EasyLoot:PLAYER_REGEN_ENABLED()
  -- if EasyLootDB.settings.plates then TogglePlates() end
end

function EasyLoot:PLAYER_REGEN_DISABLED()
  -- if EasyLootDB.settings.plates then TogglePlates() end
end

local elTooltip = CreateFrame("GameTooltip", "elTooltip", UIParent, "GameTooltipTemplate")
function EasyLoot:Dismount()
  -- do dismount
  -- increases speed -- search for speed based on
  local counter = -1
  local speed = "^Increases speed based"
  local turtle = "^Slow and steady"
  while true do
    counter = counter + 1
    local index, untilCancelled = GetPlayerBuff(counter)
    if index == -1 then break end
    if untilCancelled then
      elTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
      elTooltip:SetPlayerBuff(index)

      local desc = elTooltipTextLeft2:GetText()
      if desc then
        if string.find(desc, speed) or string.find(desc, turtle) then
          CancelPlayerBuff(counter)
          return
        end
      end
    end
  end
end

function EasyLoot:UI_ERROR_MESSAGE(msg)
  if EasyLootDB.settings.auto_dismount and string.find(arg1, "mounted") then
    EasyLoot:Dismount()
    UIErrorsFrame:Clear()
  end
  if EasyLootDB.settings.auto_stand and string.find(arg1, "must be standing") then
    SitOrStand()
    UIErrorsFrame:Clear()
  end
end

------------------------------

-- Register the ADDON_LOADED event
EasyLoot:RegisterEvent("ADDON_LOADED")
EasyLoot:SetScript("OnEvent", function ()
  EasyLoot[event](this,arg1,arg2,arg3,arg4,arg6,arg7,arg8,arg9,arg9,arg10)
end)

function EasyLoot:Load()
  EasyLootDB = EasyLootDB or {}
  EasyLootDB.needlist = EasyLootDB.needlist or default_need_list
  EasyLootDB.greedlist = EasyLootDB.greedlist or default_greed_list
  EasyLootDB.passlist = EasyLootDB.passlist or default_pass_list

  EasyLootDB.settings = EasyLootDB.settings or default_settings
  EasyLootDB.settings.general_boe_rule = EasyLootDB.settings.general_boe_rule or default_settings.general_boe_rule
  -- bool checked differently
  EasyLootDB.settings.pass_greys = (EasyLootDB.settings.pass_greys == nil) and default_settings.pass_greys or EasyLootDB.settings.pass_greys
  EasyLootDB.settings.auto_repair = (EasyLootDB.settings.auto_repair == nil) and default_settings.auto_repair or EasyLootDB.settings.auto_repair
  EasyLootDB.settings.auto_invite = (EasyLootDB.settings.auto_invite == nil) and default_settings.auto_invite or EasyLootDB.settings.auto_invite
  EasyLootDB.settings.auto_gossip = (EasyLootDB.settings.auto_gossip == nil) and default_settings.auto_gossip or EasyLootDB.settings.auto_gossip
  EasyLootDB.settings.only_holy = (EasyLootDB.settings.only_holy == nil) and default_settings.only_holy or EasyLootDB.settings.only_holy
  EasyLootDB.settings.auto_dismount = (EasyLootDB.settings.auto_dismount == nil) and default_settings.auto_dismount or EasyLootDB.settings.auto_dismount
  EasyLootDB.settings.auto_stand = (EasyLootDB.settings.auto_stand == nil) and default_settings.auto_stand or EasyLootDB.settings.auto_stand
  -- todo, add auto shapeshift removal
end

function EasyLoot:ADDON_LOADED(addon)
  if addon ~= "EasyLoot" then return end
  EasyLoot:Load()
  EasyLoot:RegisterEvent("START_LOOT_ROLL")
  EasyLoot:RegisterEvent("LOOT_OPENED")
  EasyLoot:RegisterEvent("LOOT_CLOSED")
  EasyLoot:RegisterEvent("LOOT_BIND_CONFIRM")
  EasyLoot:RegisterEvent("LOOT_SLOT_CLEARED")
  EasyLoot:RegisterEvent("CONFIRM_LOOT_ROLL")
  EasyLoot:RegisterEvent("PARTY_INVITE_REQUEST")
  EasyLoot:RegisterEvent("MERCHANT_SHOW")
  EasyLoot:RegisterEvent("GOSSIP_SHOW")
  EasyLoot:RegisterEvent("ITEM_TEXT_BEGIN")
  EasyLoot:RegisterEvent("PLAYER_REGEN_ENABLED")
  EasyLoot:RegisterEvent("PLAYER_REGEN_DISABLED")
  EasyLoot:RegisterEvent("UI_ERROR_MESSAGE")

  -- hook away superapi's autoloot functionality and set autloot to off since this handles it
  if IfShiftAutoloot then
    IfShiftAutoloot = function () return end
  end
  -- other method
  if SuperAPI then
    SuperAPI.IfShiftAutoloot = function () SetAutoloot(0) end
    SuperAPI.IfShiftNoAutoloot = function () SetAutoloot(0) end
    -- SuperAPI.frame:SetScript("OnUpdate", nil)
  end
  if SetAutoloot then
    SetAutoloot(0)
  end

  EasyLoot:CreateConfig()
end

-- lazypigs
function EasyLoot:AcceptGroupInvite()
	AcceptGroup()
	StaticPopup_Hide("PARTY_INVITE")
	PlaySoundFile("Sound\\Doodad\\BellTollNightElf.wav")
	UIErrorsFrame:AddMessage("Group Auto Accept")
end

function EasyLoot:PARTY_INVITE_REQUEST(who)
  if EasyLootDB.settings.auto_invite and (IsGuildMate(who) or IsFriend(who)) then
    EasyLoot:AcceptGroupInvite()
  end
end

function EasyLoot:MERCHANT_SHOW()
  if not EasyLootDB.settings.auto_repair or not CanMerchantRepair() or IsControlKeyDown() then return end
  local rcost = GetRepairAllCost()
  if rcost and rcost ~= 0 then
    if rcost > GetMoney() then
      el_print("Not Enough Money to Repair.")
      return
    end
    RepairAllItems()
    local gcost,scost,ccost = rcost/100/100,math.mod(rcost/100,100),math.mod(rcost,100)
    local COLOR_GOLD   = gcost > 0 and format("|cffffd700%dg|r",gcost) or ""
    local COLOR_SILVER = scost > 0 and format("|cffc7c7cf%ds|r",scost) or ""
    local COLOR_COPPER = ccost > 0 and format("|cffeda55f%dc|r",ccost) or ""
    el_print(format("Equipment repaired for: %s%s%s", COLOR_GOLD, COLOR_SILVER, COLOR_COPPER))
  end
end

function EasyLoot:ITEM_TEXT_BEGIN()
  if IsControlKeyDown() then return end
  if ItemTextGetItem() ~= "Altar of Zanza" then return end

  for bag = 0, 4 do
    for slot = 1, GetContainerNumSlots(bag) do
      local l = GetContainerItemLink(bag,slot)
      if l then
        _,_,itemId = string.find(l,"item:(%d+)")
        local name,_link,_,_lvl,_type,subtype = GetItemInfo(itemId)
        if string.find(name,".- Hakkari Bijou") then
          UseContainerItem(bag, slot)
          CloseItemText()
          return
        end
      end
    end
  end
  el_print("No Bijou found in inventory.")
  CloseItemText()
end

function EasyLoot:GOSSIP_SHOW()
  if not EasyLootDB.settings.auto_gossip or IsControlKeyDown() then return end
  -- brainwasher is weird, skip it
  if UnitName("npc") == "Goblin Brainwashing Device" then
    return
  end

  -- If there's something more to do than just gossip, don't automate
  if GetGossipAvailableQuests() or GetGossipActiveQuests() then return end

  local t = { GetGossipOptions() }
  local t2 = {}
  for i=1,tsize(t),2 do
    table.insert(t2, { text = t[i], gossip = t[i+1] })
  end

  -- only one option, and not a gossip? click it
  if t2[1] and not t2[2] and t2[1].gossip ~= "gossip" then SelectGossipOption(1) end

  for i,entry in ipairs(t2) do
    -- check for dialogue types we'd always want to click
    if elem(gossips, entry.gossip) then
      SelectGossipOption(i); break
    end
    -- check for specific gossips to skip
    if entry.gossip == "gossip" then
      for _,line in gossips_skip_lines do
        if string.find(entry.text, line) then
          SelectGossipOption(i); break
        end
      end
    end
  end
end

function EasyLoot:CreateConfig()

  local loot_quality_dropdown = { [-1] = "Off", [0] = "Pass", [2] = "Greed", [1] = "Need" }

  -- Create main frame for the configuration menu
  local EasyLootConfigFrame = CreateFrame("Frame", "EasyLootConfigFrame", UIParent)
  EasyLootConfigFrame:SetWidth(500)  -- Increased width to accommodate the horizontal layout
  EasyLootConfigFrame:SetHeight(440)  -- Adjusted height
  EasyLootConfigFrame:SetPoint("CENTER", UIParent, "CENTER")  -- Centered frame
  EasyLootConfigFrame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 32, edgeSize = 32,
      insets = { left = 11, right = 12, top = 12, bottom = 11 }
  })
  EasyLootConfigFrame:Hide()

  -- Add a close button
  local closeButton = CreateFrame("Button", nil, EasyLootConfigFrame, "UIPanelCloseButton")
  closeButton:SetPoint("TOPRIGHT", EasyLootConfigFrame, "TOPRIGHT", -5, -5)
  closeButton:SetScript("OnClick", function()
      EasyLootConfigFrame:Hide()  -- Hides the frame when the close button is clicked
  end)


  -- Title text
  local title = EasyLootConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  title:SetPoint("TOP", 0, -20)
  title:SetText("EasyLoot " .. GetAddOnMetadata("EasyLoot","Version") .. " Configuration")

  -- Function to toggle the config frame
  SLASH_EASYLOOT1 = "/easyloot"
  SlashCmdList["EASYLOOT"] = function()
      if EasyLootConfigFrame:IsShown() then
          EasyLootConfigFrame:Hide()
      else
          EasyLootConfigFrame:Show()
      end
  end

  -- Dropdown creation function
  local function CreateDropdown(parent, label, items, defaultValue, x, y, name, setting)
      local dropdown = CreateFrame("Button", name, parent, "UIDropDownMenuTemplate")  -- Name the frame properly
      -- dropdown:SetPoint("TOPLEFT", x, y)
      
      local dropdownLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      dropdownLabel:SetPoint("TOP", x-210, y)
      dropdownLabel:SetText(label)
      dropdown:SetPoint("TOP", dropdownLabel, "BOTTOM", 0, 0)

      local selectedValue = defaultValue

      -- Function to handle item selection
      -- TODO this needs to set config settings
      local function OnClick(self)
        local v = tonumber(EasyLoot[string.upper(self:GetText())])
        if v then
          UIDropDownMenu_SetSelectedName(dropdown, self:GetText())
          EasyLootDB.settings[setting] = v
        end
        -- print(UIDropDownMenu_GetSelectedValue(dropdown))
      end

      -- Manual initialization for the dropdown
      local function InitializeDropdown()
          for i, item in ixpairs(items) do
              local info = {}  -- Create a new info table for each dropdown entry
              info.text = item  -- The text displayed in the dropdown
              info.value = item -- The value stored when the item is selected
              info.func = function () OnClick(this) end   -- Attach the OnClick handler
              UIDropDownMenu_AddButton(info)  -- Add the dropdown option to the list
          end
      end

      -- Set up the dropdown, ensuring it is properly initialized with a named frame
      UIDropDownMenu_Initialize(dropdown, InitializeDropdown)
      UIDropDownMenu_SetWidth(60,dropdown)  -- Set the width of the dropdown
      UIDropDownMenu_SetSelectedValue(dropdown, selectedValue)

      return dropdown
  end

  -- Raid section: ZG
  local zgLabel = EasyLootConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  zgLabel:SetPoint("TOPLEFT", 30, -40)  
  zgLabel:SetText("ZG")

  -- Horizontal layout for ZG
  local zgCoinsDropdown = CreateDropdown(EasyLootConfigFrame, "Coins", loot_quality_dropdown, loot_quality_dropdown[EasyLootDB.settings.zg_coin], 20, -60, "ZGCoinsDropdown", "zg_coin")
  local zgBijouDropdown = CreateDropdown(EasyLootConfigFrame, "Bijou", loot_quality_dropdown, loot_quality_dropdown[EasyLootDB.settings.zg_bijou], 110, -60, "ZGBijouDropdown", "zg_bijou")
  local zgBoEDropdown = CreateDropdown(EasyLootConfigFrame, "BoE", loot_quality_dropdown, loot_quality_dropdown[EasyLootDB.settings.zg_boe], 200, -60, "ZGBoEDropdown", "zg_boe")

  -- Raid section: AQ20
  local aq20Label = EasyLootConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  aq20Label:SetPoint("TOPLEFT", 30, -120)
  aq20Label:SetText("AQ20")

  -- Horizontal layout for AQ20
  local aq20IdolsDropdown = CreateDropdown(EasyLootConfigFrame, "Idols", loot_quality_dropdown, loot_quality_dropdown[EasyLootDB.settings.aq20_idol], 20, -140, "AQ20IdolsDropdown", "aq20_idol")
  local aq20ScarabsDropdown = CreateDropdown(EasyLootConfigFrame, "Scarabs", loot_quality_dropdown, loot_quality_dropdown[EasyLootDB.settings.aq20_scarab], 110, -140, "AQ20ScarabsDropdown", "aq20_scarab")
  local aq20BoEDropdown = CreateDropdown(EasyLootConfigFrame, "BoE", loot_quality_dropdown, loot_quality_dropdown[EasyLootDB.settings.aq20_boe], 200, -140, "AQ20BoEDropdown", "aq20_boe")

  -- Raid section: MC
  local mcLabel = EasyLootConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  mcLabel:SetPoint("TOPLEFT", 30, -200)
  mcLabel:SetText("MC")

  -- Horizontal layout for MC
  local mcMatsDropdown = CreateDropdown(EasyLootConfigFrame, "Mats", loot_quality_dropdown, loot_quality_dropdown[EasyLootDB.settings.mc_mat], 20, -220, "MCMatsDropdown", "mc_mat")
  local mcBoEDropdown = CreateDropdown(EasyLootConfigFrame, "BoE", loot_quality_dropdown, loot_quality_dropdown[EasyLootDB.settings.mc_boe], 110, -220, "MCBoEDropdown", "mc_boe")

  -- Raid section: AQ40
  local aq40Label = EasyLootConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  aq40Label:SetPoint("TOPLEFT", 30, -280)
  aq40Label:SetText("AQ40")

  -- Horizontal layout for AQ40
  local aq40IdolsDropdown = CreateDropdown(EasyLootConfigFrame, "Idols", loot_quality_dropdown, loot_quality_dropdown[EasyLootDB.settings.aq40_idol], 20, -300, "AQ40IdolsDropdown", "aq40_idol")
  local aq40ScarabsDropdown = CreateDropdown(EasyLootConfigFrame, "Scarabs", loot_quality_dropdown, loot_quality_dropdown[EasyLootDB.settings.aq40_scarab], 110, -300, "AQ40ScarabsDropdown", "aq40_scarab")
  local aq40BoEDropdown = CreateDropdown(EasyLootConfigFrame, "BoE", loot_quality_dropdown, loot_quality_dropdown[EasyLootDB.settings.aq40_boe], 200, -300, "AQ40BoEDropdown", "aq40_boe")

  -- Raid section: Naxx
  local naxxLabel = EasyLootConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  naxxLabel:SetPoint("TOPLEFT", 30, -360)
  naxxLabel:SetText("Naxx")

  -- Horizontal layout for Naxx
  local naxxScrapDropdown = CreateDropdown(EasyLootConfigFrame, "Scraps", loot_quality_dropdown, loot_quality_dropdown[EasyLootDB.settings.naxx_scrap], 20, -380, "NaxxScrapDropdown", "naxx_scrap")
  local naxxBoEDropdown = CreateDropdown(EasyLootConfigFrame, "BoE", loot_quality_dropdown, loot_quality_dropdown[EasyLootDB.settings.naxx_boe], 110, -380, "NaxxBoEDropdown", "naxx_boe")


  ----------------------------------------------------------------------
  -- Additional Options section
  local optionsLabel = EasyLootConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  optionsLabel:SetPoint("TOPLEFT", 330, -40)
  optionsLabel:SetText("Additional Options")

  -- Create checkboxes function compatible with WoW 1.12
  local function CreateCheckbox(label, x, y, setting, tooltip)
    local checkbox = CreateFrame("CheckButton", nil, EasyLootConfigFrame, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", x, y)
    checkbox.text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 0, 0)
    checkbox.text:SetText(label)
    checkbox:SetChecked(EasyLootDB.settings[setting] and 1 or nil)
    checkbox:SetScript("OnClick", function ()
      EasyLootDB.settings[setting] = not EasyLootDB.settings[setting]
    end)
    checkbox:SetScript("OnEnter", function()
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:SetText(tooltip, 1, 1, 0)  -- Tooltip title
      -- GameTooltip:AddLine("Re-apply the Applied layout as people join the raid", 1, 1, 1, true)  -- Tooltip description
      GameTooltip:Show()
    end)
    checkbox:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
    return checkbox
  end

  -- Additional options checkboxes
  local boeRuleDropdown = CreateDropdown(EasyLootConfigFrame, "General BoE", loot_quality_dropdown, loot_quality_dropdown[EasyLootDB.settings.general_boe_rule], 330, -60, "GeneralBoEDropdown", "general_boe_rule")
  local passOnGreysCheckbox = CreateCheckbox("Pass on Greys", 330, -100, "pass_greys", "Do not loot grey items.")
  local onlyHolyCheckbox = CreateCheckbox("Holy Water Only", 330, -125, "only_holy", "Only loot holy water from Stratholme Chests.")
  local autoInviteCheckbox = CreateCheckbox("Auto-Invite", 330, -150, "auto_invite", "Always accept invites from friends or guild members.")
  local autoRepairCheckbox = CreateCheckbox("Auto-Repair", 330, -175, "auto_repair", "Repair at any valid vendor (hold Ctrl to disable).")
  local autoGossipCheckbox = CreateCheckbox("Auto-Gossip", 330, -200, "auto_gossip", "Automatically choose the most common gossip options (hold Ctrl to disable).")
  local autoDismountCheckbox = CreateCheckbox("Auto-Dismount", 330, -225, "auto_dismount", "Automatically dismount when trying to use actions on a mount.")
  local autoStandCheckbox = CreateCheckbox("Auto-Stand", 330, -250, "auto_stand", "Automatically stant when trying to use actions while sitting.")

  ------------------------------------

  -- Function to show the popup for adding an item
  local function ShowAddItemPopup(items)
    local foo = StaticPopup_Show("ADD_ITEM_NAME")
    foo.do_add = true
    foo.data = items
  end

  local function ShowRemoveItemPopup(items,rem_item)
    local foo = StaticPopup_Show("REM_ITEM_NAME")
    foo.data = { items, rem_item }
  end

  -- Dropdown creation function (as per your provided working code)
  local function CreateListsDropdown(parent, label, items, width, x, y, name, tooltip)
    local dropdown = CreateFrame("Button", name, parent, "UIDropDownMenuTemplate")  -- Name the frame properly
    -- dropdown:SetPoint("TOPLEFT", x, y)

    dropdown:SetScript("OnEnter", function()
      GameTooltip:SetOwner(this, "ANCHOR_LEFT") 
      GameTooltip:SetText(tooltip, 1, 1, 0)  -- Tooltip title
      -- GameTooltip:AddLine("Re-apply the Applied layout as people join the raid", 1, 1, 1, true)  -- Tooltip description
      GameTooltip:Show()
    end)
    dropdown:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
    
    local dropdownLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownLabel:SetPoint("TOP", x-210, y)
    dropdownLabel:SetText(label)
    dropdown:SetPoint("TOP", dropdownLabel, "BOTTOM", 0, 0)

    -- local selectedValue = defaultValue

    -- Function to handle item add/removal
    local function OnClick(self)
        UIDropDownMenu_SetSelectedName(dropdown, self:GetText())
        dropdown.selected = self:GetText()
    end

    -- Manual initialization for the dropdown
    local function InitializeDropdown()
      -- create the add and remove items dialogues
      local info = {}  -- Create a new info table for each dropdown entry
      info.text = "Add New item"  -- The text displayed in the dropdown
      info.func = function ()
        local add = StaticPopup_Show("ADD_ITEM_NAME", label)
        add.data = items
        local editbox = getglobal(add:GetName().."EditBox")

        local orig_ContainerFrameItemButton_OnClick = (function ()
          local orig = ContainerFrameItemButton_OnClick
          ContainerFrameItemButton_OnClick = function (button,ignoreModifiers,a3,a4,a5,a6,a7,a8,a9,a10)
            if (button == "LeftButton" and IsShiftKeyDown() and not ignoreModifiers and editbox:IsShown()) then
                editbox:Insert(ItemLinkToName(GetContainerItemLink(this:GetParent():GetID(), this:GetID())))
            else
              orig(button,ignoreModifiers,a3,a4,a5,a6,a7,a8,a9,a10)
            end
          end
          return orig
        end)()

        local orig_ChatFrame_OnHyperlinkShow = (function ()
          local orig = ChatFrame_OnHyperlinkShow
          ChatFrame_OnHyperlinkShow = function (link,text,button,a3,a4,a5,a6,a7,a8,a9,a10)
            -- print(chatFrame)
            if (button == "LeftButton" and IsShiftKeyDown() and not ignoreModifiers and editbox:IsShown()) then
              editbox:Insert(ItemLinkToName(text))
            else
              orig(link,text,button,a3,a4,a5,a6,a7,a8,a9,a10)
            end
          end
          return orig
        end)()

        add:SetScript("OnHide", function()
          getglobal(this:GetName() .. "EditBox"):SetText("")
          ContainerFrameItemButton_OnClick = orig_ContainerFrameItemButton_OnClick
          ChatFrame_OnHyperlinkShow = orig_ChatFrame_OnHyperlinkShow
        end)
      end
      info.textR = 0.1
      info.textG = 0.8
      info.textB = 0.1
      UIDropDownMenu_AddButton(info)  -- Add the dropdown option to the list

      local info = {}  -- Create a new info table for each dropdown entry
      info.text = "Remove Item"  -- The text displayed in the dropdown
      info.func = function ()
        if not dropdown.selected then
          el_print("Select an item to remove first.")
        else
          local pop = StaticPopup_Show("REM_ITEM_NAME", dropdown.selected, label)
          pop.data = { items, dropdown.selected}
          dropdown.selected = nil
        end
      end
      info.textR = 0.8
      info.textG = 0.2
      info.textB = 0.2
      UIDropDownMenu_AddButton(info)  -- Add the dropdown option to the list

      for i, item in ixpairs(items) do
          local info = {}  -- Create a new info table for each dropdown entry
          info.text = item  -- The text displayed in the dropdown
          info.value = item -- The value stored when the item is selected
          info.func = function () OnClick(this) end   -- Attach the OnClick handler
          UIDropDownMenu_AddButton(info)  -- Add the dropdown option to the list
      end
    end

    -- Set up the dropdown, ensuring it is properly initialized with a named frame
    UIDropDownMenu_Initialize(dropdown, InitializeDropdown)
    UIDropDownMenu_SetWidth(width,dropdown)  -- Set the width of the dropdown
    -- UIDropDownMenu_SetSelectedValue(dropdown, selectedValue)

    return dropdown
  end
  
-- Function to add item to dropdown
local function AddItemToDropdown(dropdown_list, item)
  table.insert(dropdown_list, item)
  el_print("Added item: "..item.." to whitelist.")
end

-- Function to remove item from dropdown
local function RemoveItemFromDropdown(dropdown_list, item)
  for i,name in pairs(dropdown_list) do
    if name == item then
      table.remove(dropdown_list,i)
      el_print("Removed item: "..item.." from whitelist.")
      break
    end
  end
end

-- Static Popup Dialog for entering item names
StaticPopupDialogs["ADD_ITEM_NAME"] = {
  text = "Add item to %s:",
  button1 = "Add",
  button2 = "Cancel",
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnAccept = function(dropdownIndex)
    local itemName = getglobal(this:GetParent():GetName() .. "EditBox"):GetText()
    if itemName ~= "" then
      AddItemToDropdown(dropdownIndex, itemName)
    end
  end,
  EditBoxOnEnterPressed = function(dropdownIndex)
    -- print(dropdownIndex)
    local itemName = this:GetText()
    if itemName ~= "" then
      AddItemToDropdown(dropdownIndex, itemName)
      this:GetParent():Hide() -- Close the dialog
    end
  end,
  OnShow = function()
    getglobal(this:GetName() .. "EditBox"):SetFocus()
  end,
  OnHide = function()
    getglobal(this:GetName() .. "EditBox"):SetText("")
  end,
  enterClicksFirstButton = true,
}

StaticPopupDialogs["REM_ITEM_NAME"] = {
  text = "Really remove %s from %s?",
  button1 = "Remove",
  button2 = "Cancel",
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnAccept = function(data)
    RemoveItemFromDropdown(data[1], data[2])
  end,
}

-- Dropdowns for adding/removing item names with proper names
local lists_x,lists_y = 350,-180
local dropdown1 = CreateListsDropdown(EasyLootConfigFrame, "Need Whitelist", EasyLootDB.needlist, 120,365, lists_y-110, "Dropdown1Frame", "A list of items that will always be Needed, even BoP items.")
local dropdown2 = CreateListsDropdown(EasyLootConfigFrame, "Greed Whitelist", EasyLootDB.greedlist, 120,365, lists_y-155, "Dropdown2Frame", "A list of items that will always be Greeded, even BoP items.")
local dropdown3 = CreateListsDropdown(EasyLootConfigFrame, "Pass Whitelist", EasyLootDB.passlist, 120,365, lists_y-200, "Dropdown3Frame", "A list of items that will always be Passed, and not auto-looted.")

end