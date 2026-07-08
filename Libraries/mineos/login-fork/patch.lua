-- mineos/login-fork/patch.lua
-- Voie d'authentification « carte » ajoutée à l'écran de connexion MineOS.
-- Conçu pour être appelé DEPUIS le login MineOS forké (voir install.lua) : il écoute un swipe,
-- résout la carte auprès du serveur, et si un compte correspond, autorise l'ouverture de session.
--
-- La voie « login + mot de passe » native de MineOS reste inchangée : ce module ajoute la carte
-- À CÔTÉ, il ne remplace rien.

local ROOT = (os.getenv and os.getenv("SECSITE_ROOT")) or "/home/secsite"
package.path = ROOT .. "/?.lua;" .. ROOT .. "/?/init.lua;" .. package.path

local net = require("mineos/lib/net")
local card = require("mineos/lib/card")
local session = require("mineos/lib/session")
local blackout = require("mineos/lib/blackout")

local patch = {}

-- Tente une connexion par carte (bloquant jusqu'au swipe ou timeout).
-- Renvoie une session serveur { token, name, role } ou (nil, raison).
function patch.tryCardLogin(timeout)
  if not card.available() then return nil, "no_reader" end
  local cardId = card.await(timeout)
  if not cardId then return nil, "timeout" end
  local resp, err = net.loginCard(cardId)
  if not resp then return nil, err or "no_server" end
  if not resp.ok then return nil, resp.error end
  return resp.data
end

-- Boucle d'écoute non bloquante à brancher dans le workspace du login MineOS.
-- `onSuccess(session)` est appelé quand une carte valide est présentée.
-- Le login MineOS choisit ensuite le profil (même nom) et ouvre la session.
function patch.attach(onSuccess, onReject)
  return function()
    -- Override « poste inaccessible » : si un blackout est actif, on prend l'écran d'abord.
    if blackout.enforce() then return end
    local s, reason = patch.tryCardLogin(0.5)
    if s then
      session.set(s) -- rend le token disponible aux apps de sécurité
      if onSuccess then onSuccess(s) end
    elseif reason and reason ~= "timeout" and reason ~= "no_reader" then
      if onReject then onReject(reason) end
    end
  end
end

-- Écouteur NON bloquant pour l'écran de login MineOS forké (system.authorize).
-- Enregistre les événements OpenSecurity (magData/rfidData) — et déclenche les scans RFID —
-- puis, sur carte valide, appelle onUser(nomDeCompte, session). À insérer DANS system.authorize
-- (voir login-fork/install.lua) : le nom de compte doit correspondre à un profil MineOS.
-- Renvoie une fonction stop() à appeler quand on quitte l'écran de login.
function patch.cardListener(onUser, onReject)
  local event = require("event")
  local reader, kind = card.reader()

  local function handle(cardId)
    if not cardId or cardId == "" then return end
    local resp = net.loginCard(cardId)
    if resp and resp.ok then
      session.set(resp.data)
      if onUser then onUser(resp.data.name, resp.data) end
    elseif onReject then
      onReject(resp and resp.error or "no_server")
    end
  end

  -- magData: (_, address, playerName, cardData, cardUniqueId, isCardLocked, side)
  local onMag = function(_, _, _, cardData, cardUniqueId) handle(cardData or cardUniqueId) end
  -- rfidData: (_, uuid, playerName, distance, data)
  local onRfid = function(_, _, _, _, data) handle(data) end
  event.listen("magData", onMag)
  event.listen("rfidData", onRfid)

  local timer
  if kind == "rfid" and reader then
    timer = event.timer(1.5, function() pcall(reader.scan) end, math.huge)
  end

  return function()
    event.ignore("magData", onMag)
    event.ignore("rfidData", onRfid)
    if timer then event.cancel(timer) end
  end
end

return patch
