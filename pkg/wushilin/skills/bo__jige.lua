local W = require "packages.haoo_generals.wushilin"
local skill = fk.CreateSkill {
  name = "bo__jige",
}

skill:addAcquireEffect(function(self, player) W.syncSkills(player) end)
skill:addLoseEffect(function(self, player) W.removeBorrowed(player) end)

Fk:loadTranslationTable {
  ["bo__jige"] = "稽歌",
  [":bo__jige"] = "你于未获得牌的回合内拥有【激昂】【急援】【神戟】【权计】。",
}

return skill
