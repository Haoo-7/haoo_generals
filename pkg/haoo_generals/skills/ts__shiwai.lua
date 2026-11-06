local shiwai = fk.CreateSkill {
  name = "ts__shiwai",
  tags = { Skill.Compulsory },
}

local shiwai_analeptic_mark = shiwai.name .. "-manjuan-inarea"

Fk:loadTranslationTable {
  ["ts__shiwai"] = "醉林",
  [":ts__shiwai"] = "锁定技，若你的手牌区已废除，你可以使用牌堆中的【酒】；若你的判定区已废除，你不能使用花色不为♣️的锦囊牌。",
  ["#ts__shiwai"] = "醉林：使用牌堆中的【酒】",
}

local function isManjuanAnalepticProhibited(player, card)
  if not card or player.drank <= 0 or not player:hasSkill("js__manjuan", true) or
      card.trueName ~= "analeptic" then
    return false
  end

  local room = Fk:currentRoom()
  if card:isVirtual() then
    return #card.subcards > 0 and table.every(card.subcards, function(id)
      return room:getCardArea(id) == Card.DiscardPile
    end)
  end
  return room:getCardArea(card.id) == Card.DiscardPile
end

-- 判定区已废除：不能使用非梅花锦囊
shiwai:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if not card then return false end
    if isManjuanAnalepticProhibited(player, card) then
      return true
    end
    return player:hasSkill(shiwai.name) and player:isJudgeAreaSealed() and
      card.type == Card.TypeTrick and card.suit ~= Card.Club
  end,
  prohibit_response = function(self, player, card)
    return isManjuanAnalepticProhibited(player, card)
  end,
})

local function findTopAnaleptic(room)
  for _, cardId in ipairs(room.draw_pile) do
    local card = Fk:getCardById(cardId, true)
    if card and card.trueName == "analeptic" then
      return cardId
    end
  end
end

local function canUseShiwai(player)
  return player and player:isHandAreaSealed() and player.drank == 0
end

local function applyShiwai(room, player, analepticRecover)
  if not player then
    return false
  end
  if player.drank > 0 then
    return false
  end
  if not player:isHandAreaSealed() then
    return false
  end

  local id = findTopAnaleptic(room)
  if not id then return false end

  -- 手牌区已废除，牌无法留在手牌区。这里显式置入弃牌堆。
  room:moveCardTo(id, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, shiwai.name, nil, true, player,
    { shiwai_analeptic_mark, { Card.DiscardPile } })
  if analepticRecover then
    -- 按官方濒死用酒流程交给酒牌技能处理回复，而不是增加 drank。
    local analeptic = Fk:cloneCard("analeptic")
    analeptic.skillName = shiwai.name
    room:useCard {
      from = player,
      tos = { player },
      card = analeptic,
      extra_data = {
        analepticRecover = true,
        must_targets = { player.id },
        fix_targets = { player.id },
      },
    }
  else
    player.drank = player.drank + 1
    room:broadcastProperty(player, "drank")
  end
  room:notifySkillInvoked(player, shiwai.name, "support")
  return true
end

-- 濒死时可以手动发动世外自救。
shiwai:addEffect(fk.AskForPeaches, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and data.who == player and player:hasSkill(shiwai.name)
      and canUseShiwai(player)
      and findTopAnaleptic(player.room) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local invoked = player.room:askToUseActiveSkill(player, {
      skill_name = shiwai.name,
      prompt = "#ts__shiwai",
      cancelable = true,
      skip = true,
    })
    if invoked then
      event:setCostData(self, true)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    applyShiwai(player.room, player, true)
  end,
})

-- 出牌阶段仍可主动再发动（零输入主动技）。
shiwai:addEffect("active", {
  anim_type = "support",
  prompt = "#ts__shiwai",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:hasSkill(shiwai.name) and canUseShiwai(player)
  end,
  on_use = function(self, room, effect)
    applyShiwai(room, effect.from)
  end,
})

