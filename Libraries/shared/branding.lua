-- shared/branding.lua
-- Identité visuelle « SecSite OS » (nom, couleurs, bannière). Utilisée par l'enrobage de login,
-- le kiosque et (optionnellement) l'en-tête des apps.

local branding = {}

branding.NAME = "SecSite OS"
branding.TAGLINE = "Terminal de sécurité"
branding.COLORS = {
  bg = 0x0E0E12,
  panel = 0x1C1C24,
  accent = 0x2E7D32,
  alert = 0xB71C1C,
  text = 0xFFFFFF,
}

branding.BANNER = {
  "==============================",
  "        S E C S I T E         ",
  "   Terminal de sécurité OC     ",
  "==============================",
}

return branding
