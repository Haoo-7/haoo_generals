local G = require "packages.haoo_generals.guozhou"
local skill = fk.CreateSkill {
  name = "sha__manbo",
}

skill:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target and target.phase == Player.Play and not target.dead and
      player:hasSkill(skill.name) and #G.candidates(player, target) > 0
  end,
  on_cost = function(self, event, target, player, data)
    if not player.room:askToSkillInvoke(target, {
      skill_name = skill.name,
      prompt = "#sha__manbo-invoke::" .. player.id,
    }) then return false end
    local chosen = player.room:askToChoosePlayers(player, {
      targets = G.candidates(player, target),
      min_num = 1,
      max_num = 1,
      cancelable = false,
      skill_name = skill.name,
      prompt = "#sha__manbo-target::" .. target.id,
    })
    if #chosen ~= 1 then return false end
    event:setCostData(self, { tos = chosen })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local other = event:getCostData(self).tos[1]
    if target.dead or other.dead or not target:canPindian(other) then return end
    room:setPlayerMark(player, G.round_count, G.count(player) + 1)
    local x = G.count(player)
    local first = room:askToChoice(target, {
      choices = table.simpleClone(G.choices),
      skill_name = skill.name,
      prompt = "#sha__manbo-first::" .. other.id .. ":" .. x,
    })
    local index = table.indexOf(G.choices, first)
    room:sendLog { type = "#sha__manbo-declare", from = target.id, arg = first }
    local choices = {}
    for i, choice in ipairs(G.choices) do
      if math.abs(i - index) >= 2 then table.insert(choices, choice) end
    end
    local second = room:askToChoice(other, {
      choices = choices,
      all_choices = table.simpleClone(G.choices),
      skill_name = skill.name,
      prompt = "#sha__manbo-second::" .. target.id .. ":" .. x,
    })
    local items = { index, table.indexOf(G.choices, second) }
    table.sort(items)
    room:sendLog { type = "#sha__manbo-declare", from = other.id, arg = second }
    if target.dead or other.dead or not target:canPindian(other) then return end
    local result = target:pindian({ other }, skill.name)
    local single = result.results[other]
    -- An interrupted/no-card contest is not a tie and executes nothing.
    if not single or not result.fromCard or not single.toCard then return end
    local winner = single.winner
    local losers = {}
    if winner ~= target then table.insert(losers, target) end
    if winner ~= other then table.insert(losers, other) end
    room:sortByAction(losers)
    for _, loser in ipairs(losers) do
      G.execute(room, loser, loser == target and other or target, items, x, skill.name)
    end
  end,
})

Fk:loadTranslationTable {
  ["sha__manbo"] = "漫播",
  [":sha__manbo"] = "每名角色可于其出牌阶段开始时让你指定对象，双方各声明【嘉嗥】中不相邻的一项再拼点，由没赢的角色执行。若其手牌数大于你，只能指定你。",
  [G.round_count] = "漫播",
  ["#sha__manbo-invoke"] = "漫播：是否让 %dest 指定一名角色与你声明项目并拼点？",
  ["#sha__manbo-target"] = "漫播：指定一名角色与 %dest 声明项目并拼点（其手牌更多时只能选你）",
  ["#sha__manbo-first"] = "漫播：声明一项，%dest 随后声明不相邻的一项；没赢者执行两项（X=%arg）",
  ["#sha__manbo-second"] = "漫播：声明与 %dest 不相邻的一项；没赢者执行两项（X=%arg）",
  ["#sha__manbo-declare"] = "%from 声明了“%arg”",
  ["sha__jiahao_1"] = "① 替换武将牌为界郭嘉",
  ["sha__jiahao_2"] = "② 受到1点伤害",
  ["sha__jiahao_3"] = "③ 翻至背面并摸X张牌",
  ["sha__jiahao_4"] = "④ 交给对方至少X张牌",
  ["sha__jiahao_5"] = "⑤ 进行X+1次闪电判定",
  ["#sha__jiahao-give"] = "嘉嗥：交给 %dest 至少%arg张手牌或装备牌（不足则全部交出）",
  ["#sha__jimi-prevent"] = "%from 的“%arg”防止了此次武将牌替换",
  ["#sha__guozhou-missing"] = "%from 无法切换为界郭嘉：请启用界限突破标准武将包并完整重启",
}

return skill
