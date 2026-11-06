local wuyi = fk.CreateSkill {
  name = "haoo__wuyi",
}

Fk:loadTranslationTable {
  ["haoo__wuyi"] = "五一",
  [":haoo__wuyi"] = "当你弃置了点数和为15的因数或倍数的牌后，你可视为使用一张无距离限制的【杀】。",
  ["#haoo__wuyi-invoke"] = "五一：你可以视为使用一张无距离限制的【杀】",
  ["#haoo__wuyi-choose"] = "五一：请选择【杀】的目标",
}

-- 点数和为15的因数或倍数：1、3、5 或 15 的倍数
local function isFactorOrMultipleOf15(sum)
  return sum == 1 or sum == 3 or sum == 5 or sum % 15 == 0
end

wuyi:addEffect(fk.AfterCardsMove, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(wuyi.name) or player.dead then return false end
    local sum, n = 0, 0
    for _, move in ipairs(data) do
      if move.from == player and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          sum = sum + Fk:getCardById(info.cardId).number
          n = n + 1
        end
      end
    end
    return n > 0 and isFactorOrMultipleOf15(sum)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = wuyi.name,
      prompt = "#haoo__wuyi-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p ~= player
    end)
    if #targets == 0 then return end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = wuyi.name,
      prompt = "#haoo__wuyi-choose",
      cancelable = true,
    })
    if #tos == 0 then return end
    room:useVirtualCard("slash", nil, player, tos[1], wuyi.name, true)
  end,
})

return wuyi
