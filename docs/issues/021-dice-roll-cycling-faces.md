# #21 · Dice roll shows final face during flight instead of cycling faces

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-23
**Priority:** low
**Tags:** gameplay, rendering

## Problem

The `DiceRoll` JS hook calls `buildDiceFaceSVG(result)` at the start of the animation, so the die shows the correct final result pip face for the *entire* flight across the screen. This makes it obvious what the result will be before the die lands, removing the tension.

## Desired behaviour

While the die is in flight (rotating and tumbling), it should rapidly cycle through random pip faces. The moment it lands (and bounces), it snaps to the actual result face. This way the player can't read the outcome until impact.

## Implementation sketch

```js
// During flight: swap face every ~80ms
const flipInterval = setInterval(() => {
  const randomFace = Math.ceil(Math.random() * 6)
  container.innerHTML = buildDiceFaceSVG(randomFace)
}, 80)

// On land: clear interval and show result
clearInterval(flipInterval)
container.innerHTML = buildDiceFaceSVG(result)
```

**Acceptance criteria**
- [x] Die shows randomly cycling pip faces while tumbling in flight
- [x] Face snaps to the correct result pip at the moment of landing/bounce
