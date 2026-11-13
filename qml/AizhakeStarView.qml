// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import Fk
import LunarLtk
import LunarLtk.Components

ColumnLayout {
  id: root
  anchors.fill: parent
  property string name: ""
  property int ownerId
  property var stars: []
  property string snapshot: ""
  signal finish()

  BigGlowText {
    Layout.fillWidth: true
    Layout.preferredHeight: childrenRect.height + 4
    text: "七星 · 星位从左至右固定，牌背为未知星"
  }

  // Inspectors are local popups, so this never consumes or interrupts a turn.
  // Read the current Lua pile each time: SetPlayerPile and reconnect preserve
  // all seven slots, including those whose identities are hidden from Self.
  function refreshStars() {
    const current = Lua.fn(`function(id)
      local A = require "packages.haoo_generals.aizhake"
      local owner = Fk:currentRoom():getPlayerById(id)
      if not owner then return {} end
      return table.map(owner:getPile(A.pile), function(cid)
        return { id = cid, known = Self:cardVisible(cid) }
      end)
    end`)(ownerId);
    const signature = JSON.stringify(current);
    if (signature !== snapshot) { snapshot = signature; stars = current; }
  }

  Component.onCompleted: refreshStars()
  Timer { interval: 200; running: true; repeat: true; onTriggered: root.refreshStars() }

  Flickable {
    Layout.fillWidth: true
    Layout.fillHeight: true
    contentWidth: starRow.width
    contentHeight: starRow.height
    clip: true
    flickableDirection: Flickable.HorizontalFlick

    Row {
      id: starRow
      spacing: 5
      Repeater {
        model: root.stars
        Column {
          required property int index
          required property var modelData
          spacing: 4
          Text {
            width: 93
            horizontalAlignment: Text.AlignHCenter
            color: "#ead8b0"
            text: "星位 " + (parent.index + 1)
          }
          CardItem {
            autoBack: false
            dataModel: Ltk.createCardModel(parent.modelData.id, {
              known: parent.modelData.known,
              selectable: false
            })
          }
        }
      }
    }
  }
}
