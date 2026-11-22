local kongsheng = fk.CreateSkill {
  name = "haoo__kongsheng",
  expand_pile = "$haoo__kongsheng_harp",
}

Fk:loadTranslationTable {
  ["haoo__kongsheng"] = "箜声",
  [":haoo__kongsheng"] = "准备阶段，或你失去及回复体力后，你可以将当前回合角色任意张牌置于其武将牌上；" ..
    "其结束阶段，你可以使用其中一张牌，其获得其余的牌。",

  ["#haoo__kongsheng-invoke"] = "箜声：你可以将 %dest 的任意张牌置为“箜”",
  ["$haoo__kongsheng_harp"] = "箜",
  ["#haoo__kongsheng-use"] = "箜声：你可以使用“箜”中一张牌，%dest 获得其余的牌",
}

local OWNERS_MARK = "haoo__kongsheng_owners"

local spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local current = room.current
    if not current or current.dead or current:isNude() then return false end
    if room:askToSkillInvoke(player, {
      skill_name = kongsheng.name,
      prompt = "#haoo__kongsheng-invoke::" .. current.id,
    }) then
      event:setCostData(self, { tos = { current } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local current = room.current
    if not current or current.dead or current:isNude() then return end
    room:notifySkillInvoked(player, kongsheng.name, "control", { current })
    if Fk.skills["m_ex__kongsheng"] then
      player:broadcastSkillInvoke("m_ex__kongsheng")
    end
    local cards = room:askToChooseCards(player, {
      min = 1,
      max = #current:getCardIds("he"),
      target = current,
      flag = "he",
      skill_name = kongsheng.name,
    })
    if #cards == 0 then return end
    current:addToPile("$haoo__kongsheng_harp", cards, false, kongsheng.name, player)
    room:addTableMarkIfNeed(current, OWNERS_MARK, player.id)
  end,
}

kongsheng:addEffect(fk.EventPhaseStart, {
  mute = true,
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kongsheng.name) and
      player.phase == Player.Start and not player:isNude()
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

kongsheng:addEffect(fk.HpLost, {
  mute = true,
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kongsheng.name) and
      player.room.current and player.room.current:isAlive() and
      not player.room.current:isNude()
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

kongsheng:addEffect(fk.HpRecover, {
  mute = true,
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kongsheng.name) and
      player.room.current and player.room.current:isAlive() and
      not player.room.current:isNude()
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

-- Delayed resolution: even if Lin Chengyuan resets back to Yang (losing Kongsheng)
-- or dies, the harp cards placed on target can still be resolved at target's Finish phase.
kongsheng:addEffect(fk.EventPhaseStart, {
  global = true,
  is_delay_effect = true,
  mute = true,
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and target.phase == Player.Finish and
      #target:getPile("$haoo__kongsheng_harp") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = target.room
    local owners = target:getTableMark(OWNERS_MARK)
    room:setPlayerMark(target, OWNERS_MARK, 0)
    local lastOwner
    for _, pid in ipairs(owners) do
      local owner = room:getPlayerById(pid)
      if owner and not owner.dead and #target:getPile("$haoo__kongsheng_harp") > 0 then
        lastOwner = owner
        room:notifySkillInvoked(owner, kongsheng.name, "control", { target })
        if Fk.skills["m_ex__kongsheng"] then
          owner:broadcastSkillInvoke("m_ex__kongsheng")
        end
        room:askToUseRealCard(owner, {
          pattern = tostring(Exppattern { id = target:getPile("$haoo__kongsheng_harp") }),
          skill_name = kongsheng.name,
          prompt = "#haoo__kongsheng-use::" .. target.id,
          cancelable = true,
          expand_pile = target:getPile("$haoo__kongsheng_harp"),
        })
      end
    end
    if not target.dead and #target:getPile("$haoo__kongsheng_harp") > 0 then
      local visible = lastOwner and { lastOwner, target } or target
      room:obtainCard(target, target:getPile("$haoo__kongsheng_harp"), false, fk.ReasonJustMove,
        lastOwner, kongsheng.name, nil, visible)
    end
  end,
})

kongsheng:addTest(function(room, me)
  local comp2 = room.players[2]
  FkTest.RunAddSkills(me, kongsheng.name)

  -- Case 1: Start phase tucks cards onto own pile; Finish uses one (ex_nihilo) and regains rest.
  local exNihilo = room:printCard("ex_nihilo", Card.Heart, 7)
  local keepCard = room:printCard("jink", Card.Diamond, 3)
  FkTest.setNextReplies(me, {
    "1",
    { exNihilo.id, keepCard.id },
    { card = { skill = "userealcard_skill", subcards = { exNihilo.id } }, targets = {} },
  })
  FkTest.runInRoom(function()
    room:setCurrent(me)
    room:obtainCard(me, { exNihilo.id, keepCard.id })
    me.phase = Player.Start
    room.logic:trigger(fk.EventPhaseStart, me, PhaseData:new { who = me, phase = Player.Start })
  end)
  lu.assertEquals(#me:getPile("$haoo__kongsheng_harp"), 2)
  lu.assertEquals(me:getHandcardNum(), 0)

  FkTest.runInRoom(function()
    me.phase = Player.Finish
    room.logic:trigger(fk.EventPhaseStart, me, PhaseData:new { who = me, phase = Player.Finish })
  end)
  lu.assertEquals(#me:getPile("$haoo__kongsheng_harp"), 0)
  -- Used ex_nihilo (+2 draws) + recovered keepCard = 3 cards
  lu.assertEquals(me:getHandcardNum(), 3)
  lu.assertIsTrue(table.contains(me:getCardIds("h"), keepCard.id))

  -- Case 2: Card placed on comp2 via HpLost returns to comp2 at Finish even after me dies.
  local compCard = room:printCard("slash", Card.Spade, 8)
  FkTest.setNextReplies(me, { "1" })
  FkTest.runInRoom(function()
    room:setCurrent(comp2)
    room:throwCard(comp2:getCardIds("h"), nil, comp2, comp2)
    room:obtainCard(comp2, compCard)
    room:loseHp(me, 1, "test")
  end)
  lu.assertEquals(comp2:getPile("$haoo__kongsheng_harp"), { compCard.id })

  FkTest.runInRoom(function()
    room:killPlayer { who = me }
    comp2.phase = Player.Finish
    room.logic:trigger(fk.EventPhaseStart, comp2, PhaseData:new { who = comp2, phase = Player.Finish })
  end)
  lu.assertIsTrue(me.dead)
  lu.assertEquals(#comp2:getPile("$haoo__kongsheng_harp"), 0)
  lu.assertIsTrue(table.contains(comp2:getCardIds("h"), compCard.id))
end)

return kongsheng
