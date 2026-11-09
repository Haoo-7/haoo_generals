local Qu = {}

Qu.mark = "@@tongqu"
Qu.enabled_tag = "honggui_qu_enabled"

function Qu.has(player)
  return player:getMark(Qu.mark) > 0
end

function Qu.protected(player)
  return player:hasSkill("hg__dongshen")
end

function Qu.add(room, player)
  if not player.dead and not Qu.has(player) then
    room:setTag(Qu.enabled_tag, true)
    room:setPlayerMark(player, Qu.mark, 1)
  end
end

function Qu.remove(room, player)
  if not player.dead and Qu.has(player) and not Qu.protected(player) then
    room:setPlayerMark(player, Qu.mark, 0)
    return true
  end
  return false
end

function Qu.holders(room, removable)
  return table.filter(room.alive_players, function(p)
    return Qu.has(p) and (not removable or not Qu.protected(p))
  end)
end

function Qu.discardCounts(room)
  local counts = {}
  room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
    for _, move in ipairs(e.data) do
      if move.from and move.moveReason == fk.ReasonDiscard then
        local id = move.from.id
        counts[id] = (counts[id] or 0) + #move.moveInfo
      end
    end
    return false
  end, Player.HistoryTurn)
  return counts
end

return Qu
