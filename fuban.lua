local F = {
  general = "fb__fuban",
  mark = "fb__hufu-inarea",
  count_mark = "@fb__yingzi",
}

function F.installKingdomChoice(engine)
  if engine.fb__fuban_kingdom_choice then return end
  local original = engine.getKingdomsNeedToChoose
  -- Older cores choose dual kingdoms directly and do not expose this method.
  -- Leave their native path untouched; never capture a noncallable fallback.
  if type(original) ~= "function" then return end
  engine.fb__fuban_kingdom_choice = true
  -- The native chooser appends God's four mapped kingdoms even for a
  -- dual-kingdom general. Override only Fuban, on both client and server.
  engine.getKingdomsNeedToChoose = function(self, name)
    if name == F.general then return { "god", "hg_tie" } end
    return original(self, name)
  end
end

function F.armor(player, id)
  return player:getVirtualEquip(id) or Fk:getCardById(id)
end

function F.name(suit)
  if suit == Card.Spade then return "vine" end
  if suit == Card.Heart or suit == Card.Diamond then return "women_dress" end
  if suit == Card.Club then return "silver_lion" end
end

function F.material(player, id)
  if table.contains(player:getCardIds("h"), id) then return F.name(Fk:getCardById(id).suit) ~= nil end
  if table.contains(player:getCardIds("e"), id) then
    local card = F.armor(player, id)
    return card.type == Card.TypeEquip and card.sub_type ~= Card.SubtypeArmor and F.name(card.suit) ~= nil
  end
  return false
end

function F.count(player)
  local n = 0
  for _, id in ipairs(player:getEquipments(Card.SubtypeArmor)) do
    if type(Fk:getCardById(id):getMark(F.mark)) == "table" then n = n + 1 end
  end
  return n
end

function F.movable(player, target)
  if player.dead or target.dead or player == target or not target:hasEmptyEquipSlot(Card.SubtypeArmor) then return {} end
  return table.filter(player:getEquipments(Card.SubtypeArmor), function(id)
    return target:canMoveCardIntoEquip(F.armor(player, id), false)
  end)
end

return F
