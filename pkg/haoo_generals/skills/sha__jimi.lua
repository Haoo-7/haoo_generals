local G = require "packages.haoo_generals.guozhou"
local skill = fk.CreateSkill {
  name = "sha__jimi",
  tags = { Skill.Compulsory },
}

skill:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player, isJudgeEvent)
    return not isJudgeEvent and player:hasSkill(skill.name) and
      (card.number == 11 or card.number == 8) and table.contains(player:getCardIds("he"), card.id)
  end,
  view_as = function(self, player, card)
    -- Clone the same card class, retaining equipment behavior and card name.
    local result = card:clone(card.suit, 13)
    -- Card:clone does not copy its package, unlike Engine:cloneCard.
    -- The client needs this to resolve the card's extension and artwork.
    result.package = card.package
    return result
  end,
})

skill:addAcquireEffect(function(self, player) G.refilter(player) end)
skill:addLoseEffect(function(self, player) G.refilter(player) end)

Fk:loadTranslationTable {
  ["sha__jimi"] = "技密",
  [":sha__jimi"] = "锁定技 你的J8=K。【嘉嗥】发动前，防止此武将牌被替换。其：每轮开始时复原且背面视为界郭嘉。",
}

return skill
