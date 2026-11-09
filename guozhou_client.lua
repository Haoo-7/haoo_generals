local G = require "packages.haoo_generals.guozhou"

local function hideOverlay(player)
  return G.nativeSlot(player) ~= nil or G.hasPlayableBack(player)
end

return function(base)
  if base.sha__guozhou_face_display then return end
  base.sha__guozhou_face_display = true
  local notifyUI, setMark = base.notifyUI, base.handleSetPlayerMark

  -- Project only the portrait's faceup flag. Client Lua keeps the real
  -- face-down state for skills, replay data and all game-rule queries.
  -- Reconnect/observe also send their properties through notifyUI.
  base.notifyUI = function(self, command, data)
    if command == "PropertyUpdate" then
      local player = self:getPlayerById(data[1])
      if player and data[2] == "faceup" and data[3] == false and hideOverlay(player) then
        data = { data[1], data[2], true }
      end
      local result = table.pack(notifyUI(self, command, data))
      if player and (data[2] == "general" or data[2] == "deputyGeneral") and not player.faceup then
        notifyUI(self, "PropertyUpdate", { player.id, "faceup", hideOverlay(player) })
      end
      return table.unpack(result, 1, result.n)
    end
    return notifyUI(self, command, data)
  end

  base.handleSetPlayerMark = function(self, data)
    local result = table.pack(setMark(self, data))
    if data[2] == G.back or data[2] == G.permanent then
      local player = self:getPlayerById(data[1])
      if player then
        self:notifyUI("PropertyUpdate", { player.id, "faceup", player.faceup })
      end
    end
    return table.unpack(result, 1, result.n)
  end
end
