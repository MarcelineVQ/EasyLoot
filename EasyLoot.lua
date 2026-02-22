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

local function TitleCase(str)
  return (string.gsub(str, "(%a)([%a']*)", function(first, rest)
    return string.upper(first) .. rest
  end))
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
local ITEM_COLOR = "|cff88bbdd"

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

local mc_trash_bop = {
  "Lavashard Axe",
  "Boots of Blistering Flames",
  "Core Forged Helmet",
  "Lost Dark Iron Chain",
  "Shoulderpads of True Flight",
  "Ashskin Belt",
}

local bwl_trash_bop = {
  "Doom's Edge",
  "Band of Dark Dominion",
  "Essence Gatherer",
  "Draconic Maul",
  "Cloak of Draconic Might",
  "Boots of Pure Thought",
  "Draconic Avenger",
  "Ringo's Blizzard Boots",
  "Interlaced Shadow Jerkin",
}

local aq40_trash_bop = {
  "Shard of the Fallen Star",
  "Gloves of the Redeemed Prophecy",
  "Gloves of the Fallen Prophet",
  "Anubisath Warhammer",
  "Ritssyn's Ring of Chaos",
  "Neretzek, The Blood Drinker",
  "Gloves of the Immortal",
  "Garb of Royal Ascension",
}

local naxx_trash_bop = {
  "Ring of the Eternal Flame",
  "Misplaced Servo Arm",
  "Ghoul Skin Tunic",
  "Necro-Knight's Garb",
  "Stygian Buckler",
  "Harbinger of Doom",
  "Spaulders of the Grand Crusader",
  "Leggings of the Grand Crusader",
  "Leggings of Elemental Fury",
  "Girdle of Elemental Fury",
  "Belt of the Grand Crusader",
}

local es_trash_bop = {
  "Lucid Nightmare",
  "Corrupted Reed",
  "Verdant Dreamer's Boots",
  "Nature's Gift",
  "Lasher's Whip",
  "Infused Wildthorn Bracers",
  "Sleeper's Ring",
  "Emerald Rod",
}

local kara_trash_bop = {
  "Slivers of Nullification",
  "The End of All Ambitions",
  "Ques' Gauntlets of Precision",
  "Boots of Elemental Fury",
  "Gauntlets of Elemental Fury",
  "Boots of the Grand Crusader",
  "Gauntlets of the Grand Crusader",
  "Dragunovi's Sash of Domination",
  "Ring of Holy Light",
  "Brand of Karazhan",
}

------------------------------
-- Raid Config
------------------------------

