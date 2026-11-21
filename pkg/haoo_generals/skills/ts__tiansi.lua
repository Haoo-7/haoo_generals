local L = require "packages.haoo_generals.sp_lin"
local skill = L.skill("ts__tiansi", "ts__lin_si", { Skill.Compulsory })

skill:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and not L.isAwake(player) and
      data.from == nil and data.damage > 0 and not data.prevented and
      player:getMark("ts__tiansi_used-turn") == 0
  end,
  on_use = function(self, event, target, player, data)
    if data.damage > 0 and not data.prevented then
      player.room:setPlayerMark(player, "ts__tiansi_used-turn", 1)
      data:preventDamage()
    end
  end,
})

Fk:loadTranslationTable {
  ["ts__tiansi"] = "天私",
  ["ts__lin_si"] = "私",
  [":ts__tiansi"] = "锁定技，每回合限一次，当你受到无来源伤害时，防止之。",
  [":ts__tiansi_awakened"] = "无止之。",
}

return skill
