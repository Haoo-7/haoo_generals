local extension = Package:new("honggui_langzi")
extension.extensionName = "haoo_generals"

extension:loadSkillSkelsByPath("./packages/haoo_generals/pkg/langzi/skills")

General:new(extension, "lz__nanmingbi", "hg_tie", 4, 4):addSkills {
  "lz__jiangli", "lz__luguan",
}

Fk:loadTranslationTable {
  ["honggui_langzi"] = "浪子·南明毕",
  ["lz"] = "浪子",
  ["lz__nanmingbi"] = "南明毕",
  ["#lz__nanmingbi"] = "浪子",
  ["designer:lz__nanmingbi"] = "用户自制",
  ["cv:lz__nanmingbi"] = "暂无",
  ["illustrator:lz__nanmingbi"] = "用户提供",
  ["~lz__nanmingbi"] = "",
}

return extension