local raid_config = {
  { zone = "Zul'Gurub", short = "ZG", categories = {
    { label = "Coins", items = zg_coin, key = "zg_coin", default = NEED },
    { label = "Bijou", items = zg_bijou, key = "zg_bijou", default = NEED },
    {},
    { label = "BoEs", key = "zg_boe", default = NEED, is_boe = true },
  }},
  { zone = "Ruins of Ahn'Qiraj", short = "AQ20", categories = {
    { label = "Idols", items = idol_aq20, key = "aq20_idol", default = NEED },
    { label = "Scarabs", items = scarab, key = "aq20_scarab", default = NEED },
    {},
    { label = "BoEs", key = "aq20_boe", default = NEED, is_boe = true },
  }},
  { zone = "Molten Core", short = "MC", categories = {
    { label = "Ingot", items = {"Sulfuron Ingot"}, key = "mc_ingot", default = OFF },
    { label = "Mats", items = mc_mat, key = "mc_mat", default = OFF },
    { label = "Trash BoPs", items = mc_trash_bop, key = "mc_trash", default = OFF },
    { label = "BoEs", key = "mc_boe", default = OFF, is_boe = true },
  }},
  { zone = "Blackwing Lair", short = "BWL", categories = {
    { label = "Elementium", items = {}, key = "bwl_mat", default = OFF },
    {},
    { label = "Trash BoPs", items = bwl_trash_bop, key = "bwl_trash", default = OFF },
    { label = "BoEs", key = "bwl_boe", default = OFF, is_boe = true },
  }},
  { zone = "Emerald Sanctum", short = "ES", categories = {
    { label = "Scales+Fading", items = {"Dreamscale", "Fading Dream Fragment"}, key = "es_mat", default = OFF },
    {},
    { label = "Trash BoPs", items = es_trash_bop, key = "es_trash", default = OFF },
    { label = "BoEs", key = "es_boe", default = OFF, is_boe = true },
  }},
  { zone = "Ahn'Qiraj", short = "AQ40", categories = {
    { label = "Idols", items = idol_aq40, key = "aq40_idol", default = OFF },
    { label = "Scarabs", items = scarab, key = "aq40_scarab", default = OFF },
    { label = "Trash BoPs", items = aq40_trash_bop, key = "aq40_trash", default = OFF },
    { label = "BoEs", key = "aq40_boe", default = OFF, is_boe = true },
  }},
  { zone = "Naxxramas", short = "Naxx", categories = {
    { label = "Scraps", items = scrap, key = "naxx_scrap", default = OFF },
    {},
    { label = "Trash BoPs", items = naxx_trash_bop, key = "naxx_trash", default = OFF },
    { label = "BoEs", key = "naxx_boe", default = OFF, is_boe = true },
  }},
  { zone = "Tower of Karazhan", aliases = {"The Rock of Desolation"}, short = "Kara40", categories = {
    { label = "Pristine Ley Crystal", items = {"Pristine Ley Crystal"}, key = "kara_mat", default = OFF },
    { label = "Overcharged Ley Energy", items = {"Overcharged Ley Energy"}, key = "kara_energy", default = OFF },
    { label = "Trash BoPs", items = kara_trash_bop, key = "kara_trash", default = OFF },
    { label = "BoEs", key = "kara_boe", default = OFF, is_boe = true },
  }},
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

local toggle_options = {
  { label = "Auto-Invite",     setting = "auto_invite",     default = true,  tooltip = "Always accept invites from friends or guild members." },
  { label = "Accept Summon",    setting = "auto_summon",     default = false,  tooltip = "Automatically accept summons." },
  { label = "Accept Resurrect", setting = "auto_resurrect",  default = false,  tooltip = "Automatically accept resurrections." },
  { label = "Buy Items", setting = "auto_buy",         default = true,  tooltip = "Automatically buy enabled items from the vendor purchase list (hold Ctrl to disable)." },
  { label = "Sell Greys", setting = "auto_sell_greys", default = true,  tooltip = "Automatically sell grey items when opening a vendor (hold Ctrl to disable)." },
  { label = "Auto-Repair",     setting = "auto_repair",     default = true,  tooltip = "Repair at any valid vendor (hold Ctrl to disable)." },
  { label = "Auto-Dismount",   setting = "auto_dismount",   default = true,  tooltip = "Automatically dismount when trying to use most actions on a mount." },
  { label = "Auto-Stand",      setting = "auto_stand",      default = true,  tooltip = "Automatically stand when trying to use actions while sitting." },
  { label = "Auto-Gossip",     setting = "auto_gossip",     default = true,  tooltip = "Automatically choose the most common gossip options (hold Ctrl to disable)." },
  { label = "Combat Plates",  setting = "combat_plates",   default = false, tooltip = "Only show enemy nameplates in combat, hide when leaving combat." },
  { label = "Shift to Loot",   setting = "shift_to_loot",   default = false, tooltip = "Invert Shift behavior: only autoloot when Shift is held." },
  { label = "Pass on Greys",   setting = "pass_greys",      default = false, tooltip = "Do not loot grey items." },
  { label = "Holy Water Only", setting = "only_holy",       default = false, tooltip = "Only loot holy water from Stratholme Chests." },
  { label = "Need List", setting = "need_whitelist",    default = true,  tooltip = "Enable the Need whitelist for auto-rolling." },
  { label = "Greed List",setting = "greed_whitelist",   default = true,  tooltip = "Enable the Greed whitelist for auto-rolling." },
  { label = "Pass List", setting = "pass_whitelist",    default = true,  tooltip = "Enable the Pass whitelist for auto-rolling." },
}

local default_settings = {
  general_boe_rule = GREED,
}
for _,opt in ipairs(toggle_options) do
  default_settings[opt.setting] = opt.default
end
for _,raid in ipairs(raid_config) do
  for _,cat in ipairs(raid.categories) do
    if cat.key then default_settings[cat.key] = cat.default end
  end
end

-- Determine what kind of roll we want for the item and do the pass, or roll of need or greed
-- returns the roll type, if it was in an explicit list, and if it's a BoE item
function EasyLoot:HandleItem(name,explicit_only)
  -- check specific lists first
  if EasyLootDB.settings.need_whitelist and fuzzy_elem(EasyLootDB.needlist,name) then
    return NEED,true,false
  elseif EasyLootDB.settings.greed_whitelist and fuzzy_elem(EasyLootDB.greedlist,name) then
    return GREED,true,false
  elseif EasyLootDB.settings.pass_whitelist and fuzzy_elem(EasyLootDB.passlist,name) then
    return PASS,true,false
  end

  -- check raid zone item lists (BoP items match explicit lists, BoE items also get fallback)
  local zone = GetRealZoneText()
  for _,raid in ipairs(raid_config) do
    if raid.zone == zone or (raid.aliases and elem(raid.aliases, zone)) then
      local boe_cat = nil
      for _,cat in ipairs(raid.categories) do
        if cat.is_boe then
          boe_cat = cat
        elseif cat.items and elem(cat.items, name) then
          return EasyLootDB.settings[cat.key],false,false
        end
      end
      -- BoP items that didn't match any explicit item list: don't auto-roll
      if explicit_only then return OFF,false,false end
      -- BoE fallback for the zone
      if boe_cat then
        return EasyLootDB.settings[boe_cat.key],false,true
      end
      return EasyLootDB.settings.general_boe_rule,false,true
    end
  end
  if explicit_only then return OFF,false,false end
  return EasyLootDB.settings.general_boe_rule,false,true
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
  local shift = IsShiftKeyDown()
  if (not EasyLootDB.settings.shift_to_loot and shift) or (EasyLootDB.settings.shift_to_loot and not shift) then
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
      local r,in_explicit_list,is_boe = EasyLoot:HandleItem(item)
      local is_container = not (UnitExists("target") and UnitIsDead("target")) -- best we can do

      -- determine loot to skip
      if in_explicit_list and (r == PASS) then
        -- loot is on our pass list
        debug_print("passlist "..item)
      elseif (quality == 0 and EasyLootDB.settings.pass_greys) and not (r > 0 and in_explicit_list) then
        -- do nothing, unless it's a whitelist item
        debug_print("passgrey " .. item)
      elseif (r == OFF or r == PASS) and InGroup() and not is_boe then
        -- non-BoE item set to pass/off in group, skip looting (e.g. coins, bijous, scarabs)
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

function EasyLoot:PLAYER_REGEN_ENABLED()
  if EasyLootDB.settings.combat_plates then HideNameplates() end
end

function EasyLoot:PLAYER_REGEN_DISABLED()
  if EasyLootDB.settings.combat_plates then ShowNameplates() end
end

function EasyLoot:PLAYER_ENTERING_WORLD()
  if EasyLootDB.settings.combat_plates and not UnitAffectingCombat("player") then
    HideNameplates()
  end
end

function EasyLoot:ZONE_CHANGED_NEW_AREA()
  if EasyLootDB.settings.combat_plates and not UnitAffectingCombat("player") then
    HideNameplates()
  end
end

function EasyLoot:VARIABLES_LOADED()
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
  EasyLoot:RegisterEvent("CONFIRM_SUMMON")
  EasyLoot:RegisterEvent("RESURRECT_REQUEST")
  EasyLoot:RegisterEvent("PLAYER_ENTERING_WORLD")
  EasyLoot:RegisterEvent("ZONE_CHANGED_NEW_AREA")

  -- hook away superapi's autoloot functionality and set autloot to off since this handles it
  if IfShiftAutoloot then
    IfShiftAutoloot = function () return end
  end
  -- other method
  if SuperAPI then
    SuperAPI.IfShiftAutoloot = function () SetAutoloot(0) end
    SuperAPI.IfShiftNoAutoloot = function () SetAutoloot(0) end
    -- SuperAPI.frame:SetScript("OnUpdate", nil)
  elseif SetAutoloot then -- superwow but no superapi
    SetAutoloot(0)
  end

  EasyLoot:CreateConfig()

  -- Restore saved frame position (must be after CreateConfig)
  if EasyLootDB.position then
    EasyLootConfigFrame:ClearAllPoints()
    EasyLootConfigFrame:SetPoint(
      EasyLootDB.position.point, UIParent,
      EasyLootDB.position.relPoint,
      EasyLootDB.position.x, EasyLootDB.position.y
    )
  end
end

function EasyLoot:CONFIRM_SUMMON()
  if EasyLootDB.settings.auto_summon then
    ConfirmSummon()
    StaticPopup_Hide("CONFIRM_SUMMON")
  end
end

function EasyLoot:RESURRECT_REQUEST()
  if EasyLootDB.settings.auto_resurrect then
    AcceptResurrect()
    StaticPopup_Hide("RESURRECT_NO_SICKNESS")
  end
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

-- Register events
EasyLoot:RegisterEvent("VARIABLES_LOADED")
EasyLoot:SetScript("OnEvent", function ()
  EasyLoot[event](this,arg1,arg2,arg3,arg4,arg6,arg7,arg8,arg9,arg9,arg10)
end)

function EasyLoot:Load()
  EasyLootDB = EasyLootDB or {}
  EasyLootDB.needlist = EasyLootDB.needlist or {}
  EasyLootDB.greedlist = EasyLootDB.greedlist or {}
  EasyLootDB.passlist = EasyLootDB.passlist or {}
  EasyLootDB.buylist = EasyLootDB.buylist or {}

  EasyLootDB.settings = EasyLootDB.settings or default_settings
  -- ensure all raid settings exist (for newly added raids)
  for _,raid in ipairs(raid_config) do
    for _,cat in ipairs(raid.categories) do
      if cat.key and EasyLootDB.settings[cat.key] == nil then
        EasyLootDB.settings[cat.key] = cat.default
      end
    end
  end
  EasyLootDB.settings.general_boe_rule = EasyLootDB.settings.general_boe_rule or default_settings.general_boe_rule
  -- ensure all boolean toggle settings exist
  for _,opt in ipairs(toggle_options) do
    if EasyLootDB.settings[opt.setting] == nil then
      EasyLootDB.settings[opt.setting] = opt.default
    end
  end
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
  if IsControlKeyDown() then return end

  -- auto repair
  if EasyLootDB.settings.auto_repair and CanMerchantRepair() then
    local rcost = GetRepairAllCost()
    if rcost and rcost ~= 0 then
      if rcost > GetMoney() then
        el_print("Not Enough Money to Repair.")
      else
        RepairAllItems()
        local gcost,scost,ccost = rcost/100/100,math.mod(rcost/100,100),math.mod(rcost,100)
        local COLOR_GOLD   = gcost > 0 and format("|cffffd700%dg|r",gcost) or ""
        local COLOR_SILVER = scost > 0 and format("|cffc7c7cf%ds|r",scost) or ""
        local COLOR_COPPER = ccost > 0 and format("|cffeda55f%dc|r",ccost) or ""
        el_print(format("Equipment repaired for: %s%s%s", COLOR_GOLD, COLOR_SILVER, COLOR_COPPER))
      end
    end
  end

  -- auto sell greys (one per frame, SortBags-style throttling)
  if EasyLootDB.settings.auto_sell_greys then
    local queue = {}
    for bag = 0, 4 do
      for slot = 1, GetContainerNumSlots(bag) do
        local link = GetContainerItemLink(bag, slot)
        if link and string.find(link, "ff9d9d9d") then
          table.insert(queue, { bag = bag, slot = slot })
        end
      end
    end
    if queue[1] then
      if not EasyLoot.vendorSellFrame then
        EasyLoot.vendorSellFrame = CreateFrame("Frame")
      end
      local f = EasyLoot.vendorSellFrame
      f.queue = queue
      f.index = 1
      f.gold_before = GetMoney()
      f.timeout = GetTime() + 7
      f.opTimeout = 0
      f.waiting = false
      f:SetScript("OnUpdate", function()
        if GetTime() > this.timeout then
          this:SetScript("OnUpdate", nil)
          return
        end
        if this.waiting then
          local item = this.queue[this.index - 1]
          if GetContainerItemLink(item.bag, item.slot) then
            if GetTime() > this.opTimeout then
              this.waiting = false
            end
            return
          end
          this.waiting = false
        end
        local item = this.queue[this.index]
        if not item then
          local earned = GetMoney() - this.gold_before
          if earned > 0 then
            local gcost = math.floor(earned / 100 / 100)
            local scost = math.floor(math.mod(earned / 100, 100))
            local ccost = math.floor(math.mod(earned, 100))
            local COLOR_GOLD   = gcost > 0 and format("|cffffd700%dg|r",gcost) or ""
            local COLOR_SILVER = scost > 0 and format("|cffc7c7cf%ds|r",scost) or ""
            local COLOR_COPPER = ccost > 0 and format("|cffeda55f%dc|r",ccost) or ""
            el_print(format("Sold grey items for: %s%s%s", COLOR_GOLD, COLOR_SILVER, COLOR_COPPER))
          end
          this:SetScript("OnUpdate", nil)
          return
        end
        UseContainerItem(item.bag, item.slot)
        this.index = this.index + 1
        this.waiting = true
        this.opTimeout = GetTime() + 2
      end)
    end
  end

  -- auto buy items from purchase list
  if EasyLootDB.settings.auto_buy and EasyLootDB.buylist then
    for _,entry in ipairs(EasyLootDB.buylist) do
      if entry.enabled ~= false then
        -- count how many of this item are already in bags
        local inBags = 0
        for bag = 0, 4 do
          for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link then
              local bagName = ItemLinkToName(link)
              if bagName and string.lower(bagName) == string.lower(entry.name) then
                local _,count = GetContainerItemInfo(bag, slot)
                inBags = inBags + (count or 1)
              end
            end
          end
        end
        local needed = entry.count - inBags
        if needed > 0 then
          for i = 1, GetMerchantNumItems() do
            local mName = GetMerchantItemInfo(i)
            if mName and string.lower(mName) == string.lower(entry.name) then
              BuyMerchantItem(i, needed)
              el_print(format("Bought %dx "..ITEM_COLOR.."%s|r", needed, entry.name))
              break
            end
          end
        end
      end
    end
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
  EasyLootConfigFrame:SetWidth(360)
  EasyLootConfigFrame:SetHeight(325)
  EasyLootConfigFrame:SetPoint("CENTER", UIParent, "CENTER")  -- Centered frame
  EasyLootConfigFrame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 32, edgeSize = 32,
      insets = { left = 11, right = 12, top = 12, bottom = 11 }
  })
  EasyLootConfigFrame:Hide()

  -- Make the frame draggable
  EasyLootConfigFrame:SetMovable(true)
  EasyLootConfigFrame:EnableMouse(true)
  EasyLootConfigFrame:RegisterForDrag("LeftButton")
  EasyLootConfigFrame:SetScript("OnDragStart", function() this:StartMoving() end)
  EasyLootConfigFrame:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    local point, _, relPoint, x, y = this:GetPoint()
    EasyLootDB.position = { point = point, relPoint = relPoint, x = x, y = y }
  end)

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
  SlashCmdList["EASYLOOT"] = function(msg)
      if msg == "reset" then
          EasyLootConfigFrame:ClearAllPoints()
          EasyLootConfigFrame:SetPoint("CENTER", UIParent, "CENTER")
          EasyLootDB.position = nil
          el_print("Frame position reset.")
          if not EasyLootConfigFrame:IsShown() then EasyLootConfigFrame:Show() end
      elseif EasyLootConfigFrame:IsShown() then
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

  -- Icon state definitions for raid loot toggles
  local state_icons = {
    [NEED]  = { tex = "Interface\\Buttons\\UI-GroupLoot-Dice-Up", label = "Need" },
    [GREED] = { tex = "Interface\\Buttons\\UI-GroupLoot-Coin-Up", label = "Greed" },
    [PASS]  = { tex = "Interface\\Buttons\\UI-GroupLoot-Pass-Up", label = "Pass" },
    [OFF]   = { tex = "Interface\\Buttons\\UI-GroupLoot-Dice-Up", label = "Off", r = 0.15, g = 0.15, b = 0.15 },
  }
  local state_cycle = { [NEED] = GREED, [GREED] = PASS, [PASS] = OFF, [OFF] = NEED }

  local function CreateStateIcon(parent, cat, x, y)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(24)
    btn:SetHeight(24)
    btn:SetPoint("TOPLEFT", x, y)

    local tex = btn:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()

    local function UpdateIcon()
      local state = EasyLootDB.settings[cat.key]
      local info = state_icons[state] or state_icons[OFF]
      tex:SetTexture(info.tex)
      if info.r then
        tex:SetVertexColor(info.r, info.g, info.b)
      else
        tex:SetVertexColor(1, 1, 1)
      end
    end

    UpdateIcon()

    local function ShowTooltip()
      GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
      local state = EasyLootDB.settings[cat.key]
      local info = state_icons[state] or state_icons[OFF]
      GameTooltip:SetText(cat.label, 1, 0.82, 0)
      GameTooltip:AddLine("Current: " .. info.label, 1, 1, 1)
      GameTooltip:AddLine("Click to cycle", 0.5, 0.5, 0.5)
      GameTooltip:Show()
    end

    btn:SetScript("OnClick", function()
      local current = EasyLootDB.settings[cat.key]
      EasyLootDB.settings[cat.key] = state_cycle[current] or NEED
      UpdateIcon()
      ShowTooltip()
    end)

    btn:SetScript("OnEnter", function()
      ShowTooltip()
    end)

    btn:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)

    return btn
  end

  -- Raid sections (generated from raid_config)
  local raid_y = -52
  for _,raid in ipairs(raid_config) do
    local zone_name = raid.zone

    local labelFrame = CreateFrame("Frame", nil, EasyLootConfigFrame)
    labelFrame:SetWidth(40)
    labelFrame:SetHeight(20)
    labelFrame:SetPoint("TOPLEFT", 20, raid_y - 2)
    labelFrame:EnableMouse(true)

    local raidLabel = labelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    raidLabel:SetPoint("LEFT", 0, 0)
    raidLabel:SetText(raid.short)

    labelFrame:SetScript("OnEnter", function()
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:SetText(zone_name, 1, 0.82, 0)
      GameTooltip:Show()
    end)
    labelFrame:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)

    for ci,cat in ipairs(raid.categories) do
      if cat.key then
        local x = 65 + (ci - 1) * 28
        CreateStateIcon(EasyLootConfigFrame, cat, x, raid_y)
      end
    end

    raid_y = raid_y - 28
  end


  -- "Other" row for non-raid BoE rule (world/dungeon)
  raid_y = raid_y - 4
  local otherLabel = CreateFrame("Frame", nil, EasyLootConfigFrame)
  otherLabel:SetWidth(50)
  otherLabel:SetHeight(20)
  otherLabel:SetPoint("TOPLEFT", 20, raid_y - 2)
  otherLabel:EnableMouse(true)

  local otherText = otherLabel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  otherText:SetPoint("LEFT", 0, 0)
  otherText:SetText("Other")

  otherLabel:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText("World and Dungeon", 1, 0.82, 0)
    GameTooltip:Show()
  end)
  otherLabel:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  CreateStateIcon(EasyLootConfigFrame,
    { label = "BoEs", key = "general_boe_rule", is_boe = true },
    65, raid_y)

  ----------------------------------------------------------------------
  -- Additional Options section
  local optionsDropdown = CreateFrame("Button", "EasyLootOptionsDropdown", EasyLootConfigFrame, "UIDropDownMenuTemplate")

  local function InitializeOptionsDropdown()
    for idx,opt in ipairs(toggle_options) do
      local setting_key = opt.setting
      local info = {}
      info.text = opt.label
      info.keepShownOnClick = 1
      info.checked = EasyLootDB.settings[setting_key] and 1 or nil
      info.func = function ()
        EasyLootDB.settings[setting_key] = not EasyLootDB.settings[setting_key]
        if setting_key == "combat_plates" then
          if EasyLootDB.settings.combat_plates and not UnitAffectingCombat("player") then
            HideNameplates()
          end
        end
      end
      UIDropDownMenu_AddButton(info)

      local btn = getglobal("DropDownList1Button"..idx)
      if btn then
        if not btn.el_orig_enter then
          btn.el_orig_enter = btn:GetScript("OnEnter")
          btn.el_orig_leave = btn:GetScript("OnLeave")
        end
        btn.el_label = opt.label
        btn.el_tooltip = opt.tooltip
        btn:SetScript("OnEnter", function()
          if this.el_orig_enter then this.el_orig_enter() end
          if UIDROPDOWNMENU_OPEN_MENU ~= "EasyLootOptionsDropdown" then return end
          GameTooltip:SetOwner(EasyLootOptionsDropdown, "ANCHOR_BOTTOMRIGHT")
          GameTooltip:SetText(this.el_label, 1, 0.82, 0)
          GameTooltip:AddLine(this.el_tooltip, 1, 1, 1, true)
          GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
          if this.el_orig_leave then this.el_orig_leave() end
          GameTooltip:Hide()
        end)
      end
    end
  end

  UIDropDownMenu_Initialize(optionsDropdown, InitializeOptionsDropdown)
  UIDropDownMenu_SetWidth(110, optionsDropdown)
  UIDropDownMenu_SetText("Options", optionsDropdown)

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
    local dropdown = CreateFrame("Button", name, parent, "UIDropDownMenuTemplate")
    dropdown.el_default_text = label
    dropdown:SetPoint("TOP", x - 210, y)

    -- local selectedValue = defaultValue

    -- Manual initialization for the dropdown
    local function InitializeDropdown()
      local btnIdx = 0

      -- "Add New item" entry
      local info = {}
      info.text = "Add New item"
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
      UIDropDownMenu_AddButton(info)
      btnIdx = btnIdx + 1

      -- tooltip on "Add New item" button
      local addBtn = getglobal("DropDownList1Button"..btnIdx)
      if addBtn then
        if not addBtn.el_orig_enter then
          addBtn.el_orig_enter = addBtn:GetScript("OnEnter")
          addBtn.el_orig_leave = addBtn:GetScript("OnLeave")
        end
        addBtn.el_dropdown_owner = name
        addBtn:SetScript("OnEnter", function()
          if this.el_orig_enter then this.el_orig_enter() end
          if UIDROPDOWNMENU_OPEN_MENU ~= this.el_dropdown_owner then return end
          GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
          GameTooltip:SetText(label, 1, 0.82, 0)
          GameTooltip:AddLine(tooltip, 1, 1, 1, true)
          GameTooltip:AddLine("Right-click an item to remove it.", 0.5, 0.5, 0.5, true)
          GameTooltip:Show()
        end)
        addBtn:SetScript("OnLeave", function()
          if this.el_orig_leave then this.el_orig_leave() end
          GameTooltip:Hide()
        end)
      end

      -- item entries with right-click to remove
      for i, item in ixpairs(items) do
          local info = {}
          info.text = item
          info.value = item
          UIDropDownMenu_AddButton(info)
          btnIdx = btnIdx + 1

          local btn = getglobal("DropDownList1Button"..btnIdx)
          if btn then
            btn.el_remove_item = item
            btn.el_dropdown_owner = name
            btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            btn:SetScript("OnClick", function()
              if UIDROPDOWNMENU_OPEN_MENU == this.el_dropdown_owner and arg1 == "RightButton" then
                CloseDropDownMenus()
                local pop = StaticPopup_Show("REM_ITEM_NAME", this.el_remove_item, label)
                pop.data = { items, this.el_remove_item, dropdown }
              else
                UIDropDownMenuButton_OnClick()
              end
            end)
          end
      end
    end

    -- Set up the dropdown, ensuring it is properly initialized with a named frame
    UIDropDownMenu_Initialize(dropdown, InitializeDropdown)
    UIDropDownMenu_SetWidth(width,dropdown)
    UIDropDownMenu_SetText(dropdown.el_default_text, dropdown)

    return dropdown
  end

