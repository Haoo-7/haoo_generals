local Qu = require "packages.haoo_generals.qu"
local skill = fk.CreateSkill {
  name = "#hg__qu_rule",
  tags = { Skill.Compulsory },
}

local function active(room)
  return room:getTag(Qu.enabled_tag) == true
end

local function hasTaoSkill(player)
  return player:hasSkill("hg__yuanqi") or player:hasSkill("hg__dongshen") or player:hasSkill("hg__chaowei")
end

skill:addEffect(fk.GameStart, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    return hasTaoSkill(player)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setTag(Qu.enabled_tag, true)
  end,
})

skill:addEffect(fk.EventAcquireSkill, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and hasTaoSkill(player)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setTag(Qu.enabled_tag, true)
  end,
})

-- In Tao games this rule owns all canal delayed effects. Leave Jia Kui's
-- GameStart/preparation effects untouched and suppress only duplicate delays.
skill:addEffect(fk.SkillEffect, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    if target ~= player or not active(player.room) or not data.skill then return false end
    local skeleton = data.skill:getSkeleton()
    return skeleton and skeleton.name == "tongqu" and
      (data.skill.event == fk.DrawNCards or data.skill.event == fk.AfterDrawNCards or data.skill.event == fk.EnterDying)
  end,
  on_refresh = function(self, event, target, player, data)
    data.prevented = true
  end,
})

local function canalTrigger(self, event, target, player, data)
  return target == player and not player.dead and active(player.room) and Qu.has(player)
end

skill:addEffect(fk.DrawNCards, {
  global = true,
  mute = true,
  is_delay_effect = true,
  can_trigger = canalTrigger,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.n = data.n + 1
  end,
})

skill:addEffect(fk.AfterDrawNCards, {
  global = true,
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return canalTrigger(self, event, target, player, data) and not player:isNude()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local discardable = table.filter(player:getCardIds("he"), function(id)
      return not player:prohibitDiscard(Fk:getCardById(id))
    end)
    local others = table.filter(Qu.holders(room), function(p) return p ~= player end)
    -- Do not open an uncancelable dialog when every possible choice is illegal.
    if #discardable == 0 and #others == 0 then return end
    local _, result = room:askToUseActiveSkill(player, {
      skill_name = "hg__qu_give",
      prompt = "#hg__qu-give",
      cancelable = false,
      skip = true,
    })
    local cards = result and result.cards or {}
    local to = result and result.targets and result.targets[1]
    cards = table.filter(cards, function(id)
      return table.contains(player:getCardIds("he"), id)
    end)
    if #cards ~= 1 then
      discardable = table.filter(player:getCardIds("he"), function(id)
        return not player:prohibitDiscard(Fk:getCardById(id))
      end)
      if #discardable > 0 then
        cards, to = { discardable[1] }, nil
      else
        others = table.filter(Qu.holders(room), function(p) return p ~= player end)
        if #others == 0 or player:isNude() then return end
        cards, to = { player:getCardIds("he")[1] }, others[1]
      end
    end
    if to and (to == player or to.dead or not Qu.has(to)) then to = nil end
    if to then
      local id = cards[1]
      room:obtainCard(to, id, false, fk.ReasonGive, player, "hg__qu_give")
      if not to.dead and table.contains(to:getCardIds("h"), id) and Fk:getCardById(id).type == Card.TypeEquip then
        room:moveCardIntoEquip(to, id, "hg__qu_give", true, player)
      end
    elseif not player:prohibitDiscard(Fk:getCardById(cards[1])) then
      room:throwCard(cards, "hg__qu_give", player, player)
    end
  end,
})

skill:addEffect(fk.EnterDying, {
  global = true,
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return canalTrigger(self, event, target, player, data) and not Qu.protected(player)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    Qu.remove(player.room, player)
  end,
})

Fk:loadTranslationTable {
  ["#hg__qu_rule"] = "渠",
  [":#hg__qu_rule"] = "有“渠”的角色摸牌阶段多摸一张牌，然后将一张手牌或装备牌交给另一名有“渠”的角色" ..
    "或弃置一张牌；以此法交出的装备牌直接置入接收者的装备区。有“渠”的角色进入濒死状态时移除其“渠”，" ..
    "但拥有〖洞深〗的角色不会因此失去“渠”。",
  ["#hg__qu-give"] = "渠：交给另一名有渠角色一张牌（装备牌直接装备），或不选目标以弃置一张牌",
}

if Fk:translate(Qu.mark) == Qu.mark then
  Fk:loadTranslationTable { [Qu.mark] = "渠" }
end

return skill
