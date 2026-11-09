local W = {}

W.general = "bo__wushilin"
W.borrowed = { "jiang", "jiyuan", "shenji", "quanji" }
W.turn_tag = "bo__wushilin_turn"
W.gained = "bo__jige_gained-turn"
W.granted = "bo__jige_granted"
W.involved = "bo__dansi_involved-turn"
W.revealed = "@@bo__dansi-inhand"
W.skip_draw = "@bo__dansi_skip"
W.extra_draw = "@bo__dansi_draw"
W.backwater = "@bo__dansi_duanchang"

function W.removeBorrowed(player)
  local names = player:getTableMark(W.granted)
  player.room:setPlayerMark(player, W.granted, 0)
  for _, name in ipairs(names) do
    if player:hasSkill(name, true, true) then
      player.room:handleAddLoseSkills(player, "-" .. name, "bo__jige", false)
    else
      -- Removing Jige itself already removes its derivative skills. The
      -- native wrapper only calls Jige's onLose, so clean derived piles too.
      Fk.skill_skels[name]:onLose(player, player.dead)
    end
  end
end

function W.syncSkills(player)
  local room = player.room
  if not player.dead and room:getTag(W.turn_tag) and player:hasSkill("bo__jige") and player:getMark(W.gained) == 0 then
    local added = player:getTableMark(W.granted)
    for _, name in ipairs(W.borrowed) do
      if not player:hasSkill(name, true, true) then
        table.insertIfNeed(added, name)
        -- Record ownership before acquire callbacks can move any cards.
        room:setPlayerMark(player, W.granted, table.simpleClone(added))
        room:handleAddLoseSkills(player, name, "bo__jige", false)
        if player.dead or not player:hasSkill("bo__jige") or player:getMark(W.gained) ~= 0 then break end
      end
    end
  else
    W.removeBorrowed(player)
  end
end

function W.beginTurn(room, current)
  room:setTag(W.turn_tag, current.id)
  for _, player in ipairs(room.players) do
    room:setPlayerMark(player, W.gained, 0)
    room:setPlayerMark(player, W.involved, 0)
  end
  for _, player in ipairs(room.players) do W.syncSkills(player) end
end

function W.endTurn(room)
  room:setTag(W.turn_tag, nil)
  for _, player in ipairs(room.players) do W.removeBorrowed(player) end
end

function W.gainedCards(player, moves)
  return table.find(moves, function(move)
    return move.to == player and move.toArea == Card.PlayerHand and
      table.find(move.moveInfo, function(info)
        return move.from ~= player or info.fromArea ~= Card.PlayerHand
      end) ~= nil
  end) ~= nil
end

function W.loseGeneralSkills(player)
  local room = player.room
  room:setPlayerMark(player, W.backwater, 0)
  W.removeBorrowed(player)
  local names = {}
  for _, name in ipairs(player:getSkillNameList()) do
    if not Fk.skill_skels[name].mode_skill then table.insert(names, "-" .. name) end
  end
  if #names > 0 then room:handleAddLoseSkills(player, names) end
end

function W.settleBackwater(player)
  if player:getMark(W.backwater) > 0 and player.room:getTag(W.turn_tag) == player.id then
    W.loseGeneralSkills(player)
  end
end

function W.redCards(player)
  return table.filter(table.connect(player:getCardIds("he"), player:getHandlyIds(false)), function(id)
    return Fk:getCardById(id).color == Card.Red
  end)
end

function W.canCounter(player, target)
  if not target or target.dead or target == player then return false end
  return table.find(W.redCards(player), function(id)
    local slash = Fk:cloneCard("slash")
    slash.skillName = "bo__dansi"
    slash:addSubcard(id)
    return player:canUseTo(slash, target, { bypass_times = true })
  end) ~= nil
end

function W.revealHands(room, player, x)
  local involved = table.filter(room:getAlivePlayers(), function(p) return p:getMark(W.involved) > 0 end)
  for _, target in ipairs(involved) do
    if player.dead then return end
    if not target.dead and not target:isKongcheng() then
      local n = math.min(x, #target:getCardIds("h"))
      local cards = room:askToChooseCards(player, {
        target = target,
        flag = "h",
        min = n,
        max = n,
        cancelable = false,
        skill_name = "bo__dansi",
        prompt = "#bo__dansi-reveal::" .. target.id .. ":" .. n,
      })
      cards = table.filter(cards, function(id) return table.contains(target:getCardIds("h"), id) end)
      for _, id in ipairs(cards) do room:setCardMark(Fk:getCardById(id), W.revealed, 1) end
      if #cards > 0 then target:showCards(cards, player) end
    end
  end
end

function W.revealedCards(player)
  return table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark(W.revealed) > 0 end)
end

function W.giveCards(room, from, to, x)
  if from.dead or to.dead or from == to then return end
  local cards = W.revealedCards(from)
  local n = math.min(x, #cards)
  if n == 0 then return end
  cards = room:askToCards(from, {
    min_num = n,
    max_num = n,
    include_equip = false,
    pattern = tostring(Exppattern { id = cards }),
    cancelable = false,
    skill_name = "bo__dansi",
    prompt = "#bo__dansi-give::" .. to.id .. ":" .. n,
  })
  cards = table.filter(cards, function(id)
    return table.contains(from:getCardIds("h"), id) and Fk:getCardById(id):getMark(W.revealed) > 0
  end)
  if #cards > 0 and not from.dead and not to.dead then
    room:obtainCard(to, cards, true, fk.ReasonGive, from, "bo__dansi")
  end
end

function W.giveDrawPhase(room, from, to)
  if from.dead or to.dead or from == to then return end
  room:setPlayerMark(from, W.skip_draw, from:getMark(W.skip_draw) + 1)
  room:setPlayerMark(to, W.extra_draw, to:getMark(W.extra_draw) + 1)
  room:sendLog { type = "#bo__dansi-transfer", from = from.id, to = { to.id }, arg = "bo__dansi" }
end

function W.resolve(room, player, use, x)
  -- UseCardData wraps the original specification; damageDealt is written
  -- back to this table. Room:useCard itself returns a boolean/nil.
  room:useCard(use)
  if player.dead then return end
  W.revealHands(room, player, x)
  if player.dead then return end
  local victims = {}
  for victim, amount in pairs(use.damageDealt or {}) do
    if amount > 0 and not victim.dead and victim ~= player then table.insert(victims, victim) end
  end
  room:sortByAction(victims)
  if #victims == 0 then return end
  local backwater = room:askToChoice(player, {
    choices = { "bo__dansi-normal", "bo__dansi-backwater" },
    skill_name = "bo__dansi",
    prompt = "#bo__dansi-backwater",
  }) == "bo__dansi-backwater"
  if backwater then room:setPlayerMark(player, W.backwater, 1) end
  for _, victim in ipairs(victims) do
    if player.dead then break end
    if not victim.dead then
      local choice
      if not backwater then
        local choices = { "bo__dansi-phase" }
        if #W.revealedCards(victim) >= x then table.insert(choices, 1, "bo__dansi-cards") end
        choice = room:askToChoice(victim, {
          choices = choices,
          all_choices = { "bo__dansi-cards", "bo__dansi-phase" },
          skill_name = "bo__dansi",
          prompt = "#bo__dansi-pay::" .. player.id .. ":" .. x,
        })
      end
      if backwater or choice == "bo__dansi-cards" then W.giveCards(room, victim, player, x) end
      if backwater or choice == "bo__dansi-phase" then W.giveDrawPhase(room, victim, player) end
    end
  end
  W.settleBackwater(player)
end

return W