-- Function to add item to dropdown
local function AddItemToDropdown(dropdown_list, item)
  item = TitleCase(item)
  for _,v in ipairs(dropdown_list) do
    if string.lower(v) == string.lower(item) then return end
  end
  table.insert(dropdown_list, item)
  el_print("Added item: "..ITEM_COLOR..item.."|r to whitelist.")
end

-- Function to remove item from dropdown
local function RemoveItemFromDropdown(dropdown_list, item)
  for i,name in pairs(dropdown_list) do
    if name == item then
      table.remove(dropdown_list,i)
      el_print("Removed item: "..ITEM_COLOR..item.."|r from whitelist.")
      break
    end
  end
end

-- Hidden fontstring for measuring edit box text width (EditBox lacks GetStringWidth in 1.12)
local _popupMeasureFS = UIParent:CreateFontString(nil, "ARTWORK", "ChatFontNormal")

-- Shared popup helpers for wide edit boxes
local function PopupEditBoxOnTextChanged()
  local popup = this:GetParent()
  _popupMeasureFS:SetText(this:GetText())
  local textWidth = _popupMeasureFS:GetStringWidth()
  local editBase = 240
  local popupBase = 420
  local overflow = textWidth - editBase + 20
  if overflow > 0 then
    popup:SetWidth(popupBase + overflow)
    this:SetWidth(editBase + overflow)
    if this._borderLeft then
      local newWidth = this._borderLeftWidth + (editBase - 130) + overflow
      this._borderLeft:SetWidth(newWidth)
      this._borderLeft:SetTexCoord(0, math.min(1, newWidth / 256), 0, 1)
    end
  else
    popup:SetWidth(popupBase)
    this:SetWidth(editBase)
    if this._borderLeft then
      local newWidth = this._borderLeftWidth + (editBase - 130)
      this._borderLeft:SetWidth(newWidth)
      this._borderLeft:SetTexCoord(0, math.min(1, newWidth / 256), 0, 1)
    end
  end
