
---------------------------------------------------- Libraries ----------------------------------------------------

package.loaded.windows = nil
package.loaded.GUI = nil

require("advancedLua")
local computer = require("computer")
local component = require("component")
local fs = require("filesystem")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local MineOSCore = require("MineOSCore")
local event = require("event")
local unicode = require("unicode")
local image = require("image")
local bigLetters = require("bigLetters")

---------------------------------------------------- Constants ----------------------------------------------------

local mainWindow
local reactorInfo
local reactor, fieldFluxGate, outputFluxGate, rfstorage
local fieldFluxGateAddress = "fe13faa4-88b2-4291-922f-ef00b9be1fee"
local outputFluxGateAddress = "34f8f61f-6dc8-4563-95ee-5ad991e5a41a"
local rfstorageAddress = "b7ac96a5-a6bb-4b58-b066-e0261ac8cfbf"

local GUIUpdateDelay = 1
local GUIUpdateTimer = 0

local function drawBigText(object)
	bigLetters.drawText(object.x, object.y, object.color, object.text)
end

local function newBigText(x, y, color, text)
	local object = GUI.object(x, y, 1, 5)
	object.color = color
	object.draw = drawBigText
	object.text = text
	return object
end

local function addNewChartValue(chart, value)
	chart.historyIndex = (chart.historyIndex or 1) + 1
	table.insert(chart.values, {chart.historyIndex, value})
	if #chart.values > tonumber(mainWindow.chartHistorySizeTextBox.text) then table.remove(chart.values, 1) end
end

local function newChart(x, y, width, height, color, yPrefix, chartName)
	mainWindow:addChild(GUI.label(x, y, width, 1, 0xEEEEEE, chartName)); y = y + 2
	return mainWindow:addChart(x, y, width, height, 0xFFFFFF, 0xBBBBBB, 0x777777, color, 0.35, 0.3, " s", yPrefix, true, {})
end

local function log(text)
	table.insert(mainWindow.logConsole.lines, text)
	if #mainWindow.logConsole.lines > mainWindow.logConsole.height then table.remove(mainWindow.logConsole.lines, 1) end
end

