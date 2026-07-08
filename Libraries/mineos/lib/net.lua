-- mineos/lib/net.lua
-- Client RPC vers le serveur de sécurité. Utilisé par les apps MineOS, la tablette et l'agent.
-- Diffuse une requête signée sur le port privé et attend la réponse corrélée (par id).
-- Le serveur est découvert par broadcast : sur le réseau privé (HMAC + liste blanche),
-- seul le vrai serveur peut produire une réponse valide.

local ROOT = (os.getenv and os.getenv("SECSITE_ROOT")) or "/home/secsite"
package.path = ROOT .. "/?.lua;" .. ROOT .. "/?/init.lua;" .. (package.path or "")

local component = require("component")
local computer = require("computer")
local event = require("event")

local netsec = require("shared/netsec")
local protocol = require("shared/protocol")
local util = require("shared/util")

local net = {}

-- Charge le secret réseau partagé (même valeur que le serveur) depuis un fichier.
-- Sans ça, un terminal utiliserait le secret par défaut et ne verrait pas le serveur.
local function loadSecret()
  local candidates = {
    ROOT .. "/secret", ROOT .. "/server/data/secret", ROOT .. "/agent/secret",
    "/etc/secsite.secret", "/secsite.secret",
  }
  for _, path in ipairs(candidates) do
    local f = io.open(path, "r")
    if f then
      local s = (f:read("*a") or ""):gsub("%s+$", "")
      f:close()
      if #s:gsub("%s+", "") >= 8 then netsec.setSecret(s); return true end
    end
  end
  return false
end
loadSecret()

local modem = component.modem
if not modem.isOpen(protocol.PORT) then modem.open(protocol.PORT) end

-- net.request(table, timeout?) -> (réponse, nil) ou (nil, raison)
function net.request(tbl, timeout)
  timeout = timeout or 3
  tbl.id = util.uuid()
  modem.broadcast(protocol.PORT, netsec.encode(tbl))
  local deadline = computer.uptime() + timeout
  while true do
    local remaining = deadline - computer.uptime()
    if remaining <= 0 then return nil, "timeout" end
    local name, _, _, port, _, msg = event.pull(remaining, "modem_message")
    if not name then return nil, "timeout" end
    if port == protocol.PORT and msg then
      local resp = netsec.decode(msg)
      if resp and resp.id == tbl.id then
        return resp
      end
    end
  end
end

-- Raccourcis d'authentification.
function net.loginCard(cardId)
  return net.request(protocol.request(protocol.REQ.AUTH_CARD, { cardId = cardId }))
end

function net.loginPassword(name, password)
  return net.request(protocol.request(protocol.REQ.AUTH_PASSWORD, { name = name, password = password }))
end

function net.ping()
  return net.request(protocol.request(protocol.REQ.PING), 2)
end

return net