end

local function PopupOnShow()
  local editbox = getglobal(this:GetName() .. "EditBox")
  if not editbox._borderLeft then
    for _, region in pairs({editbox:GetRegions()}) do
      if region.GetTexture and region:GetTexture()
         and string.find(region:GetTexture(), "Left") then
        editbox._borderLeft = region
        editbox._borderLeftWidth = region:GetWidth()
        break
      end
    end
  end
  this:SetWidth(420)
  editbox:SetWidth(240)
  if editbox._borderLeft then
    local newWidth = editbox._borderLeftWidth + (240 - 130)
    editbox._borderLeft:SetWidth(newWidth)
    editbox._borderLeft:SetTexCoord(0, math.min(1, newWidth / 256), 0, 1)
  end
  editbox:SetFocus()
end

local function PopupOnHide()
  local editbox = getglobal(this:GetName() .. "EditBox")
  this:SetWidth(320)
  editbox:SetWidth(130)
  if editbox._borderLeft then
    editbox._borderLeft:SetWidth(editbox._borderLeftWidth)
    editbox._borderLeft:SetTexCoord(0, editbox._borderLeftWidth / 256, 0, 1)
  end
  editbox:SetText("")
end

local function ParseBuyInput(text)
  local _,_,numStr,itemName = string.find(text, "^(%d+)x?%s+(.+)$")
  if not itemName then
    itemName = text
    numStr = "20"
  end
  local count = tonumber(numStr) or 20
  itemName = string.gsub(itemName, "^%s*", "")
  itemName = string.gsub(itemName, "%s*$", "")
  itemName = TitleCase(itemName)
  if itemName == "" then return end
  local found = false
  for _,entry in ipairs(EasyLootDB.buylist) do
    if string.lower(entry.name) == string.lower(itemName) then
      entry.count = count
      entry.enabled = true
      found = true
      break
    end
  end
  if not found then
    table.insert(EasyLootDB.buylist, { name = itemName, count = count, enabled = true })
  end
  el_print(format("Added %dx "..ITEM_COLOR.."%s|r to buy list.", count, itemName))
