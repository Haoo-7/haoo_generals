local jiangli = fk.CreateSkill {
  name = "haoo__jiangli",
}

Fk:loadTranslationTable {
  ["haoo__jiangli"] = "奖励",
  [":haoo__jiangli"] = "你使用牌指定目标或成为牌的目标后，可以失去1点体力并摸一张牌，然后令此牌无效。" ..
    "若你以此法进入濒死状态，你获得【肾虚】。",
  ["#haoo__jiangli-invoke"] = "奖励：你可以失去1点体力并摸一张牌，令此牌无效",
}

-- 每张牌的一次使用只询问一次，询问过（无论是否发动）即不再询问
local HANDLED = "__haoo_jiangli_done"

local function nullifyWholeCard(use)
  use.nullifiedTargets = use.nullifiedTargets or {}
  for _, to in ipairs(use.tos or Util.DummyTable) do
    table.insertIfNeed(use.nullifiedTargets, to)
  end
end

local function askCost(room, player)
  if not room:askToSkillInvoke(player, {
    skill_name = "haoo__jiangli",
    prompt = "#haoo__jiangli-invoke",
  }) then
    return false
  end
  local willDying = player.hp <= 1
  room:loseHp(player, 1, "haoo__jiangli")
  if player.dead then return false end
  player:drawCards(1, "haoo__jiangli")
  if willDying then
    room:handleAddLoseSkills(player, "haoo__shenxu", "haoo__jiangli")
  end
  return true
end

jiangli:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiangli.name) and not player.dead and
      data.use and not data.use[HANDLED] and data.to and not data.to.dead
  end,
  on_cost = function(self, event, target, player, data)
    data.use[HANDLED] = true
    return askCost(player.room, player)
  end,
  on_use = function(self, event, target, player, data)
    nullifyWholeCard(data.use)
  end,
})

jiangli:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiangli.name) and not player.dead and
      data.use and not data.use[HANDLED]
  end,
  on_cost = function(self, event, target, player, data)
    data.use[HANDLED] = true
    return askCost(player.room, player)
  end,
  on_use = function(self, event, target, player, data)
    nullifyWholeCard(data.use)
  end,
})

return jiangli
