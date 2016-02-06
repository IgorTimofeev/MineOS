
local component = require("component")
local debugCard = component.debug
local serialization = require("serialization")
local fs = require("filesystem")
local ecs = require("ECSAPI")
local world = debugCard.getWorld()

local worldEdit = {}

-------------------------------------------------------------------------------------------------

function worldEdit.getComputerWorldCoordinates()
  return debugCard.getX(), debugCard.getY(), debugCard.getZ()
end

function worldEdit.set(x1, y1, z1, x2, y2, z2, id, data)
  world.setBlocks(x1, y1, z1, x2, y2, z2, id, data)
end

function worldEdit.loadSchematic(path)
  local array = {}
  if not fs.exists(path) then error("File " .. path .. " doesn't exists!") end
  local file = io.open(path, "r")
  array = serialization.unserialize(file:read("*a"))
  file:close()
  return array
end

function worldEdit.saveSchematic(path, buffer)
  fs.makeDirectory(fs.path(path))
  local file = io.open(path, "w")
  file:write(serialization.serialize(buffer))
  file:close()
end

function worldEdit.paste(buffer, x, y, z)
  local computerX, computerY, computerZ = worldEdit.getComputerWorldCoordinates()
  local pasteX, pasteY, pasteZ
  for i = 1, #buffer do
    -- ecs.error(buffer[i].x, buffer[i].y, buffer[i].z, buffer[i].id, buffer[i].data )
    pasteX, pasteY, pasteZ = computerX + x + buffer[i].x - 1, computerY + y + buffer[i].y - 1, computerZ + z + buffer[i].z - 1
    if not ((pasteX == computerX) and (pasteY == computerY) and (pasteZ == computerZ)) then
      world.setBlock(pasteX, pasteY, pasteZ, buffer[i].id, buffer[i].data)
    end
  end
end

function worldEdit.copy(x1, y1, z1, x2, y2, z2)
  local array = {}
  local temp, id, data

  if x1 > x2 then
    temp = x1
    x1 = x2
    x2 = temp
  end

  if y1 > y2 then
    temp = y1
    y1 = y2
    y2 = temp
  end

  if z1 > z2 then
    temp = z1
    z1 = z2
    z2 = temp
  end

  local xCount, yCount, zCount = 0, 0, 0

  for x = x1, x2 do
    for y = y1, y2 do
      for z = z1, z2 do
        id = world.getBlockId(x, y, z) or "minecraft:air"
        data = world.getMetadata(x, y, z) or 0
        table.insert(array, 
          { 
            ["x"] = xCount,
            ["y"] = yCount,
            ["z"] = zCount,
            ["id"] = id,
            ["data"] = data
          }
        )
        -- print("Копирую блок: x = " .. x .. ", y = " .. y .. ", z = " .. z)
        zCount = zCount + 1
      end
      zCount = 0
      yCount = yCount + 1
    end
    yCount = 0
    xCount = xCount + 1
  end

  return array
end

-------------------------------------------------------------------------------------------------

-- local cyka = worldEdit.copy(1214, 72, 84, 1205, 75, 87)
-- worldEdit.paste(cyka, 0, 20, 0)
-- worldEdit.saveSchematic("testSchematic2.lua", cyka)

-------------------------------------------------------------------------------------------------

return worldEdit








