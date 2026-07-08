-- mineos/login-fork/autorun.lua
-- Enrobage NON INVASIF du login MineOS (pas d'édition de System.lua) :
--   * ajoute l'auth par carte à l'écran de connexion (en plus du mot de passe MineOS)
--   * applique le branding SecSite (bannière)
--   * mode kiosque optionnel (lance SecurityConsole après login)
-- À exécuter au démarrage de MineOS (installé comme autorun par install/secsite_os.lua).
--
-- ⚠️ S'appuie sur des fonctions publiques de l'API System de MineOS (setUser/updateDesktop) ;
--    les noms exacts sont À CONFIRMER en jeu. Tout est protégé par pcall : en cas d'échec, le
--    login mot de passe MineOS reste pleinement fonctionnel.

local ROOT = (os.getenv and os.getenv("SECSITE_ROOT")) or "/home/secsite"
package.path = ROOT .. "/?.lua;" .. ROOT .. "/?/init.lua;" .. (package.path or "")

local ok, system = pcall(require, "System")
if not ok then return end

local patch = require("mineos/login-fork/patch")
local session = require("mineos/lib/session")
local branding = require("shared/branding")

-- Lecture du drapeau kiosque depuis secsite.cfg.
local function kioskEnabled()
  local f = io.open(ROOT .. "/secsite.cfg", "r")
  if not f then return false end
  local data = f:read("*a"); f:close()
  local chunk = load("return " .. (data or ""), "=cfg", "t", {})
  if not chunk then return false end
  local okc, cfg = pcall(chunk)
  return okc and type(cfg) == "table" and cfg.kiosk == true
end

-- Bascule vers le bureau pour un profil donné (via API publique MineOS).
local function loginAs(userName)
  local done = false
  if system.setUser then done = pcall(system.setUser, userName) end
  if system.updateDesktop then pcall(system.updateDesktop) end
  return done
end

-- Après connexion : en mode kiosque, lance SecurityConsole en avant-plan.
local function postLogin()
  if not kioskEnabled() then return end
  pcall(function()
    dofile(ROOT .. "/mineos/apps/SecurityConsole.app/Main.lua")
  end)
end

-- Enrobe system.authorize : démarre l'écoute carte pendant l'écran de login.
if not system.__secsitePatched and system.authorize then
  system.__secsitePatched = true
  local realAuthorize = system.authorize
  function system.authorize(...)
    local stop = patch.cardListener(function(userName, sess)
      session.set(sess)
      if loginAs(userName) then
        if stop then stop() end
        postLogin()
      end
    end)
    local res = { pcall(realAuthorize, ...) }
    if stop then stop() end
    return table.unpack(res, 2)
  end
end

-- Bannière SecSite (visible si un terminal texte est disponible au boot).
pcall(function()
  for _, line in ipairs(branding.BANNER) do print(line) end
end)
