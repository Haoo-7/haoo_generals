-- Shared helpers for Lin Chengyuan (林承源).
local U = require "packages.utility.utility"

local L = {}

L.RONGKU_SUBSKILL_MARK = "haoo__rongku_subskill"
L.RONGKU_YANG_GENERAL = "haoo2__linchengyuan"
L.RONGKU_YIN_GENERAL = "haoo__linchengyuan"

--- Synchronize Lin Chengyuan's portrait with Rongku's current or target state.
---@param player ServerPlayer
---@param state? integer
function L.syncRongkuPortrait(player, state)
  local room = player.room
  if player.dead or not player:hasSkill("haoo__rongku", true) then
    return
  end

  local isYang = (state or player:getSwitchSkillState("haoo__rongku", false)) == fk.SwitchYang
  local targetGeneral = isYang and L.RONGKU_YANG_GENERAL or L.RONGKU_YIN_GENERAL
  local otherGeneral = isYang and L.RONGKU_YIN_GENERAL or L.RONGKU_YANG_GENERAL
  local targetData = Fk.generals[targetGeneral]
  if not targetData then
    return
  end

  if player.general == otherGeneral and
    table.contains(targetData:getSkillNameList(), "haoo__rongku") then
    player.general = targetGeneral
    room:broadcastProperty(player, "general")
  end
  if player.deputyGeneral == otherGeneral and
    table.contains(targetData:getSkillNameList(), "haoo__rongku") then
    player.deputyGeneral = targetGeneral
    room:broadcastProperty(player, "deputyGeneral")
  end
end

--- Synchronize both Rongku's sub-skills and Lin Chengyuan's portrait.
---@param player ServerPlayer
---@param state? integer
function L.syncRongkuForm(player, state)
  L.syncRongkuPortrait(player, state)
  L.syncRongkuSkills(player)
end

--- Synchronize the sub-skill granted by Rongku (Yang: gongxin; Yin: haoo__kongsheng).
---@param player ServerPlayer
function L.syncRongkuSkills(player)
  local room = player.room
  if player.dead or not player:hasSkill("haoo__rongku", true) then
    return
  end

  local isYang = player:getSwitchSkillState("haoo__rongku", false) == fk.SwitchYang
  local want = isYang and "gongxin" or "haoo__kongsheng"
  local drop = isYang and "haoo__kongsheng" or "gongxin"

  if player:getMark(L.RONGKU_SUBSKILL_MARK) == drop then
    room:handleAddLoseSkills(player, "-" .. drop, "haoo__rongku", false, true)
    room:setPlayerMark(player, L.RONGKU_SUBSKILL_MARK, 0)
  end

  if not player:hasSkill(want, true, true) then
    room:handleAddLoseSkills(player, want, "haoo__rongku", false, true)
    room:setPlayerMark(player, L.RONGKU_SUBSKILL_MARK, want)
  end
end

--- Force Rongku into Yang or Yin state and synchronize its portrait and granted sub-skill.
---@param player ServerPlayer
---@param targetState integer
function L.setRongkuState(player, targetState)
  if player.dead or not player:hasSkill("haoo__rongku", true) then
    return
  end
  U.SetSwitchSkillState(player, "haoo__rongku", targetState)
  L.syncRongkuForm(player, targetState)
end

--- Execute Zhiyu once (draw 1, reveal all hand cards, source discards 1 if same color).
---@param room Room
---@param player ServerPlayer
---@param from? ServerPlayer
function L.execZhiyuOnce(room, player, from)
  if player.dead then return end
  local skillName = Fk.skills["zhiyu"] and "zhiyu" or "haoo__fengchun"
  if skillName == "zhiyu" then
    room:notifySkillInvoked(player, "zhiyu", "masochism")
    player:broadcastSkillInvoke("zhiyu")
  end
  player:drawCards(1, skillName)
  if player.dead then return end
  local cards = player:getCardIds("h")
  if #cards > 0 then
    player:showCards(cards)
  end
  if from and not from.dead and not from:isKongcheng() and
    (#cards == 0 or table.every(cards, function(id)
      return Fk:getCardById(id).color == Fk:getCardById(cards[1]).color
    end)) then
    room:askToDiscard(from, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = skillName,
      cancelable = false,
    })
  end
end

--- Execute standard Kurou once (lose 1 HP, then draw 2 cards).
---@param room Room
---@param player ServerPlayer
function L.execKurouOnce(room, player)
  if player.dead then return end
  local skillName = Fk.skills["kurou"] and "kurou" or "haoo__fengchun"
  if skillName == "kurou" then
    room:notifySkillInvoked(player, "kurou", "drawcard")
    player:broadcastSkillInvoke("kurou")
  end
  room:loseHp(player, 1, skillName)
  if player:isAlive() then
    player:drawCards(2, skillName)
  end
end

return L
