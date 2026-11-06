local feihua = fk.CreateSkill {
  name = "ts__feihua",
}

Fk:loadTranslationTable {
  ["ts__feihua"] = "飞花",
  [":ts__feihua"] = "不因此技能的♣牌进入弃牌堆时，你可以弃置手牌或牌堆顶2X张牌(X为此次弃置的♣牌数)并于此回合获得[漫卷]",
  ["#ts__feihua"] = "飞花：选择弃置至多%arg张手牌或牌堆顶牌，然后获得“漫卷”",
  ["#ts__feihua-choose"] = "飞花：选择弃置手牌或牌堆顶牌",
  ["ts__feihua_hand"] = "弃置手牌",
  ["ts__feihua_draw_pile"] = "弃置牌堆顶",
}

-- 漫卷(js__manjuan)把牌当作本身使用/打出，move.skillName 会是 js__manjuan。
-- 这类牌不应回头触发飞花，否则漫卷打出的梅花牌会再次引出飞花，形成连锁。
local excluded_skills = {
  [feihua.name] = true,
  ["js__manjuan"] = true,
}

local function discardDrawPile(room, player, n)
  local ids = {}
  for i = 1, math.min(n, #room.draw_pile) do
    table.insert(ids, room.draw_pile[i])
  end
  if #ids > 0 then
    room:moveCards {
      ids = ids,
      fromArea = Card.DrawPile,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonDiscard,
      skillName = feihua.name,
      proposer = player,
    }
  end
  return #ids
end

local function count_club_cards(data, player)
  local n = 0
  local current = player.room.logic:getCurrentEvent()
  local use_event = current:findParent(GameEvent.UseCard, true)
  local respond_event = current:findParent(GameEvent.RespondCard, true)
  local use_skill = use_event and use_event.data.attachedSkillAndUser
  local respond_skill = respond_event and respond_event.data.attachedSkillAndUser
  local from_manjuan = (use_skill and use_skill.skillName == "js__manjuan") or
    (respond_skill and respond_skill.skillName == "js__manjuan")

  for _, move in ipairs(data) do
    if move.toArea == Card.DiscardPile and not excluded_skills[move.skillName] and not from_manjuan then
      for _, info in ipairs(move.moveInfo) do
        if Fk:getCardById(info.cardId, true).suit == Card.Club then
          n = n + 1
        end
      end
    end
  end
  return n
end

feihua:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(feihua.name) then return false end
    return (player:getHandcardNum() > 0 or #player.room.draw_pile > 0) and count_club_cards(data, player) > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = feihua.name,
      prompt = "#ts__feihua:::" .. (count_club_cards(data, player) * 2),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = count_club_cards(data, player)
    if n <= 0 then return end

    local choices = {}
    if player:getHandcardNum() > 0 then
      table.insert(choices, "ts__feihua_hand")
    end
    if #room.draw_pile > 0 then
      table.insert(choices, "ts__feihua_draw_pile")
    end
    if #choices > 0 then
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = feihua.name,
        prompt = "#ts__feihua-choose",
        cancelable = false,
      })
      if choice == "ts__feihua_hand" then
        local num = math.min(n * 2, player:getHandcardNum())
        room:askToDiscard(player, {
          min_num = num,
          max_num = num,
          include_equip = false,
          skill_name = feihua.name,
          cancelable = false,
        })
      else
        discardDrawPile(room, player, n * 2)
      end
    end

    if not player:hasSkill("js__manjuan", true) then
      room:handleAddLoseSkills(player, "js__manjuan", nil, false, true)
      local turn = room.logic:getMostRecentEvent(GameEvent.Turn)
      if turn then
        turn:addExitFunc(function()
          if player:hasSkill("js__manjuan", true) then
            room:handleAddLoseSkills(player, "-js__manjuan", nil, false, true)
          end
        end)
      end
    end
  end,
})

feihua:addTest(function(room, me)
  local pileCount = #room.draw_pile
  local discardCount = #room.discard_pile
  local expected = math.min(2, pileCount)
  FkTest.runInRoom(function()
    lu.assertEquals(discardDrawPile(room, me, 2), expected)
  end)
  lu.assertEquals(#room.draw_pile, pileCount - expected)
  lu.assertEquals(#room.discard_pile, discardCount + expected)
end)

return feihua
