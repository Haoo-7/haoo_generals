local extension = Package:new("haoo_generals")
extension.extensionName = "haoo_generals"

extension:loadSkillSkelsByPath("./packages/haoo_generals/pkg/haoo_generals/skills")

Fk:loadTranslationTable {
  ["haoo_generals"] = "铁群新设",
  ["haoo"] = "铁",
  ["zheng"] = "蒸",

  ["haoo__hongkainan"] = "洪凯南",
  ["#haoo__hongkainan"] = "那个男人入",
  ["designer:haoo__hongkainan"] = "日理万机",
  ["illustrator:haoo__hongkainan"] = "KayaK&Haoo",
  ["~haoo__hongkainan"] = "……",

  ["haoo__wanglei"] = "王累",
  ["#haoo__wanglei"] = "拼将一死",
  ["designer:haoo__wanglei"] = "Haoo",
  ["~haoo__wanglei"] = "如谏不从，自隔断其绳索，撞死于此地！",

  ["haoo__chenjinkun"] = "沈金坤",
  ["#haoo__chenjinkun"] = "空军司令",
  ["designer:haoo__chenjinkun"] = "Haoo&卝二",
  ["~haoo__chenjinkun"] = "小撸怡情，大撸伤身，强撸灰飞烟灭！",

  ["haoo__hongkainan2"] = "洪楷南",
  ["#haoo__hongkainan2"] = "南樂一覺",
  ["designer:haoo__hongkainan2"] = "Haoo",
  ["illustrator:haoo__hongkainan2"] = "KayaK&Haoo",
  ["~haoo__hongkainan2"] = "年愁今夜未到乡，卧思可哀晓南梁",

  ["ts__yuji"] = "于吉",
  ["#ts__yuji"] = "惑乱人心",
  ["designer:ts__yuji"] = "自制",
  ["cv:ts__yuji"] = "自制",
  ["illustrator:ts__yuji"] = "自制",
  ["~ts__yuji"] = "道法自然，生死无常……",

  ["ts__jiekang"] = "嵇康",
  ["#ts__jiekang"] = "竹林名士",
  ["designer:ts__jiekang"] = "自制",
  ["cv:ts__jiekang"] = "自制",
  ["illustrator:ts__jiekang"] = "自制",
  ["~ts__jiekang"] = "广陵散，终有绝响……",
}

General:new(extension, "haoo__hongkainan", "zheng", 4):addSkills { "haoo__jiangli" }
General:new(extension, "haoo__hongkainan2", "zheng", 4):addSkills { "haoo__tongnan", "haoo__hemeng" }
General:new(extension, "haoo__wanglei", "zheng", 3):addSkills { "haoo__xuanjian", "haoo__shijie" }
General:new(extension, "haoo__chenjinkun", "zheng", 4):addSkills {
  "haoo__shenkun", "haoo__yangjing", "haoo__xianzhe", "haoo__wuyi",
}
General:new(extension, "ts__yuji", "qun", 3):addSkills { "ts__nanbian", "ts__shifei", "ts__mengyan" }
General:new(extension, "ts__jiekang", "wei", 3):addSkills { "ts__zuilin", "ts__feihua", "ts__shiwai" }

return extension
