local extension = Package:new("haoo_generals")
extension.extensionName = "haoo_generals"

extension:loadSkillSkelsByPath("./packages/haoo_generals/pkg/haoo_generals/skills")

Fk:loadTranslationTable {
  ["haoo_generals"] = "铁群新设",
  ["haoo"] = "铁",
  ["zheng"] = "蒸",
  ["hg_tie"] = "铁",
  ["hg"] = "洪轨",
  ["lz"] = "浪子",

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

  ["hg__tao"] = "涛",
  ["#hg__tao"] = "洪轨",
  ["designer:hg__tao"] = "用户自制",
  ["cv:hg__tao"] = "暂无",
  ["illustrator:hg__tao"] = "暂无",
  ["~hg__tao"] = "",

  ["lz__nanmingbi"] = "南明毕",
  ["#lz__nanmingbi"] = "浪子",
  ["designer:lz__nanmingbi"] = "用户自制",
  ["cv:lz__nanmingbi"] = "暂无",
  ["illustrator:lz__nanmingbi"] = "用户提供",
  ["~lz__nanmingbi"] = "",

  ["sha__guozhou"] = "殺郭周",
  ["#sha__guozhou"] = "阖智议魏",
  ["designer:sha__guozhou"] = "用户自制",
  ["cv:sha__guozhou"] = "暂无",
  ["illustrator:sha__guozhou"] = "暂无",
  ["~sha__guozhou"] = "",

  ["bo__wushilin"] = "吾是琳",
  ["#bo__wushilin"] = "搏",
  ["designer:bo__wushilin"] = "用户自制",
  ["cv:bo__wushilin"] = "暂无",
  ["illustrator:bo__wushilin"] = "暂无",
  ["~bo__wushilin"] = "",

  ["azk__aizhake"] = "艾扎客",
  ["#azk__aizhake"] = "执杖曾翻嵘",
  ["designer:azk__aizhake"] = "用户自制",
  ["cv:azk__aizhake"] = "暂无",
  ["illustrator:azk__aizhake"] = "暂无",
  ["~azk__aizhake"] = "",

  ["bo__zengyixiong"] = "曾奕雄",
  ["#bo__zengyixiong"] = "一世之雄",
  ["designer:bo__zengyixiong"] = "Haoo",
  ["cv:bo__zengyixiong"] = "暂无",
  ["illustrator:bo__zengyixiong"] = "铭zmy",
  ["~bo__zengyixiong"] = "",

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

  ["ts__lin"] = "霖",
  ["#ts__lin"] = "周好",
  ["designer:ts__lin"] = "自制",
  ["cv:ts__lin"] = "自制",
  ["illustrator:ts__lin"] = "自制",
  ["~ts__lin"] = "技多不压身，可惜我只有这一招……",

  ["ts__lin_sp"] = "SP 琳",
  ["#ts__lin_sp"] = "狂赌之渊",
  ["designer:ts__lin_sp"] = "自制",
  ["cv:ts__lin_sp"] = "待定",
  ["illustrator:ts__lin_sp"] = "待定",
  ["~ts__lin_sp"] = "这一次，连命运也输掉了……",
  ["ts__duidu"] = "对赌",
  [":ts__duidu"] = "出牌阶段，你可以选择牌、体力值或体力上限，并选择一名其他角色，声明X（至少为1，至多为双方该项数值的较小值；牌计手牌与装备区的牌）。你先弃置X张牌、失去X点体力或体力上限（体力上限最多只能支付到 1），然后其选择是否接受（拒绝不退还）。若接受，其支付相同代价（不足则尽量支付），双方依次亮出牌堆顶一张牌并置入弃牌堆，点数相同则重复，直至分出大小。点数较大者获得本次双方弃置且仍在弃牌堆的牌、回复2X点体力或增加2X点体力上限。每次支付计一次本回合对赌次数。",
  ["ts__tianming"] = "天命",
  [":ts__tianming"] = "出牌阶段，每项限一次，你可以声明X（1至5），选择摸X张牌、回复X点体力或增加X点体力上限。你本回合接下来X次对赌不可被拒绝（多份承诺取剩余次数最大值）。下一回合的出牌阶段开始时，你弃置2X张手牌、失去2X点体力或体力上限。若本回合结束时你本回合发动对赌不足X次，则立即支付该项代价并取消其下回合扣款。各项分别记账。",
  ["ts__sheyi"] = "奢易",
  [":ts__sheyi"] = "其他角色的出牌阶段开始时，其可以获得你至少一张手牌或装备区的牌。其本回合不能对你造成伤害，且其此后获得的牌须交给你，直到累计交给你本次取牌数两倍的牌（多笔债务先借先还）。其他角色进入濒死状态时，若你体力值大于0，其可以回复1点体力，然后你失去1点体力；其本回合不能对你造成伤害，并于你的回合开始时令你回复2点体力，然后其失去2点体力。债务不因失去本技能取消。",
  ["ts__bet_cards"] = "牌",
  ["ts__bet_hp"] = "体力值",
  ["ts__bet_maxhp"] = "体力上限",
  ["@ts__tianming_forced-turn"] = "对赌任务",
  ["@ts__tianming_debt_cards"] = "牌债",
  ["@ts__tianming_debt_hp"] = "体力债",
  ["@ts__tianming_debt_maxhp"] = "上限债",
  ["#ts__duidu-active"] = "对赌：选择支付类型、另一名角色与赌注",
  ["#ts__duidu-kind"] = "对赌：选择支付类型",
  ["#ts__duidu-target"] = "对赌：选择一名其他角色",
  ["#ts__duidu-number"] = "对赌：声明赌注（1至%arg）",
  ["#ts__duidu-pay"] = "对赌：弃置%arg张手牌或装备区的牌",
  ["#ts__duidu-accept"] = "对赌：对方已支付，你是否接受数值为%arg的赌注？",
  ["#ts__tianming-active"] = "天命：选择本阶段未用过的选项并声明X",
  ["#ts__tianming-kind"] = "天命：选择获得牌、回复体力或增加体力上限",
  ["#ts__tianming-number"] = "天命：自行声明X（1至5）",
  ["#ts__tianming-pay"] = "天命：债务到期，弃置%arg张手牌（不足则全弃）",
  ["#ts__sheyi-take"] = "奢易：是否获得该角色的牌，并承担双倍还牌债务？",
  ["#ts__sheyi-cards"] = "奢易：选择要获得的手牌或装备区的牌（至少一张）",
  ["#ts__sheyi-dying"] = "奢易：是否回复1点体力，令其失去1点体力，并承担2点体力债务？",
}

