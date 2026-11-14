local G = require "packages.haoo_generals.guozhou"
local skill = fk.CreateSkill {
  name = "#sha__guozhou_rule",
  tags = { Skill.Compulsory },
}

-- These are card rules. They must survive the temporary loss of all three
-- printed skills while the card is face down. Real replacement ends the
-- reset/return rules, but retains the playable Guo Jia back face.
skill:addEffect(fk.GameStart, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    return not player.dead and G.hasCard(player)
  end,
  on_refresh = function(self, event, target, player, data)
    G.syncFace(player.room, player)
    G.refilter(player)
  end,
})

skill:addEffect(fk.RoundStart, {
  global = true,
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and G.hasCard(player) and (not player.faceup or player.chained)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:reset()
  end,
})

skill:addEffect(fk.TurnedOver, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and not player.dead and G.hasRules(player) and player:getMark(G.internal) == 0
  end,
  on_refresh = function(self, event, target, player, data)
    G.syncFace(player.room, player)
  end,
})

skill:addEffect(fk.BeforePropertyChange, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    if target ~= player or player:getMark(G.internal) ~= 0 or not G.protected(player) then return false end
    local slot = G.nativeSlot(player) or "general"
    return data[slot] ~= nil and data[slot] ~= player[slot]
  end,
  on_refresh = function(self, event, target, player, data)
    local slot = G.nativeSlot(player) or "general"
    data[slot] = player[slot]
    if slot == "general" then
      data.gender, data.kingdom = player.gender, player.kingdom
    end
    player.room:sendLog { type = "#sha__jimi-prevent", from = player.id, arg = "sha__jimi" }
  end,
})

skill:addEffect(fk.AfterPropertyChange, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and not player.dead and player:getMark(G.internal) == 0 and G.hasRules(player)
  end,
  on_refresh = function(self, event, target, player, data)
    G.syncFace(player.room, player)
  end,
})

Fk:loadTranslationTable {
  ["#sha__guozhou_rule"] = "技密·武将牌规则",
}

return skill
