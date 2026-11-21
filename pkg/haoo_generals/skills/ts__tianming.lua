local L = require "packages.haoo_generals.sp_lin"
local skill = L.skill("ts__tianming", "ts__lin_ming", { Skill.Wake })

skill:addEffect(fk.TurnStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(skill.name) or L.isAwake(player) or
      not player.room:getTag(L.death) then return false end
    local kingdoms = {}
    for _, other in ipairs(player.room.alive_players) do
      if other ~= player then table.insertIfNeed(kingdoms, other.kingdom) end
    end
    return #kingdoms <= 2
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, L.awake, 1)
  end,
})

return skill
