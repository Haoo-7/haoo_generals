local L = require "packages.haoo_generals.sp_lin"
local skill = L.skill("ts__tianjie", "ts__lin_jie")

skill:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ts__tianjie-active",
  card_num = 0,
  target_num = 0,
  max_phase_use_time = 1,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player.phase == Player.Play and player:getMark("ts__tianjie_used-phase") == 0 and
      player:usedSkillTimes(skill.name, Player.HistoryPhase) == 0 and
      (L.isAwake(player) or not player:isKongcheng()) and
      #L.targets(Fk:currentRoom(), player) > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    if player.dead or player:getMark("ts__tianjie_used-phase") > 0 then return end
    local awakened = L.isAwake(player)
    local targets = L.targets(room, player)
    local max = awakened and #targets or math.min(#targets, #player:getCardIds("h"))
    if max == 0 then return end
    room:setPlayerMark(player, "ts__tianjie_used-phase", 1)
    local tos = room:askToChoosePlayers(player, {
      targets = targets, min_num = 1, max_num = max, cancelable = false,
      skill_name = skill.name, prompt = "#ts__tianjie-targets",
    })
    local n = #tos
    if n == 0 or player.dead then return end
    if not awakened then
      local cards = room:askToCards(player, {
        min_num = n, max_num = n, include_equip = false, cancelable = false,
        skill_name = skill.name, prompt = "#ts__tianjie-show:::" .. n,
      })
      if #cards ~= n then return end
      player:showCards(cards)
    end
    room:sortByAction(tos)
    local judged = {}
    for _, to in ipairs(tos) do
      if player.dead then break end
      if not to.dead and not to:isNude() then
        local id = room:askToChooseCard(player, { target = to, flag = "he", skill_name = skill.name })
        if id and table.contains(to:getCardIds("he"), id) then
          -- Record the actual move, not a before/after hand-count guess.
          local previous = room:getTag(L.pending)
          local pending = { from = to, to = player, card = id }
          room:setTag(L.pending, pending)
          room:obtainCard(player, id, false, fk.ReasonPrey, player, skill.name)
          room:setTag(L.pending, previous)
          if pending.hand and (awakened or pending.last) then table.insert(judged, to) end
        end
      end
    end
    -- All acquisitions finish first. A dead substitute still consumes its slot.
    if player.dead then return end
    room:sortByAction(judged)
    for _, to in ipairs(judged) do
      if player.dead then return end
      L.lightning(room, to)
    end
    if not awakened then
      for _ = 1, n - #judged do
        if player.dead then return end
        L.lightning(room, player)
      end
    end
  end,
})

skill:addEffect(fk.AfterCardsMove, {
  priority = 1000,
  can_refresh = function(self, event, target, player, data)
    return player == player.room.players[1] and player.room:getTag(L.pending) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    local pending = player.room:getTag(L.pending)
    for _, move in ipairs(data) do
      if move.from == pending.from and move.to == pending.to and
        move.toArea == Card.PlayerHand and move.skillName == skill.name then
        for _, info in ipairs(move.moveInfo) do
          if info.cardId == pending.card and info.fromArea == Card.PlayerHand then
            pending.hand = true
            pending.last = move.from:isKongcheng()
          end
        end
      end
    end
  end,
})

-- Room-wide persistent history, including deaths when no Lin currently has the skill.
skill:addEffect(fk.Death, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    return player == player.room.players[1] and data.damage and
      data.damage.skillName == skill.name
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setTag(L.death, true)
  end,
})

Fk:loadTranslationTable {
  ["ts__tianjie"] = "天劫",
  ["ts__lin_jie"] = "劫",
  [":ts__tianjie"] = "出牌阶段限一次，你可展示X张手牌，获得X名角色各一张牌，后进行X次闪电判定。因此法失去最后一张手牌的角色代替你进行一次闪电判定。",
  [":ts__tianjie_awakened"] = "出牌阶段限一次，你可获得X名角色各一张牌。因此法失去手牌的角色进行一次闪电判定。",
  ["#ts__tianjie-active"] = "天劫：选择X名其他角色，各获得一张手牌或装备；觉醒前须展示X张手牌",
  ["#ts__tianjie-targets"] = "天劫：选择至少一名有手牌或装备的其他角色（人数为X）",
  ["#ts__tianjie-show"] = "天劫：展示%arg张手牌（不弃置）",
}

return skill
