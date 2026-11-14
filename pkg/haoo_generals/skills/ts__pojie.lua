local pojie = fk.CreateSkill {
  name = "ts__pojie",
  derived_piles = "ts__pojie_pile",
}

Fk:loadTranslationTable {
  ["ts__pojie"] = "破解",
  [":ts__pojie"] = "当你使用或打出点数为2、3、7的牌时，你可以将此牌扣置于武将牌上，称为“破解”。出牌阶段，你可以移除两张点数为7、一张点数为2、一张点数为3的“破解”牌，然后选择一项：1.本回合你使用牌无次数和距离限制；2.删除〖技霸〗的前八个字，获得〖资源〗；3.将〖破解〗设置为持恒技。",

  ["#ts__pojie-ask"] = "破解：是否将%arg扣置于武将牌上？",
  ["#ts__pojie-pay"] = "破解：移除7、7、2、3各一张“破解”牌，然后选择一项",
  ["ts__pojie_limit"] = "本回合使用牌无次数和距离限制",
  ["ts__pojie_free"] = "删除〖技霸〗的前八个字，获得〖资源〗",
  ["ts__pojie_permanent"] = "将〖破解〗设置为持恒技",
  ["ts__pojie_pile"] = "破解",
}

local valid_numbers = { [2] = true, [3] = true, [7] = true }

local function pick_combo(ids)
  local sevens, twos, threes = {}, {}, {}
  for _, id in ipairs(ids) do
    local card = Fk:getCardById(id)
    if card then
      if card.number == 7 then
        table.insert(sevens, id)
      elseif card.number == 2 then
        table.insert(twos, id)
      elseif card.number == 3 then
        table.insert(threes, id)
      end
    end
  end
  if #sevens < 2 or #twos < 1 or #threes < 1 then return nil end
  return { sevens[1], sevens[2], twos[1], threes[1] }
end

local function trigger_spec()
  return {
    anim_type = "special",
    can_trigger = function(self, event, target, player, data)
      if target ~= player or not player:hasSkill(pojie.name) then return false end
      if not valid_numbers[data.card.number] then return false end
      return #Card:getIdList(data.card) > 0
    end,
    on_cost = function(self, event, target, player, data)
      return player.room:askToSkillInvoke(player, {
        skill_name = pojie.name,
        prompt = "#ts__pojie-ask:::" .. data.card:toLogString(),
      })
    end,
    on_use = function(self, event, target, player, data)
      local room = player.room
      -- 使用/打出结束时收取处理区的牌, 装备牌还可能已进入自己的装备区.
      local ids = table.filter(Card:getIdList(data.card), function(id)
        local area = room:getCardArea(id)
        return area == Card.Processing or (area == Card.PlayerEquip and room:getCardOwner(id) == player)
      end)
      if #ids > 0 then
        player:addToPile("ts__pojie_pile", ids, true, pojie.name)
      end
    end,
  }
end

pojie:addEffect(fk.CardUseFinished, trigger_spec())
pojie:addEffect(fk.CardRespondFinished, trigger_spec())

pojie:addEffect("active", {
  anim_type = "special",
  prompt = "#ts__pojie-pay",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  can_use = function(self, player)
    return pick_combo(player:getPile("ts__pojie_pile")) ~= nil
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local ids = pick_combo(player:getPile("ts__pojie_pile"))
    if not ids then return end

    room:moveCardTo(ids, Card.DiscardPile, nil, fk.ReasonDiscard, pojie.name, nil, true, player)

    local choice = room:askToChoice(player, {
      choices = { "ts__pojie_limit", "ts__pojie_free", "ts__pojie_permanent" },
      skill_name = pojie.name,
      prompt = "#ts__pojie-pay",
      cancelable = false,
    })

    if choice == "ts__pojie_limit" then
      room:setPlayerMark(player, MarkEnum.BypassTimesLimit, 1)
      room:setPlayerMark(player, MarkEnum.BypassDistancesLimit, 1)
      local turn = room.logic:getMostRecentEvent(GameEvent.Turn)
      if turn then
        turn:addExitFunc(function()
          if player:getMark(MarkEnum.BypassTimesLimit) > 0 then
            room:setPlayerMark(player, MarkEnum.BypassTimesLimit, 0)
          end
          if player:getMark(MarkEnum.BypassDistancesLimit) > 0 then
            room:setPlayerMark(player, MarkEnum.BypassDistancesLimit, 0)
          end
        end)
      end
    elseif choice == "ts__pojie_free" then
      room:setPlayerMark(player, "ts__jiba_free", 1)
      for _, p in ipairs(room.players) do
        if p:getMark("ts__jiba_free") == 0 then
          room:setPlayerMark(p, "ts__jiba_free", 1)
        end
      end
      if not player:hasSkill("ts__ziyuan", true) then
        room:handleAddLoseSkills(player, "ts__ziyuan", nil, false, true)
      end
    elseif choice == "ts__pojie_permanent" then
      room:setPlayerMark(player, "ts__pojie_permanent", 1)
      local sk = Fk.skills[pojie.name]
      local skel = sk and sk:getSkeleton()
      if skel and skel.tags then
        table.insertIfNeed(skel.tags, Skill.Permanent)
      end
    end
  end,
})

-- 持恒技的标签写在共享的技能对象上，新开一局时清掉，免得串局。
pojie:addEffect(fk.GameStart, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(pojie.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local sk = Fk.skills[pojie.name]
    local skel = sk and sk:getSkeleton()
    if skel and skel.tags then
      skel.tags = table.filter(skel.tags, function(t) return t ~= Skill.Permanent end)
    end
  end,
})

return pojie
