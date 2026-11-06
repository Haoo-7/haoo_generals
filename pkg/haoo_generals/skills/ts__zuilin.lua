local zuilin = fk.CreateSkill {
  name = "ts__zuilin",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable {
  ["ts__zuilin"] = "世外",
  [":ts__zuilin"] = "转换技，准备阶段，阳：你可以废除你的手牌区，恢复你的判定区；阴：你可以废除你的判定区，恢复你的手牌区。",
  ["#ts__zuilin-yang"] = "世外：你可以废除你的手牌区，恢复你的判定区",
  ["#ts__zuilin-yin"] = "世外：你可以废除你的判定区，恢复你的手牌区",
}

zuilin:addEffect(fk.EventPhaseStart, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zuilin.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local state = player:getSwitchSkillState(zuilin.name, false)
    return player.room:askToSkillInvoke(player, {
      skill_name = zuilin.name,
      prompt = state == fk.SwitchYang and "#ts__zuilin-yang" or "#ts__zuilin-yin",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(zuilin.name, true) == fk.SwitchYang then
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

return zuilin