local function createWindow()
	mainWindow = GUI.fullScreenContainer()
	mainWindow.backgroundPanel = mainWindow:addPanel(1, 1, mainWindow.width, mainWindow.height, 0x1B1B1B)

	local chartWidth, chartHeight = 40, math.floor((mainWindow.height - 10) / 3)
	local yChart = 2
	mainWindow.temperatureChart = newChart(mainWindow.width - chartWidth - 1, yChart, chartWidth, chartHeight, 0xFF5555, " °C", "Core temperature")
	mainWindow.enrgyChart = newChart(3, yChart, chartWidth, chartHeight, 0xFFDB40, " RF/t", "Generation rate"); yChart = yChart + chartHeight + 3
	mainWindow.fieldChart = newChart(mainWindow.width - chartWidth - 1, yChart, chartWidth, chartHeight, 0x33B6FF, "%", "Containment field")
	mainWindow.eergySaturationChart = newChart(3, yChart, chartWidth, chartHeight, 0x6624FF, "%", "Energy saturation"); yChart = yChart + chartHeight + 3
	mainWindow.storageChart = newChart(mainWindow.width - chartWidth - 1, yChart, chartWidth, chartHeight, 0x66FF80, "%", "Draconic storage")
	mainWindow.felConversionChart = newChart(3, yChart, chartWidth, chartHeight, 0xBBBBBB, "%", "Fuel conversion"); yChart = yChart + chartHeight + 3

	local x, y = chartWidth + 9, 3
	local elementWidth = mainWindow.width - chartWidth * 2 - 16
	mainWindow:addLabel(x, y, elementWidth, 1, 0xEEEEEE, "Core status"); y = y + 2
	mainWindow.statusBigText = mainWindow:addChild(newBigText(x, y, 0xEEEEEE, reactorInfo.status)); y = y + 6

	mainWindow:addLabel(x, y, elementWidth, 1, 0xEEEEEE, "Preferred core params"); y = y + 2
	mainWindow.temperatureSlider = mainWindow:addHorizontalSlider(x, y, elementWidth, 0xFF5555, 0x444444, 0xFF8888, 0xEEEEEE, 0, 8000, 7000, false, "Temperature: ", "°C"); y = y + 3
	mainWindow.fieldSlider = mainWindow:addHorizontalSlider(x, y, elementWidth, 0x33B6FF, 0x444444, 0x66DBFF, 0xEEEEEE, 0, 100, 15, false, "Field power: ", "%"); y = y + 3
	mainWindow.storageSlider = mainWindow:addHorizontalSlider(x, y, elementWidth, 0x66FF80, 0x444444, 0xCCFFBF, 0xEEEEEE, 0, 100, 90, false, "Storage fillness yield: ", "%"); y = y + 3

	mainWindow:addLabel(x, y, elementWidth, 1, 0xEEEEEE, "History log"); y = y + 2
	mainWindow.logConsole = mainWindow:addTextBox(x, y, elementWidth, 11, 0x262626, 0xCCCCCC, {}, 1, 1, 0); y = y + mainWindow.logConsole.height + 1

	local fieldWidth = 24
	mainWindow:addLabel(x, y, fieldWidth, 1, 0xEEEEEE, "Chart history size")
	mainWindow.chartHistorySizeTextBox = mainWindow:addInputTextBox(x, y + 2, fieldWidth, 3, 0x262626, 0xBBBBBB, 0x262626, 0xEEEEEE, "50", nil, true)

	mainWindow:addLabel(mainWindow.chartHistorySizeTextBox.localPosition.x + mainWindow.chartHistorySizeTextBox.width + 2, y, fieldWidth, 1, 0xEEEEEE, "History log size")
	mainWindow.logHistorySizeTextBox = mainWindow:addInputTextBox(mainWindow.chartHistorySizeTextBox.localPosition.x + mainWindow.chartHistorySizeTextBox.width + 2, y + 2, fieldWidth, 3, 0x262626, 0xBBBBBB, 0x262626, 0xEEEEEE, "50", nil, true)

	mainWindow:addLabel(mainWindow.logHistorySizeTextBox.localPosition.x + mainWindow.logHistorySizeTextBox.width + 2, y, 10, 1, 0xEEEEEE, "Chart mode")
	mainWindow.chartModeSwitch = mainWindow:addSwitch(mainWindow.logHistorySizeTextBox.localPosition.x + mainWindow.logHistorySizeTextBox.width + 2, y + 3, 10, 0xFFDB40, 0xBBBBBB, 0xFFFFFF, true)
	mainWindow.chartModeSwitch.onStateChanged = function()
		mainWindow.temperatureChart.fillChartArea = mainWindow.chartModeSwitch.state
		mainWindow.energyChart.fillChartArea = mainWindow.chartModeSwitch.state
		mainWindow.fieldChart.fillChartArea = mainWindow.chartModeSwitch.state
		mainWindow.energySaturationChart.fillChartArea = mainWindow.chartModeSwitch.state
		mainWindow.storageChart.fillChartArea = mainWindow.chartModeSwitch.state
		mainWindow.fuelConversionChart.fillChartArea = mainWindow.chartModeSwitch.state
	end
	y = y + 7

	local firstImage = image.load("/powerButton1.pic")
	local secondImage = image.load("/powerButton2.pic")
	mainWindow.powerImage = mainWindow:addImage(math.floor(x + elementWidth / 2 - firstImage.width / 2), y, firstImage)
	mainWindow.powerImage.onTouch = function()
		mainWindow.powerImage.image = mainWindow.powerImage.cyka and firstImage or secondImage
		mainWindow.powerImage.cyka = not mainWindow.powerImage.cyka
	end

	mainWindow.onDrawFinished = function()
		for i = 1, mainWindow.height do
			buffer.text(chartWidth + 5, i, 0xEEEEEE, "│")
			buffer.text(mainWindow.width - chartWidth - 4, i, 0xEEEEEE, "│")
		end
	end

	mainWindow.onAnyEvent = function(eventData)
		local uptime = computer.uptime()
		if uptime > GUIUpdateTimer then
			GUIUpdateTimer = uptime

			reactorInfo = reactor.getReactorInfo()
			addNewChartValue(mainWindow.temperatureChart, reactorInfo.temperature)
			addNewChartValue(mainWindow.fieldChart, reactorInfo.fieldStrength / reactorInfo.maxFieldStrength * 100)
			addNewChartValue(mainWindow.energyChart, reactorInfo.generationRate)
			addNewChartValue(mainWindow.storageChart, rfstorage.getEnergyStored() / rfstorage.getMaxEnergyStored() * 100)
			addNewChartValue(mainWindow.energySaturationChart, reactorInfo.energySaturation / reactorInfo.maxEnergySaturation * 100)
			addNewChartValue(mainWindow.fuelConversionChart, reactorInfo.fuelConversion / reactorInfo.maxFuelConversion * 100)

			if reactorInfo.status == "online" then
				mainWindow.statusBigText.text = "online"
			elseif reactorInfo.status == "stopping" then
				mainWindow.statusBigText.text = "stpng"
			elseif reactorInfo.status == "offline" then
				mainWindow.statusBigText.text = "yield"
			elseif reactorInfo.status == "charging" then
				mainWindow.statusBigText.text = "chrgin"
			elseif reactorInfo.status == "charged" then
				mainWindow.statusBigText.text = "chrged"
			else
				mainWindow.statusBigText.text = "uknw"
			end
			log("textInfo: " .. math.random(0, 100))

			mainWindow:draw()
			buffer.draw()
		end
	end
