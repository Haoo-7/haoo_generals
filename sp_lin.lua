-- SP Lin only. State belongs to the player (awakening) or room (history).
local M = {}
M.awake = "ts__lin_awakened"
M.death = "ts__tianjie_death"
M.pending = "ts__tianjie_pending"

function M.isAwake(player)
  return player and player:getMark(M.awake) > 0
end

function M.skill(name, short, tags)
  return fk.CreateSkill {
    name = name,
    tags = tags,
    dynamic_name = function(self, player)
      return M.isAwake(player) and short or name
    end,
    dynamic_desc = function(self, player)
      return M.isAwake(player) and name .. "_awakened" or name
    end,
  }
end

function M.targets(room, player)
  return table.filter(room.alive_players, function(p)
    return p ~= player and not p:isNude()
  end)
end

function M.lightning(room, player)
  if player.dead then return end
  local judge = { who = player, reason = "ts__tianjie", pattern = ".|2~9|spade" }
  room:judge(judge)
  if not player.dead and judge:matchPattern() then
    room:damage {
      to = player, damage = 3, damageType = fk.ThunderDamage,
      skillName = "ts__tianjie",
    }
  end
end

return M
