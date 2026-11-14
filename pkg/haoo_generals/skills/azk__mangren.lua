local A = require "packages.haoo_generals.aizhake"
local skill = fk.CreateSkill {
  name = A.mangren,
}

skill:addEffect(fk.BeforeCardsMove, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    local ids = A.pendingStars(player, data)
    return player:hasSkill(skill.name) and #ids > 0 and #A.legalTargets(player, ids) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local ids = A.pendingStars(player, data)
    local targets = A.legalTargets(player, ids)
    local chosen = player.room:askToChoosePlayers(player, {
      targets = targets, min_num = 1, max_num = math.min(#ids, #targets),
      cancelable = true, skill_name = skill.name,
      prompt = "#azk__mangren-targets:::" .. #ids .. ":" .. (#ids + 1),
    })
    if #chosen > 0 then
      event:setCostData(self, { cards = ids, tos = chosen })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local cost = event:getCostData(self)
    local room = player.room
    local pending, valid = A.pendingStars(player, data), A.legalTargets(player, cost.cards)
    if player.dead or #cost.tos == 0 or #cost.tos > #cost.cards then return end
    for _, id in ipairs(cost.cards) do if not table.contains(pending, id) then return end end
    for _, p in ipairs(cost.tos) do if not table.contains(valid, p) then return end end
    local moveEvent = room.logic:getCurrentEvent():findParent(GameEvent.MoveCards, true)
    if not moveEvent then return end

    -- Redirect only the substituted stars. They leave the pile in the SAME
    -- MoveCards event as the replacement handcards, without entering the hand.
    -- Resolving useCard here would interrupt that event before handcards leave.
    local redirected = {}
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerHand then
        local infos = table.filter(move.moveInfo, function(info)
          return table.contains(cost.cards, info.cardId)
        end)
        if #infos > 0 then
          table.insert(redirected, MoveCardsData:new {
            moveInfo = infos, from = move.from, toArea = Card.Processing,
            moveReason = fk.ReasonUse, skillName = skill.name,
            proposer = player, moveVisible = true,
          })
        end
      end
    end
    room:cancelMove(data, cost.cards)
    table.insertTable(data, redirected)
    moveEvent:addExitFunc(function()
      local ready = not player.dead
      for _, id in ipairs(cost.cards) do ready = ready and room:getCardArea(id) == Card.Processing end
      local targets = A.legalTargets(player, cost.cards)
      for _, p in ipairs(cost.tos) do ready = ready and table.contains(targets, p) end
      if ready then
        room:useCard {
          from = player, tos = cost.tos, card = A.slash(cost.cards),
          additionalDamage = #cost.cards - #cost.tos, extraUse = false,
        }
      end
      room:cleanProcessingArea(cost.cards, skill.name)
    end)
  end,
})

skill:addEffect("targetmod", {
  bypass_distances = function(self, player, cardSkill, card)
    return card and table.contains(card.skillNames, A.mangren)
  end,
  extra_target_func = function(self, player, cardSkill, card)
    if card and table.contains(card.skillNames, A.mangren) then return math.max(#card.subcards - 1, 0) end
  end,
})

Fk:loadTranslationTable {
  ["azk__mangren"] = "茫刃",
  [":azk__mangren"] = "你获得x张星时可改为将之当伤害与目标数和为x＋1的雷杀无距离限制使用。",
  ["#azk__mangren-targets"] = "茫刃：你将获得 %arg 张星，可选择雷【杀】的目标；基础伤害＝%arg2－目标数，取消则正常获得星",
}

return skill
