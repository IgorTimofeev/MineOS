-- Accounts.app/Main.lua
-- Application MineOS (admin) — gestion des comptes : liste, création, rôle, suppression,
-- et sessions actives. Toutes les opérations passent par le serveur (permission manage_accounts).

local ROOT = (os.getenv and os.getenv("SECSITE_ROOT")) or "/home/secsite"
package.path = ROOT .. "/?.lua;" .. ROOT .. "/?/init.lua;" .. (package.path or "")

local GUI = require("GUI")
local system = require("System")
local net = require("mineos/lib/net")
local session = require("mineos/lib/session")
local protocol = require("shared/protocol")
local roles = require("shared/roles")

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 104, 32, 0x1E1E1E))
window:addChild(GUI.panel(1, 1, window.width, 3, 0x2D2D2D))
window:addChild(GUI.text(3, 2, 0xFFFFFF, "COMPTES & RÔLES"))

local function rpc(rtype, payload)
  payload = payload or {}
  payload.token = session.token()
  return net.request(protocol.request(rtype, payload))
end

local list = window:addChild(GUI.layout(3, 9, window.width - 4, window.height - 11, 1, 1))

local function refresh()
  list:removeChildren()
  local resp = rpc(protocol.REQ.ACCOUNT_LIST)
  if not (resp and resp.ok) then
    list:addChild(GUI.text(1, 1, 0xDD4444, "Non autorisé ou serveur injoignable."))
    workspace:draw(); return
  end
  for _, a in ipairs(resp.data.accounts) do
    local row = list:addChild(GUI.container(1, 1, list.width, 1))
    local flags = (a.hasCard and "🪪 " or "") .. (a.hasPassword and "🔑" or "")
    row:addChild(GUI.text(1, 1, 0xCCCCCC, string.format("%-16s %-8s %s", a.name, a.role, flags)))
    row:addChild(GUI.button(50, 1, 12, 1, 0xB71C1C, 0xFFF, 0x2D2D2D, 0xFFF, "Supprimer")).onTouch = function()
      rpc(protocol.REQ.ACCOUNT_DELETE, { id = a.id }); refresh()
    end
  end
  workspace:draw()
end

-- Formulaire de création.
local nameInput = window:addChild(GUI.input(3, 5, 24, 1, 0x262626, 0x999, 0x262626, 0xFFF, 0xFFF, "", "nom"))
local roleCombo = window:addChild(GUI.comboBox(29, 5, 16, 1, 0x262626, 0xFFF, 0x333, 0x999))
for _, r in ipairs(roles.LIST) do roleCombo:addItem(r) end
local pwInput = window:addChild(GUI.input(47, 5, 20, 1, 0x262626, 0x999, 0x262626, 0xFFF, 0xFFF, "", "mot de passe"))
window:addChild(GUI.button(69, 5, 14, 1, 0x2E7D32, 0xFFF, 0x2D2D2D, 0xFFF, "Créer")).onTouch = function()
  local resp = rpc(protocol.REQ.ACCOUNT_CREATE, {
    name = nameInput.text, role = roleCombo:getItem(roleCombo.selectedItem).text,
    password = pwInput.text ~= "" and pwInput.text or nil,
  })
  if not (resp and resp.ok) then GUI.alert("Échec: " .. tostring(resp and resp.error)) end
  refresh()
end

window:addChild(GUI.button(85, 5, 14, 1, 0x3C3C3C, 0xFFF, 0x2D2D2D, 0xFFF, "Rafraîchir")).onTouch = refresh
refresh()
