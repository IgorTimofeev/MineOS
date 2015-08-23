local palette = require("palette")

local color = palette.draw()

if color == nil then color = "никакой. Че, серьезно? Вообще ничего не выбрал? Во петух, а?" end

print(" ")
print("Выбранный цвет = "..tostring(color))
print(" ")
