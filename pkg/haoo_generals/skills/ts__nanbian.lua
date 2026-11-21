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
  ["@@ts__nanbian-inarea"] = "难辩",
  ["@ts__nanbian"] = "难辩",
}

local U = require "packages.utility.utility"

local function getShadeIds(player)
  return table.filter(player:getCardIds("h"), function(id)
    return Fk:getCardById(id).trueName == "shade"
  end)
end

local function obtainShade(room, player, n)
  local ids = U.getShade(room, n)
  -- Applied by the move itself, before any nested AfterCardsMove transfer.
  room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonJustMove, nanbian.name, nil, true, player,
    { "@@ts__nanbian-inarea", { Card.PlayerHand } })
end

local function isNanbianShade(card)
  local areas = card:getMark("@@ts__nanbian-inarea")
  return type(areas) == "table" and table.contains(areas, Card.PlayerHand)
end

-- Refresh once per event, even when seat 1 is dead or nobody owns Nanbian.
for _, refresh_event in ipairs({ fk.GameStart, fk.AfterCardsMove }) do
  nanbian:addEffect(refresh_event, {
    global = true,
    can_refresh = function(self, event, target, player, data)
      return player.seat == 1
    end,
    on_refresh = function(self, event, target, player, data)
      local room = player.room
      -- moveMark is applied AFTER the engine's -inarea cleanup. A move
      -- redirected from Void can therefore acquire this tag outside Hand.
      -- Check the actual area (not the original destination or owner), so
      -- nested hand-to-hand transfers keep their source tag.
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if room:getCardArea(info.cardId) ~= Card.PlayerHand and isNanbianShade(card) then
              room:setCardMark(card, "@@ts__nanbian-inarea", 0)
            end
          end
        end
      end
      for _, p in ipairs(room.players) do
        local n = #getShadeIds(p)
        if p:getMark("@ts__nanbian") ~= n then
          room:setPlayerMark(p, "@ts__nanbian", n)
        end
      end
    end,
  })
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
    return isNanbianShade(card)
  end,
})

nanbian:addEffect("prohibit", {
  prohibit_discard = function(self, player, card)
    return player.phase == Player.Discard and isNanbianShade(card)
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

nanbian:addTest(function(room, me)
  local other = room.players[2]
  local mark = "@@ts__nanbian-inarea"
  local shade = Fk:getCardById(U.getShade(room, 1)[1])
  FkTest.runInRoom(function()
    -- Sealed Hand rejects a newly printed Void shade before arrival.
    room:abortPlayerArea(me, Player.HandSlot)
    obtainShade(room, me, 1)
    lu.assertEquals(room:getCardArea(shade.id), Card.Void)
    lu.assertEquals(shade:getMark(mark), 0)
    room:resumePlayerArea(me, Player.HandSlot)

    -- Model a BeforeCardsMove redirect retaining moveMark: cleanup runs
    -- before moveMark, so a Void-to-Void move used to leak the Hand tag.
    room:moveCards{
      ids = { shade.id }, toArea = Card.Void,
      moveReason = fk.ReasonJustMove, skillName = nanbian.name,
      moveMark = { mark, { Card.PlayerHand } },
    }
    lu.assertEquals(room:getCardArea(shade.id), Card.Void)
    lu.assertEquals(shade:getMark(mark), 0)

    -- Ordinary getShade reuse must not inherit Nanbian's source tag.
    local reused = U.getShade(room, 1)
    lu.assertEquals(reused, { shade.id })
    room:moveCardTo(reused, Card.PlayerHand, me, fk.ReasonJustMove)
    lu.assertEquals(shade:getMark(mark), 0)

    room:setCardMark(shade, mark, { Card.PlayerHand })
    room:moveCardTo(shade.id, Card.PlayerHand, other, fk.ReasonGive)
    lu.assertEquals(shade:getMark(mark), { Card.PlayerHand })
    room:moveCardTo(shade.id, Card.Void, nil, fk.ReasonJustMove)
    lu.assertEquals(shade:getMark(mark), 0)
  end)
end)

return nanbian
