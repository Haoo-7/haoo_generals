local A = require "packages.haoo_generals.aizhake"
local skill = fk.CreateSkill {
  name = A.qixing,
  derived_piles = A.pile,
}

skill:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and player:hasSkill(A.xingye) and #player:getPile(A.pile) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    A.seed(player, "top")
    A.check(player)
    if not player.dead and player:hasSkill(A.xingye) then A.qixingExchange(player) end
  end,
})

skill:addEffect(fk.AfterDrawNCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player:hasSkill(A.xingye) and
      not player:isKongcheng() and #player:getPile(A.pile) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data) A.qixingExchange(player) end,
})

Fk:loadTranslationTable {
  ["azk__qixing"] = "七星",
  [":azk__qixing"] = "游戏开始时，你将牌堆顶的七张牌置于武将牌上，称为“星”，然后你可以用任意张手牌替换等量的“星”；摸牌阶段结束时，你可以用任意张手牌替换等量的“星”。你的“星”对其他角色明置，你可查看自己放入或已展示后放入的星。七个星位固定，交换不改变其余星的位置。",
}

return skill
