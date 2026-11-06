local shenxu = fk.CreateSkill {
  name = "haoo__shenxu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["haoo__shenxu"] = "肾虚",
  [":haoo__shenxu"] = "锁定技，你的非锦囊牌视为【顺手牵羊】。",
  ["#haoo__shenxu"] = "肾虚：你的非锦囊牌视为【顺手牵羊】",
}

shenxu:addEffect("viewas", {
  pattern = "snatch",
  prompt = "#haoo__shenxu",
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|.|.|.|basic,equip",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("snatch")
    c.skillName = shenxu.name
    c:addSubcard(cards[1])
    return c
  end,
})

shenxu:addAI(nil, "vs_skill")

return shenxu
