local tianming = fk.CreateSkill {
  name = "ts__tianming",
}

local kinds = { "ts__bet_cards", "ts__bet_hp", "ts__bet_maxhp" }
local debt_marks = {
  ts__bet_cards = "@ts__tianming_debt_cards",
  ts__bet_hp = "@ts__tianming_debt_hp",
  ts__bet_maxhp = "@ts__tianming_debt_maxhp",
}

local function settle(room, player, debt)
  if player.dead then return end
  local n = 2 * debt.n
  local mark = debt_marks[debt.kind]
  room:setPlayerMark(player, mark, math.max(0, player:getMark(mark) - n))
  if debt.kind == "ts__bet_cards" then
    room:askToDiscard(player, {
      min_num = n, max_num = n, include_equip = false,
      skill_name = tianming.name, cancelable = false,
      prompt = "#ts__tianming-pay:::" .. n,
    })
  elseif debt.kind == "ts__bet_hp" then
    room:loseHp(player, n, tianming.name)
  else
    room:changeMaxHp(player, -math.min(n, math.max(0, player.maxHp - 1)))
  end
end

tianming:addEffect("active", {
  anim_type = "support",
  prompt = "#ts__tianming-active",
  card_num = 0,
  target_num = 0,
  max_phase_use_time = 3,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player.phase == Player.Play and table.find(kinds, function(kind)
      return player:getMark("ts__tianming_" .. kind .. "-phase") == 0
    end) ~= nil
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local choices = table.filter(kinds, function(kind)
      return player:getMark("ts__tianming_" .. kind .. "-phase") == 0
    end)
    if #choices == 0 then return end
    local kind = room:askToChoice(player, {
      choices = choices, skill_name = tianming.name, prompt = "#ts__tianming-kind",
    })
    local n = room:askToNumber(player, {
      min = 1, max = 5, skill_name = tianming.name,
      prompt = "#ts__tianming-number", cancelable = false,
    })
    room:setPlayerMark(player, "ts__tianming_" .. kind .. "-phase", 1)
    -- Install debt before granting the benefit, so nested events cannot lose it.
    local debts = player:getTableMark("ts__tianming_debts")
    table.insert(debts, { kind = kind, n = n, pending = true })
    room:setPlayerMark(player, "ts__tianming_debts", debts)
    room:addPlayerMark(player, debt_marks[kind], 2 * n)
    room:setPlayerMark(player, "@ts__tianming_forced-turn",
      math.max(n, player:getMark("@ts__tianming_forced-turn")))
    if kind == "ts__bet_cards" then
      player:drawCards(n, tianming.name)
    elseif kind == "ts__bet_hp" then
      room:recover { who = player, num = n, recoverBy = player, skillName = tianming.name }
    else
      room:changeMaxHp(player, n)
    end
  end,
})

-- Obligations survive losing the skill. Refresh runs without a skill invocation prompt.
tianming:addEffect(fk.TurnEnd, {
  can_refresh = function(self, event, target, player, data)
    return target == player and #player:getTableMark("ts__tianming_debts") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local keep, due = {}, {}
    for _, debt in ipairs(player:getTableMark("ts__tianming_debts")) do
      if debt.pending then
        if player:getMark("ts__duidu_count-turn") < debt.n then
          table.insert(due, debt)
        else
          debt.pending = false
          table.insert(keep, debt)
        end
      else
        table.insert(keep, debt)
      end
    end
    room:setPlayerMark(player, "ts__tianming_debts", keep)
    for _, debt in ipairs(due) do settle(room, player, debt) end
  end,
})

tianming:addEffect(fk.EventPhaseStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and
      table.find(player:getTableMark("ts__tianming_debts"), function(debt) return not debt.pending end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local keep, due = {}, {}
    for _, debt in ipairs(player:getTableMark("ts__tianming_debts")) do
      if debt.pending then table.insert(keep, debt) else table.insert(due, debt) end
    end
    room:setPlayerMark(player, "ts__tianming_debts", keep)
    for _, debt in ipairs(due) do settle(room, player, debt) end
  end,
})

return tianming
