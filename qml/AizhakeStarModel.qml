// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import LunarLtk.Models.Popups

// Keep the native Qixing two-row model, but only permit pairwise replacements.
ArrangeCardsModel {
  id: root
  property var visibleStars: []
  property int minimum: 0
  property int maximum: 7

  function initialize() {
    initializeCards();
    for (let i = 0; i < origCards[0].length; i++) {
      cardModels[origCards[0][i]].known = visibleStars[i] === true;
    }
    for (const id of origCards[1]) cardModels[id].known = true;
  }

  function changes(stars) {
    let count = 0;
    for (let i = 0; i < stars.length; i++) {
      if (stars[i] !== origCards[0][i]) count++;
    }
    return count;
  }

  function canSwap(starIndex, handIndex) {
    if (starIndex < 0 || starIndex >= result[0].length ||
        handIndex < 0 || handIndex >= result[1].length) return false;
    const next = result[0].slice();
    next[starIndex] = result[1][handIndex];
    for (let i = 0; i < next.length; i++) {
      const original = origCards[0].indexOf(next[i]);
      if (original !== -1 && original !== i) return false;
    }
    return changes(next) <= maximum;
  }

  function swapAt(starIndex, handIndex) {
    if (!canSwap(starIndex, handIndex)) return;
    const next = [result[0].slice(), result[1].slice()];
    const old = next[0][starIndex];
    next[0][starIndex] = next[1][handIndex];
    next[1][handIndex] = old;
    result = next;
  }

  function isMoveAllowed(card, areaIdx) {
    return card.areaIdx !== areaIdx && (areaIdx === 0 || areaIdx === 1);
  }

  function moveCard(cardId, toIdx, fromAreaIdx, toAreaIdx) {
    if (fromAreaIdx === toAreaIdx) return;
    const fromIdx = result[fromAreaIdx].indexOf(cardId);
    if (fromAreaIdx === 1) swapAt(toIdx, fromIdx);
    else swapAt(fromIdx, toIdx);
  }
}
