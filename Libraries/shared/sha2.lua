-- shared/sha2.lua
-- SHA-256 + HMAC-SHA256 en Lua 5.3 pur (entiers 64 bits + opérateurs bit à bit + string.pack).
-- Aucune dépendance matérielle (pas besoin d'une Data Card OpenComputers).
-- Vérifié contre les vecteurs de test standard (voir tools/test/run.lua).

local sha2 = {}

local MASK = 0xFFFFFFFF

local function rotr(x, n)
  return ((x >> n) | (x << (32 - n))) & MASK
end

local function shr(x, n)
  return (x >> n) & MASK
end

local function bnot32(x)
  return (~x) & MASK
end

local K = {
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}

-- Renvoie les 8 mots d'état (h0..h7) après hachage de msg.
local function core(msg)
  local h0, h1, h2, h3 = 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
  local h4, h5, h6, h7 = 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

  local bitlen = #msg * 8
  msg = msg .. "\128"
  while (#msg % 64) ~= 56 do msg = msg .. "\0" end
  msg = msg .. string.pack(">I4", (bitlen >> 32) & MASK) .. string.pack(">I4", bitlen & MASK)

  local w = {}
  for chunk = 1, #msg, 64 do
    for j = 0, 15 do
      w[j] = (string.unpack(">I4", msg, chunk + j * 4))
    end
    for j = 16, 63 do
      local a15, a2 = w[j - 15], w[j - 2]
      local s0 = rotr(a15, 7) ~ rotr(a15, 18) ~ shr(a15, 3)
      local s1 = rotr(a2, 17) ~ rotr(a2, 19) ~ shr(a2, 10)
      w[j] = (w[j - 16] + s0 + w[j - 7] + s1) & MASK
    end

    local a, b, c, d = h0, h1, h2, h3
    local e, f, g, h = h4, h5, h6, h7
    for j = 0, 63 do
      local S1 = rotr(e, 6) ~ rotr(e, 11) ~ rotr(e, 25)
      local ch = (e & f) ~ (bnot32(e) & g)
      local t1 = (h + S1 + ch + K[j + 1] + w[j]) & MASK
      local S0 = rotr(a, 2) ~ rotr(a, 13) ~ rotr(a, 22)
      local maj = (a & b) ~ (a & c) ~ (b & c)
      local t2 = (S0 + maj) & MASK
      h = g; g = f; f = e; e = (d + t1) & MASK
      d = c; c = b; b = a; a = (t1 + t2) & MASK
    end

    h0 = (h0 + a) & MASK; h1 = (h1 + b) & MASK; h2 = (h2 + c) & MASK; h3 = (h3 + d) & MASK
    h4 = (h4 + e) & MASK; h5 = (h5 + f) & MASK; h6 = (h6 + g) & MASK; h7 = (h7 + h) & MASK
  end

  return h0, h1, h2, h3, h4, h5, h6, h7
end

-- Digest binaire (32 octets).
function sha2.digest(msg)
  return string.pack(">I4I4I4I4I4I4I4I4", core(msg))
end

-- Digest hexadécimal (64 caractères).
function sha2.sha256(msg)
  return (string.format("%08x%08x%08x%08x%08x%08x%08x%08x", core(msg)))
end

-- HMAC-SHA256 -> hex.
function sha2.hmac(key, msg)
  local B = 64
  if #key > B then key = sha2.digest(key) end
  key = key .. string.rep("\0", B - #key)
  local ipad, opad = {}, {}
  for n = 1, B do
    local kb = string.byte(key, n)
    ipad[n] = string.char(kb ~ 0x36)
    opad[n] = string.char(kb ~ 0x5c)
  end
  return sha2.sha256(table.concat(opad) .. sha2.digest(table.concat(ipad) .. msg))
end

return sha2
