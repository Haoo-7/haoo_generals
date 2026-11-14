local jiba = fk.CreateSkill {
  name = "ts__jiba",
  dynamic_desc = function(self, player, lang)
    if player and player:getMark("ts__jiba_free") > 0 then
      return "ts__jiba_free"
    end
    return "ts__jiba"
  end,
}

Fk:loadTranslationTable {
  ["ts__jiba"] = "技霸",
  [":ts__jiba"] = "你的其余技能无效。你可以将此技能交给一名其他角色：观看其手牌并获得其一张手牌。一轮游戏结束后，你收回此技能。",
  [":ts__jiba_free"] = "你可以将此技能交给一名其他角色：观看其手牌并获得其一张手牌。一轮游戏结束后，你收回此技能。",

  ["#ts__jiba-active"] = "技霸：将“技霸”交给一名其他角色，观看其手牌并获得其中一张",
}

-- 收回“技霸”。owner 是真正的持有者（霖），就算被转手多次也认这一个人。
local function recall(room, owner)
  for _, p in ipairs(room.players) do
    if p:getMark("ts__jiba_owner") == owner.id then
      room:setPlayerMark(p, "ts__jiba_owner", 0)
      if p ~= owner and p:hasSkill(jiba.name, true) then
        room:handleAddLoseSkills(p, "-" .. jiba.name, nil, false, true)
      end
    end
  end
  if not owner.dead and not owner:hasSkill(jiba.name, true) then
    room:handleAddLoseSkills(owner, jiba.name, nil, false, true)
  end
end

-- “你的其余技能无效”。交出去以后自己不再持有本技能，其余技能自然恢复。
local function skel_name(skill)
  local skel = skill:getSkeleton()
  return skel and skel.name or skill.name
end

jiba:addEffect("invalidity", {
  global = true,
  invalidity_func = function(self, from, skill)
    local name = skel_name(skill)
    if name == jiba.name then return false end
    if skill:isEquipmentSkill(from) then return false end
    if not from:hasSkill(jiba.name, true) then return false end
    -- 破解第三项：设为持恒技后不再被本技能无效
    if name == "ts__pojie" and from:getMark("ts__pojie_permanent") > 0 then return false end
    -- 破解第二项：删掉“你的其余技能无效”这八个字
    if from:getMark("ts__jiba_free") > 0 then return false end
    return true
  end,
})

jiba:addEffect("active", {
  anim_type = "control",
  prompt = "#ts__jiba-active",
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select:isAlive()
  end,
  on_use = function(self, room, effect)
    local from = effect.from
    local target = effect.tos[1]
    if target == nil or target.dead then return end

    -- 先交出去：这一刻“技霸”不再压制自己的【破解】【资源】
    local owner_id = from:getMark("ts__jiba_owner")
    local owner = owner_id > 0 and room:getPlayerById(owner_id) or from
    room:setPlayerMark(from, "ts__jiba_owner", 0)
    room:setPlayerMark(target, "ts__jiba_owner", owner.id)
    if from:getMark("ts__jiba_free") > 0 then
      room:setPlayerMark(target, "ts__jiba_free", 1)
    end
    if from:hasSkill(jiba.name, true) then
      room:handleAddLoseSkills(from, "-" .. jiba.name, nil, false, true)
    end
    if not target:hasSkill(jiba.name, true) then
      room:handleAddLoseSkills(target, jiba.name, nil, false, true)
    end

    -- 一轮游戏结束后收回
    local round = room.logic:getMostRecentEvent(GameEvent.Round)
    if round then
      round:addExitFunc(function()
        recall(room, owner)
      end)
    end

    if target:isAlive() and #target:getCardIds("h") > 0 then
      local hand = target:getCardIds("h")
      local card = room:askToChooseCard(from, {
        target = target,
        flag = { card_data = { { "$Hand", hand } } },
        skill_name = jiba.name,
      })
      if card then
        room:obtainCard(from, card, false, fk.ReasonPrey, from, jiba.name)
      end
    end
  end,
})

return jiba
