-- Reactor.app/Main.lua
-- Application MineOS — supervision réacteurs / énergie (température, combustible, puissance),
-- avec arrêt d'urgence (SCRAM) réservé au rôle admin.

local ROOT = (os.getenv and os.getenv("SECSITE_ROOT")) or "/home/secsite"
package.path = ROOT .. "/?.lua;" .. ROOT .. "/?/init.lua;" .. (package.path or "")

local GUI = require("GUI")
local system = require("System")
local net = require("mineos/lib/net")
local session = require("mineos/lib/session")
local protocol = require("shared/protocol")

local STATUS_COLOR = { ok = 0x66BB6A, warn = 0xF9A825, crit = 0xB71C1C, unknown = 0x757575 }

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 96, 30, 0x1E1E1E))
window:addChild(GUI.panel(1, 1, window.width, 3, 0x2D2D2D))
window:addChild(GUI.text(3, 2, 0xFFFFFF, "SUPERVISION RÉACTEURS / ÉNERGIE"))

local function rpc(rtype, payload)
  payload = payload or {}; payload.token = session.token()
  return net.request(protocol.request(rtype, payload))
end

local list = window:addChild(GUI.layout(3, 5, window.width - 4, window.height - 6, 1, 1))

local function refresh()
  list:removeChildren()
  local resp = rpc(protocol.REQ.POWER_STATE)
  if not (resp and resp.ok) then
    list:addChild(GUI.text(1, 1, 0xDD4444, "Non autorisé ou serveur injoignable."))
    workspace:draw(); return
  end
  for _, r in ipairs(resp.data.reactors) do
    local row = list:addChild(GUI.container(1, 1, list.width, 2))
    row:addChild(GUI.text(1, 1, STATUS_COLOR[r.status] or 0xCCCCCC, "● " .. r.name .. "  [" .. (r.status or "?") .. "]"))
    local info = {}
    if r.temp then info[#info + 1] = "T=" .. math.floor(r.temp) end
    if r.fuel then info[#info + 1] = "Fuel=" .. math.floor(r.fuel) end
    if r.power then info[#info + 1] = "P=" .. math.floor(r.power) end
    if r.energy then info[#info + 1] = "E=" .. math.floor(r.energy) end
    row:addChild(GUI.text(30, 1, 0x999999, table.concat(info, "  ")))
    row:addChild(GUI.button(70, 1, 12, 1, 0xB71C1C, 0xFFF, 0x2D2D2D, 0xFFF, "SCRAM")).onTouch = function()
      local sc = rpc(protocol.REQ.REACTOR_SCRAM, { id = r.id })
      GUI.alert((sc and sc.ok) and "SCRAM envoyé" or ("Échec: " .. tostring(sc and sc.error)))
    end
  end
  workspace:draw()
end

window:addChild(GUI.button(3, window.height - 1, 14, 1, 0x3C3C3C, 0xFFF, 0x2D2D2D, 0xFFF, "Rafraîchir")).onTouch = refresh
refresh()
