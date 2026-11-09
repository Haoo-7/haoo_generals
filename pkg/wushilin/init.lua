local extension = Package:new("honggui_wushilin")
extension.extensionName = "haoo_generals"

extension:loadSkillSkelsByPath("./packages/haoo_generals/pkg/wushilin/skills")

local general = General:new(extension, "bo__wushilin", "hg_tie", 4, 4)
general.prefix = nil
general:addSkills { "bo__jige", "bo__dansi" }
general:addRelatedSkills { "jiang", "jiyuan", "shenji", "quanji", "wusheng" }

Fk:loadTranslationTable {
  ["honggui_wushilin"] = "搏·吾是琳",
  ["bo__wushilin"] = "吾是琳",
  ["#bo__wushilin"] = "搏",
  ["designer:bo__wushilin"] = "用户自制",
  ["cv:bo__wushilin"] = "暂无",
  ["illustrator:bo__wushilin"] = "暂无",
  ["~bo__wushilin"] = "",
}

return extension
