local sheyi = fk.CreateSkill {
  name = "ts__sheyi",
}

local function protect(room, debtor, owner)
  local ids = debtor:getTableMark("ts__sheyi_protected-turn")
  table.insertIfNeed(ids, owner.id)
  room:setPlayerMark(debtor, "ts__sheyi_protected-turn", ids)
end

local function add_debt(room, debtor, owner, mark, n)
  local debts = debtor:getTableMark(mark)
  local debt = table.find(debts, function(d) return d.owner == owner.id end)
  if debt then debt.n = debt.n + n else table.insert(debts, { owner = owner.id, n = n }) end
  room:setPlayerMark(debtor, mark, debts)
end

sheyi:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(sheyi.name) and target and target ~= player and
      not target.dead and target.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(target, {
      skill_name = sheyi.name, prompt = "#ts__sheyi-take",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.dead or target.dead or player:isNude() then return end
    local cards = room:askToChooseCards(target, {
      target = player, flag = "he", min = 1, max = #player:getCardIds("he"),
      skill_name = sheyi.name, prompt = "#ts__sheyi-cards", cancelable = false,
    })
    if #cards == 0 then return end
    protect(room, target, player)
    -- Register after the initial acquisition: the borrowed cards do not repay this loan.
    room:obtainCard(target, cards, false, fk.ReasonPrey, target, sheyi.name)
    if not target.dead and not player.dead then
      add_debt(room, target, player, "ts__sheyi_card_debts", 2 * #cards)
    end
  end,
})

sheyi:addEffect(fk.DamageInflicted, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.from and
      table.contains(data.from:getTableMark("ts__sheyi_protected-turn"), player.id)
  end,
  on_refresh = function(self, event, target, player, data)
    data:preventDamage()
  end,
})

local function gained(room, player, data)
  local ids = {}
  for _, move in ipairs(data) do
    if move.to == player and move.from ~= player and
      (move.toArea == Card.PlayerHand or move.toArea == Card.PlayerEquip) then
      for _, info in ipairs(move.moveInfo) do
        local id = info.cardId
        local area = room:getCardArea(id)
        if room:getCardOwner(id) == player and
          (area == Card.PlayerHand or area == Card.PlayerEquip) then
          table.insertIfNeed(ids, id)
        end
      end
    end
  end
  return ids
end

sheyi:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player.dead or not player:hasSkill(sheyi.name) then return false end
    local room = player.room
    return table.find(room.players, function(debtor)
      return not debtor.dead and table.find(debtor:getTableMark("ts__sheyi_card_debts"),
        function(debt) return debt.owner == player.id and debt.n > 0 end) ~= nil and
        #gained(room, debtor, data) > 0
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player.dead then return end
    local transfers = {}
    for _, debtor in ipairs(room.players) do
      if not debtor.dead then
        local ids = gained(room, debtor, data)
        local keep = {}
        for _, debt in ipairs(debtor:getTableMark("ts__sheyi_card_debts")) do
          if debt.owner == player.id then
            local cards = {}
            while debt.n > 0 and #ids > 0 do
              table.insert(cards, table.remove(ids, 1))
              debt.n = debt.n - 1
            end
            if #cards > 0 then table.insert(transfers, { debtor = debtor, cards = cards }) end
            if debt.n > 0 then table.insert(keep, debt) end
          else
            table.insert(keep, debt)
          end
        end
        -- Debit all borrowers before any transfer can trigger nested AfterCardsMove events.
        room:setPlayerMark(debtor, "ts__sheyi_card_debts", keep)
      end
    end
    for _, transfer in ipairs(transfers) do
      if player.dead then return end
      local debtor = transfer.debtor
      if not debtor.dead then
        local cards = table.filter(transfer.cards, function(id) return room:getCardOwner(id) == debtor end)
        if #cards > 0 then
          room:moveCardTo(cards, Player.Hand, player, fk.ReasonGive, sheyi.name, nil, false, debtor)
        end
      end
    end
  end,
})

sheyi:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(sheyi.name) and target and target ~= player and
      not target.dead and target.hp < 1 and player.hp > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(target, {
      skill_name = sheyi.name, prompt = "#ts__sheyi-dying",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    protect(room, target, player)
    add_debt(room, target, player, "ts__sheyi_hp_debts", 2)
    room:recover { who = target, num = 1, recoverBy = player, skillName = sheyi.name }
    if not player.dead then room:loseHp(player, 1, sheyi.name) end
  end,
})

sheyi:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    if target ~= player or player.dead or not player:hasSkill(sheyi.name) then return false end
    return table.find(player.room.players, function(debtor)
      return not debtor.dead and table.find(debtor:getTableMark("ts__sheyi_hp_debts"),
        function(debt) return debt.owner == player.id and debt.n > 0 end) ~= nil
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if target ~= player or player.dead then return end
    for _, debtor in ipairs(room.players) do
      if player.dead then return end
      if not debtor.dead then
        local keep, n = {}, 0
        for _, debt in ipairs(debtor:getTableMark("ts__sheyi_hp_debts")) do
          if debt.owner == player.id then n = n + debt.n else table.insert(keep, debt) end
        end
        if n > 0 then
          room:setPlayerMark(debtor, "ts__sheyi_hp_debts", keep)
          room:recover { who = player, num = n, recoverBy = debtor, skillName = sheyi.name }
          if not debtor.dead then room:loseHp(debtor, n, sheyi.name) end
        end
      end
    end
  end,
})

return sheyi
