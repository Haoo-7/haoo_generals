local shiwai = fk.CreateSkill {
  name = "ts__shiwai",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable {
  ["ts__shiwai"] = "世外",
  [":ts__shiwai"] = "转换技，准备阶段，阳：你可以废除你的手牌区，恢复你的判定区；阴：你可以废除你的判定区，恢复你的手牌区。",
  ["#ts__shiwai-yang"] = "世外：你可以废除你的手牌区，恢复你的判定区",
  ["#ts__shiwai-yin"] = "世外：你可以废除你的判定区，恢复你的手牌区",
}

Fk:loadTranslationTable {
  ["@@ts__shiwai-hand"] = "手牌区已废除",
  ["@@ts__shiwai-judge"] = "判定区已废除",
}

-- Follow actual area state, including external restoration and skill loss.
for _, refresh_event in ipairs({
  fk.GameStart, fk.AreaAborted, fk.AreaResumed, fk.EventAcquireSkill, fk.EventLoseSkill,
}) do
  shiwai:addEffect(refresh_event, {
    global = true,
    can_refresh = function(self, event, target, player, data)
      return (event == fk.GameStart or target == player) and
        (player:hasSkill(shiwai.name, true) or player:hasSkill("ts__zuilin", true) or
          player:getMark("@@ts__shiwai-hand") ~= 0 or player:getMark("@@ts__shiwai-judge") ~= 0 or
          (event == fk.EventLoseSkill and data and data.skill and
            (data.skill.name == shiwai.name or data.skill.name == "ts__zuilin")))
    end,
    on_refresh = function(self, event, target, player, data)
      local room = player.room
      room:setPlayerMark(player, "@@ts__shiwai-hand", player:isHandAreaSealed() and 1 or 0)
      room:setPlayerMark(player, "@@ts__shiwai-judge", player:isJudgeAreaSealed() and 1 or 0)
    end,
  })
end

shiwai:addEffect(fk.EventPhaseStart, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shiwai.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local state = player:getSwitchSkillState(shiwai.name, false)
    return player.room:askToSkillInvoke(player, {
      skill_name = shiwai.name,
      prompt = state == fk.SwitchYang and "#ts__shiwai-yang" or "#ts__shiwai-yin",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(shiwai.name, true) == fk.SwitchYang then
      room:abortPlayerArea(player, Player.HandSlot)
      room:resumePlayerArea(player, Player.JudgeSlot)
    else
      room:abortPlayerArea(player, Player.JudgeSlot)
      room:resumePlayerArea(player, Player.HandSlot)
    end
  end,
})

-- 注：核心已在 moveInfoTranslate 阶段把“移入已废除手牌区”的牌改判为置入弃牌堆
-- （见 ltk/server/events/movecard.lua 的 abortMoveInfos 分支），触发 BeforeCardsMove 时
-- move.toArea 已是 Card.DiscardPile，故此处无需再补一段补偿逻辑。

return shiwai
