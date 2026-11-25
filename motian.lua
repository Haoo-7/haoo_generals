local M = {
  general = "mt__motian",
  partner = "mt__houfu-noclear",
  suits = "@mt__chouba-noclear",
}

-- Filter the mode's actual winners, including dead teammates. Check every
-- Tianji owner against the original list so filtering never changes a condition.
function M.filterWinners(room, winners)
  local owners = table.filter(room.players, function(p)
    return p:hasSkill("mt__tianji", false, true)
  end)
  if #owners == 0 then return winners end
  local normal = winners
  if type(winners) == "string" then
    local roles = winners:split("+")
    normal = table.filter(room.players, function(p)
      return table.contains(roles, p.role)
    end)
  end
  if not table.find(owners, function(p) return not table.contains(normal, p) end) then return winners end
  return table.filter(normal, function(p)
    return not p:hasSkill("tiandu", false, true)
  end)
end

-- The native engine has no winner-filter event. Wrap only this room's final
-- entry point; the original implementation still handles results and stats.
function M.installVictory(room)
  if room.mt__tianji_gameover then return end
  room.mt__tianji_gameover = true
  local original = room.gameOver
  room.gameOver = function(self, winners)
    return original(self, M.filterWinners(self, winners))
  end
end

function M.loseTiandu(room, player)
  local sources = {}
  for source, skills in pairs(player.derivative_skills) do
    if table.contains(skills, Fk.skills.tiandu) then table.insert(sources, source) end
  end
  for _, source in ipairs(sources) do room:handleAddLoseSkills(player, "-tiandu", source) end
  room:handleAddLoseSkills(player, "-tiandu")
end

return M