General:new(extension, "haoo__hongkainan", "zheng", 4):addSkills { "haoo__jiangli" }
General:new(extension, "haoo__hongkainan2", "zheng", 4):addSkills { "haoo__tongnan" }
General:new(extension, "haoo__wanglei", "zheng", 3):addSkills { "haoo__xuanjian", "haoo__shijie" }
General:new(extension, "haoo__chenjinkun", "zheng", 4):addSkills {
  "haoo__shenkun", "haoo__yangjing", "haoo__xianzhe", "haoo__wuyi",
}
General:new(extension, "hg__tao", "hg_tie", 4, 4):addSkills {
  "hg__yuanqi", "hg__dongshen", "hg__chaowei",
}
General:new(extension, "lz__nanmingbi", "hg_tie", 4, 4):addSkills {
  "lz__jiangli", "lz__luguan",
}
local guozhou = General:new(extension, "sha__guozhou", "hg_tie", 4, 4, General.Male)
-- 殺郭周 is the full name; 殺 is not an edition prefix.
guozhou.prefix = nil
guozhou:addSkills {
  "sha__jimi", "sha__manbo", "sha__jiahao",
}
local wushilin = General:new(extension, "bo__wushilin", "hg_tie", 4, 4)
wushilin.prefix = nil
wushilin:addSkills { "bo__jige", "bo__dansi" }
wushilin:addRelatedSkills { "jiang", "jiyuan", "shenji", "quanji", "wusheng" }
local aizhake = General:new(extension, "azk__aizhake", "hg_tie", 4, 4)
aizhake.prefix = nil
aizhake:addSkills { "azk__xingye", "azk__mangren" }
aizhake:addRelatedSkills { "azk__qixing" }
local zengyixiong = General:new(extension, "bo__zengyixiong", "wei", 4, 4)
zengyixiong.prefix = nil
zengyixiong:addSkills { "bo__xiongbian", "bo__xiongqi" }
zengyixiong:addRelatedSkills { "paoxiao", "benxi", "zhuhai" }

General:new(extension, "ts__lin", "haoo", 3):addSkills { "ts__jiba", "ts__pojie" }
General:new(extension, "ts__yuji", "qun", 3):addSkills { "ts__nanbian", "ts__shifei", "ts__mengyan" }
General:new(extension, "ts__jiekang", "wei", 3):addSkills { "ts__zuilin", "ts__feihua", "ts__shiwai" }
General:new(extension, "ts__lin_sp", "haoo", 3):addSkills { "ts__duidu", "ts__tianming", "ts__sheyi" }

return extension
