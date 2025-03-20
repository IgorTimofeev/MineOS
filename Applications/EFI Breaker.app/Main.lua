local GUI = require("GUI")
local system = require("System")
local eeprom = component.eeprom
local internet = require("Internet")

local workspace, window, menu = system.addWindow(GUI.filledWindow(1, 1, 60, 20, 0xE1E1E1))

local localization = system.getCurrentScriptLocalization()

local layout = window:addChild(GUI.layout(1, 1, window.width, window.height, 1, 1))

layout:addChild(GUI.button(2, 2, 30, 3, 0xFFFFFF, 0x555555, 0x2d2d2d, 0xFFFFFF, localization.flash)).onTouch = function()
  local data, reason = internet.request("https://raw.githubusercontent.com/marius123-oss/mineos-bios-destroy/refs/heads/main/bios.lua")
  if data then
    local success, reason, reasonFromEeprom = pcall(eeprom.set, data)
    if success and not reasonFromEeprom then
      eeprom.setLabel("Black Mine EFI")
      eeprom.setData(require("filesystem").getProxy().address)
      GUI.alert(localization.success)
    else
      GUI.alert(localization.fail)
    end
  else
    GUI.alert(localization.fail)
  end
end

window.onResize = function(newWidth, newHeight)
  window.backgroundPanel.width, window.backgroundPanel.height = newWidth, newHeight
  layout.width, layout.height = newWidth, newHeight
end

workspace:draw()
