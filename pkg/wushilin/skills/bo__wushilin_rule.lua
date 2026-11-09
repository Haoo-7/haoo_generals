local W = require "packages.haoo_generals.wushilin"
local skill = fk.CreateSkill {
  name = "#bo__wushilin_rule",
  tags = { Skill.Compulsory },
}

skill:addEffect(fk.TurnStart, {
  global = true,
  can_refresh = function(self, event, target, player, data) return target == player end,
  on_refresh = function(self, event, target, player, data)
    W.beginTurn(player.room, player)
    W.settleBackwater(player)
  end,
})

skill:addEffect(fk.TurnEnd, {
  global = true,
  late_refresh = true,
  can_refresh = function(self, event, target, player, data) return target == player end,
  on_refresh = function(self, event, target, player, data) W.endTurn(player.room) end,
})

skill:addEffect(fk.AfterCardsMove, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    return player.room:getTag(W.turn_tag) and W.gainedCards(player, data)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, W.gained, 1)
    W.removeBorrowed(player)
  end,
})

skill:addEffect(fk.CardUsing, {
  global = true,
  can_refresh = function(self, event, target, player, data) return data.from == player end,
  on_refresh = function(self, event, target, player, data) player.room:setPlayerMark(player, W.involved, 1) end,
})

skill:addEffect(fk.TargetSpecified, {
  global = true,
  can_refresh = function(self, event, target, player, data) return data.to == player end,
  on_refresh = function(self, event, target, player, data) player.room:setPlayerMark(player, W.involved, 1) end,
})

-- A transferred phase remains owed after Dansi/its owner is lost.
-- Consume each debt once even when another effect already skipped the phase.
for _, timing in ipairs({ fk.EventPhaseChanging, fk.EventPhaseSkipping }) do
  skill:addEffect(timing, {
    global = true,
    can_refresh = function(self, event, target, player, data)
      return target == player and data.phase == Player.Draw and not data.bo__dansi_skipped and player:getMark(W.skip_draw) > 0
    end,
    on_refresh = function(self, event, target, player, data)
      player.room:setPlayerMark(player, W.skip_draw, player:getMark(W.skip_draw) - 1)
      data.bo__dansi_skipped, data.skipped = true, true
    end,
  })
end

skill:addEffect(fk.EventPhaseEnd, {
  global = true,
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and data.phase == Player.Draw and not data.skipped and player:getMark(W.extra_draw) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local n = player:getMark(W.extra_draw)
    player.room:setPlayerMark(player, W.extra_draw, 0)
    for _ = 1, n do player:gainAnExtraPhase(Player.Draw, "bo__dansi") end
  end,
})

skill:addEffect("visibility", {
  global = true,
  card_visible = function(self, player, card)
    if card:getMark(W.revealed) > 0 and Fk:currentRoom():getCardArea(card.id) == Card.PlayerHand then return true end
  end,
  move_visible = function(self, player, info, move)
    if info.fromArea == Card.PlayerHand and info.beforeCard and info.beforeCard:getMark(W.revealed) > 0 then return true end
  end,
})

skill:addEffect("invalidity", {
  global = true,
  invalidity_func = function(self, player, target_skill)
    local skel = target_skill:getSkeleton()
    if skel and table.contains(player:getTableMark(W.granted), skel.name) and not player:hasSkill("bo__jige") then return true end
  end,
})

Fk:loadTranslationTable {
  ["#bo__wushilin_rule"] = "吾是琳·延迟结算",
  ["@@bo__dansi-inhand"] = "明置",
  ["@bo__dansi_skip"] = "交出摸牌阶段",
  ["@bo__dansi_draw"] = "获赠摸牌阶段",
  ["@bo__dansi_duanchang"] = "待断肠",
  ["#bo__dansi-transfer"] = "%from 因“%arg”将下个摸牌阶段交给 %to",
}

return skill
