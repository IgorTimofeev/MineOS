
local drone = component.proxy(component.list("drone")())
local modem = component.proxy(component.list("modem")())
local inventory = component.proxy(component.list("inventory_controller")())
local port = 512
local moveSpeed = 1.0
local suckSide = 0

modem.open(port)

-------------------------------------

while true do
  local e = { computer.pullSignal() }
  if e[1] == "modem_message" then
    if e[4] == port then
      if e[6] == "ECSDrone" then
        drone.setStatusText("Команда: " .. e[7])
        if e[7] == "moveUp" then
          drone.move(0, moveSpeed, 0)
        elseif e[7] == "moveDown" then
          drone.move(0, -moveSpeed, 0)
        elseif e[7] == "moveForward" then
          drone.move(moveSpeed, 0, 0)
        elseif e[7] == "moveBack" then
          drone.move(-moveSpeed, 0, 0)
        elseif e[7] == "moveLeft" then
          drone.move(0, 0, -moveSpeed)
        elseif e[7] == "moveRight" then
          drone.move(0, 0, moveSpeed)
        elseif e[7] == "changeColor" then
          drone.setLightColor(math.random(0x0, 0xFFFFFF))
        elseif e[7] == "OTSOS" then
          for i = 1, (inventory.getInventorySize(0) or 1) do
            inventory.suckFromSlot(0, i)
          end
          for i = 1, (inventory.getInventorySize(1) or 1) do
            inventory.suckFromSlot(1, i)
          end
        elseif e[7] == "VIBROSI" then
          for i = 1, drone.inventorySize() do
            drone.select(i)
            drone.drop(64)
          end
        elseif e[7] == "moveSpeedUp" then
          moveSpeed = moveSpeed + 0.1
        elseif e[7] == "moveSpeedDown" then
          moveSpeed = moveSpeed - 0.1
          if moveSpeed < 0.1 then moveSpeed = 0.1 end
        end
      end
    end
  end
end











