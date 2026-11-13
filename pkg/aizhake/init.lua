local extension = Package:new("honggui_aizhake")
extension.extensionName = "haoo_generals"

extension:loadSkillSkelsByPath("./packages/haoo_generals/pkg/aizhake/skills")

local general = General:new(extension, "azk__aizhake", "hg_tie", 4, 4)
general.prefix = nil
general:addSkills { "azk__xingye", "azk__mangren" }
general:addRelatedSkills { "azk__qixing" }

Fk:loadTranslationTable {
  ["honggui_aizhake"] = "艾扎客",
  ["azk__aizhake"] = "艾扎客",
  ["#azk__aizhake"] = "执杖曾翻嵘",
  ["designer:azk__aizhake"] = "用户自制",
  ["cv:azk__aizhake"] = "暂无",
  ["illustrator:azk__aizhake"] = "暂无",
  ["~azk__aizhake"] = "",
}

return extension