end

-- Static Popup Dialog for entering item names
StaticPopupDialogs["ADD_ITEM_NAME"] = {
  text = "Add item to %s:\nShift-click an item to insert its name.",
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
    local itemName = this:GetText()
    if itemName ~= "" then
      AddItemToDropdown(dropdownIndex, itemName)
      this:GetParent():Hide()
    end
  end,
  EditBoxOnTextChanged = PopupEditBoxOnTextChanged,
  OnShow = PopupOnShow,
  OnHide = PopupOnHide,
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
    data[3].selected = nil
    UIDropDownMenu_SetText(data[3].el_default_text or "", data[3])
  end,
}

StaticPopupDialogs["ADD_BUY_ITEM"] = {
  text = "Enter quantity and item name: 20 Sacred Candle\nShift-click an item to insert its name.",
  button1 = "Add",
  button2 = "Cancel",
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnAccept = function()
    local text = getglobal(this:GetParent():GetName() .. "EditBox"):GetText()
    if text ~= "" then ParseBuyInput(text) end
  end,
  EditBoxOnEnterPressed = function()
    local text = this:GetText()
    if text ~= "" then ParseBuyInput(text) end
    this:GetParent():Hide()
  end,
  EditBoxOnTextChanged = PopupEditBoxOnTextChanged,
  OnShow = PopupOnShow,
  OnHide = PopupOnHide,
  enterClicksFirstButton = true,
}

