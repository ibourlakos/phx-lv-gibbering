// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// ---------------------------------------------------------------------------
// DiceRoll hook — animates a tumbling SVG d6 across the viewport on attacks.
// The server fires push_event("roll_dice", %{result: N, label: "..."}).
// ---------------------------------------------------------------------------

const DICE_FACES = {
  1: [[32, 32]],
  2: [[18, 18], [46, 46]],
  3: [[18, 18], [32, 32], [46, 46]],
  4: [[18, 18], [46, 18], [18, 46], [46, 46]],
  5: [[18, 18], [46, 18], [32, 32], [18, 46], [46, 46]],
  6: [[18, 14], [46, 14], [18, 32], [46, 32], [18, 50], [46, 50]],
}

function buildDiceFaceSVG(n) {
  const dots = (DICE_FACES[n] || DICE_FACES[1])
    .map(([cx, cy]) => `<circle cx="${cx}" cy="${cy}" r="5.5" fill="#111" opacity="0.85"/>`)
    .join("")
  return `<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
    <rect x="4" y="4" width="56" height="56" rx="10" fill="#f5e6c8" stroke="#2a1a08" stroke-width="3"/>
    <rect x="6" y="6" width="52" height="52" rx="8" fill="#fff8e8"/>
    ${dots}
  </svg>`
}

function rollDiceAnimation(result, label) {
  const overlay = document.createElement("div")
  overlay.id = "dice-roll-overlay"
  overlay.style.cssText = `
    position: fixed; inset: 0; z-index: 9999; pointer-events: none;
    overflow: hidden;
  `

  const container = document.createElement("div")
  container.style.cssText = `
    position: absolute; will-change: transform;
    width: 64px; height: 64px;
    filter: drop-shadow(0 4px 16px rgba(0,0,0,0.7));
  `
  container.innerHTML = buildDiceFaceSVG(result)

  const label_el = document.createElement("div")
  label_el.style.cssText = `
    position: absolute; font-size: 22px; font-weight: 900;
    color: #f1c40f; text-shadow: 0 2px 8px #000, 0 0 20px #f39c12;
    font-family: serif; white-space: nowrap;
    opacity: 0; transition: opacity 0.25s;
    pointer-events: none;
  `
  label_el.textContent = `${label} — ${result}`

  overlay.appendChild(container)
  overlay.appendChild(label_el)
  document.body.appendChild(overlay)

  const vw = window.innerWidth
  const vh = window.innerHeight
  const fromLeft = Math.random() > 0.5

  const startX = fromLeft ? -80 : vw + 80
  const startY = vh * 0.2 + Math.random() * vh * 0.4
  const landX = vw / 2 - 32
  const landY = vh / 2 - 32
  const endX = fromLeft ? vw + 80 : -80
  const endY = startY + (Math.random() - 0.5) * 200

  const duration = 700
  const start = performance.now()
  let phase = "flying"
  let landTime = null

  function ease(t) { return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t }

  function step(now) {
    if (phase === "flying") {
      const t = Math.min((now - start) / duration, 1)
      const e = ease(t)
      const x = startX + (landX - startX) * e
      const y = startY + (landY - startY) * e
      const rot = (fromLeft ? 1 : -1) * 720 * e
      container.style.transform = `translate(${x}px, ${y}px) rotate(${rot}deg)`

      if (t >= 1) {
        phase = "landed"
        landTime = now
        container.style.transform = `translate(${landX}px, ${landY}px) rotate(0deg)`

        // bounce effect via CSS
        container.style.transition = "transform 0.18s cubic-bezier(.36,.07,.19,.97)"
        container.style.transform = `translate(${landX}px, ${landY + 18}px) scale(1.12)`
        setTimeout(() => {
          container.style.transform = `translate(${landX}px, ${landY}px) scale(1)`
        }, 180)

        // show label
        label_el.style.left = `${landX - 60}px`
        label_el.style.top = `${landY + 72}px`
        label_el.style.opacity = "1"

        // switch to result face immediately on land
        container.innerHTML = buildDiceFaceSVG(result)
      }
      if (phase === "flying") requestAnimationFrame(step)
      else setTimeout(() => requestAnimationFrame(step), 300)
    } else if (phase === "landed") {
      const held = now - landTime
      if (held < 900) {
        requestAnimationFrame(step)
      } else {
        // slide out
        phase = "leaving"
        const leaveStart = now
        requestAnimationFrame(function leave(n) {
          const t = Math.min((n - leaveStart) / 400, 1)
          const e = ease(t)
          const x = landX + (endX - landX) * e
          const y = landY + (endY - landY) * e
          container.style.transition = "none"
          container.style.transform = `translate(${x}px, ${y}px) rotate(${(fromLeft ? 1 : -1) * 360 * e}deg)`
          label_el.style.opacity = `${1 - e}`
          if (t < 1) requestAnimationFrame(leave)
          else overlay.remove()
        })
      }
    }
  }

  container.style.transform = `translate(${startX}px, ${startY}px) rotate(0deg)`
  requestAnimationFrame(step)
}