end

local function getProxies()
	reactor = component.proxy(component.list("draconic_reactor")())
	fieldFluxGate = component.proxy(fieldFluxGateAddress)
	outputFluxGate = component.proxy(outputFluxGateAddress)
	rfstorage = component.proxy(rfstorageAddress)
end

local function checkReactorShit()
	local reactorInfo = reactor.getReactorInfo()
	local fieldLowFlow = fieldFluxGate.getSignalLowFlow()
	local outputLowFlow = outputFluxGate.getSignalLowFlow()

	local fieldStrength = reactorInfo.fieldStrength / reactorInfo.maxFieldStrength

	print("Drain rate: " .. reactorInfo.fieldDrainRate)
	print("Target output: " .. preferredOutput)
	print("fieldStrength: " .. fieldStrength)
	print("targetdFieldStrength: " .. reactorInfo.fieldDrainRate / reactorInfo.maxFieldStrength * 100 .. "%")

	if reactorInfo.temperature > maximumTemperature or fieldStrength < minimumFieldStrength then
		fieldFluxGate.setSignalLowFlow(1000000000)
		outputFluxGate.setSignalLowFlow(0)
		computer.beep(1500, 0.2)
	else
		outputFluxGate.setSignalLowFlow(preferredOutput)

		if fieldStrength > preferredFieldStrength then
			local newFlow = fieldLowFlow / 2
			if newFlow < 2 then newFlow = 2 end
			fieldFluxGate.setSignalLowFlow(newFlow)
		else
			local newFlow = fieldLowFlow * 2
			if newFlow < 2 then newFlow = 2 end
			fieldFluxGate.setSignalLowFlow(newFlow)
		end
	end
end

local function chargeReactor()
	reactor.stopReactor()
	reactor.chargeReactor()
	local reactorInfo
	repeat
		reactorInfo = reactor.getReactorInfo()
		print("Зарядочка")
		fieldFluxGate.setSignalLowFlow(100000000)
		os.sleep(0.05)
	until reactorInfo.status == "charged" or reactorInfo.status == "online"
	reactor.activateReactor()
end

---------------------------------------------------- Meow-meow ----------------------------------------------------

buffer.changeResolution(component.gpu.maxResolution())

getProxies()
reactorInfo = reactor.getReactorInfo()
createWindow()

mainWindow:draw()
buffer.draw()
mainWindow:handleEvents(1)
