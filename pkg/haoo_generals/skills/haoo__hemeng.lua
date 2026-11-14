local hemeng = fk.CreateSkill {
  name = "haoo__hemeng",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable {
  ["haoo__hemeng"] = "和梦",
  [":haoo__hemeng"] = "觉醒技，当你于一回合内同时触发“通南”的①②项后，你获得游戏胜利。",
}

-- 南梁一觉：〖和梦〗是〖通南〗的相关技能（related_skills），武将详情页紫色显示。
-- 状态由〖通南〗用技能所有权表达：开局授予=在武将牌上（可被当【酒】喝掉）；
-- 被喝掉=移除本技能；〖通南〗执行①或②并重置武将牌后重新授予（回到武将牌上）。
-- 全卡没有任何真正获得它的途径，觉醒条件形同虚设，永不觉醒，
-- “获得游戏胜利”只是梦（设计如此，勿实现觉醒逻辑）。
-- 若日后要实现胜利结算，胜利范围为你与你的阵营：
-- room:gameOver(player:getFriends(true, true))

return hemeng
