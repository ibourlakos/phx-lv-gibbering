# Client-Side: JS Hooks

LiveView hooks are registered in `assets/js/app.js`:

| Hook | Element | Purpose |
|---|---|---|
| `DiceRoll` | `#game-board` | Listens for `roll_dice` push events; animates a tumbling SVG d6 across the viewport |

The `roll_dice` event carries `%{result: 1..6, label: string}`. The die enters from a random screen edge, lands at centre with a bounce, displays the result pip face and label, then slides off.
