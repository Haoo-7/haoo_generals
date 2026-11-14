local extension = Package:new("honggui_zengyixiong")
extension.extensionName = "haoo_generals"

extension:loadSkillSkelsByPath("./packages/haoo_generals/pkg/zengyixiong/skills")

local general = General:new(extension, "bo__zengyixiong", "wei", 4, 4)
general.prefix = nil
general:addSkills { "bo__xiongbian", "bo__xiongqi" }
general:addRelatedSkills { "paoxiao", "benxi", "zhuhai" }

Fk:loadTranslationTable {
  ["honggui_zengyixiong"] = "一世之雄·曾奕雄",
  ["bo__zengyixiong"] = "曾奕雄",
  ["#bo__zengyixiong"] = "一世之雄",
  ["designer:bo__zengyixiong"] = "Haoo",
  ["cv:bo__zengyixiong"] = "暂无",
  ["illustrator:bo__zengyixiong"] = "铭zmy",
  ["~bo__zengyixiong"] = "",
}

return extension
