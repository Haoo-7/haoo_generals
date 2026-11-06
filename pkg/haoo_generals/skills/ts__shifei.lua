local shifei = fk.CreateSkill {
  name = "ts__shifei",
}

Fk:loadTranslationTable{
  ["ts__shifei"] = "是非",
  [":ts__shifei"] = "每回合限一次（你的出牌阶段改为每种牌名限一次），你可以将一张【影】交给一名其他角色，"..
    "视为使用或打出一张基本牌或普通锦囊牌。",

  ["#ts__shifei"] = "是非：将一张【影】交给一名其他角色，视为使用或打出一张基本牌或普通锦囊牌",
  ["#ts__shifei-give"] = "是非：请选择获得此【影】的角色",
}

local function hasShade(player)
  return table.find(player:getCardIds("h"), function(id)
    return Fk:getCardById(id).trueName == "shade"
  end) ~= nil
end

local function canAsk(player)
  local room = Fk:currentRoom()
  return not player.dead and hasShade(player) and table.find(room.alive_players, function(p)
    return p ~= player
  end) ~= nil
end

local function hasNewCardName(player)
  local all_names = Fk:getAllCardNames("bt")
  local names = player:getViewAsCardNames(shifei.name, all_names)
  local used = player:getTableMark("ts__shifei-turn")
  return table.find(names, function(name)
    return not table.contains(used, name)
  end) ~= nil
end

local function enabledCheck(player)
  if not canAsk(player) then return false end
  local room = Fk:currentRoom()
  if room:getCurrent() == player and player.phase == Player.Play then
    return hasNewCardName(player)
  end
  return player:usedSkillTimes(shifei.name, Player.HistoryTurn) == 0
end

shifei:addEffect("viewas", {
  pattern = ".",
  prompt = "#ts__shifei",
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("bt")
    local names = player:getViewAsCardNames(shifei.name, all_names)
    if Fk:currentRoom():getCurrent() == player and player.phase == Player.Play then
      local used = player:getTableMark("ts__shifei-turn")
      names = table.filter(names, function(name)
        return not table.contains(used, name)
      end)
    end
    if #names == 0 then return end
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".",
  },
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "shade"
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addFakeSubcards(cards)
    card.skillName = shifei.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local card = use.card
    local tos = room:getOtherPlayers(player, false)
    if #tos == 0 then return "" end
    local targets = room:askToChoosePlayers(player, {
      targets = tos,
      min_num = 1,
      max_num = 1,
      cancelable = false,
      skill_name = shifei.name,
      prompt = "#ts__shifei-give",
    })
    if #targets == 0 then return "" end
    room:moveCardTo(card.fake_subcards, Card.PlayerHand, targets[1], fk.ReasonGive, shifei.name, nil, false, player)
    room:addTableMarkIfNeed(player, "ts__shifei-turn", card.name)
  end,
  enabled_at_play = function(self, player)
    return enabledCheck(player)
  end,
  enabled_at_response = function(self, player, response)
    return enabledCheck(player)
  end,
})

return shifei
