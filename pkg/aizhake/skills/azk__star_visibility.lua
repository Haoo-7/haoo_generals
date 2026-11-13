local A = require "packages.haoo_generals.aizhake"
local skill = fk.CreateSkill { name = "#azk__star_visibility" }

skill:addEffect("visibility", {
  global = true,
  card_visible = function(self, viewer, card)
    local room = Fk:currentRoom()
    if room:getCardArea(card.id) ~= Card.PlayerSpecial then return end
    local owner = room:getCardOwner(card.id)
    if owner and owner:getPileNameOfId(card.id) == A.pile then
      return viewer ~= owner or A.known(owner, card.id)
    end
  end,
  move_visible = function(self, viewer, info, move)
    if move.toArea == Card.PlayerSpecial and move.specialName == A.pile then
      return viewer ~= move.to or A.known(move.to, info.cardId)
    end
    if info.fromArea == Card.PlayerSpecial and info.fromSpecialName == A.pile then
      if move.toArea == Card.PlayerHand then
        return viewer ~= move.from or viewer == move.to or A.known(move.from, info.cardId)
      end
      if move.toArea == Card.Processing or move.toArea == Card.DiscardPile then return true end
    end
  end,
})

Fk:loadTranslationTable { ["#azk__star_visibility"] = "星夜·星可见性" }

return skill
