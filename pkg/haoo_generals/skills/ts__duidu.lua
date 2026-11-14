local duidu = fk.CreateSkill {
  name = "ts__duidu",
}

local function amount(player, kind)
  if kind == "ts__bet_cards" then return #player:getCardIds("he") end
  if kind == "ts__bet_hp" then return math.max(0, player.hp) end
  return math.max(0, player.maxHp - 1)
end

local function pay(room, player, kind, n)
  if player.dead then return {} end
  if kind == "ts__bet_cards" then
    return room:askToDiscard(player, {
      min_num = n, max_num = n, include_equip = true,
      skill_name = duidu.name, cancelable = false,
      prompt = "#ts__duidu-pay:::" .. n,
    })
  elseif kind == "ts__bet_hp" then
    room:loseHp(player, math.min(n, math.max(0, player.hp)), duidu.name)
  else
    room:changeMaxHp(player, -math.min(n, math.max(0, player.maxHp - 1)))
  end
  return {}
end

local function reveal(room, player)
  local ids = room:getNCards(1)
  if #ids == 0 then return nil end
  room:moveCards {
    ids = ids, toArea = Card.Processing, moveReason = fk.ReasonJustMove,
    skillName = duidu.name, proposer = player,
  }
  room:delay(600)
  return ids[1]
end

duidu:addEffect("active", {
  anim_type = "special",
  prompt = "#ts__duidu-active",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player.phase == Player.Play
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local choices = {}
    local candidates = {}
    for _, kind in ipairs({ "ts__bet_cards", "ts__bet_hp", "ts__bet_maxhp" }) do
      candidates[kind] = table.filter(room.alive_players, function(p)
        return p ~= player and amount(p, kind) > 0
      end)
      if amount(player, kind) > 0 and #candidates[kind] > 0 then
        table.insert(choices, kind)
      end
    end
    if #choices == 0 then return end
    local kind = room:askToChoice(player, {
      choices = choices, skill_name = duidu.name, prompt = "#ts__duidu-kind",
    })
    local tos = room:askToChoosePlayers(player, {
      targets = candidates[kind], min_num = 1, max_num = 1,
      skill_name = duidu.name, prompt = "#ts__duidu-target", cancelable = false,
    })
    local other = tos[1]
    if not other or player.dead or other.dead then return end
    local limit = math.min(amount(player, kind), amount(other, kind))
    if limit < 1 then return end
    local n = room:askToNumber(player, {
      min = 1, max = limit, skill_name = duidu.name,
      prompt = "#ts__duidu-number:::" .. limit, cancelable = false,
    })
    -- Count a committed wager even if payment kills its initiator or the opponent refuses.
    room:addPlayerMark(player, "ts__duidu_count-turn", 1)
    local forced = player:getMark("@ts__tianming_forced-turn") > 0
    if forced then room:removePlayerMark(player, "@ts__tianming_forced-turn", 1) end
    local cards = pay(room, player, kind, n)
    if player.dead or other.dead then return end
    if not forced and not room:askToSkillInvoke(other, {
      skill_name = duidu.name, prompt = "#ts__duidu-accept:::" .. n,
    }) then return end
    table.insertTable(cards, pay(room, other, kind, n))
    if player.dead or other.dead then return end
    local winner
    repeat
      local first = reveal(room, player)
      if not first then return end
      local second = reveal(room, other)
      if not second then room:cleanProcessingArea({ first }); return end
      local a, b = Fk:getCardById(first).number, Fk:getCardById(second).number
      -- Hold both cards in Processing until compared: a shuffle cannot redraw the first card.
      room:cleanProcessingArea({ first, second })
      if a > b then winner = player elseif b > a then winner = other end
    until winner or player.dead or other.dead
    if not winner or winner.dead then return end
    if kind == "ts__bet_cards" then
      cards = table.filter(cards, function(id) return room:getCardArea(id) == Card.DiscardPile end)
      if #cards > 0 then room:obtainCard(winner, cards, true, fk.ReasonJustMove, winner, duidu.name) end
    elseif kind == "ts__bet_hp" then
      room:recover { who = winner, num = 2 * n, recoverBy = winner, skillName = duidu.name }
    else
      room:changeMaxHp(winner, 2 * n)
    end
  end,
})

return duidu
