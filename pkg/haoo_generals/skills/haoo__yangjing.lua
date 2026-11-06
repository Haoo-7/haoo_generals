local yangjing = fk.CreateSkill {
  name = "haoo__yangjing",
  tags = { Skill.Compulsory },
}

local U = require "packages.utility.utility"

Fk:loadTranslationTable {
  ["haoo__yangjing"] = "养精",
  [":haoo__yangjing"] = "锁定技，你于不因【神坤】造成伤害后获得1点蓄力点。",
}

-- 判断牌是否为【神坤】使用的牌（兼容朱雀羽扇等改牌技能：changeCard 会继承 skillNames 列表）
local function isShenkunCard(card)
  return card ~= nil and (card.skillName == "haoo__shenkun" or
    (card.skillNames and table.contains(card.skillNames, "haoo__shenkun") or false))
end

yangjing:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return data.from == player and player:hasSkill(yangjing.name) and not player.dead and
      data.skillName ~= "haoo__shenkun" and not isShenkunCard(data.card)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    U.skillCharged(player, 1)
  end,
})

return yangjing
