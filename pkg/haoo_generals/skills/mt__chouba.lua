local M = require "packages.haoo_generals.motian"
local skill = fk.CreateSkill {
  name = "mt__chouba",
}

local function hasJudged(room, to)
  return #room.logic:getEventsOfScope(GameEvent.Judge, 1, function(e)
    return e.data.who == to
  end, Player.HistoryTurn) > 0
end

local function targets(room)
  return table.filter(room.alive_players, function(p)
    return not p.dead and not hasJudged(room, p)
  end)
end

local spec = {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and #targets(player.room) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local candidates = targets(player.room)
    if #candidates == 0 then return false end
    local chosen = player.room:askToChoosePlayers(player, {
      targets = candidates,
      min_num = 1,
      max_num = 1,
      cancelable = true,
      skill_name = skill.name,
      prompt = "#mt__chouba-choose",
    })
    if #chosen == 0 then return false end
    event:setCostData(self, { tos = chosen })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if to.dead or hasJudged(room, to) then return end
    local judge = { who = to, reason = skill.name, pattern = "." }
    room:judge(judge)
    -- Interrupted judgments have no valid result; normal Tiandu may already
    -- have taken the card, so read its final suit regardless of current area.
    local card = rawget(judge, "card")
    if not judge.results or #judge.results == 0 or not card or player.dead then return end
    if not table.contains({ Card.Spade, Card.Heart, Card.Club, Card.Diamond }, card.suit) then return end
    local suit = card:getSuitString(true)
    local suits = to:getTableMark(M.suits)
    if table.contains(suits, suit) then
      if not to.dead then room:damage { from = player, to = to, damage = 1, skillName = skill.name } end
    else
      table.insert(suits, suit)
      room:setPlayerMark(to, M.suits, suits)
      player:drawCards(#suits, skill.name)
    end
  end,
}

skill:addEffect(fk.Damage, spec)
skill:addEffect(fk.Damaged, spec)

Fk:loadTranslationTable {
  ["mt__chouba"] = "筹拔",
  [":mt__chouba"] = "你造成或受到伤害后可令本回合未判定过的角色判定，若判定花色已记录，你对其造成一点伤害，否则你记录并摸其已记录花色张牌。",
  ["#mt__chouba-choose"] = "筹拔：你可以令本回合未判定过的角色判定；已记录花色则对其造成1点伤害，否则记录并按其花色数摸牌",
  ["@mt__chouba-noclear"] = "筹拔花色",
}

return skill
