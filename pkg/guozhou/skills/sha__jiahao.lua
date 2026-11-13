local G = require "packages.haoo_generals.guozhou"
local skill = fk.CreateSkill {
  name = "sha__jiahao",
  tags = { Skill.Limited },
}

skill:addEffect("active", {
  anim_type = "special",
  prompt = "#sha__jiahao-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player.phase == Player.Play and player:usedSkillTimes(skill.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and not to_select.dead
  end,
  on_use = function(self, room, effect)
    local player, other = effect.from, effect.tos[1]
    local x = G.count(player)
    -- Only a real activation releases Jimi's replacement protection.
    room:setPlayerMark(player, G.unlocked, 1)
    G.execute(room, player, other, { 1, 2, 3, 4, 5 }, x, skill.name)
  end,
})

Fk:loadTranslationTable {
  ["sha__jiahao"] = "嘉嗥",
  [":sha__jiahao"] = "限定技 出牌阶段，你于选定一名角色后执行以下项：替换武将牌为界郭嘉；受到一点伤害；翻至背面并摸x张牌；交给对方至少x张牌；进行x+1次闪电判定。(x为本轮【漫播】发动次数)",
  ["#sha__jiahao-active"] = "嘉嗥：选定一名角色，依次执行五项（X为本轮漫播次数，可为0）",
}

return skill
