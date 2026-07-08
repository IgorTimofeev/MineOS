-- shared/protocol.lua
-- Contrat de communication terminal/agent/tablette <-> serveur.
-- Les messages sont des tables sérialisées (util.serialize) puis emballées (netsec.wrap).

local protocol = {}

protocol.VERSION = 1
protocol.PORT = 2412 -- port modem dédié à l'intranet de sécurité

-- Types de requêtes (client -> serveur).
protocol.REQ = {
  PING            = "ping",
  AUTH_CARD       = "auth.card",       -- { cardId }         -> résout un compte via badge
  AUTH_PASSWORD   = "auth.password",   -- { name, password } -> login classique
  SESSION_CHECK   = "session.check",   -- { token }
  LOGOUT          = "auth.logout",     -- { token }
  ACCOUNT_LIST    = "account.list",    -- { token }
  ACCOUNT_CREATE  = "account.create",  -- { token, name, role, cardId?, password? }
  ACCOUNT_DELETE  = "account.delete",  -- { token, id }
  LOG_QUERY       = "log.query",       -- { token, limit? }
  DOOR_LIST       = "door.list",       -- { token }
  DOOR_CMD        = "door.cmd",         -- { token, id, action }
  RADAR_STATE     = "radar.state",      -- { token }
  SESSION_LIST    = "session.list",     -- { token }
  ACCOUNT_SETROLE = "account.setrole",  -- { token, id, role }
  ACCOUNT_SETCARD = "account.setcard",  -- { token, id, cardId? }
  -- Flotte (lot 4) :
  NODE_REGISTER   = "node.register",    -- { token?, address, kind }
  NODE_CMD        = "node.cmd",         -- { token, address, command }
  NODE_LIST       = "node.list",        -- { token }
  -- Collaboration (lot 5) :
  ANNOUNCE_POST   = "announce.post",    -- { token, text }
  BOARD_GET       = "board.get",        -- { token }
  MSG_SEND        = "msg.send",         -- { token, to, text }
  MSG_INBOX       = "msg.inbox",        -- { token }
  -- Salle de contrôle & protocoles (lot 7) :
  SITUATION_GET   = "situation.get",    -- { token }
  PROTOCOL_LIST   = "protocol.list",    -- { token }
  PROTOCOL_RUN    = "protocol.run",     -- { token, code, drill }
  -- Supervision réacteur & contre-mesures :
  POWER_STATE     = "power.state",      -- { token }
  REACTOR_SCRAM   = "reactor.scram",    -- { token, id }
  DEFENSE_STATE   = "defense.state",    -- { token }
  DEFENSE_MODE    = "defense.mode",     -- { token, mode }
  DEFENSE_FIRE    = "defense.fire",     -- { token }
  -- Kiosque public (sans token) & configuration :
  KIOSK_GET       = "kiosk.get",        -- {} (aucun token requis : info publique)
  SETTINGS_GET    = "settings.get",     -- { token }
  SETTINGS_SET    = "settings.set",     -- { token, key, value }
}

-- Actions de porte acceptées par DOOR_CMD.
protocol.DOOR_ACTIONS = {
  open = true, close = true,
  inner_open = true, inner_close = true,
  outer_open = true, outer_close = true,
  lockdown = true, release = true,
}

-- Types d'événements diffusés (serveur -> clients).
protocol.EVT = {
  ALERT     = "evt.alert",     -- montée DEFCON / missile
  LOCKDOWN  = "evt.lockdown",
  ANNOUNCE  = "evt.announce",  -- annonce / bulletin
}

-- Messages serveur -> agent de nœud (gestion à distance).
protocol.AGENT = {
  EXEC = "agent.exec",         -- { command } où command ∈ NODE_COMMANDS
}

protocol.NODE_COMMANDS = {
  reboot = true, shutdown = true, lock = true, status = true,
  blackout = true, release = true, -- override « poste inaccessible » + levée
}

-- Construit une requête.
function protocol.request(rtype, payload)
  local req = payload or {}
  req.v = protocol.VERSION
  req.t = rtype
  return req
end

-- Réponses normalisées.
function protocol.ok(data)
  return { ok = true, data = data }
end

function protocol.err(reason)
  return { ok = false, error = reason }
end

return protocol
