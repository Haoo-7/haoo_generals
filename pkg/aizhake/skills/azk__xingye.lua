local A = require "packages.haoo_generals.aizhake"
local skill = fk.CreateSkill {
  name = A.xingye,
  derived_piles = A.pile,
  related_skills = { A.qixing },
}

skill:addAcquireEffect(function(self, player)
  player.room:handleAddLoseSkills(player, A.qixing, A.xingye, false, true)
end)

skill:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, A.knownMark, 0)
  player.room:setPlayerMark(player, A.viewMark, 0)
  player.room:handleAddLoseSkills(player, "-" .. A.qixing, A.xingye, false, true)
end)

skill:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_refresh = function(self, event, target, player, data)
    return table.find(data, function(move)
      return (move.to == player and move.toArea == Card.PlayerSpecial and move.specialName == A.pile) or
        (move.from == player and table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerSpecial and info.fromSpecialName == A.pile
        end) ~= nil)
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data) A.sync(player) end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and not A.busy(player) and A.isIncreasing(player:getPile(A.pile))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data) A.check(player) end,
})

skill:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Finish
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data) A.finish(player) end,
})

Fk:loadTranslationTable {
  ["azk__xingye"] = "星夜",
  [":azk__xingye"] = "你拥有只对其他角色明置的七星。七星点数严格递曾时，你获得所有星并将牌堆底7张牌另作为星。\n你的结束阶段，其他角色可依次展示一张牌并替换星，然后你闭月并如此。",
  ["#azk_star"] = "星",
  ["@[azk_star]"] = "星",
  ["#azk__qixing-arrange"] = "七星：点选一张手牌和一个星位，或跨行拖动换牌；星位固定，牌背为未知星",
  ["#azk__single-arrange"] = "星夜：用一张手牌替换一个固定星位；点选两张牌或跨行拖动",
  ["#azk__xingye-exchange"] = "星夜：展示一张手牌，与 %src 的一张星交换；取消则不交换",
  ["#azk__xingye-star"] = "星夜：选择获得 %src 的一张星，你展示的手牌将替换其原位置",
  ["azk__slot1"] = "第1张星（最左）",
  ["azk__slot2"] = "第2张星",
  ["azk__slot3"] = "第3张星",
  ["azk__slot4"] = "第4张星",
  ["azk__slot5"] = "第5张星",
  ["azk__slot6"] = "第6张星",
  ["azk__slot7"] = "第7张星（最右）",
}

return skill