shiwai:addTest(function(room, me)
  local active
  local askForPeaches
  for _, effect in ipairs(shiwai.effect_spec_list) do
    if effect[1] == "active" then
      active = effect[3]
    elseif effect[1] == fk.AskForPeaches then
      askForPeaches = effect[3]
    end
  end
  lu.assertNotNil(active)
  lu.assertNotNil(askForPeaches)
  FkTest.RunAddSkills(me, shiwai.name)
  lu.assertFalse(active.can_use(active, me))

  local analepticId
  local existingAnalepticId
  FkTest.runInRoom(function()
    room:abortPlayerArea(me, Player.HandSlot)
    for _, cardId in ipairs(room.draw_pile) do
      local card = Fk:getCardById(cardId, true)
      if card and card.trueName == "analeptic" then
        if not analepticId then
          analepticId = cardId
        else
          existingAnalepticId = cardId
          break
        end
      end
    end
    if existingAnalepticId then
      room:moveCardTo(existingAnalepticId, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile,
        shiwai.name, nil, true, me)
    end
  end)
  lu.assertTrue(active.can_use(active, me))
  lu.assertNotNil(analepticId)
  lu.assertNotNil(existingAnalepticId)

  local drawPileCount = #room.draw_pile
  local discardPileCount = #room.discard_pile
  FkTest.runInRoom(function()
    active.on_use(active, room, { from = me })
  end)

  lu.assertEquals(#room.draw_pile, drawPileCount - 1)
  lu.assertEquals(#room.discard_pile, discardPileCount + 1)
  lu.assertEquals(room:getCardArea(analepticId), Card.DiscardPile)
  lu.assertEquals(me.drank, 1)

  FkTest.RunAddSkills(me, "js__manjuan")
  local markedAnaleptic = Fk:getCardById(analepticId, true)
  local existingAnaleptic = Fk:getCardById(existingAnalepticId, true)
  lu.assertNotEquals(markedAnaleptic:getMark(shiwai_analeptic_mark), 0)
  lu.assertTrue(me:prohibitUse(markedAnaleptic))
  lu.assertTrue(me:prohibitResponse(markedAnaleptic))
  lu.assertTrue(me:prohibitUse(existingAnaleptic))
  lu.assertTrue(me:prohibitResponse(existingAnaleptic))

  local drawPileAnaleptic
  for _, cardId in ipairs(room.draw_pile) do
    local card = Fk:getCardById(cardId, true)
    if card and card.trueName == "analeptic" then
      drawPileAnaleptic = card
      break
    end
  end
  lu.assertNotNil(drawPileAnaleptic)
  lu.assertFalse(me:prohibitUse(drawPileAnaleptic))
  lu.assertFalse(me:prohibitResponse(drawPileAnaleptic))

  me.drank = 0
  room:broadcastProperty(me, "drank")
  lu.assertFalse(me:prohibitUse(markedAnaleptic))
  lu.assertFalse(me:prohibitResponse(markedAnaleptic))
  lu.assertFalse(me:prohibitUse(existingAnaleptic))
  lu.assertFalse(me:prohibitResponse(existingAnaleptic))
  me.drank = 1
  room:broadcastProperty(me, "drank")

  FkTest.runInRoom(function()
    room:moveCardTo(analepticId, Card.Processing, nil, fk.ReasonJustMove, shiwai.name, nil, true, me)
  end)
  lu.assertEquals(room:getCardArea(analepticId), Card.Processing)
  lu.assertEquals(markedAnaleptic:getMark(shiwai_analeptic_mark), 0)
  lu.assertFalse(me:prohibitUse(markedAnaleptic))
  lu.assertFalse(me:prohibitResponse(markedAnaleptic))

  -- 已有酒的伤害加成时，主动技不可用。
  lu.assertFalse(active.can_use(active, me))

  -- 服务端执行和濒死入口也必须拒绝重复饮酒。
  local discardPileCountWithDrank = #room.discard_pile
  FkTest.runInRoom(function()
    lu.assertFalse(applyShiwai(room, me, false))
  end)
  lu.assertEquals(me.drank, 1)
  lu.assertEquals(#room.discard_pile, discardPileCountWithDrank)
  lu.assertFalse(askForPeaches.can_trigger(askForPeaches, fk.AskForPeaches, me, me, { who = me }))

  -- 濒死分支使用官方 analepticRecover 路径，只回复1点且不增加 drank。
  me.drank = 0
  room:broadcastProperty(me, "drank")
  lu.assertTrue(active.can_use(active, me))
  local recoverId = findTopAnaleptic(room)
  lu.assertNotNil(recoverId)
  local hp = me.hp
  FkTest.runInRoom(function()
    room:loseHp(me, 1)
    lu.assertTrue(applyShiwai(room, me, true))
  end)
  lu.assertEquals(me.hp, hp - 1 + 1)
  lu.assertEquals(me.drank, 0)
  lu.assertEquals(room:getCardArea(recoverId), Card.DiscardPile)
  lu.assertNotEquals(Fk:getCardById(recoverId, true):getMark(shiwai_analeptic_mark), 0)

  -- 世外不再包含出牌阶段开始的自动触发。
  for _, effect in ipairs(shiwai.effect_spec_list) do
    lu.assertNotEquals(effect[1], fk.EventPhaseStart)
  end
end)

return shiwai
