local shenkun = fk.CreateSkill {
  name = "haoo__shenkun",
  tags = { Skill.Charge },
}

local U = require "packages.utility.utility"

Fk:loadTranslationTable {
  ["haoo__shenkun"] = "神坤",
  [":haoo__shenkun"] = "蓄力技（2/4），出牌阶段，你可以减少1点蓄力点以视为使用一张【杀】或【决斗】。" ..
    "当你于回合内减少1/2/3/4点蓄力点后，你摸一张牌/弃置两张牌/失去1点体力/此伤害+1，" ..
    "你删去第一个选项，该技能本回合失效。",
  ["#haoo__shenkun-active"] = "神坤：你可以减少1点蓄力点，视为使用一张【杀】或【决斗】",
  ["#haoo__shenkun-discard"] = "神坤：你须弃置两张牌",
}

-- 判断牌是否为【神坤】使用的牌（兼容朱雀羽扇等改牌技能：changeCard 会继承 skillNames 列表）
local function isShenkunCard(card)
  return card ~= nil and (card.skillName == "haoo__shenkun" or
    (card.skillNames and table.contains(card.skillNames, "haoo__shenkun") or false))
end

shenkun:addAcquireEffect(function(self, player)
  U.skillCharged(player, 2, 4)
end)

shenkun:addLoseEffect(function(self, player)
  U.skillCharged(player, -2, -4)
end)

shenkun:addEffect("active", {
  anim_type = "offensive",
  prompt = "#haoo__shenkun-active",
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("skill_charge") > 0 and
      player:getMark("haoo__sk_disabled-turn") == 0
  end,
  interaction = function(self, player)
    return UI.CardNameBox { choices = { "slash", "duel" }, all_choices = { "slash", "duel" } }
  end,
  target_filter = function(self, player, to_select, selected)
    if #selected > 0 or to_select == player then return false end
    if (self.interaction.data or "slash") == "slash" then
      return player:inMyAttackRange(to_select)
    end
    return true
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local to = effect.tos[1]
    U.skillCharged(player, -1)
    local name = self.interaction.data
    if name ~= "slash" and name ~= "duel" then
      name = room:askToChoice(player, {
        choices = { "slash", "duel" },
        skill_name = shenkun.name,
      })
    end
    if not player.dead then
      room:useVirtualCard(name, nil, player, to, shenkun.name)
    end
  end,
})

-- 回合内累计减少1/2/3/4点蓄力点的档位效果
shenkun:addEffect(U.SkillChargeChanged, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shenkun.name) and
      data.num < 0 and player.room:getCurrent() == player
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local old = player:getMark("haoo__sk_spent-turn")
    local spent = old - data.num
    room:setPlayerMark(player, "haoo__sk_spent-turn", spent)
    if old < 1 and spent >= 1 then
      player:drawCards(1, shenkun.name)
    end
    if old < 2 and spent >= 2 then
      local n = #player:getCardIds("he")
      if n > 0 then
        room:askToDiscard(player, {
          min_num = math.min(2, n),
          max_num = math.min(2, n),
          include_equip = true,
          skill_name = shenkun.name,
          prompt = "#haoo__shenkun-discard",
          cancelable = false,
        })
      end
    end
    if old < 3 and spent >= 3 then
      room:loseHp(player, 1, shenkun.name)
    end
    if old < 4 and spent >= 4 then
      room:setPlayerMark(player, "haoo__sk_buff-turn", 1)
      -- 第4档触发后，神坤本回合失效
      room:setPlayerMark(player, "haoo__sk_disabled-turn", 1)
    end
  end,
})

-- 第4档：此伤害+1
shenkun:addEffect(fk.DamageCaused, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shenkun.name) and
      player:getMark("haoo__sk_buff-turn") > 0 and
      (data.skillName == shenkun.name or isShenkunCard(data.card))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "haoo__sk_buff-turn", 0)
    data:changeDamage(1)
  end,
})

return shenkun
