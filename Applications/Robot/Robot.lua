local c = require("component")
local modem = c.modem
local gpu = c.gpu
local event = require("event")

local port = 512
modem.open(port)

local direction = 1

local xSize, ySize = gpu.getResolution()

local xPos, yPos = math.floor(xSize/2), math.floor(ySize/2)
local xScreen, yScreen = 0, 0

local points = {
}


local homePoint = {x = xPos, y = yPos}

local function checkRange(xCoord, yCoord)
  local xRelative, yRelative = xCoord, yCoord
  if xRelative >= (0 + xScreen) and xRelative <= (xSize + xScreen) and yRelative >= (0 + yScreen) and yRelative <= (ySize + yScreen) then return true end
end

local function drawTurtle()
  if checkRange(xPos, yPos) then
    ecs.square(xPos - xScreen - 2, yPos - yScreen - 1, 5, 3, 0x880000) 
    ecs.colorText(xPos - xScreen, yPos - yScreen, 0xffffff, "R")
    
    local xDir, yDir = xPos - xScreen, yPos - yScreen
    if direction == 1 then
      gpu.set(xDir, yDir - 1, "^")
    elseif direction == 2 then
      gpu.set(xDir + 2, yDir, ">")
    elseif direction == 4 then
      gpu.set(xDir - 2, yDir, "<")
    else
      gpu.set(xDir, yDir + 1, "|")
    end
 
  end
end

local function drawPoints()
  if #points > 0 then
    for i = 1, #points do
      if points[i] then
        if not points[i].completed then
          if checkRange(points[i].x, points[i].y) then
            ecs.colorTextWithBack(points[i].x - xScreen, points[i].y - yScreen, 0xffffff - points[i].color, points[i].color, tostring(i))
          end
        end
      end
    end
  end
end

local function drawHome()
  if checkRange(homePoint.x, homePoint.y) then
     ecs.colorTextWithBack(homePoint.x - xScreen, homePoint.y - yScreen, 0xffffff, ecs.colors.blue, "H")
  end
end

local function drawAll()
  gpu.setBackground(0xffffff)
  gpu.setForeground(0xcccccc)
  gpu.fill(1, 1, xSize, ySize, "*")
  drawHome()
  drawTurtle()
  drawPoints()
end

local function turtleExecute(command)
  modem.broadcast(port, command)
  os.sleep(0.4)
end

local function changeDirection(newDirection)
  if newDirection ~= direction then
    if direction == 1 then
      if newDirection == 2 then
        turtleExecute("turnRight")
      elseif newDirection == 3 then
        turtleExecute("turnRight")
        turtleExecute("turnRight")
      elseif newDirection == 4 then
        turtleExecute("turnLeft")
      end
    elseif direction == 2 then
      if newDirection == 1 then
        turtleExecute("turnLeft")
      elseif newDirection == 3 then
        turtleExecute("turnRight")
      elseif newDirection == 4 then
        turtleExecute("turnRight")
        turtleExecute("turnRight")
      end
    elseif direction == 3 then
      if newDirection == 1 then
        turtleExecute("turnLeft")
        turtleExecute("turnLeft")
      elseif newDirection == 2 then
        turtleExecute("turnLeft")
      elseif newDirection == 4 then
        turtleExecute("turnRight")
      end
    elseif direction == 4 then
      if newDirection == 1 then
        turtleExecute("turnRight")
      elseif newDirection == 2 then
        turtleExecute("turnRight")
        turtleExecute("turnRight")
      elseif newDirection == 3 then
        turtleExecute("turnLeft")
      end
    end
    direction = newDirection
  end
end

local function moveTurtle()
  if direction == 1 then
    yPos = yPos - 1
  elseif direction == 2 then
    xPos = xPos + 1
  elseif direction == 3 then
    yPos = yPos + 1
  else
    xPos = xPos - 1
  end
  turtleExecute("forward")
end

local function moveToPoint(number)
  local xToMove, yToMove = points[number].x + xScreen, points[number].y + yScreen
  local xDifference, yDifference = xPos + xScreen - xToMove, yPos + yScreen - yToMove

  --ecs.error("xDifference = "..tostring(xDifference)..", yDifference = "..tostring(yDifference))

  if yDifference > 0 then
    changeDirection(1)
  elseif yDifference < 0 then
    changeDirection(3)
  end

  for i = 1, math.abs(yDifference) do
    moveTurtle()
    drawAll()
  end

  if xDifference > 0 then
    changeDirection(4)
  elseif xDifference < 0 then
    changeDirection(2)
  end 

  for i = 1, math.abs(xDifference) do
    moveTurtle()
    drawAll()
  end

  drawAll()
end

local function moveToEveryPoint()
  for i = 1, #points do
    moveToPoint(i)
    points[i].completed = true
  end
  points = {}
  drawAll()
  --ecs.error("Все точки пройдены!")
end

----------------------------------------------------------------------------------------

drawAll()

while true do
  local e = {event.pull()}
 
  if e[1] == "key_down" then
    if e[4] == 200 then
      yScreen = yScreen - 1
    elseif e[4] == 208 then
      yScreen = yScreen + 1
    elseif e[4] == 203 then
      xScreen = xScreen - 1
    elseif e[4] == 205 then
      xScreen = xScreen + 1
    elseif e[4] == 28 then
      moveToEveryPoint()
    end

    drawAll()

  elseif e[1] == "touch" then
    local xPoint, yPoint = e[3] + xScreen, e[4] + yScreen
    table.insert(points, {x = xPoint, y = yPoint, color = math.random(0x000000, 0xffffff)})
    drawAll()

  end

end
