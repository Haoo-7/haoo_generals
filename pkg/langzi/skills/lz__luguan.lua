local skill = fk.CreateSkill {
  name = "lz__luguan",
  tags = { Skill.Compulsory },
}

local mark = "@lz__luguan-turn"
local cards = { "duel", "fire_attack", "enemy_at_the_gates" }

local function damageIndex(player, data)
  -- Count damage instances, not damage points, including the current damage.
  -- Recorder order keeps nested damage from changing this damage's ordinal.
  return #player.room.logic:getActualDamageEvents(4, function(e)
    return e.data.to == player and e.data.dealtRecorderId <= data.dealtRecorderId
  end, Player.HistoryTurn)
end

local function active(player)
  return player:hasSkill(skill.name) and table.contains(cards, player:getMark(mark))
end

skill:addEffect(fk.Damaged, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(skill.name) then return false end
    local n = damageIndex(player, data)
    return n > 0 and n <= 3
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { num = damageIndex(player, data) })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local n = event:getCostData(self).num
    player.room:setPlayerMark(player, mark, cards[n])
    player:filterHandcards()
  end,
})

skill:addEffect("filter", {
  card_filter = function(self, card, player)
    return active(player) and card.color == Card.Red and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    local result = Fk:cloneCard(player:getMark(mark), card.suit, card.number)
    result.skillName = skill.name
    return result
  end,
})

-- Keep installed equipment as equipment in the engine's movement/slot data.
-- Its skills and weapon range are disabled instead of placing trick objects
-- into equipment slots, which would break uninstall and replacement handling.
skill:addEffect("invalidity", {
  invalidity_func = function(self, player, equip_skill)
    -- Check the queried skill first to avoid recursion through hasSkill.
    if not equip_skill:isEquipmentSkill(player) or not active(player) then return false end
    local disabled = false
    for _, id in ipairs(player:getCardIds("e")) do
      local equip = player:getVirtualEquip(id) or Fk:getCardById(id, true)
      if equip.type == Card.TypeEquip then
        for _, supplied in ipairs(equip:getEquipSkills(player)) do
          if supplied.name == equip_skill.name or supplied:getSkeleton() == equip_skill:getSkeleton() then
            if equip.color ~= Card.Red then return false end
            disabled = true
          end
        end
      end
    end
    return disabled
  end,
  invalidity_attackrange = function(self, player, card)
    return card.color == Card.Red and active(player)
  end,
})

Fk:loadTranslationTable {
  ["lz__luguan"] = "橹冠",
  [":lz__luguan"] = "锁定技 你每回合第x次受到伤害后，红色牌视为<br>①决斗②火攻③兵临城下",
  [mark] = "橹冠",
}

return skill
