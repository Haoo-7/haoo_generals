local L = require "packages.haoo_generals.linchengyuan"

local rongku = fk.CreateSkill {
  name = "haoo__rongku",
  tags = { Skill.Switch },
  related_skills = { "gongxin", "haoo__kongsheng" },
}

Fk:loadTranslationTable {
  ["haoo__rongku"] = "荣枯",
  [":haoo__rongku"] = "转换技，阳：你拥有〖攻心〗，你的【杀】不可被响应；" ..
    "阴：你拥有〖箜声〗，你不能响应【杀】。",
  [":haoo__rongku_yang"] = "转换技，<font color=\"#E0DB2F\">阳：你拥有〖攻心〗，你的【杀】不可被响应；</font>" ..
    "阴：你拥有〖箜声〗，你不能响应【杀】。",
  [":haoo__rongku_yin"] = "转换技，阳：你拥有〖攻心〗，你的【杀】不可被响应；" ..
    "<font color=\"#E0DB2F\">阴：你拥有〖箜声〗，你不能响应【杀】。</font>",
}

rongku:addAcquireEffect(function(self, player)
  L.syncRongkuSkills(player)
end)

rongku:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, L.RONGKU_SUBSKILL_MARK, 0)
end)

-- Yang: your Slash cannot be responded to.
-- Use refresh hooks so passive Slash usage never auto-flips the Switch skill state.
rongku:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(rongku.name) and
      data.card.trueName == "slash" and
      player:getSwitchSkillState(rongku.name, false) == fk.SwitchYang
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(data.disresponsiveList, p)
    end
  end,
})

-- Yin: you cannot respond to Slash.
rongku:addEffect(fk.TargetConfirmed, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(rongku.name) and
      data.card.trueName == "slash" and
      player:getSwitchSkillState(rongku.name, false) == fk.SwitchYin
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsive = true
  end,
})

rongku:addEffect(fk.GameStart, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(rongku.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    L.syncRongkuForm(player)
  end,
})

rongku:addTest(function(room, me)
  local comp2 = room.players[2]
  lu.assertIsTrue(Fk.generals["haoo2__linchengyuan"].total_hidden)
  FkTest.runInRoom(function()
    me.general = "haoo__linchengyuan"
    room:broadcastProperty(me, "general")
  end)
  FkTest.RunAddSkills(me, rongku.name)
  lu.assertEquals(me.general, "haoo__linchengyuan")
  FkTest.runInRoom(function()
    room.logic:trigger(fk.GameStart, me, nil)
  end)
  lu.assertEquals(me:getSwitchSkillState(rongku.name, false), fk.SwitchYang)
  lu.assertEquals(me.general, "haoo2__linchengyuan")
  lu.assertIsTrue(me:hasSkill("gongxin", true))
  lu.assertIsFalse(me:hasSkill("haoo__kongsheng", true))

  -- Yang: me's Slash cannot be responded by Jink.
  local compJink = room:printCard("jink", Card.Diamond, 2)
  FkTest.setNextReplies(comp2, { { card = compJink.id } })
  FkTest.runInRoom(function()
    room:obtainCard(comp2, compJink)
    room:useVirtualCard("slash", nil, me, comp2, nil, true)
  end)
  lu.assertEquals(comp2.hp, 3)
  lu.assertEquals(room:getCardArea(compJink.id), Card.PlayerHand)

  -- Switch to Yin: swaps gongxin -> haoo__kongsheng and restores Yin portrait; me cannot respond to Slash.
  local myJink = room:printCard("jink", Card.Club, 2)
  FkTest.setNextReplies(me, { { card = myJink.id } })
  FkTest.runInRoom(function()
    L.setRongkuState(me, fk.SwitchYin)
    room:obtainCard(me, myJink)
    room:useVirtualCard("slash", nil, comp2, me, nil, true)
  end)
  lu.assertEquals(me:getSwitchSkillState(rongku.name, false), fk.SwitchYin)
  lu.assertEquals(me.general, "haoo__linchengyuan")
  lu.assertIsFalse(me:hasSkill("gongxin", true))
  lu.assertIsTrue(me:hasSkill("haoo__kongsheng", true))
  lu.assertEquals(me.hp, 3)
  lu.assertEquals(room:getCardArea(myJink.id), Card.PlayerHand)

  -- Reset back to Yang: swaps haoo__kongsheng -> gongxin and restores Yang portrait.
  FkTest.runInRoom(function()
    L.setRongkuState(me, fk.SwitchYang)
  end)
  lu.assertEquals(me:getSwitchSkillState(rongku.name, false), fk.SwitchYang)
  lu.assertEquals(me.general, "haoo2__linchengyuan")
  lu.assertIsTrue(me:hasSkill("gongxin", true))
  lu.assertIsFalse(me:hasSkill("haoo__kongsheng", true))
end)

return rongku
