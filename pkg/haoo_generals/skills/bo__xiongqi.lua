local xiongqi = fk.CreateSkill {
  name = "bo__xiongqi",
}

Fk:loadTranslationTable {
  ["bo__xiongqi"] = "雄起",
  [":bo__xiongqi"] = "出牌阶段限一次，你可以废除所有装备栏，并将所有手牌作为一张【南蛮入侵】使用，" ..
    "然后你摸等同于你本次废除的装备栏的数量的牌。" ..
    "当全场被“雄乱”的角色数不小于全场数量的一半（向下取整），你获得“咆哮”“奔袭”直到回合结束。" ..
    "弃牌阶段，本回合未被“雄乱”的角色获得“诛害”直到回合结束。" ..
    "回合结束后，你恢复X个装备栏（X为你本回合造成的伤害数）。",
  ["#bo__xiongqi"] = "雄起：废除所有装备栏，将所有手牌当【南蛮入侵】使用",
  ["#bo__xiongqi-restore"] = "雄起：请选择要恢复的装备栏",
}

local USED_MARK = "bo__xq_used"
local GRANTED_MARK = "bo__xq_granted_" -- 后接技能名，记录哪些技能是本回合临时获得
local LUAN_MARK = "@@xiongluan-turn" -- 与张绣【雄乱】共用的标记，回合结束自动清除

-- 雄乱人数达标即授予咆哮、奔袭：雄起结算后调用一次，此后每挂上一个雄乱也会调用
local function evaluate(player)
  local room = player.room
  if player.dead or room:getCurrent() ~= player then return end
  if player:getMark(USED_MARK) == 0 then return end

  local marked = #table.filter(room.alive_players, function(p)
    return p:getMark(LUAN_MARK) > 0
  end)
  if marked < math.floor(#room.alive_players / 2) then return end

  local granted = {}
  for _, name in ipairs({ "paoxiao", "benxi" }) do
    if not player:hasSkill(name) and player:getMark(GRANTED_MARK .. name) == 0 then
      table.insert(granted, name)
    end
  end
  if #granted == 0 then return end

  room:handleAddLoseSkills(player, table.concat(granted, "|"), xiongqi.name)
  for _, name in ipairs(granted) do
    room:setPlayerMark(player, GRANTED_MARK .. name, 1)
  end
end

-- 供【雄辩】在挂上雄乱后调用
HaooGenerals_XiongqiEvaluate = evaluate

xiongqi:addEffect("active", {
  anim_type = "offensive",
  prompt = "#bo__xiongqi",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:usedSkillTimes(xiongqi.name, Player.HistoryPhase) == 0 and
      #player:getCardIds("h") > 0 and #Fk:currentRoom().alive_players > 1
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local slots = player:getAvailableEquipSlots()
    if #slots > 0 then
      room:abortPlayerArea(player, slots)
    end
    room:setPlayerMark(player, USED_MARK, 1)

    local cards = player:getCardIds("h")
    local targets = table.filter(room.alive_players, function(p)
      return p ~= player
    end)
    if #cards > 0 and #targets > 0 then
      room:useVirtualCard("savage_assault", cards, player, targets, xiongqi.name)
    end
    if player.dead then return end

    if #slots > 0 then
      player:drawCards(#slots, xiongqi.name)
    end

    evaluate(player)
  end,
})

-- 弃牌阶段：本回合未被雄乱的角色获得【诛害】直到回合结束
xiongqi:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiongqi.name) and not player.dead and
      player.phase == Player.Discard and player:getMark(USED_MARK) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p ~= player and p:getMark(LUAN_MARK) == 0 and not p:hasSkill("zhuhai") then
        room:handleAddLoseSkills(p, "zhuhai", xiongqi.name)
        room:setPlayerMark(p, GRANTED_MARK .. "zhuhai", 1)
      end
    end
  end,
})

xiongqi:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiongqi.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local used = player:getMark(USED_MARK) > 0

    for _, p in ipairs(room.players) do
      if p:getMark(GRANTED_MARK .. "zhuhai") > 0 then
        room:handleAddLoseSkills(p, "-zhuhai", xiongqi.name, false, true)
        room:setPlayerMark(p, GRANTED_MARK .. "zhuhai", 0)
      end
    end
    for _, name in ipairs({ "paoxiao", "benxi" }) do
      if player:getMark(GRANTED_MARK .. name) > 0 then
        room:handleAddLoseSkills(player, "-" .. name, xiongqi.name, false, true)
        room:setPlayerMark(player, GRANTED_MARK .. name, 0)
      end
    end
    room:setPlayerMark(player, USED_MARK, 0)

    if not used or player.dead then return end

    local sealedEquip = table.filter(player.sealedSlots, function(slot)
      return table.contains(player.equipSlots, slot)
    end)
    if #sealedEquip == 0 then return end

    local damage = 0
    local events = room.logic:getActualDamageEvents(999, function(e)
      return e.data.from == player
    end, Player.HistoryTurn)
    for _, e in ipairs(events) do
      damage = damage + (e.data.damage or 0)
    end
    damage = math.min(damage, #sealedEquip)
    if damage == 0 then return end

    if damage >= #sealedEquip then
      room:resumePlayerArea(player, sealedEquip)
      return
    end

    local remaining = table.simpleClone(sealedEquip)
    local toResume = {}
    for _ = 1, damage do
      if #remaining == 0 then break end
      local slot = room:askToChoice(player, {
        choices = remaining,
        skill_name = xiongqi.name,
        prompt = "#bo__xiongqi-restore",
      })
      table.removeOne(remaining, slot)
      table.insert(toResume, slot)
    end
    if #toResume > 0 then
      room:resumePlayerArea(player, toResume)
    end
  end,
})

return xiongqi
