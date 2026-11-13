local extension = Package:new("honggui_guozhou")
extension.extensionName = "haoo_generals"

extension:loadSkillSkelsByPath("./packages/haoo_generals/pkg/guozhou/skills")

local general = General:new(extension, "sha__guozhou", "hg_tie", 4, 4, General.Male)
-- 殺郭周 is the full name; 殺 is not an edition prefix.
general.prefix = nil
general:addSkills {
  "sha__jimi", "sha__manbo", "sha__jiahao",
}

Fk:loadTranslationTable {
  ["honggui_guozhou"] = "殺郭周",
  ["sha__guozhou"] = "殺郭周",
  ["#sha__guozhou"] = "阖智议魏",
  ["designer:sha__guozhou"] = "用户自制",
  ["cv:sha__guozhou"] = "暂无",
  ["illustrator:sha__guozhou"] = "暂无",
  ["~sha__guozhou"] = "",
}

return extension
