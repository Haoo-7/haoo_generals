local A = {
  general = "azk__aizhake",
  pile = "#azk_star",
  xingye = "azk__xingye",
  mangren = "azk__mangren",
  qixing = "azk__qixing",
  busyTag = "azk__star_busy_",
  orderTag = "azk__star_order_",
  knownMark = "azk__known_stars",
  viewMark = "@[azk_star]",
}

function A.known(player, id)
  return table.contains(player:getTableMark(A.knownMark), id)
end

function A.sync(player)
  local room = player.room
  local wanted = room:getTag(A.orderTag .. player.id)
  if wanted then
    local actual = player:getPile(A.pile)
    local ordered = table.filter(wanted, function(id) return table.contains(actual, id) end)
    for _, id in ipairs(actual) do table.insertIfNeed(ordered, id) end
    -- Refresh the slots before any post-move skill can suspend for input.
    room:setPlayerPile(player, A.pile, ordered)
  end
  room:setPlayerMark(player, A.viewMark, #player:getPile(A.pile))
end

-- A dedicated live inspector preserves unknown slots instead of filtering them
-- out like the standard ViewPile popup. '#' suppresses the duplicate pile icon.
Fk:addQmlMark {
  name = "azk_star",
  how_to_show = function(name, value, player)
    return tostring(#player:getPile(A.pile))
  end,
  qml = function(name, value, player)
    return {
      url = "packages/haoo_generals/qml/AizhakeStarView.qml",
      prop = { ownerId = player.id },
    }
  end,
}

Fk:addPoxiMethod {
  name = "azk__star_required",
  card_filter = Util.TrueFunc,
  feasible = function(selected, result, original)
    if not result[1] or not original[1] then return false end
    local count = 0
    for i, id in ipairs(result[1]) do
      if id ~= original[1][i] then count = count + 1 end
    end
    return count == 1
  end,
}

-- Slots are fixed. Exchanging a star replaces its slot rather than sorting it.
function A.isIncreasing(ids)
  if #ids ~= 7 then return false end
  for i = 2, 7 do
    if Fk:getCardById(ids[i - 1]).number >= Fk:getCardById(ids[i]).number then return false end
  end
  return true
end

function A.busy(player)
  return (player.room:getTag(A.busyTag .. player.id) or 0) > 0
end

function A.lock(player, delta)
  local room, key = player.room, A.busyTag .. player.id
  local depth = (room:getTag(key) or 0) + delta
  room:setTag(key, depth > 0 and depth or nil)
end

function A.viewers(player)
  return table.filter(player.room.players, function(p) return p ~= player end)
end

function A.seed(player, from)
  player.room:setPlayerMark(player, A.knownMark, 0)
  local ids = player.room:getNCards(7, from or "top")
  if #ids > 0 then player:addToPile(A.pile, ids, false, A.xingye, player, A.viewers(player)) end
  A.sync(player)
end

function A.check(player)
  if player.dead or not player:hasSkill(A.xingye) or A.busy(player) then return end
  A.lock(player, 1)
  while not player.dead and player:hasSkill(A.xingye) and A.isIncreasing(player:getPile(A.pile)) do
    local room, stars = player.room, player:getPile(A.pile)
    room:obtainCard(player, stars, true, fk.ReasonJustMove, player, A.xingye)
    -- A replacement of the acquisition may leave cards where they were.
    -- Do not add seven more cards to a pile which was not actually cleared.
    if player.dead or not player:hasSkill(A.xingye) or #player:getPile(A.pile) > 0 then break end
    A.seed(player, "bottom")
  end
  A.lock(player, -1)
end

function A.exchange(owner, actor, incoming, outgoing, reveal, reason)
  local room, stars = owner.room, owner:getPile(A.pile)
  if owner.dead or actor.dead or #incoming == 0 or #incoming ~= #outgoing then return false end
  local hand = actor:getCardIds("h")
  local seen = {}
  for i, id in ipairs(incoming) do
    if seen[id] or seen[outgoing[i]] or not table.contains(hand, id) or
      not table.contains(stars, outgoing[i]) then return false end
    seen[id], seen[outgoing[i]] = true, true
  end
  local ordered = table.simpleClone(stars)
  for i, id in ipairs(outgoing) do ordered[table.indexOf(ordered, id)] = incoming[i] end
  A.lock(owner, 1)
  if reveal then actor:showCards(incoming) end
  -- Revealing can itself move cards or kill a participant.
  hand = actor:getCardIds("h")
  local valid = not owner.dead and not actor.dead
  for i, id in ipairs(incoming) do
    valid = valid and table.contains(hand, id) and table.contains(owner:getPile(A.pile), outgoing[i])
  end
  if valid then
    -- Remember identities before the move notification so the owner's client
    -- can show revealed cards (and their own handcards) immediately.
    local known = table.simpleClone(owner:getTableMark(A.knownMark))
    if reveal or actor == owner then
      for _, id in ipairs(incoming) do table.insertIfNeed(known, id) end
    end
    room:setPlayerMark(owner, A.knownMark, known)
    local orderKey = A.orderTag .. owner.id
    local previousOrder = room:getTag(orderKey)
    room:setTag(orderKey, ordered)
    room:moveCards({
      ids = incoming, from = actor, to = owner, toArea = Card.PlayerSpecial,
      specialName = A.pile, moveReason = fk.ReasonExchange, skillName = reason,
      proposer = actor, moveVisible = false, visiblePlayers = A.viewers(owner),
    }, {
      ids = outgoing, from = owner, to = actor, toArea = Card.PlayerHand,
      moveReason = fk.ReasonExchange, skillName = reason,
      proposer = actor, moveVisible = false, visiblePlayers = actor,
    })
    room:setTag(orderKey, previousOrder)
    local actual = owner:getPile(A.pile)
    ordered = table.filter(ordered, function(id) return table.contains(actual, id) end)
    for _, id in ipairs(actual) do table.insertIfNeed(ordered, id) end
    -- This native API changes only display/order, without creating fake moves.
    room:setPlayerPile(owner, A.pile, ordered)
    known = table.filter(known, function(id) return table.contains(ordered, id) end)
    room:setPlayerMark(owner, A.knownMark, #known > 0 and known or 0)
    A.sync(owner)
  end
  A.lock(owner, -1)
  A.check(owner)
  return valid
end

local function same(a, b)
  if #a ~= #b then return false end
  for i, id in ipairs(a) do if id ~= b[i] then return false end end
  return true
end

-- Validate the complete permutation on the server. An original star may stay
-- in its slot or leave the pile; it can never migrate to a different slot.
function A.parseArrangement(stars, hand, result, minimum, maximum)
  if type(result) ~= "table" or #result ~= 2 or type(result[1]) ~= "table" or
    type(result[2]) ~= "table" or #result[1] ~= #stars or #result[2] ~= #hand then return end
  local allowed, seen, incoming, outgoing = {}, {}, {}, {}
  for _, id in ipairs(stars) do allowed[id] = true end
  for _, id in ipairs(hand) do allowed[id] = true end
  for _, row in ipairs(result) do
    for _, id in ipairs(row) do
      if type(id) ~= "number" or not allowed[id] or seen[id] then return end
      seen[id] = true
    end
  end
  for i, id in ipairs(result[1]) do
    if id ~= stars[i] then
      if not table.contains(hand, id) then return end
      table.insert(incoming, id)
      table.insert(outgoing, stars[i])
    end
  end
  if #incoming < minimum or #incoming > maximum then return end
  return incoming, outgoing
end

function A.arrange(owner, actor, minimum, maximum, reason, reveal)
  if owner.dead or actor.dead or actor:isKongcheng() or #owner:getPile(A.pile) == 0 then return end
  local stars = table.simpleClone(owner:getPile(A.pile))
  local hand = actor:getCardIds("h")
  local visible = table.map(stars, function(id) return actor ~= owner or A.known(owner, id) end)
  local result = owner.room:askToCustomDialog(actor, {
    skill_name = reason,
    component = {
      url = "packages/haoo_generals/qml/AizhakeStarExchange.qml",
      model = {
        url = "packages/haoo_generals/qml/AizhakeStarModel.qml",
        prop = {
          origCards = { stars, hand }, areaNames = { A.pile, "$Hand" },
          areaCapacities = { #stars, #hand }, areaLimits = { #stars, #hand },
          visibleStars = visible, minimum = minimum, maximum = maximum,
          freeArrange = false, cancelable = minimum == 0, size = 7,
          poxiType = minimum == 1 and "azk__star_required" or "",
          prompt = maximum == 1 and "#azk__single-arrange" or "#azk__qixing-arrange",
        },
      },
    },
  })
  if owner.dead or actor.dead or not owner:hasSkill(A.xingye) or
    not same(stars, owner:getPile(A.pile)) or not same(hand, actor:getCardIds("h")) then return end
  local incoming, outgoing = A.parseArrangement(stars, hand, result, minimum, maximum)
  -- Timeout/invalid input must not cancel the owner's compulsory final swap.
  if not incoming and minimum == 1 then incoming, outgoing = { hand[1] }, { stars[1] } end
  if incoming and #incoming > 0 then A.exchange(owner, actor, incoming, outgoing, reveal, reason) end
end

function A.qixingExchange(player)
  A.arrange(player, player, 0, math.min(7, #player:getCardIds("h")), A.qixing, false)
end

function A.singleExchange(owner, actor, optional)
  A.arrange(owner, actor, optional and 0 or 1, 1, A.xingye, true)
end

function A.finish(player)
  local room = player.room
  local others = table.filter(room.alive_players, function(p) return p ~= player end)
  room:sortByAction(others)
  for _, other in ipairs(others) do
    if player.dead or not player:hasSkill(A.xingye) then return end
    A.singleExchange(player, other, true)
  end
  if player.dead or not player:hasSkill(A.xingye) then return end
  player:drawCards(1, A.xingye)
  if not player.dead and player:hasSkill(A.xingye) then A.singleExchange(player, player, false) end
end

function A.pendingStars(player, data)
  local ids = {}
  for _, move in ipairs(data) do
    if move.to == player and move.toArea == Card.PlayerHand then
      for _, info in ipairs(move.moveInfo) do
        if info.fromArea == Card.PlayerSpecial and info.fromSpecialName == A.pile then
          table.insertIfNeed(ids, info.cardId)
        end
      end
    end
  end
  return ids
end

function A.slash(ids)
  local card = Fk:cloneCard("thunder__slash")
  card.skillName = A.mangren
  card:addSubcards(ids)
  return card
end

function A.legalTargets(player, ids)
  local card = A.slash(ids)
  return table.filter(player.room.alive_players, function(p)
    return not p.dead and player:canUseTo(card, p, { bypass_distances = true })
  end)
end

return A
