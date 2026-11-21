-- Dynamic names are native, but dashboard SkillModels cache their initial name.
-- Rebuild only this player's SP Lin buttons after the synchronized awakening mark.
-- UI notifications do not acquire/lose skills or reset any gameplay history.
local skills = { "ts__tianjie", "ts__tianhou", "ts__tiansi", "ts__tianming" }
return function(base)
  if base.ts__lin_name_refresh then return end
  base.ts__lin_name_refresh = true
  local setMark = base.handleSetPlayerMark
  base.handleSetPlayerMark = function(self, data)
    local result = table.pack(setMark(self, data))
    if data[2] == "ts__lin_awakened" then
      local player = self:getPlayerById(data[1])
      if player then
        for _, name in ipairs(skills) do
          if player:hasSkill(name, true) then
            self:notifyUI("LoseSkill", { player.id, name })
            self:notifyUI("AddSkill", { player.id, name })
          end
        end
      end
    end
    return table.unpack(result, 1, result.n)
  end
end
