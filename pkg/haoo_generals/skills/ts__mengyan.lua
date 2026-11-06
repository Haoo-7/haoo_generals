local mengyan = fk.CreateSkill {
  name = "ts__mengyan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ts__mengyan"] = "梦魔",
  [":ts__mengyan"] = "锁定技，其他角色使用牌指定你为目标时，其须交给你一张【影】，否则此牌对你无效。"..
    "每轮结束时，所有其他角色弃置所有【影】，以此法弃置【影】数不小于其体力值的角色受到1点伤害且下轮非锁定技失效。",

  ["#ts__mengyan-give"] = "梦魔：你须交给 %src 一张【影】，否则此牌对其无效",
  ["@@ts__mengyan_next"] = "梦魔",
}

local function getShadeIds(player)
  return table.filter(player:getCardIds("h"), function(id)
    return Fk:getCardById(id).trueName == "shade"
  end)
end

mengyan:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mengyan.name) and data.from and
      data.from ~= player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = data.from
    if from.dead or #getShadeIds(from) == 0 then
      data.nullified = true
      return
    end
    local cards = room:askToCards(from, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      cancelable = true,
      skill_name = mengyan.name,
      pattern = "shade",
      prompt = "#ts__mengyan-give:" .. player.id,
    })
    if #cards == 0 then
      data.nullified = true
    else
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, mengyan.name, nil, false, from)
    end
  end,
})

mengyan:addEffect(fk.RoundEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mengyan.name) and not player.dead and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return #getShadeIds(p) > 0
      end) ~= nil
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      if not p.dead then
        local shades = getShadeIds(p)
        local n = #shades
        if n > 0 then
          room:throwCard(shades, mengyan.name, p, player)
          if not p.dead and n >= p.hp then
            room:damage{
              from = player,
              to = p,
              damage = 1,
              skillName = mengyan.name,
            }
            if not p.dead then
              room:setPlayerMark(p, "@@ts__mengyan_next", 1)
            end
          end
        end
      end
    end
  end,
})

mengyan:addEffect(fk.RoundStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mengyan.name) and not player.dead and
      table.find(player.room:getAllPlayers(), function(p)
        return p:getMark("@@ts__mengyan_next") > 0
      end) ~= nil
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAllPlayers()) do
      if p:getMark("@@ts__mengyan_next") > 0 then
        room:setPlayerMark(p, "@@ts__mengyan_next", 0)
        if not p.dead then
          room:addPlayerMark(p, MarkEnum.UncompulsoryInvalidity .. "-round")
        end
      end
    end
  end,
})

return mengyan
