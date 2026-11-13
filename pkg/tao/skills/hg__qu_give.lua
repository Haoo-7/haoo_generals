local Qu = require "packages.haoo_generals.qu"
local skill = fk.CreateSkill {
  name = "hg__qu_give",
}

-- An auxiliary request skill; no general acquires this button.
skill:addEffect("active", {
  include_equip = true,
  card_num = 1,
  min_target_num = 0,
  max_target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("he"), to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select.dead and Qu.has(to_select)
  end,
  feasible = function(self, player, selected, selected_cards)
    if #selected_cards ~= 1 then return false end
    return #selected == 1 or (#selected == 0 and not player:prohibitDiscard(Fk:getCardById(selected_cards[1])))
  end,
})

Fk:loadTranslationTable {
  ["hg__qu_give"] = "渠",
}

return skill