StaticPopupDialogs["REM_BUY_ITEM"] = {
  text = "Really remove %s from buy list?",
  button1 = "Remove",
  button2 = "Cancel",
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnAccept = function(data)
    local displayName = data[1]
    for i,entry in ipairs(EasyLootDB.buylist) do
      local entryDisplay = entry.count .. "x " .. entry.name
      if entryDisplay == displayName then
        table.remove(EasyLootDB.buylist, i)
        el_print("Removed "..ITEM_COLOR .. entry.name .. "|r from buy list.")
        break
      end
    end
    data[2].selected = nil
    UIDropDownMenu_SetText(data[2].el_default_text or "", data[2])
  end,
}

  ----------------------------------------------------------------------
  -- Buy List dropdown
  local function CreateBuyListDropdown(parent, x, y)
    local dropdown = CreateFrame("Button", "EasyLootBuyListDropdown", parent, "UIDropDownMenuTemplate")
    dropdown.el_default_text = "Buy List"
    dropdown:SetPoint("TOP", x - 210, y)

    local function InitializeDropdown()
      local btnIdx = 0

      -- "Add New item" entry
      local info = {}
      info.text = "Add New item"
      info.func = function ()
        local add = StaticPopup_Show("ADD_BUY_ITEM")
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
      UIDropDownMenu_AddButton(info)
      btnIdx = btnIdx + 1

      -- tooltip on "Add New item" button
      local addBtn = getglobal("DropDownList1Button"..btnIdx)
      if addBtn then
        if not addBtn.el_orig_enter then
          addBtn.el_orig_enter = addBtn:GetScript("OnEnter")
          addBtn.el_orig_leave = addBtn:GetScript("OnLeave")
        end
        addBtn:SetScript("OnEnter", function()
          if this.el_orig_enter then this.el_orig_enter() end
          if UIDROPDOWNMENU_OPEN_MENU ~= "EasyLootBuyListDropdown" then return end
          GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
          GameTooltip:SetText("Buy List", 1, 0.82, 0)
          GameTooltip:AddLine("Format: 20 Sacred Candle (or 20x Sacred Candle)", 1, 1, 1, true)
          GameTooltip:AddLine("Right-click an item to remove it.", 0.5, 0.5, 0.5, true)
          GameTooltip:Show()
        end)
        addBtn:SetScript("OnLeave", function()
          if this.el_orig_leave then this.el_orig_leave() end
          GameTooltip:Hide()
        end)
      end

      -- item entries with right-click to remove
      for _,entry in ipairs(EasyLootDB.buylist) do
        if entry.enabled == nil then entry.enabled = true end
        local displayText = entry.count .. "x " .. entry.name
        local thisEntry = entry
        local info = {}
        info.text = displayText
        info.value = entry.name
        info.keepShownOnClick = 1
        info.checked = entry.enabled and 1 or nil
        info.func = function ()
          thisEntry.enabled = not thisEntry.enabled
        end
        UIDropDownMenu_AddButton(info)
        btnIdx = btnIdx + 1

        local btn = getglobal("DropDownList1Button"..btnIdx)
        if btn then
          btn.el_remove_display = displayText
          btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
          btn:SetScript("OnClick", function()
            if UIDROPDOWNMENU_OPEN_MENU == "EasyLootBuyListDropdown" and arg1 == "RightButton" then
              CloseDropDownMenus()
              local pop = StaticPopup_Show("REM_BUY_ITEM", this.el_remove_display)
              pop.data = { this.el_remove_display, dropdown }
            else
              UIDropDownMenuButton_OnClick()
            end
          end)
        end
      end
    end

    UIDropDownMenu_Initialize(dropdown, InitializeDropdown)
    UIDropDownMenu_SetWidth(110, dropdown)
    UIDropDownMenu_SetText(dropdown.el_default_text, dropdown)

    return dropdown
  end

