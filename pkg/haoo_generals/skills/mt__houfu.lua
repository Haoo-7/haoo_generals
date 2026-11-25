local M = require "packages.haoo_generals.motian"
local skill = fk.CreateSkill {
  name = "mt__houfu",
  tags = { Skill.Compulsory },
}

skill:addEffect(fk.GameStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and #player.room:getOtherPlayers(player) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local chosen = player.room:askToChoosePlayers(player, {
      targets = player.room:getOtherPlayers(player),
      min_num = 1,
      max_num = 1,
      cancelable = false,
      skill_name = skill.name,
      prompt = "#mt__houfu-choose",
    })
    if #chosen == 0 then return false end
    event:setCostData(self, { tos = chosen })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    if to.dead then return end
    player.room:setPlayerMark(player, M.partner, to.id)
    player.room:handleAddLoseSkills(to, "tiandu")
  end,
})

skill:addEffect(fk.HpRecover, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(skill.name) or data.num <= 0 then return false end
    local id = player:getMark(M.partner)
    if id == 0 then return false end
    local to = player.room:getPlayerById(id)
    return to and not to.dead and to:isWounded()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark(M.partner))
    if not to or to.dead then return end
    room:recover { who = to, num = data.num, recoverBy = player, skillName = skill.name }
  end,
})

skill:addEffect(fk.Damaged, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target and player:hasSkill(skill.name) and target.id == player:getMark(M.partner) and data.damage > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage { to = player, damage = data.damage, skillName = skill.name }
  end,
})

Fk:loadTranslationTable {
  ["mt__houfu"] = "后辅",
  [":mt__houfu"] = "游戏开始时，你选择一名后辅角色，其获得【天妒】。你回复若干体力或其受到若干伤害后，对方如是。",
  ["#mt__houfu-choose"] = "后辅：选择一名其他角色，其获得【天妒】，并与你联动回复体力和受到伤害",
}

return skill
