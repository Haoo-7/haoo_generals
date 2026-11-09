local Qu = require "packages.haoo_generals.qu"
local skill = fk.CreateSkill {
  name = "hg__dongshen",
  tags = { Skill.Compulsory },
}

skill:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not target or target.phase ~= Player.Finish or not player:hasSkill(skill.name) then
      return false
    end
    local counts = Qu.discardCounts(player.room)
    return #Qu.holders(player.room, true) > 0 and
      table.find(player.room.alive_players, function(p)
        return Qu.has(p) and (counts[p.id] or 0) > 0
      end) ~= nil
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    -- Freeze every player's discard count before any optional removal resolves.
    local counts = Qu.discardCounts(room)
    local actors = table.filter(room:getAlivePlayers(), function(p)
      return Qu.has(p) and (counts[p.id] or 0) > 0
    end)
    for _, p in ipairs(actors) do
      if player.dead or not player:hasSkill(skill.name) then break end
      if not p.dead and Qu.has(p) then
        local targets = Qu.holders(room, true)
        local limit = math.min(counts[p.id], #targets)
        if limit > 0 then
          local chosen = room:askToChoosePlayers(p, {
            targets = targets,
            min_num = 1,
            max_num = limit,
            cancelable = true,
            skill_name = skill.name,
            prompt = "#hg__dongshen-remove:::" .. counts[p.id],
          })
          room:sortByAction(chosen)
          for _, to in ipairs(chosen) do
            Qu.remove(room, to)
          end
        end
      end
    end
  end,
})

skill:addEffect("visibility", {
  card_visible = function(self, player, card)
    if player:hasSkill(skill.name) then
      local room = Fk:currentRoom()
      local owner = room:getCardOwner(card.id)
      if owner and not owner.dead and Qu.has(owner) and room:getCardArea(card.id) == Card.PlayerHand then
        return true
      end
    end
  end,
  move_visible = function(self, player, info, move)
    if player:hasSkill(skill.name) then
      local room = Fk:currentRoom()
      local from = type(move.from) == "number" and room:getPlayerById(move.from) or move.from
      local to = type(move.to) == "number" and room:getPlayerById(move.to) or move.to
      if (from and not from.dead and Qu.has(from) and info.fromArea == Card.PlayerHand) or
        (to and not to.dead and Qu.has(to) and move.toArea == Card.PlayerHand) then
        return true
      end
    end
  end,
})

Fk:loadTranslationTable {
  ["hg__dongshen"] = "洞深",
  [":hg__dongshen"] = "你不会失去渠。拥有渠的角色始终向你明牌，其可于回合内弃置过x张牌的结束阶段移除场上至多x个渠。",
  ["#hg__dongshen-remove"] = "洞深：你本回合弃置了 %arg 张牌，可以选择至多 %arg 名角色，移除其“渠”",
}

return skill
