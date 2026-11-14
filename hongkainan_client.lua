-- 洪楷南（haoo__hongkainan2）的客户端表现钩子。
-- 「和梦」是否在武将牌上由隐藏标记 haoo__hemeng_drunk 表达（见 haoo__tongnan.lua）。
-- 客户端按标记动态增删〖通南〗骨架的 related_skills 中的〖和梦〗，
-- 使玩家详情弹窗（PlayerDetail.qml 读 Ltk.getPlayerSkills 的 related_skills）
-- 中紫色〖和梦〗随“喝掉/回归”消失与恢复。

local MARK = "haoo__hemeng_drunk"
local HOST_SKILL = "haoo__tongnan"
local RELATED_SKILL = "haoo__hemeng"
local HOST_GENERAL = "haoo__hongkainan2"

local function setRelated(present)
  local skel = Fk.skill_skels[HOST_SKILL]
  if not skel then return end
  skel.related_skills = skel.related_skills or {}
  local exists = table.contains(skel.related_skills, RELATED_SKILL)
  if present and not exists then
    table.insert(skel.related_skills, RELATED_SKILL)
  elseif not present and exists then
    skel.related_skills = table.filter(skel.related_skills, function(s)
      return s ~= RELATED_SKILL
    end)
  end
end

return function(base)
  if base.haoo__hongkainan_client then return end
  base.haoo__hongkainan_client = true

  local notifyUI = base.notifyUI
  base.notifyUI = function(self, command, data)
    -- 开局分到洪楷南 / 对局结束：把〖和梦〗放回武将牌上，
    -- 防止上一局“喝掉”状态泄漏到本局或大厅武将一览
    if command == "PropertyUpdate" and data[2] == "general" and data[3] == HOST_GENERAL then
      setRelated(true)
    elseif command == "GameOver" then
      setRelated(true)
    end
    return notifyUI(self, command, data)
  end

  -- 喝掉 / 回归的标记同步：驱动相关技能表增删
  local setMark = base.handleSetPlayerMark
  base.handleSetPlayerMark = function(self, data)
    local result = table.pack(setMark(self, data))
    if data[2] == MARK then
      setRelated((data[3] or 0) == 0)
    end
    return table.unpack(result, 1, result.n)
  end
end
