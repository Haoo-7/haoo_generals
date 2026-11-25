local extension = Package:new("haoo_generals")
extension.extensionName = "haoo_generals"

local luanze = Package:new("haoo_luanze")
luanze.extensionName = "haoo_generals"
if Client then
  require("packages.haoo_generals.sp_lin_client")(Client)
end

extension:loadSkillSkelsByPath("./packages/haoo_generals/pkg/haoo_generals/skills")

Fk:loadTranslationTable {
  ["haoo_generals"] = "铁群新设",
  ["haoo_luanze"] = "乱泽",
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

  ["fb__fuban"] = "副班",
  ["#fb__fuban"] = "里织帛柟",
  ["designer:fb__fuban"] = "用户自制",
  ["cv:fb__fuban"] = "暂无",
  ["illustrator:fb__fuban"] = "ShapBy三眼皮猴的万宝路&AI",
  ["~fb__fuban"] = "",

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

  ["ts__lin_sp"] = "琳",
  ["#ts__lin_sp"] = "狂徒之渊",
  ["designer:ts__lin_sp"] = "自制",
  ["cv:ts__lin_sp"] = "待定",
  ["illustrator:ts__lin_sp"] = "ShapByAI&gpt",
  ["~ts__lin_sp"] = "这一次，连命运也输掉了……",
  ["ts__duidu"] = "对赌",
  [":ts__duidu"] = "出牌阶段，你可选择一名其他角色并声明X（X至少为一且不大于双方能支付的数量；牌为手牌与装备区的牌数，对方的体力上限可支付数为空勾玉数），然后选择一项：1.弃置X张牌；2.失去X点体力；3.减X点体力上限（最少保留1点）。其选择是否接受。若其接受，其支付等量的牌、体力或体力上限，然后你与其依次亮出牌堆顶的一张牌并置入弃牌堆，点数相同则重复此流程，点数较大者获得本次双方以此法弃置在弃牌堆的牌，或回复2X点体力，或加2X点体力上限。",
  ["ts__lin_ming"] = "命",
  [":ts__tianming_awakened"] = "大于天。",
  ["ts__tianming"] = "天命",
  [":ts__tianming"] = "觉醒技，回合开始时，若当场上其余势力数不大于2，且有角色因【天劫】死亡，你删除所有划线字符。",
  ["ts__sheyi"] = "奢易",
  [":ts__sheyi"] = "其他角色的出牌阶段开始时，其可获得你任意张手牌或装备区的牌。若如此做，其本回合对你造成的伤害被防止，且其此后获得的牌须交给你，直到累计交给你本次获得牌数两倍的牌。其他角色进入濒死状态时，若你的体力值大于0，其可获得你1点体力（每名角色每回合限一次）。若如此做，其本回合对你造成的伤害被防止，且你于回合开始时收回其2点体力。当你进入濒死状态时，所有欠你体力债的角色立即交给你相应的体力。",
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

Fk:loadTranslationTable {
  ["@ts__sheyi_card_debt"] = "奢易牌债",
  ["@ts__sheyi_hp_debt"] = "奢易体力债",
}

Fk:loadTranslationTable {
  ["hshen"] = "神",

  ["huang__huang"] = "皇",
  ["#huang__huang"] = "仙瑞",
  ["designer:huang__huang"] = "自制",
  ["cv:huang__huang"] = "暂无",
  ["illustrator:huang__huang"] = "暂无",
  ["~huang__huang"] = "",
}

General:new(extension, "haoo__hongkainan", "zheng", 4):addSkills { "haoo__jiangli" }
local hongkainan2 = General:new(extension, "haoo__hongkainan2", "zheng", 4)
-- 与洪凯南（haoo__hongkainan）、南明毕（lz__nanmingbi）互为同名武将
hongkainan2.trueName = "hongkainan"
hongkainan2:addSkills { "haoo__tongnan" }
General:new(extension, "haoo__wanglei", "zheng", 3):addSkills { "haoo__xuanjian", "haoo__shijie" }
General:new(extension, "haoo__chenjinkun", "zheng", 4):addSkills {
  "haoo__shenkun", "haoo__yangjing", "haoo__xianzhe", "haoo__wuyi",
}
General:new(extension, "hg__tao", "hg_tie", 4, 4):addSkills {
  "hg__yuanqi", "hg__dongshen", "hg__chaowei",
}
local nanmingbi = General:new(extension, "lz__nanmingbi", "hg_tie", 4, 4)
nanmingbi.trueName = "hongkainan"
nanmingbi:addSkills {
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

-- 角标（prefix）默认取 id 中 "__" 之前的部分（此处为 ts），自制的 ts 系武将改成称号
local lin = General:new(luanze, "ts__lin", "haoo", 3)
lin.prefix = "周好"
-- 与殺郭周（sha__guozhou）互为同名武将
lin.trueName = "guozhou"
lin:addSkills { "ts__jiba", "ts__pojie" }

local yuji = General:new(luanze, "ts__yuji", "qun", 3)
yuji.prefix = "惑乱人心"
yuji:addSkills { "ts__nanbian", "ts__shifei", "ts__mengyan" }

local jiekang = General:new(luanze, "ts__jiekang", "wei", 3)
jiekang.prefix = "竹林名士"
jiekang:addSkills { "ts__shiwai", "ts__feihua", "ts__zuilin" }

local lin_sp = General:new(luanze, "ts__lin_sp", "haoo", 3, 4)
lin_sp.prefix = "狂徒之渊"
-- 与吾是琳（bo__wushilin）互为同名武将
lin_sp.trueName = "wushilin"
lin_sp:addSkills { "ts__tianjie", "ts__tianhou", "ts__tiansi", "ts__tianming" }

local fuban = General:new(extension, "fb__fuban", "god", 3, 3, General.Male)
fuban.subkingdom = "hg_tie"
fuban.prefix = nil
fuban:addSkills { "fb__hufu", "fb__bangban" }
fuban:addRelatedSkills { "fb__yingzi" }

-- 皇（原测试集 huang_test 并入）；角标同样改成称号
local huang = General:new(luanze, "huang__huang", "haoo", 3, 3, General.Male)
huang.prefix = "仙瑞"
huang:addSkills { "huang__daoshi", "huang__luoze" }

local cha = General:new(luanze, "cha__cha", "haoo", 3, 3)
cha.prefix = "临颧"
cha:addSkills { "cha__beizhi", "cha__bifa", "cha__jiaji", "cha__zhengdu" }
cha:addRelatedSkills { "cha__jinghua" }
Fk:loadTranslationTable {
  ["cha__cha"] = "搽刹",
  ["#cha__cha"] = "临颧",
  ["临颧"] = "临颧",
}

Fk:loadTranslationTable {
  ["haoo__linchengyuan"] = "林承源",
  ["#haoo__linchengyuan"] = "伤春悲秋",
  ["designer:haoo__linchengyuan"] = "Haoo",
  ["cv:haoo__linchengyuan"] = "暂无",
  ["illustrator:haoo__linchengyuan"] = "凡果",
  ["~haoo__linchengyuan"] = "",
  ["haoo2__linchengyuan"] = "林承源",
  ["#haoo2__linchengyuan"] = "伤春悲秋",
  ["designer:haoo2__linchengyuan"] = "Haoo",
  ["cv:haoo2__linchengyuan"] = "暂无",
  ["illustrator:haoo2__linchengyuan"] = "凡果",
  ["~haoo2__linchengyuan"] = "",
}

local linchengyuan = General:new(extension, "haoo__linchengyuan", "haoo", 3, 4, General.Male)
linchengyuan.prefix = nil
linchengyuan:addSkills { "haoo__rongku", "haoo__fengchun" }

local linchengyuan2 = General:new(extension, "haoo2__linchengyuan", "haoo", 3, 4, General.Male)
linchengyuan2.prefix = nil
linchengyuan2.total_hidden = true
linchengyuan2:addSkills { "haoo__rongku", "haoo__fengchun" }

Fk:loadTranslationTable {
  ["mt__motian"] = "漠阗",
  ["#mt__motian"] = "魏倚至何",
  ["designer:mt__motian"] = "用户自制",
  ["cv:mt__motian"] = "暂无",
  ["illustrator:mt__motian"] = "用户提供",
  ["~mt__motian"] = "",
}

local motian = General:new(extension, "mt__motian", "hg_tie", 4, 4, General.Male)
motian.prefix = nil
motian:addSkills { "mt__houfu", "mt__tianji", "mt__chouba" }
motian:addRelatedSkills { "tiandu" }

Fk:loadTranslationTable {
  ["slg__shenglugao"] = "胜律皋",
  ["#slg__shenglugao"] = "魏倚之何",
  ["designer:slg__shenglugao"] = "用户自制",
  ["cv:slg__shenglugao"] = "暂无",
  ["illustrator:slg__shenglugao"] = "用户提供",
  ["~slg__shenglugao"] = "",
}

local shenglugao = General:new(extension, "slg__shenglugao", "hg_tie", 4, 4, General.Male)
shenglugao.prefix = nil
shenglugao:addSkills { "slg__shaohuo", "slg__maoting" }

require("packages.haoo_generals.fuban").installKingdomChoice(Fk)

return { extension, luanze }
