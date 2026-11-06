local xuanjian = fk.CreateSkill {
  name = "haoo__xuanjian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["haoo__xuanjian"] = "悬剑",
  [":haoo__xuanjian"] = "锁定技，摸牌阶段，你多摸一张牌。出牌阶段开始时，你交给任意名角色各一张牌，" ..
    "称为“谏”，若“谏”为装备牌，其使用之。回合结束时，每有一张“谏”不因弃置进入弃牌堆，" ..
    "你摸两张牌并令其回复1点体力；否则，其弃置“谏”并失去1点体力。每回合结束后，你弃置一张牌。",
  ["#haoo__xuanjian-give"] = "悬剑：请交给一名角色一张牌（称为“谏”）",
  ["#haoo__xuanjian-discard"] = "悬剑：每回合结束后，你须弃置一张牌",
  ["@haoo__jian"] = "谏",
}

local JIAN_MARK = "@haoo__jian" -- @开头=卡面可见标记，显示为“谏”
local GOT_MARK = "haoo__got_jian"

local function markJian(room, id)
  room:setCardMark(Fk:getCardById(id), JIAN_MARK, 1)
end

local function hasJianCard(room)
  for _, id in ipairs(room.discard_pile) do
    if Fk:getCardById(id):getMark(JIAN_MARK) == 1 then return true end
  end
  for _, p in ipairs(room.alive_players) do
    for _, id in ipairs(p:getCardIds("he")) do
      if Fk:getCardById(id):getMark(JIAN_MARK) == 1 then return true end
    end
  end
  return false
end

-- 查询一张牌最近一次进入弃牌堆的移动原因（仅本回合内），未找到返回 nil
local function lastDiscardEntry(room, id)
  local reason, from
  room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
    for _, move in ipairs(e.data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if info.cardId == id then
            reason = move.moveReason
            from = move.from
          end
        end
      end
    end
    return false
  end, Player.HistoryTurn)
  return reason, from
end

-- 查找本回合内最后使用/打出过这张牌的角色（使用结算进弃牌堆的移动没有 from 字段，只能从用牌事件找）
local function findLastUser(room, id)
  local user
  room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
    if e.data.card and table.contains(Card:getIdList(e.data.card), id) then
      user = e.data.from
    end
    return false
  end, Player.HistoryTurn)
  if not user then
    room.logic:getEventsOfScope(GameEvent.RespondCard, 1, function(e)
      if e.data.card and table.contains(Card:getIdList(e.data.card), id) then
        user = e.data.from
      end
      return false
    end, Player.HistoryTurn)
  end
  return user
end

-- 摸牌阶段，你多摸一张牌
xuanjian:addEffect(fk.DrawNCards, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xuanjian.name) and data.n > 0
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + 1
  end,
})

-- 出牌阶段开始时：交给任意名角色各一张牌
xuanjian:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xuanjian.name) and
      player.phase == Player.Play and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local chosenIds = {}
    local first = true
    while not player.dead and not player:isKongcheng() do
      local candidates = table.filter(room.alive_players, function(p)
        return not table.contains(chosenIds, p.id)
      end)
      if #candidates == 0 then break end
      local tos, cards = room:askToChooseCardsAndPlayers(player, {
        min_num = 1,
        max_num = 1,
        min_card_num = 1,
        max_card_num = 1,
        targets = candidates,
        pattern = tostring(Exppattern{ id = player:getHandlyIds() }),
        skill_name = xuanjian.name,
        prompt = "#haoo__xuanjian-give",
        cancelable = not first,
      })
      if #tos == 0 or #cards == 0 then break end
      first = false
      local to = tos[1]
      table.insert(chosenIds, to.id)
      room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, xuanjian.name, nil, false, player)
      for _, id in ipairs(cards) do
        markJian(room, id)
        -- “谏”为装备牌时，其立即使用之
        local card = Fk:getCardById(id)
        if card.type == Card.TypeEquip then
          room:useCard{
            from = to,
            tos = {},
            card = card,
          }
        end
      end
      room:setPlayerMark(to, GOT_MARK, 1)
    end
  end,
})

-- 回合结束时：结算“谏”；每回合结束后：你弃置一张牌
xuanjian:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    local ok = player:hasSkill(xuanjian.name) and not player.dead and
      (hasJianCard(player.room) or not player:isNude())
    return ok
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if hasJianCard(room) then
      -- 弃牌堆中的“谏”
      for _, id in ipairs(table.simpleClone(room.discard_pile)) do
        local card = Fk:getCardById(id)
        if card:getMark(JIAN_MARK) == 1 then
          local reason, from = lastDiscardEntry(room, id)
          if reason and reason ~= fk.ReasonDiscard then
            player:drawCards(2, xuanjian.name)
            local user = findLastUser(room, id) or from
            if user and not user.dead and user:isWounded() then
              room:recover{
                who = user,
                num = 1,
                recoverBy = player,
                skillName = xuanjian.name,
              }
            end
          end
          room:setCardMark(card, JIAN_MARK, 0)
        end
      end
      -- 装备区中的“谏”：已使用（其装备了它）→ 你摸两张牌并令其回复1点体力，牌留在装备区
      for _, p in ipairs(room.alive_players) do
        for _, id in ipairs(p:getCardIds("e")) do
          local card = Fk:getCardById(id)
          if card:getMark(JIAN_MARK) == 1 then
            player:drawCards(2, xuanjian.name)
            if not p.dead and p:isWounded() then
              room:recover{
                who = p,
                num = 1,
                recoverBy = player,
                skillName = xuanjian.name,
              }
            end
            room:setCardMark(card, JIAN_MARK, 0)
          end
        end
      end
      -- 手牌区中的“谏”：未使用 → 其弃置“谏”并失去1点体力
      local holders = {}
      for _, p in ipairs(room.alive_players) do
        for _, id in ipairs(p:getCardIds("h")) do
          if Fk:getCardById(id):getMark(JIAN_MARK) == 1 then
            table.insert(holders, { p = p, id = id })
          end
        end
      end
      for _, h in ipairs(holders) do
        local card = Fk:getCardById(h.id)
        if card:getMark(JIAN_MARK) == 1 then
          if not h.p.dead then
            room:throwCard(h.id, xuanjian.name, h.p, h.p)
            room:loseHp(h.p, 1, xuanjian.name)
          end
          room:setCardMark(card, JIAN_MARK, 0)
        end
      end
    end
    if not player.dead and not player:isNude() then
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = xuanjian.name,
        prompt = "#haoo__xuanjian-discard",
        cancelable = false,
      })
    end
  end,
})

return xuanjian
