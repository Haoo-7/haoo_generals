local G = {}

G.general = "sha__guozhou"
G.back_general = "ex__guojia"
G.back = "sha__guozhou_back"
G.permanent = "sha__guozhou_permanent_back"
G.internal = "sha__guozhou_switching"
G.unlocked = "sha__jiahao_unlocked"
G.round_count = "@sha__manbo-round"
G.choices = { "sha__jiahao_1", "sha__jiahao_2", "sha__jiahao_3", "sha__jiahao_4", "sha__jiahao_5" }

function G.count(player)
  -- Zero is a real value: there is no minimum of one.
  return player:getMark(G.round_count)
end

function G.nativeSlot(player)
  if player.general == G.general then return "general" end
  if player.deputyGeneral == G.general then return "deputyGeneral" end
end

function G.hasCard(player)
  return G.nativeSlot(player) ~= nil or type(player:getMark(G.back)) == "table"
end

function G.hasRules(player)
  return G.hasCard(player) or type(player:getMark(G.permanent)) == "table"
end

function G.hasPlayableBack(player)
  for _, mark in ipairs({G.back, G.permanent}) do
    local state = player:getMark(mark)
    if type(state) == "table" and player[state.slot] == G.back_general then return true end
  end
  return false
end

function G.installTurnRule(room)
  local logic = room.logic
  if logic.sha__guozhou_turn_rule then return end
  logic.sha__guozhou_turn_rule = true
  local trigger = logic.trigger
  local pending = setmetatable({}, { __mode = "k" })
  -- 0.5.25 checks faceup directly between PreTurnStart and BeforeTurnStart.
  -- Adapt only that check, after all PreTurnStart skills have finished and
  -- before any BeforeTurnStart skill runs. No fake flip is sent to clients.
  -- Keep the native turn/phase events, cancellation and extra-turn handling.
  logic.trigger = function(self, kind, target, data, ...)
    if kind == fk.BeforeTurnStart and pending[data] then
      pending[data].faceup = false
      pending[data] = nil
    end
    local result = table.pack(trigger(self, kind, target, data, ...))
    if kind == fk.PreTurnStart and target and data and data.who == target and not data.turn_end then
      if not target.dead and not target.faceup and G.hasPlayableBack(target) then
        pending[data] = target
        target.faceup = true
      end
    end
    return table.unpack(result, 1, result.n)
  end
end

function G.protected(player)
  return player:hasSkill("sha__jimi") and player:getMark(G.unlocked) == 0
end

function G.refilter(player)
  for _, id in ipairs(player:getCardIds("he")) do
    -- Broadcast the same refresh to clients, including installed equipment.
    player.room:filterCard(id, player)
  end
end

local function available(room, player)
  if Fk.generals[G.back_general] then return true end
  room:sendLog { type = "#sha__guozhou-missing", from = player.id }
  return false
end

function G.syncFace(room, player)
  G.installTurnRule(room)
  if player.dead or player:getMark(G.internal) ~= 0 then return end
  local permanent = player:getMark(G.permanent)
  if type(permanent) == "table" and player[permanent.slot] ~= G.back_general then
    room:setPlayerMark(player, G.permanent, 0)
  end
  local state = player:getMark(G.back)
  local slot = G.nativeSlot(player)
  if not player.faceup and slot then
    if not available(room, player) then return end
    room:setPlayerMark(player, G.back, { slot = slot, kingdom = player.kingdom })
    room:setPlayerMark(player, G.internal, 1)
    -- A temporary back face retains current HP and maximum HP, including
    -- the lord bonus (ordinary 4, lord 5). It is not a fresh 3-HP Guo Jia.
    room:changeHero(player, G.back_general, false, slot == "deputyGeneral", true, false, false)
    room:changeKingdom(player, "wei")
    room:setPlayerMark(player, G.internal, 0)
    if player[slot] ~= G.back_general then room:setPlayerMark(player, G.back, 0) end
    G.refilter(player)
  elseif player.faceup and type(state) == "table" then
    if player[state.slot] ~= G.back_general then
      room:setPlayerMark(player, G.back, 0)
      return
    end
    room:setPlayerMark(player, G.internal, 1)
    room:changeHero(player, G.general, false, state.slot == "deputyGeneral", true, false, false)
    room:changeKingdom(player, state.kingdom)
    room:setPlayerMark(player, G.internal, 0)
    room:setPlayerMark(player, G.back, 0)
    G.refilter(player)
  elseif type(state) == "table" and player[state.slot] ~= G.back_general then
    -- An external replacement of the back face ends the original card rule.
    room:setPlayerMark(player, G.back, 0)
  end
end

function G.replace(room, player)
  if G.protected(player) then
    room:sendLog { type = "#sha__jimi-prevent", from = player.id, arg = "sha__jimi" }
    return false
  end
  if not available(room, player) then return false end
  local state = player:getMark(G.back)
  local permanent = player:getMark(G.permanent)
  local slot = G.nativeSlot(player) or (type(state) == "table" and state.slot) or
    (type(permanent) == "table" and permanent.slot) or "general"
  local keepBack = G.hasRules(player)
  room:setPlayerMark(player, G.internal, 1)
  -- This is a real, permanent replacement. Use the engine's normal Guo Jia
  -- maximum HP (and normal mode/lord adjustments), without healing.
  room:changeHero(player, G.back_general, false, slot == "deputyGeneral", true)
  room:setPlayerMark(player, G.internal, 0)
  if player[slot] == G.back_general then
    if keepBack then
      room:setPlayerMark(player, G.permanent, { slot = slot })
      G.installTurnRule(room)
    end
    room:setPlayerMark(player, G.back, 0)
    G.refilter(player)
    return true
  end
  return false
end

function G.candidates(owner, actor)
  if actor.dead or owner.dead then return {} end
  return table.filter(owner.room.alive_players, function(p)
    return not p.dead and actor:canPindian(p) and
      (actor:getHandcardNum() <= owner:getHandcardNum() or p == owner)
  end)
end

function G.execute(room, player, other, items, x, reason)
  items = table.simpleClone(items)
  table.sort(items)
  for _, item in ipairs(items) do
    if player.dead then break end
    if item == 1 then
      G.replace(room, player)
    elseif item == 2 then
      room:damage { to = player, damage = 1, skillName = reason }
    elseif item == 3 then
      if player.faceup then player:turnOver() end
      if not player.dead and x > 0 then player:drawCards(x, reason) end
    elseif item == 4 then
      if other and not other.dead and other ~= player and not player:isNude() then
        local cards = room:askToCards(player, {
          min_num = math.min(x, #player:getCardIds("he")),
          max_num = #player:getCardIds("he"),
          include_equip = true,
          cancelable = false,
          skill_name = reason,
          prompt = "#sha__jiahao-give::" .. other.id .. ":" .. x,
        })
        if #cards > 0 and not player.dead and not other.dead then
          room:moveCardTo(cards, Card.PlayerHand, other, fk.ReasonGive, reason, nil, false, player)
        end
      end
    elseif item == 5 then
      for _ = 1, x + 1 do
        if player.dead then break end
        local judge = { who = player, reason = "lightning", pattern = ".|2~9|spade" }
        room:judge(judge)
        if not player.dead and judge.results and judge:matchPattern() then
          room:damage {
            to = player,
            damage = 3,
            damageType = fk.ThunderDamage,
            card = Fk:cloneCard("lightning"),
            skillName = reason,
          }
        end
      end
    end
  end
end

return G
