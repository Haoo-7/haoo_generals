local tongnan = fk.CreateSkill {
  name = "haoo__tongnan",
  -- 〖和梦〗是本技能的相关技能：不通过 addSkills 授予，开局即“未获得”，
  -- 武将详情中显示为紫色，牌局中没有对应按钮
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

-- 「武将牌上未获得的技能」即〖和梦〗：它是本技能的相关技能（开局不授予，
-- 紫色“未获得”状态，无牌局按钮）。将和梦当【酒】使用即“喝掉”和梦，
-- 喝掉后酒源关闭；当①或②执行并重置武将牌后，和梦回到武将牌上，酒源恢复。
-- “已被喝掉”用玩家标记 haoo__hemeng_drunk 记录（无 @ 前缀，不显示在头像区）。
-- 酒的每回合一次（增益）与濒死自救不限的规则沿用【酒】本身（analeptic_skill）。

local HEMENG_DRUNK = "haoo__hemeng_drunk"
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
    return player:getMark(HEMENG_DRUNK) == 0 and
      player:usedCardTimes("analeptic", Player.HistoryTurn) == 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:getMark(HEMENG_DRUNK) == 0
  end,
  -- 用酒即“喝掉”和梦（服务端结算回调，实际使用时消耗）
  before_use = function(self, player, use)
    player.room:addPlayerMark(player, HEMENG_DRUNK, 1)
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
      room:setPlayerMark(player, HEMENG_DRUNK, 0)
    end
  end,
})

return tongnan
