local extension = Package:new("honggui_tao")
extension.extensionName = "haoo_generals"

extension:loadSkillSkelsByPath("./packages/haoo_generals/pkg/tao/skills")

General:new(extension, "hg__tao", "hg_tie", 4, 4):addSkills {
  "hg__yuanqi", "hg__dongshen", "hg__chaowei",
}

Fk:loadTranslationTable {
  ["honggui_tao"] = "洪轨·涛",
  ["hg"] = "洪轨",
  ["hg_tie"] = "铁",
  ["hg__tao"] = "涛",
  ["#hg__tao"] = "洪轨",
  ["designer:hg__tao"] = "用户自制",
  ["cv:hg__tao"] = "暂无",
  ["illustrator:hg__tao"] = "暂无",
  ["~hg__tao"] = "",
}

return extension
