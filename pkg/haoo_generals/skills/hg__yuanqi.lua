local Qu = require "packages.haoo_generals.qu"
local skill = fk.CreateSkill {
  name = "hg__yuanqi",
}

skill:addEffect(fk.GameStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return not Qu.has(p)
    end)
    if #targets == 0 then return false end
    local chosen = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = #targets,
      cancelable = true,
      skill_name = skill.name,
      prompt = "#hg__yuanqi-start",
    })
    if #chosen > 0 then
      room:sortByAction(chosen)
      event:setCostData(self, { tos = chosen })
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      Qu.add(player.room, p)
    end
  end,
})

skill:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(skill.name) or data.card.type ~= Card.TypeTrick then
      return false
    end
    local first = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      return e.data.card.type == Card.TypeTrick
    end, Player.HistoryTurn)
    return #first > 0 and first[1].data == data and
      table.find(player.room.alive_players, function(p)
        return p ~= player and not Qu.has(p) and not p:isNude()
      end) ~= nil
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if player.dead or not player:hasSkill(skill.name) then break end
      if p ~= player and not p.dead and not Qu.has(p) and not p:isNude() then
        local cards = room:askToCards(p, {
          min_num = 1,
          max_num = #p:getCardIds("he"),
          include_equip = true,
          cancelable = true,
          skill_name = skill.name,
          prompt = "#hg__yuanqi-give::" .. player.id,
        })
        if #cards > 0 and not player.dead and not p.dead then
          cards = table.filter(cards, function(id)
            return table.contains(p:getCardIds("he"), id)
          end)
          if #cards > 0 then
            room:obtainCard(player, cards, false, fk.ReasonGive, p, skill.name)
            Qu.add(room, p)
          end
        end
      end
    end
  end,
})

Fk:loadTranslationTable {
  ["hg__yuanqi"] = "渊启",
  [":hg__yuanqi"] = "游戏开始时，你令任意角色获得渠。每回合其他角色可于首张锦囊牌结算后交给你牌以获得渠。",
  ["#hg__yuanqi-start"] = "渊启：选择任意名角色（可包含自己），令其各获得一个“渠”",
  ["#hg__yuanqi-give"] = "渊启：你可以交给 %dest 任意张手牌或装备牌（至少一张），然后获得“渠”",
}

return skill
