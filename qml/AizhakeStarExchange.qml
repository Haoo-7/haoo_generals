// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import LunarLtk.Pages.Popups

// Reuse Shen Zhuge Liang's actual card box, card backs, and drag animations.
ArrangeCardsBox {
  id: root
  property var pendingCard: null

  function findTargetIndex(card, areaIdx) {
    let index = -1;
    let distance = Infinity;
    const ids = dataModel.result[areaIdx];
    for (let i = 0; i < ids.length; i++) {
      const target = dataModel.cardModels[ids[i]].cardItem;
      const delta = Math.abs(target.x - card.x);
      if (delta < distance) { index = i; distance = delta; }
    }
    return index;
  }

  function updateCardDragging(card) {
    draggingToArea = -1;
    draggingToIndex = -1;
    draggingNeedReplace = false;
    const area = findTargetArea(card);
    if (area === -1 || area === card.areaIdx) return;
    const index = findTargetIndex(card, area);
    const from = dataModel.result[card.areaIdx].indexOf(card.dataModel.cardId);
    if (!dataModel.canSwap(area === 0 ? index : from, area === 1 ? index : from)) return;
    draggingToArea = area;
    draggingToIndex = index;
    draggingNeedReplace = true;
  }

  function updateCardReleased(card) {
    const area = findTargetArea(card);
    const index = area < 0 ? -1 : findTargetIndex(card, area);
    draggingCard = null;
    draggingToArea = -1;
    draggingToIndex = -1;
    draggingNeedReplace = false;
    if (area < 0 || area === card.areaIdx) return;
    dataModel.moveCard(card.dataModel.cardId, index, card.areaIdx, area);
  }

  function updateCardSelected(card) {
    if (!card.selected) {
      if (pendingCard === card) pendingCard = null;
      return;
    }
    const previous = pendingCard;
    pendingCard = card;
    if (!previous || previous === card) return;
    if (previous.areaIdx === card.areaIdx) {
      previous.selected = false;
      return;
    }
    const star = previous.areaIdx === 0 ? previous : card;
    const hand = previous.areaIdx === 1 ? previous : card;
    const slot = dataModel.result[0].indexOf(star.dataModel.cardId);
    const handIndex = dataModel.result[1].indexOf(hand.dataModel.cardId);
    pendingCard = null;
    previous.selected = false;
    card.selected = false;
    dataModel.swapAt(slot, handIndex);
  }
}
