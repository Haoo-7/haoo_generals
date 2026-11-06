local nanbian = fk.CreateSkill {
  name = "ts__nanbian",
}

Fk:loadTranslationTable{
  ["ts__nanbian"] = "难辩",
  [":ts__nanbian"] = "一名角色的回合开始时，其可展示一张手牌并令所有角色选择是否与你议事。议事结束后，与你意见不同的角色各获得一张【影】；"..
    "若结果与展示牌颜色相同，你弃置所有【影】，其获得一张【影】且本回合对你造成的伤害+1；若不同，其获得两张【影】。"..
    "（以此法获得的【影】不计入手牌上限且弃牌阶段不能弃置）",

  ["#ts__nanbian-show"] = "难辩：请展示一张手牌",
  ["#ts__nanbian-join"] = "难辩：是否参与议事？",

  ["@ts__nanbian_dmg-turn"] = "难辩",
  ["@@ts__nanbian-inhand"] = "难辩",
}

local U = require "packages.utility.utility"

local function getShadeIds(player)
  return table.filter(player:getCardIds("h"), function(id)
    return Fk:getCardById(id).trueName == "shade"
  end)
end

local function obtainShade(room, player, n)
  local ids = U.getShade(room, n)
  room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonJustMove, nanbian.name, nil, true, player)
  for _, id in ipairs(ids) do
    room:setCardMark(Fk:getCardById(id), "@@ts__nanbian-inhand", 1)
  end
end

nanbian:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target and player:hasSkill(nanbian.name) and not player.dead and
      not player:isKongcheng() and not target.dead and not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      cancelable = true,
      skill_name = nanbian.name,
      prompt = "#ts__nanbian-show",
    })
    if #cards == 0 then return false end
    event:setCostData(self, { cards = cards, to = target })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    local turn_player = cost.to
    local shown_id = cost.cards[1]
    if not turn_player or turn_player.dead then return end

    turn_player:showCards({ shown_id })
    local shown_color = Fk:getCardById(shown_id):getColorString()
    room:delay(800)

    local tos = { turn_player }
    if player ~= turn_player then
      table.insert(tos, player)
    end

    local candidates = table.filter(room:getAllPlayers(), function(p)
      return not p.dead and not p:isKongcheng() and p ~= turn_player and p ~= player
    end)
    room:sortByAction(candidates)
    for _, p in ipairs(candidates) do
      if player.dead then break end
      if room:askToSkillInvoke(p, {
        skill_name = nanbian.name,
        prompt = "#ts__nanbian-join",
      }) then
        table.insert(tos, p)
      end
    end
    room:sortByAction(tos)
    if #tos == 0 or player.dead then return end

    local discussion = U.Discussion(player, tos, nanbian.name)
    local my_result = discussion.results[player]
    local my_opinion = my_result and my_result.opinion
    if my_opinion then
      for _, p in ipairs(tos) do
        local result = discussion.results[p]
        if not p.dead and result and result.opinion and result.opinion ~= my_opinion then
          obtainShade(room, p, 1)
        end
      end
    end

    if turn_player.dead then return end
    if discussion.color == shown_color then
      if not player.dead then
        local shades = getShadeIds(player)
        if #shades > 0 then
          room:throwCard(shades, nanbian.name, player, player)
        end
      end
      if not turn_player.dead then
        obtainShade(room, turn_player, 1)
        room:addPlayerMark(turn_player, "@ts__nanbian_dmg-turn")
      end
    elseif discussion.color ~= "noresult" then
      obtainShade(room, turn_player, 2)
    end
  end,
})

nanbian:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@ts__nanbian-inhand") > 0
  end,
})

nanbian:addEffect("prohibit", {
  prohibit_discard = function(self, player, card)
    return player.phase == Player.Discard and card:getMark("@@ts__nanbian-inhand") > 0
  end,
})

nanbian:addEffect(fk.DamageCaused, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(nanbian.name) and data.to == player and data.from and
      data.from ~= player and data.from:getMark("@ts__nanbian_dmg-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return nanbian