const Hooks = {
  DiceRoll: {
    mounted() {
      this.handleEvent("roll_dice", ({result, label}) => {
        rollDiceAnimation(result, label || "Rolled")
      })
    }
  },

  // ---------------------------------------------------------------------------
  // PanZoom hook — wheel zoom + pointer drag pan + arrow key pan on the SVG.
  //
  // State lives entirely in this hook; the server never sees the viewBox.
  // updated() restores the client viewBox after every LV patch, and re-centres
  // on the active entity when data-center-sx/sy changes (if data-follow="true").
  //
  // Zoom range: viewBox width clamped to [svgW/4, svgW] (1× – 4× zoom).
  // Pan clamped to one half-tile beyond each SVG edge.
  // Drag threshold of 5px distinguishes click (phx-click) from drag.
  // ---------------------------------------------------------------------------
  PanZoom: {
    mounted() {
      const vb = this.el.getAttribute("viewBox").split(" ").map(Number)
      this.vbX = vb[0]; this.vbY = vb[1]; this.vbW = vb[2]; this.vbH = vb[3]
      this.dragging = false
      this.lastCenterKey = `${this.el.dataset.centerSx},${this.el.dataset.centerSy}`

      this._wheel = e => this.onWheel(e)
      this._down  = e => this.onPointerDown(e)
      this._move  = e => this.onPointerMove(e)
      this._up    = e => this.onPointerUp(e)
      this._key   = e => this.onKeyDown(e)
      this._ctx   = e => this.onContextMenu(e)

      this.el.addEventListener("wheel", this._wheel, {passive: false})
      this.el.addEventListener("pointerdown", this._down)
      this.el.addEventListener("pointermove", this._move)
      this.el.addEventListener("pointerup", this._up)
      this.el.addEventListener("contextmenu", this._ctx)
      window.addEventListener("keydown", this._key)
    },

    destroyed() {
      this.el.removeEventListener("wheel", this._wheel)
      this.el.removeEventListener("pointerdown", this._down)
      this.el.removeEventListener("pointermove", this._move)
      this.el.removeEventListener("pointerup", this._up)
      this.el.removeEventListener("contextmenu", this._ctx)
      window.removeEventListener("keydown", this._key)
    },

    updated() {
      this.apply()

      if (this.el.dataset.follow !== "true") return
      const key = `${this.el.dataset.centerSx},${this.el.dataset.centerSy}`
      if (key === this.lastCenterKey) return
      this.lastCenterKey = key
      this.vbX = parseFloat(this.el.dataset.centerSx) - this.vbW / 2
      this.vbY = parseFloat(this.el.dataset.centerSy) - this.vbH / 2
      this.clamp()
      this.apply()
    },

    svgW() { return parseFloat(this.el.dataset.svgW) },
    svgH() { return parseFloat(this.el.dataset.svgH) },

    apply() {
      this.el.setAttribute("viewBox", `${this.vbX} ${this.vbY} ${this.vbW} ${this.vbH}`)
    },

    clamp() {
      const svgW = this.svgW(), svgH = this.svgH()
      const hw = 32, hh = 16  // half tile_w, half tile_h — one-tile margin
      this.vbX = Math.max(-hw, Math.min(svgW - this.vbW + hw, this.vbX))
      this.vbY = Math.max(-hh, Math.min(svgH - this.vbH + hh, this.vbY))
    },

    onWheel(e) {
      e.preventDefault()
      const svgW = this.svgW(), svgH = this.svgH()
      const rect = this.el.getBoundingClientRect()
      // Cursor position in SVG coordinate space
      const cx = this.vbX + (e.clientX - rect.left) / rect.width * this.vbW
      const cy = this.vbY + (e.clientY - rect.top) / rect.height * this.vbH
      // Scale factor; clamp so vbW stays in [svgW/4, svgW]
      const rawF = Math.pow(1.1, -e.deltaY / 100)
      const newVbW = Math.max(svgW / 4, Math.min(svgW, this.vbW * rawF))
      const scale = newVbW / this.vbW
      this.vbH *= scale
      this.vbW = newVbW
      // Zoom anchored at cursor
      this.vbX = cx - (cx - this.vbX) * scale
      this.vbY = cy - (cy - this.vbY) * scale
      this.clamp()
      this.apply()
    },

    onPointerDown(e) {
      if (e.button !== 0) return
      this.dragging = false
      this.ptrId = e.pointerId
      this.ptrStartX = e.clientX
      this.ptrStartY = e.clientY
    },

    onPointerMove(e) {
      if (this.ptrId !== e.pointerId) return
      if (!this.dragging) {
        if (Math.abs(e.clientX - this.ptrStartX) + Math.abs(e.clientY - this.ptrStartY) < 5) return
        this.dragging = true
        this.el.setPointerCapture(e.pointerId)
        this.ptrLastX = this.ptrStartX
        this.ptrLastY = this.ptrStartY
        this.el.style.cursor = "grabbing"
      }
      const rect = this.el.getBoundingClientRect()
      this.vbX -= (e.clientX - this.ptrLastX) * (this.vbW / rect.width)
      this.vbY -= (e.clientY - this.ptrLastY) * (this.vbH / rect.height)
      this.ptrLastX = e.clientX
      this.ptrLastY = e.clientY
      this.clamp()
      this.apply()
    },

    onPointerUp(e) {
      if (e.pointerId !== this.ptrId) return
      this.dragging = false
      this.ptrId = null
      this.el.style.cursor = ""
    },

    onContextMenu(e) {
      e.preventDefault()
      this.pushEvent("deselect_spell", {})
    },

    onKeyDown(e) {
      const tag = document.activeElement?.tagName
      if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT") return
      const step = 32  // tile_w / 2
      switch (e.key) {
        case "ArrowLeft":  this.vbX -= step; break
        case "ArrowRight": this.vbX += step; break
        case "ArrowUp":    this.vbY -= step; break
        case "ArrowDown":  this.vbY += step; break
        default: return
      }
      e.preventDefault()
      this.clamp()
      this.apply()
    }
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks,
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

