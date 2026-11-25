local skill = fk.CreateSkill {
  name = "slg__maoting",
}

local function available(player)
  local current = Fk:currentRoom():getCurrent()
  return not player.chained and current ~= nil and not current.dead
end

skill:addEffect("viewas", {
  anim_type = "control",
  pattern = "nullification",
  prompt = "#slg__maoting",
  card_num = 0,
  filter_pattern = { min_num = 0, max_num = 0, pattern = "", subcards = {} },
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if not available(player) then return end
    local card = Fk:cloneCard("nullification")
    card.skillName = skill.name
    return card
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player, response)
    return not response and available(player)
  end,
  enabled_at_nullification = function(self, player, data)
    return available(player)
  end,
  before_use = function(self, player, use)
    local current = player.room:getCurrent()
    if player.dead or player.chained or not current or current.dead then return skill.name end
    player:setChainState(true)
    if current ~= player and not current.dead then current:setChainState(true) end
    if player.dead or not player.chained or current.dead or not current.chained then return skill.name end
  end,
})

skill:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and player.chained and target ~= player and target.chained and
      data.card and data.card.name == "lightning"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
  end,
})

Fk:loadTranslationTable {
  ["slg__maoting"] = "冇霆",
  [":slg__maoting"] = "若你未横置，你可以与当前回合角色横置，以视为使用一张【无懈可击】。若你已横置，防止其他横置角色受到的闪电伤害。",
  ["#slg__maoting"] = "冇霆：横置你与当前回合角色，视为使用一张【无懈可击】",
}

return skill
