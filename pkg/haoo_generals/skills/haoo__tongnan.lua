local tongnan = fk.CreateSkill {
  name = "haoo__tongnan",
}

Fk:loadTranslationTable {
  ["haoo__tongnan"] = "通南",
  [":haoo__tongnan"] = "你可以将武将牌上未获得的技能当【酒】使用。" ..
    "①当你对一名角色使用♥牌结算后，其摸一张牌。" ..
    "②当一名角色对你使用♥牌结算后，你摸一张牌。" ..
    "当你执行该技能的①或②项后，你重置武将牌。",
  ["#haoo__tongnan"] = "通南：将武将牌上未获得的技能当【酒】使用",
}

-- 「武将牌上未获得的技能」即〖和梦〗：它是觉醒技，但本卡没有任何获得它的
-- 途径，永远处于“未获得”状态，因此此处酒源常驻。酒的每回合一次限制
-- 与濒死自救规则沿用【酒】本身（analeptic_skill）的结算。
tongnan:addEffect("viewas", {
  anim_type = "support",
  pattern = "analeptic",
  prompt = "#haoo__tongnan",
  card_num = 0,
  card_filter = Util.FalseFunc,
  view_as = function(self, player)
    local card = Fk:cloneCard("analeptic")
    card.skillName = tongnan.name
    return card
  end,
  -- 出牌阶段当酒增益：每回合限一次（濒死自救不受此限，走 enabled_at_response）
  enabled_at_play = function(self, player)
    return not player:hasSkill("haoo__hemeng") and
      player:usedCardTimes("analeptic", Player.HistoryTurn) == 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and not player:hasSkill("haoo__hemeng")
  end,
})

-- ①②为无选择的结算：♥牌使用整场监听，无 on_cost 询问，直接执行
tongnan:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player.dead or not player:hasSkill(tongnan.name) then return false end
    local card = data and data.card
    if not card or card.suit ~= Card.Heart then return false end
    if data.from == player then return true end
    return data.tos and table.contains(data.tos, player) or false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local done1 = data.from == player
    local done2 = data.tos and table.contains(data.tos, player) or false
    if done1 then
      for _, to in ipairs(data.tos) do
        if not to.dead then
          to:drawCards(1, tongnan.name)
        end
      end
    end
    if done2 and not player.dead then
      player:drawCards(1, tongnan.name)
    end
    -- 执行①或②后，重置武将牌（正面朝下时翻回正面）
    if (done1 or done2) and not player.dead and not player.faceup then
      player:turnOver()
    end
  end,
})

return tongnan