-- Right-column dropdown layout (all positions in one spot)
local right_col_dropdowns = {
  { type = "options",   y = -45  },
  { type = "buylist",   y = -80  },
  { type = "whitelist", y = -215, label = "Need List",  list = "needlist",  tooltip = "A list of items that will always be Needed, even BoP items." },
  { type = "whitelist", y = -245, label = "Greed List", list = "greedlist", tooltip = "A list of items that will always be Greeded, even BoP items." },
  { type = "whitelist", y = -275, label = "Pass List",  list = "passlist",  tooltip = "A list of items that will always be Passed, and not auto-looted." },
}
local wl_idx = 0
for _,dd in ipairs(right_col_dropdowns) do
  if dd.type == "options" then
    optionsDropdown:SetPoint("TOP", 85, dd.y)
  elseif dd.type == "buylist" then
    CreateBuyListDropdown(EasyLootConfigFrame, 295, dd.y)
  elseif dd.type == "whitelist" then
    wl_idx = wl_idx + 1
    CreateListsDropdown(EasyLootConfigFrame, dd.label, EasyLootDB[dd.list], 110, 295, dd.y, "Dropdown"..wl_idx.."Frame", dd.tooltip)
  end
end

  ----------------------------------------------------------------------
  -- Minimap button (shape-aware, based on MBF's snapMinimap approach)
  local MinimapShapes = {
    ["ROUND"]                   = {true, true, true, true},
    ["SQUARE"]                  = {false, false, false, false},
    ["CORNER-TOPLEFT"]          = {false, false, false, true},
    ["CORNER-TOPRIGHT"]         = {false, false, true, false},
    ["CORNER-BOTTOMLEFT"]       = {false, true, false, false},
    ["CORNER-BOTTOMRIGHT"]      = {true, false, false, false},
    ["SIDE-LEFT"]               = {false, true, false, true},
    ["SIDE-RIGHT"]              = {true, false, true, false},
    ["SIDE-TOP"]                = {false, false, true, true},
    ["SIDE-BOTTOM"]             = {true, true, false, false},
    ["TRICORNER-TOPLEFT"]       = {false, true, true, true},
    ["TRICORNER-TOPRIGHT"]      = {true, false, true, true},
    ["TRICORNER-BOTTOMLEFT"]    = {true, true, false, true},
    ["TRICORNER-BOTTOMRIGHT"]   = {true, true, true, false},
  }

  local function GetMinimapShapeCompat()
    if Squeenix then return "SQUARE" end
    if GetMinimapShape then return GetMinimapShape() or "ROUND" end
    if simpleMinimap_Skins then
      local skins = { "ROUND", "SQUARE", "CORNER-BOTTOMLEFT", "CORNER-BOTTOMRIGHT", "CORNER-TOPRIGHT", "CORNER-TOPLEFT" }
      return skins[simpleMinimap_Skins.db.profile.skin] or "ROUND"
    end
    if pfUI and pfUI_config and pfUI_config["disabled"] and pfUI_config["disabled"]["minimap"] ~= "1" then return "SQUARE" end
    return "ROUND"
  end

  local minimapBtn = CreateFrame("Button", "EasyLootMinimapButton", Minimap)
  minimapBtn:SetWidth(32)
  minimapBtn:SetHeight(32)
  minimapBtn:SetFrameStrata("MEDIUM")
  minimapBtn:SetFrameLevel(8)
  minimapBtn:SetToplevel(true)
  minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local icon = minimapBtn:CreateTexture(nil, "ARTWORK")
  icon:SetTexture("Interface\\Icons\\INV_Box_02")
  icon:SetWidth(20)
  icon:SetHeight(20)
  icon:SetPoint("CENTER", 0, 0)

  local border = minimapBtn:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetWidth(56)
  border:SetHeight(56)
  border:SetPoint("TOPLEFT", 0, 0)

  local function MinimapButton_UpdatePosition(angle)
    local mapSize = (Minimap:GetWidth() / 2)
    local rad = math.rad(angle)
    local x = math.cos(rad)
    local y = math.sin(rad)

    -- determine quadrant and check if round or square in that corner
    local q = 1
    if x < 0 then q = q + 1 end
    if y > 0 then q = q + 2 end
    local quadTable = MinimapShapes[GetMinimapShapeCompat()] or MinimapShapes["ROUND"]
    if quadTable[q] then
      x = x * mapSize
      y = y * mapSize
    else
      local diagDist = math.sqrt(2 * mapSize * mapSize)
      x = math.max(-mapSize, math.min(x * diagDist, mapSize))
      y = math.max(-mapSize, math.min(y * diagDist, mapSize))
    end

    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
  end

  EasyLootDB.minimap_angle = EasyLootDB.minimap_angle or 220
  MinimapButton_UpdatePosition(EasyLootDB.minimap_angle)

  minimapBtn:RegisterForDrag("LeftButton")
  minimapBtn:SetScript("OnDragStart", function()
    this.dragging = true
  end)
  minimapBtn:SetScript("OnDragStop", function()
    this.dragging = false
  end)
  minimapBtn:SetScript("OnUpdate", function()
    if not this.dragging then return end
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    cx, cy = cx / scale, cy / scale
    local angle = math.deg(math.atan2(cy - my, cx - mx))
    EasyLootDB.minimap_angle = angle
    MinimapButton_UpdatePosition(angle)
  end)

  minimapBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  minimapBtn:SetScript("OnClick", function()
    if EasyLootConfigFrame:IsShown() then
      EasyLootConfigFrame:Hide()
    else
      EasyLootConfigFrame:Show()
    end
  end)
  minimapBtn:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText("EasyLoot", 1, 0.82, 0)
    GameTooltip:AddLine("Click to toggle config.", 1, 1, 1)
    GameTooltip:AddLine("Drag to move.", 0.5, 0.5, 0.5)
    GameTooltip:Show()
  end)
  minimapBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

end