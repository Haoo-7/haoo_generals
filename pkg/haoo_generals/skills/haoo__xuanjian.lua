local xuanjian = fk.CreateSkill {
  name = "haoo__xuanjian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["haoo__xuanjian"] = "悬剑",
  [":haoo__xuanjian"] = "锁定技，摸牌阶段，你多摸一张牌。出牌阶段开始时，交给任意名其他角色各一张牌（称为“谏”），" ..
    "其使用其中的装备牌。得到“谏”的角色回合结束时，若“谏”不因弃置进入弃牌堆，你可摸两张牌并令其回复1点体力。" ..
    "否则，其弃置“谏”并失去1点体力。每回合结束时，你弃置一张牌。",
  ["#haoo__xuanjian-give"] = "悬剑：请交给其他角色一张牌（称为“谏”）",
  ["#haoo__xuanjian-discard"] = "悬剑：每回合结束时，你须弃置一张牌",
  ["#haoo__xuanjian-reward"] = "悬剑：是否摸两张牌并令其回复1点体力？",
  ["@haoo__jian"] = "谏",
}

local JIAN_MARK = "@haoo__jian" -- @开头=卡面可见标记，显示为“谏”
local TO_MARK = "haoo__jian_to" -- 无@=隐藏标记，值为得到“谏”的角色的 id
local DISCARD_MARK = "haoo__jian_discarded" -- 无@=隐藏标记，“谏”进入弃牌堆时记录是否因弃置（1=因弃置）
local GOT_MARK = "haoo__got_jian" -- 无@=隐藏玩家标记，“得到过谏”，供矢节查询

local function markJian(room, id, toId)
  local card = Fk:getCardById(id)
  room:setCardMark(card, JIAN_MARK, 1)
  room:setCardMark(card, TO_MARK, toId)
end

local function clearJian(room, id)
  local card = Fk:getCardById(id)
  room:setCardMark(card, JIAN_MARK, 0)
  room:setCardMark(card, TO_MARK, 0)
  room:setCardMark(card, DISCARD_MARK, 0)
end

-- 找出得到者为 receiverId 的所有未结算“谏”（弃牌堆 + 所有角色的手牌/装备/判定区）
local function findJianCards(room, receiverId)
  local found = {}
  local function checkId(id)
    local card = Fk:getCardById(id)
    if card:getMark(JIAN_MARK) > 0 and card:getMark(TO_MARK) == receiverId then
      table.insert(found, id)
    end
  end
  for _, id in ipairs(table.simpleClone(room.discard_pile)) do
    checkId(id)
  end
  for _, p in ipairs(room.alive_players) do
    for _, id in ipairs(p:getCardIds("hej")) do
      checkId(id)
    end
  end
  return found
end

-- 判定一张“谏”在得到者回合结束时的结算分支：
-- "reward" 已使用/打出进入弃牌堆，或装备/判定区中；"discard_penalty" 因弃置进入弃牌堆；
-- "hand_penalty" 仍在得到者手里；nil 在其他角色手里或牌堆中，暂不结算
local function judgeJian(room, id, receiver)
  if table.contains(room.discard_pile, id) then
    if Fk:getCardById(id):getMark(DISCARD_MARK) == 1 then
      return "discard_penalty"
    end
    return "reward"
  end
  for _, p in ipairs(room.alive_players) do
    if table.contains(p:getCardIds("e"), id) or table.contains(p:getCardIds("j"), id) then
      return "reward"
    end
    if p.id == receiver.id and table.contains(p:getCardIds("h"), id) then
      return "hand_penalty"
    end
  end
  return nil
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

-- 记录“谏”进入弃牌堆是否因弃置（使用/打出进入弃牌堆不算弃置）
xuanjian:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(xuanjian.name) then return false end
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId):getMark(JIAN_MARK) > 0 then
            return true
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if card:getMark(JIAN_MARK) > 0 then
            room:setCardMark(card, DISCARD_MARK, move.moveReason == fk.ReasonDiscard and 1 or 0)
          end
        end
      end
    end
  end,
})

-- 出牌阶段开始时：交给任意名其他角色各一张牌
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
        return p ~= player and not table.contains(chosenIds, p.id)
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
        markJian(room, id, to.id)
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

-- 得到“谏”的角色回合结束时：结算其名下的“谏”
xuanjian:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    if not target or target.dead then return false end
    if not player:hasSkill(xuanjian.name) or player.dead then return false end
    return #findJianCards(player.room, target.id) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(findJianCards(room, target.id)) do
      if target.dead then break end
      local verdict = judgeJian(room, id, target)
      if verdict == "reward" then
        if room:askToSkillInvoke(player, {
          skill_name = xuanjian.name,
          prompt = "#haoo__xuanjian-reward",
        }) then
          player:drawCards(2, xuanjian.name)
          if not target.dead and target:isWounded() then
            room:recover{
              who = target,
              num = 1,
              recoverBy = player,
              skillName = xuanjian.name,
            }
          end
        end
        clearJian(room, id)
      elseif verdict == "discard_penalty" then
        room:loseHp(target, 1, xuanjian.name)
        clearJian(room, id)
      elseif verdict == "hand_penalty" then
        room:throwCard(id, xuanjian.name, target, target)
        room:loseHp(target, 1, xuanjian.name)
        clearJian(room, id)
      end
    end
  end,
})

-- 每回合结束时：你弃置一张牌
xuanjian:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xuanjian.name) and not player.dead and not player:isNude()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = xuanjian.name,
      prompt = "#haoo__xuanjian-discard",
      cancelable = false,
    })
  end,
})

return xuanjian
