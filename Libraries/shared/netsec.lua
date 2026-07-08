-- shared/netsec.lua
-- Sécurité du réseau privé de l'intranet :
--   * secret partagé (déployé uniquement sur les machines admises)
--   * signature HMAC-SHA256 de chaque message (authenticité + intégrité)
--   * nonce + horodatage -> fenêtre anti-rejeu
--   * liste blanche d'adresses de composants
-- Un ordinateur qui ne connaît pas le secret ne peut ni forger ni lire un message valide.

local util = require("shared/util")
local sha2 = require("shared/sha2")

local netsec = {}

netsec.secret = "CHANGE_ME_DEFAULT_SECRET" -- à remplacer par un fichier de config déployé
netsec.window = 30                          -- tolérance d'horloge / anti-rejeu (secondes)
netsec.whitelist = nil                      -- nil = pas de filtrage ; table[addr]=true sinon

function netsec.setSecret(s)
  assert(type(s) == "string" and #s >= 8, "netsec: secret trop court")
  netsec.secret = s
end

-- Liste blanche : table {address = true}. nil pour désactiver.
function netsec.setWhitelist(set)
  netsec.whitelist = set
end

function netsec.allow(addr)
  netsec.whitelist = netsec.whitelist or {}
  netsec.whitelist[addr] = true
end

function netsec.isAllowed(addr)
  if not netsec.whitelist then return true end
  return netsec.whitelist[addr] == true
end

function netsec.mac(data)
  return sha2.hmac(netsec.secret, data)
end

-- Emballe une charge utile (string déjà sérialisée) dans une enveloppe signée.
function netsec.wrap(payload)
  assert(type(payload) == "string", "netsec.wrap attend une string")
  local body = tostring(util.now()) .. "|" .. util.uuid(16) .. "|" .. payload
  return { b = body, m = netsec.mac(body) }
end

-- Vérifie et déballe. Renvoie (payload, nonce) ou (nil, raison).
function netsec.unwrap(env)
  if type(env) ~= "table" or type(env.b) ~= "string" or type(env.m) ~= "string" then
    return nil, "malformed"
  end
  if netsec.mac(env.b) ~= env.m then
    return nil, "bad_mac"
  end
  local ts, nonce, payload = env.b:match("^(%d+)|([^|]+)|(.*)$")
  if not ts then
    return nil, "bad_body"
  end
  if netsec.window and math.abs(util.now() - tonumber(ts)) > netsec.window then
    return nil, "expired"
  end
  return payload, nonce
end

-- Format « fil » : table -> string signée prête à envoyer sur le modem.
function netsec.encode(tbl)
  return util.serialize(netsec.wrap(util.serialize(tbl)))
end

-- string reçue -> table, ou (nil, raison) si signature/format invalide.
function netsec.decode(str)
  local env = util.deserialize(str)
  if type(env) ~= "table" then return nil, "decode" end
  local payload, reason = netsec.unwrap(env)
  if not payload then return nil, reason end
  local tbl = util.deserialize(payload)
  if type(tbl) ~= "table" then return nil, "payload" end
  return tbl
end

return netsec
