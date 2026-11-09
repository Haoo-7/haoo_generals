local skill = fk.CreateSkill {
  name = "lz__jiangli",
}

local choice_mark = "@lz__jiangli-turn"
local progress_mark = "lz__jiangli_progress-turn"
local result_mark = "lz__jiangli_result-turn"
local rewarded_mark = "lz__jiangli_rewarded-turn"
local choices = { "lz__jiangli_leijin", "lz__jiangli_bianzhen", "lz__jiangli_mingzhi" }

local function updateProgress(player, value)
  player.room:setPlayerMark(player, progress_mark, value)
end

local function finishZhengsu(player, success)
  local room = player.room
  room:setPlayerMark(player, result_mark, success and "success" or "failure")
  room:sendLog {
    type = success and "#lz__jiangli-success" or "#lz__jiangli-failure",
    from = player.id,
    arg = player:getMark(choice_mark),
  }
end

skill:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = skill.name,
      prompt = "#lz__jiangli-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = skill.name,
      prompt = "#lz__jiangli-choice",
      detailed = true,
    })
    room:setPlayerMark(player, choice_mark, choice)
    updateProgress(player, {})
    room:setPlayerMark(player, result_mark, 0)
    room:setPlayerMark(player, rewarded_mark, 0)
    room:damage {
      from = player,
      to = player,
      damage = 1,
      damageType = fk.NormalDamage,
      skillName = skill.name,
    }
  end,
})

-- Record this skill's own attempt so simultaneous native Zhengsu attempts
-- cannot change its selected condition or receive its enhanced reward.
skill:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and not player.dead and player.phase == Player.Play and
      player:getMark(result_mark) == 0 and
      table.contains({ choices[1], choices[2] }, player:getMark(choice_mark))
  end,
  on_refresh = function(self, event, target, player, data)
    local progress = player:getTableMark(progress_mark)
    if player:getMark(choice_mark) == choices[1] then
      -- Match native Zhengsu: cards with number 0 do not count.
      if data.card.number == 0 then return end
      if #progress > 0 and data.card.number <= progress[#progress] then
        finishZhengsu(player, false)
      else
        table.insert(progress, data.card.number)
        if #progress > 3 then table.remove(progress, 1) end
        updateProgress(player, progress)
      end
    else
      -- Match native Zhengsu: cards without a suit do not count.
      if data.card.suit == Card.NoSuit then return end
      if #progress > 0 and data.card.suit ~= progress[1] then
        finishZhengsu(player, false)
      else
        table.insert(progress, data.card.suit)
        if #progress > 2 then table.remove(progress, 1) end
        updateProgress(player, progress)
      end
    end
  end,
})

skill:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return not player.dead and player.phase == Player.Discard and
      player:getMark(result_mark) == 0 and player:getMark(choice_mark) == choices[3]
  end,
  on_refresh = function(self, event, target, player, data)
    local progress = player:getTableMark(progress_mark)
    for _, move in ipairs(data) do
      if move.from == player and move.moveReason == fk.ReasonDiscard and move.skillName == "phase_discard" then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            local suit = Fk:getCardById(info.cardId, true).suit
            if not table.insertIfNeed(progress, suit) then
              finishZhengsu(player, false)
              return
            end
          end
        end
      end
    end
    updateProgress(player, progress)
  end,
})

skill:addEffect(fk.EventPhaseEnd, {
  can_refresh = function(self, event, target, player, data)
    if target ~= player or player.dead or player:getMark(result_mark) ~= 0 then return false end
    local choice = player:getMark(choice_mark)
    return (data.phase == Player.Play and table.contains({ choices[1], choices[2] }, choice)) or
      (data.phase == Player.Discard and choice == choices[3])
  end,
  on_refresh = function(self, event, target, player, data)
    local required = player:getMark(choice_mark) == choices[1] and 3 or 2
    finishZhengsu(player, #player:getTableMark(progress_mark) >= required)
  end,
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and data.phase == Player.Discard and
      player:getMark(result_mark) == "success" and player:getMark(rewarded_mark) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local choice = player:getMark(choice_mark)
    local draw = choice == choices[1] and "lz__jiangli_draw4" or "lz__jiangli_draw2"
    local recover = choice == choices[3] and "lz__jiangli_recover2" or "lz__jiangli_recover1"
    local rewards = { draw }
    if player:isWounded() then table.insert(rewards, recover) end
    local reward = player.room:askToChoice(player, {
      choices = rewards,
      all_choices = { draw, recover },
      skill_name = skill.name,
      prompt = "#lz__jiangli-reward",
    })
    event:setCostData(self, { choice = reward })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local reward = event:getCostData(self).choice
    -- Mark the attempt paid before executing a reward that can trigger skills.
    room:setPlayerMark(player, rewarded_mark, 1)
    if reward == "lz__jiangli_draw4" or reward == "lz__jiangli_draw2" then
      player:drawCards(reward == "lz__jiangli_draw4" and 4 or 2, skill.name)
    else
      room:recover {
        who = player,
        num = reward == "lz__jiangli_recover2" and 2 or 1,
        recoverBy = player,
        skillName = skill.name,
      }
    end
  end,
})

Fk:loadTranslationTable {
  ["lz__jiangli"] = "桨励",
  [":lz__jiangli"] = "准备阶段，你可整肃以对自己造成一点伤害，若你成功：擂进/鸣止，可双倍摸牌/回复体力。",
  [choice_mark] = "桨励",
  ["lz__jiangli_leijin"] = "擂进",
  [":lz__jiangli_leijin"] = "出牌阶段内，至少使用3张有点数的牌，其点数严格递增。成功后可摸4张牌或回复1点体力。",
  ["lz__jiangli_bianzhen"] = "变阵",
  [":lz__jiangli_bianzhen"] = "出牌阶段内，至少使用2张有花色的牌，其花色均相同。成功后可摸2张牌或回复1点体力。",
  ["lz__jiangli_mingzhi"] = "鸣止",
  [":lz__jiangli_mingzhi"] = "弃牌阶段内，因阶段弃牌而弃置至少2张手牌，其花色各不相同。成功后可摸2张牌或回复2点体力。",
  ["lz__jiangli_draw4"] = "摸四张牌",
  ["lz__jiangli_draw2"] = "摸两张牌",
  ["lz__jiangli_recover2"] = "回复两点体力",
  ["lz__jiangli_recover1"] = "回复一点体力",
  ["#lz__jiangli-invoke"] = "桨励：你可以选择一项整肃，并立即对自己造成1点伤害",
  ["#lz__jiangli-choice"] = "桨励：选择本回合整肃条件，成功后于弃牌阶段结束时选择奖励",
  ["#lz__jiangli-reward"] = "桨励：整肃成功，选择一项奖励",
  ["#lz__jiangli-success"] = "%from 的“桨励”整肃（%arg）成功",
  ["#lz__jiangli-failure"] = "%from 的“桨励”整肃（%arg）失败",
}

return skill
