-- Logs.app/Main.lua
-- Application MineOS — consultation du journal d'audit (connexions, portes, radar, sécurité).

local ROOT = (os.getenv and os.getenv("SECSITE_ROOT")) or "/home/secsite"
package.path = ROOT .. "/?.lua;" .. ROOT .. "/?/init.lua;" .. (package.path or "")

local GUI = require("GUI")
local system = require("System")
local net = require("mineos/lib/net")
local session = require("mineos/lib/session")
local protocol = require("shared/protocol")

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 100, 30, 0x1E1E1E))
window:addChild(GUI.panel(1, 1, window.width, 3, 0x2D2D2D))
window:addChild(GUI.text(3, 2, 0xFFFFFF, "JOURNAL D'AUDIT"))

local view = window:addChild(GUI.textBox(3, 5, window.width - 4, window.height - 7, 0x161616, 0xBBBBBB, {}, 1, 0, 0))

local function refresh()
  local lines = {}
  local resp = net.request(protocol.request(protocol.REQ.LOG_QUERY, { token = session.token(), limit = 100 }))
  if resp and resp.ok then
    for _, e in ipairs(resp.data.entries) do
      lines[#lines + 1] = string.format("%s  [%s] %s — %s", e.stamp or "", e.kind or "?", e.actor or "?", e.message or "")
    end
  else
    lines = { "Serveur injoignable ou non autorisé." }
  end
  view.lines = lines
  workspace:draw()
end

window:addChild(GUI.button(3, window.height - 1, 14, 1, 0x3C3C3C, 0xFFF, 0x2D2D2D, 0xFFF, "Rafraîchir")).onTouch = refresh
refresh()
