local G = require "packages.haoo_generals.guozhou"
local skill = fk.CreateSkill {
  name = "sha__jiahao",
  tags = { Skill.Limited },
}

skill:addEffect(fk.RoundEnd, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and
      player:usedSkillTimes(skill.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askToChoosePlayers(player, {
      targets = player.room:getAlivePlayers(),
      min_num = 1,
      max_num = 1,
      cancelable = true,
      skill_name = skill.name,
      prompt = "#sha__jiahao-choose",
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room, other = player.room, event:getCostData(self).tos[1]
    local x = G.count(player)
    -- Only a real activation releases Jimi's replacement protection.
    room:setPlayerMark(player, G.unlocked, 1)
    G.execute(room, player, other, { 1, 2, 3, 4, 5 }, x, skill.name)
  end,
})

Fk:loadTranslationTable {
  ["sha__jiahao"] = "嘉嗥",
  [":sha__jiahao"] = "限定技 每轮结束时你可选定一名角色并执行以下项：替换武将牌为界郭嘉；受到一点伤害；翻至背面并摸X张牌；交给对方至少X张牌；进行X+1次闪电判定。(X为本轮【漫播】发动次数）",
  ["#sha__jiahao-choose"] = "嘉嗥：你可以选定一名角色，依次执行五项（X为本轮漫播次数，可为0）",
}

return skill
