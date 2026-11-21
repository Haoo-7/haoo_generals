local L = require "packages.haoo_generals.sp_lin"
local skill = L.skill("ts__tianhou", "ts__lin_hou", { Skill.Compulsory })

local function pendingIds(data, player, other)
  local ids = {}
  for _, move in ipairs(data) do
    if move.to == player and move.toArea == Card.PlayerHand and move.from == other then
      for _, info in ipairs(move.moveInfo) do
        if info.fromArea == Card.PlayerHand and
          table.contains(other:getCardIds("h"), info.cardId) then
          table.insertIfNeed(ids, info.cardId)
        end
      end
    end
  end
  return ids
end

skill:addEffect(fk.BeforeCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and table.find(data, function(move)
      return move.from and move.from ~= player and not move.from.dead and
        #pendingIds(data, player, move.from) > 0
    end) ~= nil
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room, others = player.room, {}
    for _, move in ipairs(data) do
      if move.from and move.from ~= player and #pendingIds(data, player, move.from) > 0 then
        table.insertIfNeed(others, move.from)
      end
    end
    room:sortByAction(others)
    for _, other in ipairs(others) do
      if player.dead then break end
      local ids = pendingIds(data, player, other)
      if not other.dead and #ids > 0 and room:askToSkillInvoke(other, {
        skill_name = skill.name, prompt = "#ts__tianhou-pay:" .. player.id,
      }) then
        -- Cancel before HP loss: dying/death may itself move these cards.
        room:cancelMove(data, ids, function(move, info)
          return move.to == player and move.toArea == Card.PlayerHand and
            move.from == other and info.fromArea == Card.PlayerHand
        end)
        room:loseHp(other, 1, skill.name)
        if not player.dead then
          room:recover { who = player, num = 1, recoverBy = other, skillName = skill.name }
        end
      end
    end
    if player.dead then
      room:cancelMove(data, nil, function(move) return move.to == player end)
    end
  end,
})

skill:addEffect(fk.DamageCaused, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and data.from == player and player:hasSkill(skill.name) and
      not L.isAwake(player) and data.to:isKongcheng() and data.damage > 0 and not data.prevented
  end,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
  end,
})

Fk:loadTranslationTable {
  ["ts__tianhou"] = "天侯",
  ["ts__lin_hou"] = "侯",
  [":ts__tianhou"] = "锁定技，当你将获得其他角色的手牌时，其可交给你1点体力防止之，你无法对没有手牌的角色造成伤害。",
  [":ts__tianhou_awakened"] = "锁定技，当你将获得其他角色的手牌时，其可交给你1点体力防止之。",
  ["#ts__tianhou-pay"] = "天侯：是否失去1点体力，令%src回复1点体力，防止其本次获得你的手牌？",
}

return skill
