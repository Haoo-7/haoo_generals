local skill = fk.CreateSkill {
  name = "slg__shaohuo",
}

local function fireAttack(player)
  local card = Fk:cloneCard("fire_attack")
  card:addSubcards(player:getCardIds("h"))
  card.skillName = skill.name
  return card
end

local function damageCount(player)
  local n = 0
  player.room.logic:getActualDamageEvents(1, function(e)
    if e.data.from == player then n = n + e.data.damage end
    return false
  end, Player.HistoryTurn)
  return n
end

skill:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Play and
      not player:isKongcheng() and #fireAttack(player):getAvailableTargets(player) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local card = fireAttack(player)
    local targets = card:getAvailableTargets(player)
    local tos = player.room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = math.min(#card.subcards, #targets),
      skill_name = skill.name,
      prompt = "#slg__shaohuo-targets:::" .. #card.subcards,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos, cards = table.simpleClone(card.subcards) })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if player.dead or player:isKongcheng() then return end
    local cost = event:getCostData(self)
    local card = fireAttack(player)
    -- Do not spend a changed hand or use an obsolete target selection.
    if #card.subcards ~= #cost.cards or #cost.tos > #card.subcards then return end
    for _, id in ipairs(cost.cards) do
      if not table.contains(card.subcards, id) then return end
    end
    local targets = card:getAvailableTargets(player)
    for _, to in ipairs(cost.tos) do
      if not table.contains(targets, to) then return end
    end
    local suits = {}
    for _, id in ipairs(card.subcards) do
      table.insertIfNeed(suits, Fk:getCardById(id).suit)
    end
    player.room:sortByAction(cost.tos)
    player.room:useCard {
      from = player,
      tos = cost.tos,
      card = card,
      extra_data = {
        slg__shaohuo_suits = suits,
        extra_effect = {
          -- The native fire_attack hook receives the card actually shown.
          -- Keep it on this effect, as extra_data is shared by all targets.
          [skill.name] = function(room, effect, shown, params)
            effect.slg__shaohuo_suit = shown.suit
            return params
          end,
        },
      },
    }
  end,
})

skill:addEffect("targetmod", {
  extra_target_func = function(self, player, cardSkill, card)
    if card and card.name == "fire_attack" and table.contains(card.skillNames, skill.name) then
      return math.max(#card.subcards - 1, 0)
    end
  end,
})

skill:addEffect(fk.CardEffectFinished, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return data.from == player and not player.dead and data.to and not data.to.dead and
      data.card.name == "fire_attack" and table.contains(data.card.skillNames, skill.name) and
      data.slg__shaohuo_suit ~= nil and not data.slg__shaohuo_done and
      table.contains((data.extra_data or {}).slg__shaohuo_suits or {}, data.slg__shaohuo_suit)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.slg__shaohuo_done = true
    player.room:damage {
      from = player,
      to = data.to,
      damage = 1,
      damageType = fk.FireDamage,
      skillName = skill.name,
    }
  end,
})

skill:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and damageCount(player) > 0
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { num = damageCount(player) })
    return true
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(event:getCostData(self).num, skill.name)
  end,
})

Fk:loadTranslationTable {
  ["slg__shaohuo"] = "烧获",
  [":slg__shaohuo"] = "出牌阶段开始时你可【奇策】火攻并指定至多底牌数个目标，其中展示与底牌花色相同牌的须于结算后受到一点火焰伤害。你于造成过X点伤害的回合结束后摸X张牌。",
  ["#slg__shaohuo-targets"] = "烧获：将全部手牌当【火攻】使用，选择至多 %arg 名目标；展示牌与任一底牌同花色者结算后额外受到1点火焰伤害",
}

return skill
