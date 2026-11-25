local M = require "packages.haoo_generals.motian"
local skill = fk.CreateSkill {
  name = "mt__tianji",
  tags = { Skill.Compulsory },
}

skill:addEffect(fk.GameStart, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(skill.name)
  end,
  on_refresh = function(self, event, target, player, data)
    M.installVictory(player.room)
  end,
})

skill:addAcquireEffect(function(self, player, is_start)
  M.installVictory(player.room)
end)

skill:addEffect(fk.EventPhaseStart, {
  global = true,
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target and target.phase == Player.Start and target:hasSkill(skill.name) and player:hasSkill("tiandu")
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = skill.name,
      prompt = "#mt__tianji-release::" .. target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    M.loseTiandu(room, player)
    if not player.dead and player.hp > 0 then room:loseHp(player, player.hp, skill.name) end
  end,
})

Fk:loadTranslationTable {
  ["mt__tianji"] = "天嫉",
  [":mt__tianji"] = "你为【天妒】增加以下效果：未满足漠阗的胜利条件时你不能胜利；漠阗的准备阶段，你可以失去所有体力和【天妒】。",
  ["#mt__tianji-release"] = "天嫉：%dest的准备阶段，你可以先失去【天妒】，再失去所有体力（正常进入濒死）",
}

return skill
