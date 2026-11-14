local hemeng = fk.CreateSkill {
  name = "haoo__hemeng",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable {
  ["haoo__hemeng"] = "和梦",
  [":haoo__hemeng"] = "当你于一回合内同时触发“通南”的①②项后，你获得游戏胜利。",
}

-- 南梁一觉：〖和梦〗是〖通南〗的相关技能（related_skills），永不作为真实技能授予。
-- 状态由隐藏标记 haoo__hemeng_drunk 表达（喝掉=打标记；①②重置武将牌=清标记），
-- 客户端钩子（hongkainan_client.lua）按标记在详情中显示/移除本技能的紫色条目。
-- 全卡没有任何真正获得它的途径，觉醒条件形同虚设，永不觉醒，
-- “获得游戏胜利”只是梦（设计如此，勿实现觉醒逻辑）。
-- 若日后要实现胜利结算，胜利范围为你与你的阵营：
-- room:gameOver(player:getFriends(true, true))

return hemeng
