local xiongbian = fk.CreateSkill {
  name = "bo__xiongbian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["bo__xiongbian"] = "雄辩",
  [":bo__xiongbian"] = "锁定技，当其他角色响应你的牌时，其获得“雄乱”标记。",
  ["@@xiongluan-turn"] = "雄乱",
}

-- 与张绣【雄乱】共用 @@xiongluan-turn 标记：标记在获得它的那个回合结束时自动清除，任何回合都可获得
local function canTrigger(self, event, target, player, data)
  return player:hasSkill(xiongbian.name) and not player.dead and target ~= player and
    data.responseToEvent ~= nil and data.responseToEvent.from == player
end

local function onTrigger(self, event, target, player, data)
  local room = player.room
  room:addPlayerMark(target, "@@xiongluan-turn")
  if HaooGenerals_XiongqiEvaluate then
    HaooGenerals_XiongqiEvaluate(player)
  end
end

-- 杀被闪抵消走“使用”(CardUseFinished)，南蛮/决斗打出杀走“打出”(CardResponding)
xiongbian:addEffect(fk.CardUseFinished, {
  mute = true,
  can_trigger = canTrigger,
  on_cost = Util.TrueFunc,
  on_use = onTrigger,
})

xiongbian:addEffect(fk.CardResponding, {
  mute = true,
  can_trigger = canTrigger,
  on_cost = Util.TrueFunc,
  on_use = onTrigger,
})

-- 与张绣【雄乱】相同的限制：雄乱角色不能使用或打出手牌
xiongbian:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:getMark("@@xiongluan-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or { card.id }
      return #subcards > 0 and
        table.every(subcards, function(id)
          return table.contains(player:getCardIds("h"), id)
        end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@@xiongluan-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or { card.id }
      return #subcards > 0 and
        table.every(subcards, function(id)
          return table.contains(player:getCardIds("h"), id)
        end)
    end
  end,
})

return xiongbian
