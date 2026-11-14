local tongnan = fk.CreateSkill {
  name = "haoo__tongnan",
  -- 〖和梦〗是本技能的相关技能：武将详情页紫色显示；不写入 addSkills，
  -- 开局由 fk.GameStart 授予，用“技能所有权”表达“在武将牌上/已被喝掉”
  related_skills = { "haoo__hemeng" },
}

Fk:loadTranslationTable {
  ["haoo__tongnan"] = "通南",
  [":haoo__tongnan"] = "你可以将武将牌上未获得的技能当【酒】使用。" ..
    "①当你对一名角色使用♥牌结算后，其摸一张牌。" ..
    "②当一名角色对你使用♥牌结算后，你摸一张牌。" ..
    "当你执行该技能的①或②项后，你重置武将牌。",
  ["#haoo__tongnan"] = "通南：将武将牌上未获得的技能当【酒】使用",
}

-- 「武将牌上未获得的技能」即〖和梦〗，状态用技能所有权表达（handleAddLoseSkills 幂等）：
--   在武将牌上（可喝）= 已授予〖和梦〗，头像区显示黑框觉醒技按钮
--   被喝掉             = 移除〖和梦〗，按钮消失、酒源关闭
--   ①或②执行并重置武将牌后 = 重新授予〖和梦〗，按钮恢复、酒源恢复
-- 酒的每回合一次（增益）与濒死自救不限的规则沿用【酒】本身（analeptic_skill）。

-- 开局把〖和梦〗放到武将牌上
tongnan:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tongnan.name) and not player:hasSkill("haoo__hemeng")
  end,
  on_use = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "haoo__hemeng", tongnan.name, false)
  end,
})

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
    return player:hasSkill("haoo__hemeng") and
      player:usedCardTimes("analeptic", Player.HistoryTurn) == 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:hasSkill("haoo__hemeng")
  end,
  -- 用酒即“喝掉”和梦（服务端结算回调）：移除〖和梦〗
  before_use = function(self, player, use)
    player.room:handleAddLoseSkills(player, "-haoo__hemeng", tongnan.name)
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
    -- 重置武将牌后，被喝掉的〖和梦〗回到武将牌上
    if done1 or done2 then
      room:handleAddLoseSkills(player, "haoo__hemeng", tongnan.name)
    end
  end,
})

return tongnan
