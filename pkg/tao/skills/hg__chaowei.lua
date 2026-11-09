local Qu = require "packages.haoo_generals.qu"
local skill = fk.CreateSkill {
  name = "hg__chaowei",
  tags = { Skill.Limited },
}

skill:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#hg__chaowei-active",
  card_num = 0,
  target_num = 0,
  max_game_use_time = 1,
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player.phase == Player.Play and player:usedSkillTimes(skill.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    for _, p in ipairs(room:getAlivePlayers()) do
      if player.dead then return end
      if not p.dead and Qu.has(p) and not Qu.protected(p) then
        local chooser = player.role == "lord" and p.kingdom == "hg_tie" and player or p
        local choice = room:askToChoice(chooser, {
          choices = { "hg__qu_keep", "hg__qu_remove" },
          skill_name = skill.name,
          prompt = "#hg__chaowei-choice::" .. p.id,
        })
        room:sendLog {
          type = "#hg__chaowei-choice-log",
          from = chooser.id,
          to = { p.id },
          arg = choice,
        }
        if choice == "hg__qu_remove" then
          Qu.remove(room, p)
        end
      end
    end
    if player.dead then return end
    local holders = Qu.holders(room)
    local n = #holders
    if n == 0 then return end
    local targets = room:askToChoosePlayers(player, {
      targets = holders,
      min_num = 1,
      max_num = n,
      cancelable = true,
      skill_name = skill.name,
      prompt = "#hg__chaowei-draw:::" .. n,
    })
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not p.dead then
        p:drawCards(n, skill.name)
      end
    end
  end,
})

Fk:loadTranslationTable {
  ["hg__chaowei"] = "潮蔚",
  [":hg__chaowei"] = "限定技，出牌阶段，你可以令所有角色选择是否移除渠，然后你令任意有渠的角色摸场上渠数张牌。若你为主公，你代替铁势力角色选择。",
  ["#hg__chaowei-active"] = "潮蔚：令角色依次选择是否移除自己的“渠”，然后令你选择的有渠角色摸牌（整局限一次）",
  ["#hg__chaowei-choice"] = "潮蔚：请选择是否移除 %dest 的“渠”",
  ["#hg__chaowei-draw"] = "潮蔚：场上剩余 %arg 个“渠”，你可以选择任意名有渠角色，各摸 %arg 张牌",
  ["hg__qu_keep"] = "保留渠",
  ["hg__qu_remove"] = "移除渠",
  ["#hg__chaowei-choice-log"] = "%from 为 %to 选择了“%arg”",
}

return skill
