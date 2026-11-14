local hemeng = fk.CreateSkill {
  name = "haoo__hemeng",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable {
  ["haoo__hemeng"] = "和梦",
  [":haoo__hemeng"] = "觉醒技，当你于一回合内同时触发“通南”的①②项后，你获得游戏胜利。",
}

-- 南梁一觉：本卡没有任何获得〖和梦〗的途径，觉醒条件形同虚设，
-- 本技能永不觉醒，“获得游戏胜利”只是梦（设计如此，勿实现觉醒逻辑）。
-- 若日后要实现胜利结算，胜利范围为你与你的阵营：
-- room:gameOver(player:getFriends(true, true))

return hemeng
