local W = require "packages.haoo_generals.wushilin"
local skill = fk.CreateSkill {
  name = "bo__dansi",
}

skill:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(skill.name) or not data.card.is_damage_card or not W.canCounter(player, data.from) then return false end
    local first = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      return e.data.card.is_damage_card
    end, Player.HistoryTurn)
    return #first > 0 and first[1].data == data
  end,
  on_cost = function(self, event, target, player, data)
    local use = player.room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = skill.name,
      prompt = "#bo__dansi-slash::" .. data.from.id,
      card_filter = { n = 1, pattern = ".|.|red" },
      extra_data = { exclusive_targets = { data.from.id }, must_targets = { data.from.id }, bypass_times = true, extraUse = true },
      cancelable = true,
      skip = true,
    })
    if use then
      event:setCostData(self, { tos = { data.from }, extra_data = { use = use, x = player.maxHp - player.hp + 1 } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local cost = event:getCostData(self).extra_data
    W.resolve(player.room, player, cost.use, cost.x)
  end,
})

Fk:loadTranslationTable {
  ["bo__dansi"] = "旦死",
  [":bo__dansi"] = "每回合首次有角色使用伤害牌后，你可武圣之然后明置此回合所有使用和成为过牌指定目标的角色各x张手牌，因此法受伤的角色交给对方：x张明置牌；下个摸牌阶段。（x为你的空勾玉数+1）\n背水：吾是琳于其回合内断肠",
  ["#bo__dansi-slash"] = "旦死：你可以将一张红色牌当【杀】对 %dest 使用，然后明置本回合参与用牌的角色的手牌",
  ["#bo__dansi-reveal"] = "旦死：选择 %dest 的 %arg 张手牌，持续明置",
  ["#bo__dansi-give"] = "旦死：交给 %dest %arg 张明置手牌",
  ["#bo__dansi-pay"] = "旦死：交给 %dest %arg 张明置牌，或将下个摸牌阶段交给其",
  ["#bo__dansi-backwater"] = "旦死：是否背水，令受伤角色执行两项，然后你于自己的回合内失去所有武将技能？",
  ["bo__dansi-normal"] = "不背水：受伤者选择一项交出",
  ["bo__dansi-backwater"] = "背水：执行两项，吾是琳于其回合内断肠",
  ["bo__dansi-cards"] = "交出明置牌",
  ["bo__dansi-phase"] = "交出下个摸牌阶段",
}

return skill
