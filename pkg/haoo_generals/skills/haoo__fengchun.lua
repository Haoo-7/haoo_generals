local L = require "packages.haoo_generals.linchengyuan"

local fengchun = fk.CreateSkill {
  name = "haoo__fengchun",
  related_skills = { "zhiyu", "kurou" },
}

Fk:loadTranslationTable {
  ["haoo__fengchun"] = "逢春",
  [":haoo__fengchun"] = "当你受到伤害后，你可以视为对伤害来源使用一张【推心置腹】，然后展示获得的牌：" ..
    "若其中有<font color='red'>♥</font>牌，你回复1点体力，然后重置〖荣枯〗；" ..
    "否则你〖智愚〗，然后切换〖荣枯〗为阴形态并〖苦肉〗。",

  ["#haoo__fengchun-invoke"] = "逢春：你可以视为对 %dest 使用一张【推心置腹】（无距离限制）",
}

-- Record cards obtained from the target by sincere_treat before the give-back step runs.
fengchun:addEffect(fk.AfterCardsMove, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
    if not e or not e.data.extra_data or e.data.extra_data.haoo__fengchun_user ~= player.id then
      return false
    end
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerHand and move.skillName == "sincere_treat_skill" then
        return true
      end
    end
    return false
  end,
  on_refresh = function(self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
    if not e then return end
    local tag = e.data.extra_data.haoo__fengchun_tag
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerHand and move.skillName == "sincere_treat_skill" then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(tag.obtained, info.cardId)
        end
      end
    end
  end,
})

fengchun:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(fengchun.name) then return false end
    local from = data.from
    if not from or from == player or from.dead or from:isAllNude() then return false end
    local card = Fk:cloneCard("sincere_treat")
    card.skillName = fengchun.name
    return not player:prohibitUse(card) and not player:isProhibited(from, card)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = fengchun.name,
      prompt = "#haoo__fengchun-invoke::" .. data.from.id,
    }) then
      event:setCostData(self, { tos = { data.from } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = data.from
    if not from or from.dead or from:isAllNude() then return end

    local tag = { obtained = {} }
    local use = room:useVirtualCard("sincere_treat", nil, player, from, fengchun.name, true, {
      haoo__fengchun_user = player.id,
      haoo__fengchun_tag = tag,
    })

    if player.dead or not use then
      return
    end

    -- Reveal obtained cards after obtaining and giving back complete.
    -- If nullified (e.g. Nullification), 0 cards were obtained, so no Heart was obtained -> triggers Zhiyu/Yin/Kurou.
    if #tag.obtained > 0 then
      player:showCards(tag.obtained)
    end

    local hasHeart = table.find(tag.obtained, function(id)
      return Fk:getCardById(id).suit == Card.Heart
    end) ~= nil

    if hasHeart then
      if player:isWounded() then
        room:recover {
          who = player,
          num = 1,
          recoverBy = player,
          skillName = fengchun.name,
        }
      end
      if not player.dead and player:hasSkill("haoo__rongku", true) then
        L.setRongkuState(player, fk.SwitchYang)
      end
    else
      L.execZhiyuOnce(room, player, from)
      if not player.dead and player:hasSkill("haoo__rongku", true) then
        L.setRongkuState(player, fk.SwitchYin)
      end
      if not player.dead then
        room:delay(400)
        L.execKurouOnce(room, player)
      end
    end
  end,
})

fengchun:addTest(function(room, me)
  local comp2 = room.players[2]
  FkTest.RunAddSkills(me, "haoo__rongku|" .. fengchun.name)

  -- 1) Nullification negates sincere_treat: no cards obtained -> still has no Heart ->
  -- triggers Zhiyu (draw 1, reveal all hand cards, source discards 1) -> Rongku Yin -> Kurou!
  local compBlack = room:printCard("slash", Card.Spade, 7)
  local nullCard = room:printCard("nullification", Card.Club, 12)
  FkTest.setNextReplies(me, { "1" })
  FkTest.setNextReplies(comp2, { { card = nullCard.id } })
  FkTest.runInRoom(function()
    room:setCurrent(comp2)
    room:obtainCard(comp2, { compBlack.id, nullCard.id })
    room:damage { from = comp2, to = me, damage = 1 }
  end)
  lu.assertEquals(me.hp, 2) -- 4 - 1(dmg) - 1(kurou) = 2
  lu.assertEquals(me:getSwitchSkillState("haoo__rongku", false), fk.SwitchYin)
  lu.assertIsTrue(me:hasSkill("haoo__kongsheng", true))
  lu.assertEquals(me:getHandcardNum(), 3) -- 1(zhiyu) + 2(kurou)
  lu.assertTrue(comp2:isKongcheng()) -- forced discard from Zhiyu single-color hand

  -- 2) No Heart obtained: reveal obtained card -> Zhiyu -> Rongku becomes Yin (+haoo__kongsheng)
  -- -> Kurou (-1 HP, +2 draw) -> HpLost triggers haoo__kongsheng on comp2's returned card!
  local meReturnBlack = room:printCard("jink", Card.Club, 5)
  local zhiyuRed = room:printCard("slash", Card.Diamond, 9)
  local kurouDraw1 = room:printCard("slash", Card.Spade, 10)
  local kurouDraw2 = room:printCard("jink", Card.Club, 11)
  FkTest.setNextReplies(me, {
    "1", -- invoke haoo__fengchun
    { card = { skill = "choose_cards_skill", subcards = { meReturnBlack.id } }, targets = {} }, -- give back
    "1", -- invoke haoo__kongsheng on HpLost
  })
  FkTest.runInRoom(function()
    me.hp = 3
    L.setRongkuState(me, fk.SwitchYang)
    room:setCurrent(comp2)
    room:throwCard(comp2:getCardIds("h"), nil, comp2, comp2)
    room:throwCard(me:getCardIds("h"), nil, me, me)
    -- Stack draw pile top-to-bottom cleanly (first pushed to top ends up deepest):
    room:moveCardTo(kurouDraw2, Card.DrawPile)
    room:moveCardTo(kurouDraw1, Card.DrawPile)
    room:moveCardTo(zhiyuRed, Card.DrawPile)
    room:obtainCard(comp2, compBlack) -- 1 card -> sincere_treat auto-picks compBlack
    room:obtainCard(me, meReturnBlack)
    room:damage { from = comp2, to = me, damage = 1 }
  end)
  lu.assertEquals(me:getSwitchSkillState("haoo__rongku", false), fk.SwitchYin)
  lu.assertIsFalse(me:hasSkill("gongxin", true))
  lu.assertIsTrue(me:hasSkill("haoo__kongsheng", true))
  -- 3 - 1(dmg) - 1(kurou) = 1 HP; hand has compBlack + zhiyuRed + kurouDraw1 + kurouDraw2 = 4 cards.
  lu.assertEquals(me.hp, 1)
  lu.assertEquals(me:getHandcardNum(), 4)
  -- comp2's returned card was tucked onto "$haoo__kongsheng_harp" by HpLost trigger!
  lu.assertEquals(#comp2:getPile("$haoo__kongsheng_harp"), 1)
  -- Clean comp2's pile before test 3
  FkTest.runInRoom(function()
    room:moveCardTo(table.simpleClone(comp2:getPile("$haoo__kongsheng_harp")), Card.DiscardPile, nil, fk.ReasonJustMove)
    room:setPlayerMark(comp2, "haoo__kongsheng_owners", 0)
  end)

  -- 3) In Yin state and Heart obtained:
  -- Recover 1 HP triggers haoo__kongsheng BEFORE resetting Rongku to Yang!
  -- And after resetting to Yang (losing Kongsheng), comp2's Finish phase still resolves the delayed effect.
  local compHeart = room:printCard("peach", Card.Heart, 6)
  local meReturnCard = room:printCard("jink", Card.Spade, 4)
  FkTest.setNextReplies(me, {
    "1", -- invoke haoo__fengchun
    { card = { skill = "choose_cards_skill", subcards = { meReturnCard.id } }, targets = {} }, -- give back
    "1", -- invoke haoo__kongsheng on HpRecover BEFORE resetting to Yang!
  })
  FkTest.runInRoom(function()
    me.hp = 3
    room:setCurrent(comp2)
    room:throwCard(comp2:getCardIds("h"), nil, comp2, comp2)
    room:throwCard(me:getCardIds("h"), nil, me, me)
    room:obtainCard(comp2, compHeart) -- 1 card -> auto-picked
    room:obtainCard(me, meReturnCard)
    room:damage { from = comp2, to = me, damage = 1 }
  end)
  lu.assertEquals(me.hp, 3) -- 3 - 1(dmg) + 1(recover) = 3
  lu.assertEquals(me:getSwitchSkillState("haoo__rongku", false), fk.SwitchYang)
  lu.assertIsTrue(me:hasSkill("gongxin", true))
  lu.assertIsFalse(me:hasSkill("haoo__kongsheng", true))
  -- Verify HpRecover DID trigger haoo__kongsheng right before reset and held the card in pile!
  lu.assertEquals(comp2:getPile("$haoo__kongsheng_harp"), { meReturnCard.id })

  -- Simulate comp2 Finish phase even though me is now back in Yang without haoo__kongsheng:
  FkTest.setNextReplies(me, { "" }) -- decline using the card from harp pile
  FkTest.runInRoom(function()
    comp2.phase = Player.Finish
    room.logic:trigger(fk.EventPhaseStart, comp2, PhaseData:new { who = comp2, phase = Player.Finish })
  end)
  lu.assertEquals(#comp2:getPile("$haoo__kongsheng_harp"), 0)
  lu.assertIsTrue(table.contains(comp2:getCardIds("h"), meReturnCard.id))
end)

return fengchun
