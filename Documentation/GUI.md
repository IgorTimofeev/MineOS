| Содержание |
| ----- |
| [О библиотеке](#О-библиотеке) |
| [Установка](#Установка) |
| [Standalone-методы](#standalone-методы) |
| [    GUI.contextMenu](#guicontextmenu-x-y--table-contextmenu) |
| [    GUI.error](#guierror-text-) |
| [Контейнеры](#Контейнеры) |
| [    GUI.container](#guicontainer-x-y-width-height--table-container) |
| [    GUI.layout](#guilayout-x-y-width-height-columns-rows--table-container) |
| [Виджеты](#Виджеты) |
| [    GUI.object](#guiobject-x-y-width-height--table-object) |
| [Анимация](#Анимация) |
| [Готовые виджеты](#Готовые-виджеты) |
| [    GUI.panel](#guipanel-x-y-width-height-color-transparency--table-panel) |
| [    GUI.image](#guiimage-x-y-loadedimage--table-image) |
| [    GUI.label](#guilabel-x-y-width-height-textcolor-text--table-label) |
| [    GUI.button](#guibutton-x-y-width-height-buttoncolor-textcolor-buttonpressedcolor-textpressedcolor-text--table-button) |
| [    GUI.input](#guiinput-x-y-width-height-backgroundcolor-textcolor-placeholdertextcolor-backgroundfocusedcolor-textfocusedcolor-text-placeholdertext-erasetextonfocus-textmask--table-input) |
| [    GUI.slider](#guislider-x-y-width-primarycolor-secondarycolor-pipecolor-valuecolor-minimumvalue-maximumvalue-value-showcornervalues-currentvalueprefix-currentvaluepostfix--table-slider) |
| [    GUI.switch](#guiswitch-x-y-width-primarycolor-secondarycolor-pipecolor-state--table-switch) |
| [    GUI.switchAndLabel](#guiswitchandlabel-x-y-width-switchwidth-primarycolor-secondarycolor-pipecolor-textcolor-text-switchstate--table-switchandlabel) |
| [    GUI.colorSelector](#guicolorselector-x-y-width-height-color-text--table-colorselector) |
| [    GUI.comboBox](#guicombobox-x-y-width-elementheight-backgroundcolor-textcolor-arrowbackgroundcolor-arrowtextcolor--table-combobox) |
| [    GUI.menu](#guimenu-x-y-width-backgroundcolor-textcolor-backgroundpressedcolor-textpressedcolor-backgroundtransparency--table-menu) |
| [    GUI.progressBar](#guiprogressbar-x-y-width-primarycolor-secondarycolor-valuecolor-value-thin-showvalue-valueprefix-valuepostfix--table-progressbar) |
| [    GUI.treeView](#guitreeview-x-y-width-height-backgroundcolor-textcolor-selectionbackgroundcolor-selectiontextcolor-arrowcolor-scrollbarprimarycolor-scrollbarsecondarycolor-workpath--table-treeview) |
| [    GUI.filesystemChooser](#guifilesystemchooser-x-y-width-height-backgroundcolor-textcolor-tipbackgroundcolor-tiptextcolor-initialtext-sumbitbuttontext-cancelbuttontext-placeholdertext-filesystemdialogmode-filesystemdialogpath--table-filesystemchooser) |
| [    GUI.codeView](#guicodeview-x-y-width-height-lines-fromsymbol-fromline-maximumlinelength-selections-highlights-highlightluasyntax-indentationwidth--table-codeview) |
| [    GUI.chart](#guichart-x-y-width-height-axiscolor-axisvaluecolor-axishelperscolor-chartcolor-xaxisvalueinterval-yaxisvalueinterval-xaxispostfix-yaxispostfix-fillchartarea-values--table-chart) |
| [    GUI.brailleCanvas](#guibraillecanvas-x-y-width-height-table--braillecanvas) |
| [    GUI.scrollBar](#guiscrollbar-x-y-width-height-backgroundcolor-foregroundcolor-minimumvalue-maximumvalue-value-shownvaluecount-onscrollvalueincrement-thinhorizontalmode--table-scrollbar) |
| [    GUI.textBox](#guitextboxx-y-width-height-backgroundcolor-textcolor-lines-currentline-horizontaloffset-verticaloffset-table-textbox) |
| [Практические примеры](#Практические-примеры) |
| [    Пример #1: Кнопочки](#Пример-1-Кнопочки) |
| [    Пример #2: Окно авторизации](#Пример-2-Окно-авторизации) |
| [    Пример #3: Создание собственного виджета](#Пример-3-Создание-собственного-виджета) |
| [    Пример #4: Углубленная работа с Layout](#пример-4-углубленная-работа-с-layout) |
| [    Пример #5: Анимация собственного виджета](#Пример-5-Анимация-собственного-виджета) |


О библиотеке
======
GUI - многофункциональная графическая библиотека, отлаженная под использование маломощными компьютерами с максимально возможной производительностью. С ее помощью можно реализовать самые извращенные фантазии: от банальных кнопок, слайдеров и графиков до сложных анимированных интерфейсов. Быстродействие библиотеки достигается за счет использования двойной буферизации и сложных группировочных алгоритмов.

К примеру, моя операционная система, среда разработки и 3D-приложение полностью реализованы методами данной библиотеки:

![Imgur](http://i.imgur.com/hTFGCqj.gif)

![Imgur](http://i.imgur.com/tHAiTmF.gif)

Пусть обилие текста и вас не пугает, в документации имеется множество наглядных иллюстрированных примеров и практических задач.

Установка
======

| Библиотека | Функционал |
| ------ | ------ |
| *[GUI](https://github.com/IgorTimofeev/OpenComputers/blob/master/lib/GUI.lua)* | Данная библиотека |
| *[advancedLua](https://github.com/IgorTimofeev/OpenComputers/blob/master/lib/advancedLua.lua)* | Дополнение стандартных библиотек Lua множеством функций: быстрой сериализацией таблиц, переносом строк, методами обработки бинарных данных и т.д. |
| *[doubleBuffering](https://github.com/IgorTimofeev/OpenComputers/blob/master/lib/doubleBuffering.lua)* | Низкоуровневая библиотека двойной буферизации для максималььно быстрой отрисовки графики с поддержкой методов полупиксельной отрисовки |
| *[color](https://github.com/IgorTimofeev/OpenComputers/blob/master/lib/color.lua)* | Низкоуровневая библиотека для работы с цветом, предоставляющая методы получения цветовых каналов, различные палитры и конвертацию цвета в 8-битный формат |
| *[image](https://github.com/IgorTimofeev/OpenComputers/blob/master/lib/image.lua)* | Библиотека, реализующая стандарт изображений для OpenComputers и методы их обработки: транспонирование, обрезку, поворот, отражение и т.д. |
| *[OCIF](https://github.com/IgorTimofeev/OpenComputers/blob/master/lib/ImageFormatModules/OCIF.lua)* | Модуль формата изображения OCIF (OpenComputers Image Format) для библиотеки image, написанный с учетом особенностей мода и реализующий эффективное сжатие пиксельных данных |
| *[syntax](https://github.com/IgorTimofeev/OpenComputers/blob/master/lib/syntax.lua)* | Подсветка lua-синтаксиса для виджета CodeView |
| *[palette](https://github.com/IgorTimofeev/OpenComputers/blob/master/lib/palette.lua)* | Библиотека-окно для работы с цветом в режиме HSV и выборе конкретных цветовых данных для виджета ColorSelector |

Вы можете использовать имеющиеся выше ссылки для установки зависимостей вручную или запустить автоматический [установщик](https://pastebin.com/ryhyXUKZ), загружающий все необходимые файлы за вас:

    pastebin run ryhyXUKZ

Standalone-методы
======

Библиотека имеет несколько полезных независимых методов, упрощающих разработку программ. К таковым относятся, к примеру, контекстное меню и информационное alert-окно.

GUI.**contextMenu**( x, y ): *table* contextMenu
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата меню по оси x |
| *int* | y | Координата меню по оси y |

Открыть по указанным координатам контекстное меню и ожидать выбора пользователя. При выборе какого-либо элемента будет вызван его callback-метод .**onTouch**, если таковой имеется.

Если контекстное меню содержит слишком большое количество элементов, то появятся удобные кнопочки и поддержка колеса мыши для прокрутки содержимого.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *function* | :**addItem**( *string* text, *boolean* disabled, *string* shortcut, *int* color )| Добавить в контекстное меню элемент с указанными параметрами. При параметре disabled элемент не будет реагировать на клики мышью. Каждый элемент может иметь собственный callback-метод .**onTouch** для последующей обработки данных |
| *function* | :**addSeparator**()| Добавить в контекстное меню визуальный разделитель |
| *function* | :**addSubMenu**(*string* text): *table* contextMenu| Добавить в данное контекстное меню другое контекстное меню. Возвращаемый методом объект меню самостоятелен и поддерживает все описанные выше методы  |   |

Пример реализации контекстного меню:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

------------------------------------------------------------------------------------------

local contextMenu = GUI.contextMenu(2, 2)
contextMenu:addItem("New")
contextMenu:addItem("Open").onTouch = function()
	-- Do something to open file or whatever
end

local subMenu = contextMenu:addSubMenu("Open with")
subMenu:addItem("Explorer.app")
subMenu:addItem("Viewer.app")
subMenu:addItem("Finder.app")
subMenu:addSeparator()
subMenu:addItem("Browse...")

contextMenu:addSeparator()
contextMenu:addItem("Save", true)
contextMenu:addItem("Save as")
contextMenu:addSeparator()
for i = 1, 25 do
	contextMenu:addItem("Do something " .. i)
end

------------------------------------------------------------------------------------------

buffer.clear(0x2D2D2D)
buffer.draw(true)
contextMenu:show()
```

Результат:

![Imgur](http://i.imgur.com/A9NCEdc.gif)

GUI.**error**( text )
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *string* | text | Текст информационного окна |


Показать отладочное окно с текстовой информацией. Слишком длинная строка будет автоматически перенесена. Для закрытия окна необходимо использовать клавишу return или нажать на кнопку "ОК".

Пример реализации:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

buffer.clear(0x2D2D2D)
GUI.error("Something went wrong here, my friend")
```

Результат:

![Imgur](http://i.imgur.com/s8mA2FL.png?1)

Контейнеры
======

Вся библиотека делится на две основные кострукции: контейнеры и виджеты. Контейнер предназначен для группировки нескольких виджетов и их конвеерной обработки, поэтому в первую очередь необходимо изучить особенности работы с контейнерами.

GUI.**container**( x, y, width, height ): *table* container
-----------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата контейнера по оси x |
| *int* | y | Координата контейнера по оси y |
| *int* | width | Ширина контейнера |
| *int* | height | Высота контейнера |

Каждый контейнер - это группировщик для других объектов, его поведение очень похоже на папку, содержащую множество вложенных файлов и других папок. Для создания контейнера по размеру экрана используйте метод GUI.**fullScreenContainer**().

Все дочерние элементы контейнера имеют свою *localPosition* в контейнере (к примеру, *{x = 4, y = 2}*). После добавления дочернего элемента в контейнер для дальнейших рассчетов используется именно его локальная позиция. Для получения глобальных (экранных) координат дочернего элемента необходимо обращаться к *element.x* и *element.y*. Глобальная (экранная) позиция дочерних элементов рассчитывается при каждой отрисовке содержимого контейнера. Таким образом, изменяя глобальные координаты дочернего элемента вручную, вы, в сущности, ничего не добьётесь.

Наглядно система иерархии и позиционирования контейнеров и дочерних элементов представлена на следущем изображении:

![Imgur](http://i.imgur.com/nU2bLU8.png?1)

У контейнеров имеется немаловажная особенность: любой дочерний элемент, выступающий за границы контейнера, будет отрисован только в рамках размера этого контейнера:

![Imgur](http://i.imgur.com/PMtOpNS.png?1)

Для добавления в контейнер дочернего элемента используйте синтаксическую конструкцию :**addChild**(**<Объект>**). При этом глобальные координаты объекта становятся локальными. К примеру, для добавления кнопки на локальную позицию *x = 5, y = 10* используйте :**addChild**(GUI.**button**(5, 10, ...)). В контейнер можно добавлять другие контейнеры, а в добавленные - еще одни, создавая сложные иерархические цепочки и группируя дочерние объекты по своему усмотрению.

Наконец, самая важная особенность контейнеров - это автоматизированная обработка системных событий. Для запуска обработки событий необходимо вызвать метод :**startEventHandling**. После этого при каждом событии текущий контейнер и всего его вложенные объекты будут рекурсивно проанализированы на наличие метода-обработчика .**eventHandler**.

Если метод-обработчик имеется, то он будет вызван со следующими аргументами: *container* mainContainer, *object* object, *table* eventData, где первым аргументом является контейнер, обрабатывающий события, вторым является текущий рассматриваемый объект обработчика событий, а третьим - таблица с данными события. Многие объекты, перечисленные ниже, уже имеют собственный .**eventHandler** - к примеру, кнопка автоматически нажимается, слайдер перемещается влево-вправо, а селектор цвета открывает палитру для выбора желаемого оттенка. Все это реализовано именно на методе-обработчике. 

В качестве примера ниже приведен исходный код обработчика событий GUI.**button**. Как видите, в начале событие анализируется на соответствие "touch", затем кнопка визуально "нажимается", а в конце вызывается метод кнопки .*onTouch*, если он вообще имеется.
```lua
button.eventHandler = function(mainContainer, button, eventData)
	if eventData[1] == "touch" then
		button.pressed = true
		mainContainer:draw()
		buffer.draw()
		
		os.sleep(0.2)
		
		button.pressed = false
		mainContainer:draw()
		buffer.draw()
		
		if button.onTouch then
			button.onTouch(mainContainer, object, eventData)
		end
	end
end
```

Ключевая деталь обработчика событий в том, что если событие "экранное", то есть относящееся к клику пользователя на монитор (touch, drag, drop, scroll), то метод-обработчик объекта будет вызван только в том случае, если на пути прослеживания клика не имеется никаких других объектов, после чего обработка событий для оставшихся необработанных дочерних элементов завершится. Если событие не относится к экрану (key_down, clipboard и т.д.), или же объект не имеет метода-обработчика, то обработка оставшихся дочерних элементов продолжится в прежнем виде.

Если необходимо прекратить обработку событий, то необходимо вызвать метод :**stopEventHandling**.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *function* | :**addChild**( *table* child, [*int* atIndex] ): *table* child| Добавить произвольный объект в контейнер в качестве дочернего - таким образом вы способны создавать собственные виджеты с индивидуальными особенностями. Уточняю, что у добавляемого объекта **обязательно** должен иметься метод *:draw* (подробнее см. ниже). При добавлении объекта его глобальные координаты становятся локальными. Если указан опциональный параметр *atIndex*, то элемент будет добавлен на соответствующую позицию |
| *function* | :**deleteChildren**([*int* fromIndex, *int* toIndex]): *table* container | Удалить все дочерние элементы контейнера. Если указаны опциональные параметры индексов элементов, то удаление будет произведено в соответствующем диапазоне |
| *function* | :**draw**(): *table* container | Рекурсивная отрисовка содержимого контейнера в порядке очереди его дочерних элементов. Обращаю внимание на то, что данный метод осуществляет отрисовку только в экранный буфер. Для отображения изменений на экране необходимо использовать метод библиотеки двойного буфера *.draw()* |
| *function* | :**startEventHandling**([*float* delay]): *table* container | Запуск обработчика событий для данного контейнера и всех вложенных в него дочерних элементов. Параметр *delay* аналогичен таковому в computer.**pullSignal** |
| *function* | :**stopEventHandling**(): *table* container | Остановка обработчика событий для данного контейнера |

GUI.**layout**( x, y, width, height, columns, rows ): *table* container
-----------------------------------------------------

| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | height | Высота объекта |
| *int* | columnCount | Количество рядов сетки |
| *int* | rowCount | Количество строк сетки |

Layout является наследником GUI.**container**, автоматически располагающим дочерние объекты внутри себя. К примеру, если вам хочется визуально красиво отобразить множество объектов, не тратя время на ручной расчет координат, то layout создан для вас. На картинке ниже подробно показана структура layout размером 4x3:

![Imgur](http://i.imgur.com/qf91PuM.png)

Видно, что имеется 12 ячеек, каждая из которых может иметь собственную ориентацию объектов, расстояние между ними, а также выравнивание по границам. Границы ячеек условны, так что дочерние объекты могут без проблем выходить за них, если это допускает указанный alignment. Каждому столбцу и каждому ряду можно задать свой индивидуальный размер либо в пикселях, либо в процентном отношении, так что работа с layout фантастически удобна.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
|*boolean*| .**showGrid**| Включение или отключение отображения границ координатной сетки. По умолчанию равно false |
| *function* | :**setGridSize**(*int* columnCount, *int* columnCount): *layout* layout | Установить размер сетки. Все объекты, находящиеся вне диапазона нового размера, должны быть размещены в сетке заново через :**setCellPosition**()  |
| *function* | :**setColumnWidth**(*int* column, *enum* sizePolicy, *float* size): *layout* layout | Установить ширину указанного столбца. Ширина может быть двух типов: GUI.**sizePolicies.absolute** или GUI.**sizePolicies.percentage**. В первом случае ширина выражена в пикселях, и не меняется при изменении размеров layout, а во втором она выражена дробным числом в промежутке **[0; 1]**, обозначающим процентную ширину столбца. Если указана процентная ширина, и справа от выбранного столбца имеются другие, то их процентная ширина будет автоматически перерассчитана до нужных процентных значений. |
| *function* | :**setRowHeight**(*int* row, *enum* sizePolicy, *float* size): *layout* layout | Установить высоту указанного ряда. Поведение метода аналогично **:setColumnWidth** |
| *function* | :**addColumn**(*enum* sizePolicy, *float* size): *layout* layout | Добавить в сетку layout пустой столбец с указанным размером |
| *function* | :**addRow**(*enum* sizePolicy, *float* size): *layout* layout | Добавить в сетку layout пустой ряд с указанным размером |
| *function* | :**removeColumn**(*int* column): *layout* layout | Удалить из сетки layout указанный столбец |
| *function* | :**removeRow**(*int* row): *layout* layout | Удалить из сетки layout указанный ряд |
| *function* | :**setCellPosition**(*int* column, *int* row, *object* child): *object* child| Назначить дочернему объекту layout конкретную ячейку сетки. В одной ячейке может располагаться сколь угодно много объектов. |
| *function* | :**setCellDirection**(*int* column, *int* row, *enum* direction): *layout* layout | Назначить ячейке сетки ориентацию дочерних объектов. Поддерживаются GUI.directions.horizontal и GUI.directions.vertical |
| *function* | :**setCellAlignment**(*int* column, *int* row, *enum* GUI.alignment.vertical, *enum* GUI.alignment.horizontal): *layout* layout | Назначить ячейке сетки метод выравнивания дочерних объектов. Поддерживаются все 9 вариантов |
| *function* | :**setCellSpacing**(*int* column, *int* row, *int* spacing): *layout* layout | Назначить ячейке сетки расстояние в пикселях между объектами. По умолчанию оно равняется 1 |
| *function* | :**setCellMargin**(*int* column, *int* row, *int* horizontalMargin, *int* verticalMargin): *layout* layout | Назначить ячейке сетки отступы в пикселях в зависимости от текущего *alignment* этой ячейки |
| *function* | :**setCellFitting**(*int* column, *int* row, *int* horizontalFitting, *int* verticalFitting): *layout* layout | Назначить ячейке сетки параметр автоматического назначения размера дочерних элементов равным размеру соответствующего ряда/столбца|

Пример реализации layout:
```lua
local image = require("image")
local buffer = require("doubleBuffering")
local GUI = require("GUI")

-- Создаем полноэкранный контейнер, добавляем на него загруженное изображение и полупрозрачную черную панель
local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.image(1, 1, image.load("/MineOS/Pictures/Raspberry.pic")))
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x000000, 40))

-- Добавляем в созданный контейнер layout с сеткой размером 5x1
local layout = mainContainer:addChild(GUI.layout(1, 1, mainContainer.width, mainContainer.height, 5, 1))

-- Добавяляем в layout 9 кнопок, назначая им соответствующие позиции в сетке.
-- Как видите, сначала создается объект кнопки, затем он добавляется в качестве дочернего к layout,
-- а в конце концов ему назначается позиция сетки.
layout:setCellPosition(1, 1, layout:addChild(GUI.button(1, 1, 26, 3, 0xEEEEEE, 0x000000, 0xAAAAAA, 0x000000, "Button 1")))
layout:setCellPosition(2, 1, layout:addChild(GUI.button(1, 1, 26, 3, 0xEEEEEE, 0x000000, 0xAAAAAA, 0x000000, "Button 2")))
layout:setCellPosition(2, 1, layout:addChild(GUI.button(1, 1, 26, 3, 0xEEEEEE, 0x000000, 0xAAAAAA, 0x000000, "Button 3")))
layout:setCellPosition(3, 1, layout:addChild(GUI.button(1, 1, 26, 3, 0xEEEEEE, 0x000000, 0xAAAAAA, 0x000000, "Button 4")))
layout:setCellPosition(3, 1, layout:addChild(GUI.button(1, 1, 26, 3, 0xEEEEEE, 0x000000, 0xAAAAAA, 0x000000, "Button 5")))
layout:setCellPosition(3, 1, layout:addChild(GUI.button(1, 1, 26, 3, 0xEEEEEE, 0x000000, 0xAAAAAA, 0x000000, "Button 6")))
layout:setCellPosition(4, 1, layout:addChild(GUI.button(1, 1, 26, 3, 0xEEEEEE, 0x000000, 0xAAAAAA, 0x000000, "Button 7")))
layout:setCellPosition(4, 1, layout:addChild(GUI.button(1, 1, 26, 3, 0xEEEEEE, 0x000000, 0xAAAAAA, 0x000000, "Button 8")))
layout:setCellPosition(5, 1, layout:addChild(GUI.button(1, 1, 26, 3, 0xEEEEEE, 0x000000, 0xAAAAAA, 0x000000, "Button 9")))

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![Imgur](http://i.imgur.com/ti58Z75.png?1)

Как видите, 9 кнопок автоматически сгруппировались по 5 ячейкам сетки. Визуально структура созданного layout выглядит так:

![Imgur](http://i.imgur.com/4l7uK25.png)

Также мы можем модифицировать код, чтобы кнопки группировались в 3 колонки, а расстояние между ними было равным 4 пикселям. А заодно включим отображение координатной сетки и активируем автоматический расчет ширины объектов в 3 колонке:

```lua
-- Включаем отображение границ сетки
layout.showGrid = true
-- Изменяем размер сетки на 3x1
layout:setGridSize(3, 1)
-- Устанавливаем расстояние между объектами для каждой колонки
for column = 1, 3 do
	layout:setCellSpacing(column, 1, 4)
end
-- Обновляем позиции трех последних кнопок, чтобы они принадлежали третьей колонке
for child = 7, 9 do
	layout:setCellPosition(3, 1, layout.children[child])
end
-- Включаем автоматическое изменение ширины дочерних элементов в ячейке 3x1
layout:setCellFitting(3, 1, true, false)
```
Результат:

![Imgur](http://i.imgur.com/C2TWOJ7.png)

Более подробно работа с layout рассмотрена в практическом примере 4 в конце документа.

Виджеты
======

После понимания концепции контейнеров можно с легкостью приступить к добавлению виджетов в созданный контейнер. Каждый виджет - это наследник объекта типа GUI.**object**

GUI.**object**( x, y, width, height ): *table* object
-----------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | height | Высота объекта |

Помимо координат и размера GUI.**object** имеет несколько универсальных свойств:

| Тип свойства| Свойство |Описание |
| ------ | ------ | ------ |
| *boolean* | .**hidden** | Является ли объект скрытым. Если объект скрыт, то его отрисовка и анализ системных событий игнорируются |
| *boolean* | .**disabled** | Является ли объект отключенным. Если объект отключен, то все системные события при обработке игнорируются |
| *function* | :**draw**() | Обязательный метод, вызываемый для отрисовки виджета на экране. Он может быть определен пользователем любым удобным для него образом. Данный метод осуществляет отрисовку только в экранный буфер, а не на экран |
| *function* | :**isClicked**( *int* x, *int* y ): *boolean* isClicked | Метод для проверки валидности клика на объект. Используется родительскими методами контейнеров и удобен для ручной проверки пересечения указанных координат с расположением объекта на экране |

После добавления объекта в контейнер с помощью метода *:addChild* он приобретает дополнительные свойства для удобства использования:

| Тип свойства| Свойство |Описание |
| ------ | ------ | ------ |
| *table* | .**parent** | Указатель на таблицу-контейнер родителя этого виджета |
| *table* | .**localPosition** | Таблица вида {x = *int*, y = *int*} с локальными координатами виджета в родительском контейнере |
| *function* | :**indexOf**() | Получить индекс данного виджета в родительском контейнере |
| *function* | :**moveForward**() | Передвинуть виджет "назад" в иерархии виджетов контейнера |
| *function* | :**moveBackward**() | Передвинуть виджет "вперед" в иерархии виджетов контейнера |
| *function* | :**moveToFront**() | Передвинуть виджет в конец иерархии виджетов контейнера |
| *function* | :**moveToBack**() | Передвинуть виджет в начало иерархии виджетов контейнера |
| *function* | :**getFirstParent**() | Получить первый родительский контейнер для рассматриваемой системы родительских контейнеров. К примеру, при существовании множества вложенных контейнеров метод вернет первый и "главный" из них |
| *function* | :**delete**() | Удалить этот объект из родительского контейнера. Грубо говоря, это удобный способ самоуничтожения |
| *function* | :**addAnimation**(*function* frameHandler, *function* onFinish): *table* animation | Добавить к этому объекту анимацию. Подробнее об анимациях и их создании см. ниже  |
| [*callback-function* | .**eventHandler**(*container* mainContainer, *object* object, *table* eventData) ]| Необязательный метод для обработки системных событий, вызываемый обработчиком родительского контейнера. Если он имеется у рассматриваемого объекта, то будет вызван с соотвествующими аргументами |

Анимация
======
Каждый виджет может быть без проблем анимирован при желании. К примеру, ниже представлена анимация GUI.**switch**.

![Imgur](http://i.imgur.com/f5aO73U.gif)

Чтобы добавить анимацию к виджету, вызовите метод *<виджет>*:**addAnimation**(*function* frameHandler, *function* onFinish). Данный метод возвращает объект анимации для дальнейшего использования, имеющий следущие свойства:

| Тип свойства| Свойство |Описание |
| ------ | ------ | ------ |
| *table* | .**object** | Указатель на таблицу виджета, к которому была добавлена анимация |
| *float* | .**position** | Текущая позиция воспроизведения анимации. Всегда находится в диапазоне [0.0; 1.0], где левая граница - начало анимации, а правая - ее конец |
| *function* | :**start**() | Метод, начинающий воспроизведение анимации. **Важная деталь**: во время воспроизведения анимации контейнер, содержащий анимированные объекты, временно будет обрабатывать события с максимально возможной скоростью. По окончанию воспроизведения задержка между вызовами .**pullSignal** станет такой, какой была изначально |
| *function* | :**stop**() | Метод, завершающий воспроизведение анимации |
| *function* | :**delete**() | Метод, удаляющий анимацию из объекта |
| *callback-function* | .**frameHandler**(*table* mainContainer, *table* object, *table* animation) | Функция-обработчик кадра анимации. Вызывается автоматически каждый раз перед отрисовкой объекта. Первым параметром идет главный контейнер, в котором вызван обработчик событий, вторым - сам анимированный виджет, а третьим - объект анимации |
| *callback-function* | .**onFinish**() | Функция, вызываемая по окончанию воспроизведения анимации. Отмечу, что метод **:stop()** не вызывает срабатывания **.onFinish** |

Создание анимированных объектов во всех подробностях описано в практическом примере в конце документа.

Готовые виджеты
======

Далее перечислены виджеты, поставляющиеся вместе с библиотекой и созданные на основе описанных выше инструкций.  При желании вы можете сделать абсолютно аналогичные или гораздо более технически продвинутые виджеты без каких-либо затруднений. Подробнее о создании собственных виджетов см. практические примеры в конце документации. 

GUI.**panel**( x, y, width, height, color, [transparency] ): *table* panel
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | height | Высота объекта |
| *int* | color | Цвет панели |
| [*int* | transparency] | Опциональная прозрачность панели |

Создать объект типа "панель", представляющий собой закрашенный прямоугольник с определенной опциональной прозрачностью. В большинстве случаев служит декоративным элементом.

Пример реализации панели:
```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

------------------------------------------------------------------------------------------

local mainContainer = GUI.fullScreenContainer()

mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x262626))
mainContainer:addChild(GUI.panel(10, 10, mainContainer.width - 20, mainContainer.height - 20, 0x880000))

------------------------------------------------------------------------------------------

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![Imgur](http://i.imgur.com/Rho1RTl.png?1)

GUI.**image**( x, y, loadedImage ): *table* image
-------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *table* | loadedImage | Изображение, загруженное методом *image.load()* |

Создать объект типа "изображение", представляющий из себя аналог объекта *panel* с тем лишь исключением, что вместо статичного цвета используется загруженное изображение.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *callback-function* | .**onTouch**( *table* eventData )| Метод, вызываемый после нажатия на изображение в обработчике событий |
| *table* | .**image**| Таблица пиксельных данных изображения |

Пример реализации изображения:

```lua
local image = require("image")
local buffer = require("doubleBuffering")
local GUI = require("GUI")

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x0))

mainContainer:addChild(GUI.image(2, 2, image.load("/Furnance.pic")))

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![enter image description here](http://i91.fastpic.ru/big/2017/0402/80/3b0ec81c3b2f660b9a4c6f18908f4280.png)

GUI.**label**( x, y, width, height, textColor, text ): *table* label
--------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | height | Высота объекта |
| *int* | textColor | Цвет текста лейбла|
| *string* | text | Текст лейбла |

Создать объект типа "лейбл", предназначенный для отображения текстовой информации в различных вариациях расположения.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *callback-function* | .**onTouch**( *table* eventData )| Метод, вызываемый после нажатия на лейбл в обработчике событий |
| *function* | :**setAlignment**( *enum* GUI.alignment.vertical, *enum* GUI.alignment.horizontal ): *table* label| Выбрать вариант отображения текста относительно границ лейбла |

Пример реализации лейбла:
```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x2D2D2D))

mainContainer:addChild(GUI.label(2, 2, mainContainer.width, mainContainer.height, 0xFFFFFF, "Centered text")):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.center)

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![Imgur](http://i.imgur.com/4Hl5G7l.png?1)

GUI.**button**( x, y, width, height, buttonColor, textColor, buttonPressedColor, textPressedColor, text ): *table* button
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | height | Высота объекта |
| *int* | buttonColor | Цвет кнопки |
| *int* | textColor | Цвет текса |
| *int* | buttonPressedColor | Цвет кнопки при нажатии |
| *int* | textPressedColor | Цвет текста при нажатии |
| *string* | text | Текст на кнопке |

Создать объект типа "кнопка". Каждая кнопка имеет два состояния (*isPressed = true/false*), автоматически переключаемые методом-обработчиком .*eventHandler*. Для назначения какого-либо действия кнопке после ее нажатия создайте для нее метод *.onTouch()*.

Существует два дополнительных виджета кнопки, имеющие визуально разные стили:

 - GUI.**framedButton**(...) отрисовывается с рамкой по краям кнопки

 ![Imgur](https://i.imgur.com/ajmXYFR.png)

 - GUI.**roundedButton**(...) имеет симпатичные скругленные уголки

 ![Imgur](https://i.imgur.com/0UO3Vbm.png)
 
Для удобства имеется также альтернативные способы создания кнопки: 

 - GUI.**adaptiveButton**(...) отличается тем, что вместо *width* и *height* использует отступ в пикселях со всех сторон от текста. Этот способ удобен для автоматического расчета размера кнопки вне зависимости от вложенного текста. Разумеется, поддерживаются также GUI.**adaptiveFramedButton**(...) и  GUI.**adaptiveRoundedButton**(...)

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *callback-function* | .**onTouch**( *table* eventData )| Метод, вызываемый после нажатия кнопки в обработчике событий |
| *function* | :**press**()| Изменить состояние кнопки на "нажатое" |
| *function* | :**release**()| Изменить состояние кнопки на "отжатое" |
| *function* | :**pressAndRelease**( *float* time )| Нажать и отжать кнопку в течение указанного временного периода. Примечание: этот метод использует отрисовку содержимого двойного буфера |

Пример реализации кнопки:
```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

------------------------------------------------------------------------------------------

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x2D2D2D))

mainContainer:addChild(GUI.button(2, 2, 30, 3, 0xFFFFFF, 0x555555, 0xAAAAAA, 0x2D2D2D, "Regular button")).onTouch = function()
	GUI.error("Regular button was pressed")
end

mainContainer:addChild(GUI.roundedButton(2, 6, 30, 3, 0xFFFFFF, 0x555555, 0xAAAAAA, 0x2D2D2D, "Rounded button")).onTouch = function()
	GUI.error("Rounded button was pressed")
end

mainContainer:addChild(GUI.framedButton(2, 10, 30, 3, 0xFFFFFF, 0xFFFFFF, 0xAAAAAA, 0xAAAAAA, "Framed button")).onTouch = function()
	GUI.error("Framed button was pressed")
end

------------------------------------------------------------------------------------------

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![Imgur](https://i.imgur.com/9zZvR6g.gif)

GUI.**input**( x, y, width, height, backgroundColor, textColor, placeholderTextColor, backgroundFocusedColor, textFocusedColor, text, [placeholderText, eraseTextOnFocus, textMask ): *table* input
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | height | Высота объекта |
| *int* | backgroundColor | Цвет фона |
| *int* | textColor | Цвет текста |
| *int* | placeholderTextColor | Цвет текста *placeholder* при условии, что он указан ниже |
| *int* | backgroundFocusedColor | Цвет фона в состоянии *focused* |
| *int* | textFocusedColor |Цвет текста в состоянии *focused* |
| *string* | text | Введенный на момент создания поля текст |
| [*string* | placeholderText] | Текст, появляющийся при условии, что введенный текст отсутствует |
| [*boolean* | eraseTextOnFocus] | Необходимо ли удалять текст при активации ввода |
| [*char* | textMask] | Символ-маска для вводимого текста. Удобно для создания поля ввода пароля |

Создать объект, предназначенный для ввода и анализа текстовых данных с клавиатуры. Объект универсален и подходит как для создания простых форм для ввода логина/пароля, так и для сложных структур наподобие интерпретаторов команд. К примеру, окно *палитры* со скриншота в начале документации полностью основано на использовании этого объекта.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *function* | :**startInput**()| Начать ввод в текстовое поле. Метод полезен, если хочется сразу сделать  |
| *callback-function* | .**validator**( *string* text )| Метод, вызывающийся после окончания ввода текста в поле. Если возвращает *true*, то текст в текстовом поле меняется на введенный, в противном случае введенные данные игнорируются. К примеру, в данном методе удобно проверять, является ли введенная текстовая информация числом через *tonumber()* |
| *callback-function* | .**onInputFinished**( *string* text, *table* eventData )| Метод, вызываемый после ввода данных в обработчике событий. Удобная штука, если хочется выполнить какие-либо действия сразу после ввода текста. Если у объекта имеется *validator*, и текст не прошел проверку через него, то *onInputFinished* вызван не будет. |

Пример реализации поля ввода:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

------------------------------------------------------------------------------------------

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x2D2D2D))

mainContainer:addChild(GUI.input(2, 2, 30, 3, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "Hello world", "Placeholder text")).onInputFinished = function()
	GUI.error("Input finished!")
end

------------------------------------------------------------------------------------------

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![Imgur](http://i.imgur.com/njPN0eg.gif)

GUI.**slider**( x, y, width, primaryColor, secondaryColor, pipeColor, valueColor, minimumValue, maximumValue, value, [showCornerValues, currentValuePrefix, currentValuePostfix] ): *table* slider
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | primaryColor | Основной цвет слайдера |
| *int* | secondaryColor | Вторичный цвет слайдера |
| *int* | pipeColor | Цвет "пимпочки" слайдера |
| *int* | valueColor | Цвет текста значений слайдера |
| *float* | minimumValue | Минимальное значение слайдера |
| *float* | maximumValue | Максимальное значение слайдера |
| *float* | value | Значение слайдера |
| [*bool* | showCornerValues] | Показывать ли пиковые значения слайдера по сторонам от него |
| [*string* | currentValuePrefix] | Префикс для значения слайдера |
| [*string* | currentValuePostfix] | Постфикс для значения слайдера |

Создать объект типа "слайдер", предназначенный для манипуляцией числовыми данными. Значение слайдера всегда будет варьироваться в диапазоне от минимального до максимального значений. Опционально можно указать значение поля *слайдер.**roundValues** = true*, если необходимо округлять изменяющееся число.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *callback-function* | .**onValueChanged**( *float* value, *table* eventData )| Метод, вызывающийся после изменения значения слайдера |

Пример реализации слайдера:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

------------------------------------------------------------------------------------------

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x2D2D2D))

local slider = mainContainer:addChild(GUI.slider(4, 2, 30, 0x66DB80, 0x0, 0xFFFFFF, 0xAAAAAA, 0, 100, 50, true, "Prefix: ", " postfix"))
slider.roundValues = true
slider.onValueChanged = function(value)
	-- Do something when slider's value changed
end

------------------------------------------------------------------------------------------

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![Imgur](http://i.imgur.com/F7jrTPM.gif)

GUI.**switch**( x, y, width, primaryColor, secondaryColor, pipeColor, state ): *table* switch
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | primaryColor | Основной цвет переключателя |
| *int* | secondaryColor | Вторичный цвет переключателя |
| *int* | pipeColor | Цвет "пимпочки" переключателя |
| *boolean* | state | Состояние переключателя |

Создать объект типа "переключатель", для определения истинности или ложности того или иного события. При клике на объект меняет состояние на противоположное. 

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *callback-function* | .**onStateChanged**( *boolean* state, *table* eventData )| Метод, вызывающийся после изменения состояния переключателя |

Пример реализации свитча:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

------------------------------------------------------------------------------------------

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x2D2D2D))

local switch1 = mainContainer:addChild(GUI.switch(3, 2, 8, 0x66DB80, 0x1D1D1D, 0xEEEEEE, true))
local switch2 = mainContainer:addChild(GUI.switch(3, 4, 8, 0x66DB80, 0x1D1D1D, 0xEEEEEE, false))
switch2.onStateChanged = function(state)
	GUI.error("Switch state changed!")
end

------------------------------------------------------------------------------------------

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![Imgur](http://i.imgur.com/prBIAsL.gif)

GUI.**switchAndLabel**( x, y, width, switchWidth, primaryColor, secondaryColor, pipeColor, textColor, text, switchState ): *table* switchAndLabel
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Общая ширина |
| *int* | width | Ширина переключателя |
| *int* | primaryColor | Основной цвет переключателя |
| *int* | secondaryColor | Вторичный цвет переключателя |
| *int* | pipeColor | Цвет "пимпочки" переключателя |
| *int* | textColor | Цвет текста лейбла |
| *string* | text | Текст лейбла |
| *boolean* | state | Состояние переключателя |

Быстрый способ создания пары из свитча и лейбла одновременно. Идеально подходит для визуального отображения параметров типа *boolean* у любых объектов .

| Тип свойства | Свойство | Описание |
| ------ | ------ | ------ |
| *table* | .**switch**| Указатель на объект свитча |
| *table* | .**label**| Указатель на объект лейбла |

Пример реализации свитча и лейбла:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

------------------------------------------------------------------------------------------

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x2D2D2D))

mainContainer:addChild(GUI.switchAndLabel(2, 2, 25, 8, 0x66DB80, 0x1D1D1D, 0xEEEEEE, 0x999999, "Sample text 1:", true))
mainContainer:addChild(GUI.switchAndLabel(2, 4, 25, 8, 0x66DB80, 0x1D1D1D, 0xEEEEEE, 0x999999, "Sample text 2:", false))

------------------------------------------------------------------------------------------

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![Imgur](http://i.imgur.com/4zKOla9.gif)

GUI.**colorSelector**( x, y, width, height, color, text ): *table* colorSelector
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | height | Высота объекта |
| *int* | color | Текущий цвет селектора |
| *string* | text | Текст селектора |

Создать объект типа "селектор цвета", представляющий собой аналог кнопки, позволяющей выбрать цвет при помощи удобной палитры.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *callback-function* | .**onTouch**( *table* eventData )| Метод, вызываемый после нажатия на селектор цвета в обработчике событий |

Пример реализации селектора цвета:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

------------------------------------------------------------------------------------------

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x2D2D2D))

mainContainer:addChild(GUI.colorSelector(2, 2, 30, 3, 0xFF55FF, "Choose color")).onTouch = function()
	-- Do something after choosing color
end

------------------------------------------------------------------------------------------

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![Imgur](http://i.imgur.com/QVxu2N0.gif)

GUI.**comboBox**( x, y, width, elementHeight, backgroundColor, textColor, arrowBackgroundColor, arrowTextColor ): *table* comboBox
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | elementHeight | Высота элемента комбо-бокса |
| *int* | backgroundColor | Цвет фона комбо-бокса |
| *int* | textColor | Цвет текста комбо-бокса |
| *int* | arrowBackgroundColor | Цвет фона стрелки комбо-бокса |
| *int* | arrowTextColor | Цвет текста стрелки комбо-бокса |

Создать объект типа "комбо-бокс", позволяющий выбирать объекты из множества перечисленных вариантов. Методика обращения к комбо-боксу схожа с обращением к контекстному меню.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *int* | .**currentItem** | Индекс выбранного элемента комбо-бокса |
| *function* | :**addItem**( *string* text, *boolean* disabled, *string* shortcut, *int* color )| Добавить в комбо-бокс элемент с указанными параметрами. При параметре disabled элемент не будет реагировать на клики мышью. Каждый элемент может иметь собственный callback-метод .**onTouch** для последующей обработки данных |
| *function* | :**addSeparator**()| Добавить визуальный в комбо-бокс разделитель |
| *function* | :**clear**()| Очистить элементы комбо-бокса |
| *function* | :**getItem**(*int* index)| Получить элемент комбо-бокса с соответствующим индексом |
| *function* | :**indexOfItem**(*string* itemText)| Получить индекс элемента комбо-бокса с соответствующим текстом |

Пример реализации комбо-бокса:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

------------------------------------------------------------------------------------------

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x2D2D2D))

local comboBox = mainContainer:addChild(GUI.comboBox(3, 2, 30, 3, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
comboBox:addItem(".PNG")
comboBox:addItem(".JPG").onTouch = function()
	-- Do something when .JPG was selected
end
comboBox:addItem(".GIF")
comboBox:addItem(".PIC")

------------------------------------------------------------------------------------------

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![Imgur](http://i.imgur.com/6ROzLAc.gif)

GUI.**menu**( x, y, width, backgroundColor, textColor, backgroundPressedColor, textPressedColor, backgroundTransparency ): *table* menu
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | backgroundColor | Цвет фона меню |
| *int* | textColor | Цвет текста меню |
| *int* | backgroundPressedColor | Цвет фона меню при нажатии на элемент |
| *int* | textPressedColor | Цвет текста меню при нажатии на элемент |
| *int* | backgroundTransparency | Прозрачность фона меню |

Создать объект типа "горизонтальное меню", позволяющий выбирать объекты из множества перечисленных вариантов. По большей части применяется в структурах типа "Файл - Редактировать - Вид - Помощь" и подобных.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *function* | :**addItem**( *string* text, *int* color ): *table* item | Добавить в меню элемент с указанными параметрами. Каждый элемент имеет собственный callback-метод .**onTouch** |
| *callback-function* | .**onItemSelected**( *table* item, *table* eventData )| Метод, вызывающийся после выборе какого-либо элемента комбо-бокса |

Пример реализации меню:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

------------------------------------------------------------------------------------------

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x2D2D2D))

local menu = mainContainer:addChild(GUI.menu(1, 1, mainContainer.width, 0xEEEEEE, 0x666666, 0x3366CC, 0xFFFFFF, nil))
menu:addItem("MineCode IDE", 0x0)
local item = menu:addItem("File")
item.onTouch = function(eventData)
	local contextMenu = GUI.contextMenu(item.x, item.y + 1)
	contextMenu:addItem("New")
	contextMenu:addItem("Open").onTouch = function()
		GUI.error("Open was pressed")
	end
	contextMenu:addSeparator()
	contextMenu:addItem("Save")
	contextMenu:addItem("Save as")
	contextMenu:show()
end
menu:addItem("Edit")
menu:addItem("View")
menu:addItem("About")

------------------------------------------------------------------------------------------

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![Imgur](http://i.imgur.com/b1Tmge5.gif)

GUI.**progressBar**( x, y, width, primaryColor, secondaryColor, valueColor, value, [thin, showValue, valuePrefix, valuePostfix] ): *table* progressBar
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | primaryColor | Основной цвет шкалы прогресса |
| *int* | secondaryColor | Вторичный цвет шкалы прогресса |
| *int* | valueColor | Цвет текста значений шкалы прогресса |
| *float* | value | Значение шкалы прогресса |
| [*bool* | thin] | Активировать ли режим отрисовки "тонкого" объекта |
| [*bool* | showValue] | Показывать ли значение шкалы прогресса |
| [*string* | valuePrefix] | Префикс для значения шкалы прогресса |
| [*string* | valuePostfix] | Постфикс для значения шкалы прогресса |

Создать объект типа "шкала прогресса", значение которой меняется от 0 до 100.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *int* | .**value**| Текущее числовое значение шкалы прогресса |

Пример реализации шкалы прогресса:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x0))

mainContainer:addChild(GUI.progressBar(2, 2, 50, 0x3366CC, 0xEEEEEE, 0xEEEEEE, 80, true, true, "Value prefix: ", " value postfix"))

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![](http://i89.fastpic.ru/big/2017/0402/f1/ef1da27531ccf899eb9eb59c010180f1.png)

GUI.**treeView**( x, y, width, height, backgroundColor, directoryColor, fileColor, arrowColor, backgroundSelectionColor, textSelectedColor, arrowSelectionColor, wrongExtensionColor, scrollBarBackground, scrollBarForeground, workPath, showMode, selectionMode ): *table* treeView
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | height | Высота объекта |
| *int* or *nil* | backgroundColor | Цвет фона TreeView |
| *int* | directoryColor | Цвет директорий TreeView |
| *int* | fileColor | Цвет файлов TreeView |
| *int* | arrowColor | Цвет стрелки директорий TreeView |
| *int* | backgroundSelectionColor | Цвет выделения фона TreeView |
| *int* | textSelectionColor | Цвет выделения текста TreeView |
| *int* | arrowSelectionColor | Цвет выделения стрелки TreeView |
| *int* | wrongExtensionColor | Цвет файла с неподдерживаемым расширением TreeView |
| *int* | scrollBarPrimaryColor | Первичный цвет скроллбара TreeView |
| *int* | scrollBarSecondaryColor | Вторичный цвет скроллбара TreeView |
| *string* | workPath | Стартовая директория TreeView |
| [*enum* | filesystemShowMode] | Опциональный режим отображения содержимого текущей директориии. Может принимать значения GUI.**filesystemModes**.**file**, GUI.**filesystemModes**.**directory** или GUI.**filesystemModes**.**both**  |
| [*enum* | filesystemSelectionMode] | Опциональный режим выбора содепжимого текущей директориии. Значения принимает те же, что и у filesystemShowMode  |

Создать объект типа "TreeView", предназначенный для навигации по файловой системе в виде иерархического древа. При клике на директорию будет показано ее содержимое, а во время прокрутки колесиком мыши содержимое будет "скроллиться" в указанном направлении.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *callback-function* | .**onItemSelected**( *string* path )| Метод, вызываемый после выбора элемента в TreeView. В качестве аргумента передается абсолютный путь выбранного элемента |
| *function* | :**addExtensionFilter**( *string* extension )| Добавить фильтр на указанное расширение файла. После этого в диалоговом окне пользователь сможет выбирать лишь те файлы, которые имеют соответствующее расширение |

Пример реализации TreeView:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

------------------------------------------------------------------------------------------

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x262626))

local treeView1 = mainContainer:addChild(GUI.treeView(2, 2, 30, 41, 0xCCCCCC, 0x2D2D2D, 0x3C3C3C, 0xEEEEEE, 0x666666, 0xC3C3C3, 0x393939, "/", GUI.filesystemModes.both, GUI.filesystemModes.both))
treeView1.onItemSelected = function(path)
	GUI.error("Something was selected, the path is: \"" .. path .. "\"")
end

local treeView2 = mainContainer:addChild(GUI.treeView(34, 2, 30, 41, 0xCCCCCC, 0x2D2D2D, 0x3C3C3C, 0xEEEEEE, 0x666666, 0xC3C3C3, 0x393939, "/", GUI.filesystemModes.file, GUI.filesystemModes.file))
treeView2.onItemSelected = function(path)
	GUI.error("File was selected, the path is: \"" .. path .. "\"")
end

local treeView3 = mainContainer:addChild(GUI.treeView(66, 2, 30, 41, 0xCCCCCC, 0x2D2D2D, 0x3C3C3C, 0xEEEEEE, 0x666666, 0xC3C3C3, 0x393939, "/", GUI.filesystemModes.directory, GUI.filesystemModes.directory))
treeView3.onItemSelected = function(path)
	GUI.error("Directory was selected, the path is: \"" .. path .. "\"")
end

------------------------------------------------------------------------------------------

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![Imgur](https://i.imgur.com/igGozFP.gif)

GUI.**filesystemChooser**( x, y, width, height, backgroundColor, textColor, tipBackgroundColor, tipTextColor, initialText, sumbitButtonText, cancelButtonText, placeholderText, filesystemDialogMode, filesystemDialogPath ): *table* filesystemChooser
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | height | Высота объекта |
| *int* | backgroundColor | Цвет фона |
| *int* | textColor | Цвет текста |
| *int* | tipBackgroundColor | Цвет фона "пимпочки" в правой части filesystemChooser |
| *int* | tipTextgroundColor | Цвет текста "пимпочки" в правой части filesystemChooser |
| *string* | sumbitButtonText | Стартовый текст filesystemChooser |
| *string* | sumbitButtonText | Текст кнопки подтверждения выбора в диалоговом окне |
| *string* | cancelButtonText | Текст кнопки отмены выбора в диалоговом окне |
| *string* | placeholderText | Текст, появляющийся в случае отсутствия выбора конкретного пути |
| *enum* | filesystemDialogMode | Режим выбора содержимого в диалоговом окне. Может принимать значения GUI.**filesystemModes**.**file**, GUI.**filesystemModes**.**directory** или GUI.**filesystemModes**.**both** |
| *string* | filesystemDialogPath | Стартовая директория диалогового окна |

FilesystemChooser  предназначен для удобного выбора файла или директории. При нажатии на объект всплывает диалоговое окно с уже знакомым нам TreeView, позволяющее выбрать необходимый элемент путем навигации по файловой системе.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *callback-function* | .**onSubmit**( *string* path )| Метод, вызываемый после выбора файла или директории, а также нажатии кнопки подтверждения в диалоговом окне. В качестве аргумента передается абсолютный путь до выбранного элемента |
| *callback-function* | .**onCancel**(  )| Метод, вызываемый после нажатия на кнопку отмены в диалоговом окне |
| *function* | :**addExtensionFilter**( *string* extension )| Добавить фильтр на указанное расширение файла. После этого в диалоговом окне пользователь сможет выбирать лишь те файлы, которые имеют соответствующее расширение |

Пример реализации FilesystemChooser:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

------------------------------------------------------------------------------------------

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x262626))

local filesystemChooser = mainContainer:addChild(GUI.filesystemChooser(2, 2, 30, 3, 0xE1E1E1, 0x888888, 0x3C3C3C, 0x888888, "Open", "Cancel", "Choose file", GUI.filesystemModes.file, "/", nil))

filesystemChooser:addExtensionFilter(".cfg")

filesystemChooser.onSubmit = function(path)
	GUI.error("File \"" .. path .. "\" was selected")
end

------------------------------------------------------------------------------------------

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![Imgur](https://i.imgur.com/F0ch8yQ.gif)

GUI.**codeView**( x, y, width, height, lines, fromSymbol, fromLine, maximumLineLength, selections, highlights, highlightLuaSyntax, indentationWidth ): *table* codeView
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | height | Высота объекта |
| *table* | lines | Таблица с отображаемыми строками |
| *int* | fromSymbol | С какого символа начинать отображение кода |
| *int* | fromLine | С какой строки начинать отображение кода |
| *int* | maximumLineLength | Максимальная длина строки из имеющихся строк |
| *table* | selections | Таблица вида { {from = {line = *int* line, symbol = *int* symbol}, to = {line = *int* line, symbol = *int* symbol}}, ... }, позволяющая осуществлять выделение кода таким образом, как если бы пользователь выделил бы его мышью |
| *table* | highlights | Таблица вида { [*int* lineIndex] = *int* color, ... }, позволяющая подсвечивать указанные строки указанными цветом |
| *boolean* | highlightLuaSyntax | Подсвечивать ли синтаксис Lua |
| *int* | indentationWidth | Ширина индентации кода |

Создать объект типа "CodeView", предназначенный для наглядного отображения Lua-кода с номерами строк, подсветкой синтаксиса, выделениям и скроллбарами.

Пример реализации CodeView:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local unicode = require("unicode")

------------------------------------------------------------------------------------------

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x0))

local codeView = mainContainer:addChild(GUI.codeView(2, 2, 130, 30, {}, 1, 1, 1, {}, {}, true, 2))

local file = io.open("/lib/color.lua", "r")
for line in file:lines() do
	line = line:gsub("\t", "  "):gsub("\r\n", "\n")
	table.insert(codeView.lines, line)
	codeView.maximumLineLength = math.max(codeView.maximumLineLength, unicode.len(line))
end
file:close()

------------------------------------------------------------------------------------------

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![](https://i.imgur.com/o1yLMJr.png)

GUI.**chart**( x, y, width, height, axisColor, axisValueColor, axisHelpersColor, chartColor, xAxisValueInterval, yAxisValueInterval, xAxisPostfix, yAxisPostfix, fillChartArea, values ): *table* chart
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | height | Высота объекта |
| *int* | axisColor | Цвет координатных осей |
| *int* | axisValueColor | Цвет числовых значений координатных осей |
| *int* | axisHelpersColor | Цвет вспомогательных линий координатных осей |
| *int* | chartColor | Цвет графика |
| *float* | xAxisValueInterval | Интервал от 0 до 1, с которым будут итерироваться значения графика на конкретной оси |
| *float* | yAxisValueInterval | Интервал от 0 до 1, с которым будут итерироваться значения графика на конкретной оси |
| *string* | xAxisPostfix | Текстовый постфикс для значений графика конкретной оси |
| *string* | yAxisPostfix | Текстовый постфикс для значений графика конкретной оси |
| *boolean* | fillChartArea | Необходимо ли закрашивать область графика или же рисовать его линией |
| *table* | values | Таблица вида {{*float* x, *float* y}, ...} со значениями графика |

Создать объект типа "график", предназначенный для отображения статистической информации в виде графика с подписью значений осей.

Пример реализации Chart:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x0))

local chart = mainContainer:addChild(GUI.chart(2, 2, 100, 30, 0xEEEEEE, 0xAAAAAA, 0x888888, 0xFFDB40, 0.25, 0.25, "s", "t", true, {}))
for i = 1, 100 do
	table.insert(chart.values, {i, math.random(0, 80)})
end

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()

```

Результат:

![enter image description here](http://i91.fastpic.ru/big/2017/0402/5b/66ff353492298f6a0c9b01c0fc8a525b.png)

GUI.**brailleCanvas**( x, y, width, height ): *table* brailleCanvas
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | height | Высота объекта |

Данный объект по своей сути похож на пиксельный холст. Его отличительной особенностью является использование шрифта Брайля, создающего повышенное в сравнении с стандартным разрешение: каждый реальный пиксель может вмещать до 2х4 "мини-пикселей". Очень полезен для детальной отрисовки мелкой графики, с которой мод справиться не способен. К примеру, если создан BrailleCanvas размером 10x10 реальных пикселей, то он будет содержать 20x40 виртуальных.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *function* | :**set**( *int* x, *int* y, *boolean* state, *int* color )| Установить соответствующее значение пикселя по локальным координатам BrailleCanvas (не глобальным экранным). Если в данной позиции уже имеется установленный пиксель, то его значение цвета будет заменено на новое |

Пример реализации BrailleCanvas:
```lua
local buffer = require("doubleBuffering")
local GUI = dofile("/lib/GUI.lua")

------------------------------------------------------------------------------------------

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x262626))

mainContainer:addChild(GUI.label(2, 2, 30, 1, 0xFFFFFF, "Текст для сравнения размеров"))

-- Создаем BrailleCanvas размером 30x15 пикселей
local brailleCanvas = mainContainer:addChild(GUI.brailleCanvas(2, 4, 30, 15))
-- Рисуем рамочку вокруг объекта. Для начала делаем две белых вертикальных линии
local localCanvasWidth = brailleCanvas.width * 2
for i = 1, brailleCanvas.height * 4 do
	brailleCanvas:set(1, i, true, 0xFFFFFF)
	brailleCanvas:set(localCanvasWidth, i, true, 0xFFFFFF)
end
-- А затем две горизонтальных
local localCanvasHeight = brailleCanvas.height * 4
for i = 1, brailleCanvas.width * 2 do
	brailleCanvas:set(i, 1, true, 0xFFFFFF)
	brailleCanvas:set(i, localCanvasHeight, true, 0xFFFFFF)
end
-- Рисуем диагональную линию красного цвета
for i = 1, 60 do
	brailleCanvas:set(i, i, true, 0xFF0000)
end

------------------------------------------------------------------------------------------

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![Imgur](http://i.imgur.com/3Oq1nzY.png)

GUI.**scrollBar**( x, y, width, height, backgroundColor, foregroundColor, minimumValue, maximumValue, value, shownValueCount, onScrollValueIncrement, thinMode ): *table* scrollBar
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | height | Высота объекта |
| *int* | backgroundColor | Цвет фона scrollBar |
| *int* | foregroundColor | Цвет текста scrollBar |
| *int* | minimumValue | Минимальное значение scrollBar |
| *int* | maximumValue | Максимальное значение scrollBar |
| *int* | value | Текущее значение scrollBar |
| *int* | shownValueCount | Число "отображаемых" значений scrollBar |
| *int* | onScrollValueIncrement | Количество строк, пролистываемых при прокрутке |
| *boolean* | thinMode | Режим отображения scrollBar в тонком пиксельном виде |

Создать объект типа "ScrollBar", предназначенный для визуальной демонстрации числа показанных объектов на экране. Сам по себе практически не используется, полезен в совокупности с другими виджетами.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *callback-function* | .**onTouch**( *table* eventData )| Метод, вызываемый при клике на скорллбар. Значение скроллбара будет изменяться автоматически в указанном диапазоне |
| *callback-function* | .**onScroll**( *table* eventData )| Метод, вызываемый при использовании колеса мыши на скроллбаре. Значение скроллбара будет изменяться в зависимости от величины *.onScrollValueIncrement* |

Пример реализации ScrollBar:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

------------------------------------------------------------------------------------------

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x2D2D2D))

-- Добавляем вертикальный скроллбар в главный контейнер
local verticalScrollBar = mainContainer:addChild(GUI.scrollBar(2, 3, 1, 15, 0x444444, 0x888888, 1, 100, 1, 10, 1, true))
verticalScrollBar.onTouch = function()
	GUI.error("Vertical scrollbar was touched")
end

-- И горизонтальный заодно тоже
local horizontalScrollBar = mainContainer:addChild(GUI.scrollBar(3, 2, 60, 1, 0x444444, 0x888888, 1, 100, 1, 10, 1, true))
horizontalScrollBar.onTouch = function()
	GUI.error("Horizontal scrollbar was touched")
end

------------------------------------------------------------------------------------------

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![enter image description here](https://i.imgur.com/XrqDvBk.png)

GUI.**textBox**(x, y, width, height, backgroundColor, textColor, lines, currentLine, horizontalOffset, verticalOffset): *table* textBox
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | height | Высота объекта |
| *int* or *nil* | backgroundColor | Цвет фона текстбокса. При значении *nil* фон не рисуется в экранный буфер |
| *int* | textColor | Цвет текста текстбокса |
| *table* | lines | Таблица отображаемых строк текстбокса. Имеется опциональная возможность установки цвета конкретной строки, для этого элемент таблицы должен иметь вид {text = *string*, color = *int*} |
| *int* | currentLine | Текущая строка текстбокса, с которой осуществляется отображение текста |
| *int* | horizontalOffset | Отступ отображения текста от левого и правого краев текстбокса |
| *int* | verticalOffset | Отступ отображения текста от верхнего и нижнего краев текстбокса |

Создать объект типа "текстбокс", предназначенный для отображения большого количества текстовых данных в небольшом контейнере с полосами прокрутки. При использовании колесика мыши и активации события *scroll* содержимое текстбокса будет автоматически "скроллиться" в нужном направлении.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *function* | :**setAlignment**( *enum* GUI.alignment.vertical, *enum* GUI.alignment.horizontal ): *table* textBox| Выбрать вариант отображения текста относительно границ текстбокса |
| *table* | .**lines**| Таблица со строковыми данными текстбокса |

Пример реализации текстбокса:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x0))

local textBox = mainContainer:addChild(GUI.textBox(2, 2, 32, 16, 0xEEEEEE, 0x2D2D2D, {}, 1, 1, 0))
table.insert(textBox.lines, {text = "Sample colored line ", color = 0x880000})
for i = 1, 100 do
	table.insert(textBox.lines, "Sample line " .. i)
end

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![enter image description here](http://i89.fastpic.ru/big/2017/0402/ad/01cdcf7aec919051f64ac2b7d9daf0ad.png)

Практические примеры
======
Ниже приведены подробно прокомментированные участки кода и иллюстрации, позволяющие во всех деталях разобраться с особенностями библиотеки. Не стесняйтесь изменять их под свой вкус и цвет.

Пример #1: Кнопочки
======

Возьмем простейшую задачу: расположим на экране 5 кнопок по вертикали и заставим их показывать окно с порядковым номером этой кнопки при нажатии на нее. Напишем следующий код:
 
```lua
-- Подключаем необходимые библиотеки
local buffer = require("doubleBuffering")
local GUI = require("GUI")

------------------------------------------------------------------------------------------

-- Создаем полноэкранный контейнер
local mainContainer = GUI.fullScreenContainer()
-- Добавляем на окно темно-серую панель по всей его ширине и высоте
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x2D2D2D))

-- Создаем 5 объектов-кнопок, располагаемых все ниже и ниже
local y = 2
for i = 1, 5 do
	-- При нажатии на конкретную кнопку будет вызван указанный метод .onTouch()
	mainContainer:addChild(GUI.button(2, y, 30, 3, 0xEEEEEE, 0x2D2D2D, 0x666666, 0xEEEEEE, "This is button " .. i)).onTouch = function()
		GUI.error("You've pressed button " .. i .. "!")
	end

	y = y + 4
end

------------------------------------------------------------------------------------------

-- Отрисовываем содержимое окно
mainContainer:draw()
-- Отрисовываем содержимое экранного буфера
buffer.draw()
-- Активируем режим обработки событий
mainContainer:startEventHandling()
```
При нажатии на любую из созданных кнопок будет показываться дебаг-окно с информацией, указанной в методе *.onTouch*:

![enter image description here](http://i.imgur.com/GChy5UA.gif)

Пример #2: Окно авторизации
======

Поскольку в моде OpenComputers имеется интернет-плата, я написал небольшой клиент для работы с VK.com. Разумеется, для этого необходимо реализовать авторизацию на серверах, вводя свой e-mail/номер телефона и пароль к аккаунту. В качестве тренировки привожу часть кода, отвечающую за это:
 
```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

------------------------------------------------------------------------------------------

-- Задаем базовые параметры - минимальную длину пароля и регулярное выражение для проверки валидности адреса почты
local minimumPasswordLength = 2
local emailRegex = "%w+@%w+%.%w+"

-- Для примера также задаем "корректные" данные пользователя
local userEmail = "cyka@gmail.com"
local userPassword = "1234567"

------------------------------------------------------------------------------------------

-- Создаем контейнер с синей фоновой панелью
local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x002440))
-- Добавляем в него layout с размерностью сетки 1x1
local layout = mainContainer:addChild(GUI.layout(1, 1, mainContainer.width, mainContainer.height, 1, 1))

-- Добавляем в layout поле для ввода почтового адреса
local emailInput = layout:addChild(GUI.input(1, 1, 40, 3, 0xEEEEEE, 0x555555, 0x888888, 0xEEEEEE, 0x262626, nil, "E-mail", false, nil, nil, nil))
-- Добавляем красный текстовый лейбл, показывающийся только в том случае, когда адрес почты невалиден
local invalidEmailLabel = layout:addChild(GUI.label(1, 1, mainContainer.width, 1, 0xFF5555, "Incorrect e-mail")):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
invalidEmailLabel.hidden = true

-- Добавляем аналогичное текстовое поле с лейблом для ввода пароля
local passwordInput = layout:addChild(GUI.input(1, 1, 40, 3, 0xEEEEEE, 0x555555, 0x888888, 0xEEEEEE, 0x262626, nil, "Password", false, "*", nil, nil))
local invalidPasswordLabel = layout:addChild(GUI.label(1, 1, mainContainer.width, 1, 0xFF5555, "Password is too short")):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
invalidPasswordLabel.hidden = true

-- Добавляем кнопку, ползволяющую осуществлять авторизацию
local loginButton = layout:addChild(GUI.button(1, 1, 40, 3, 0x3392FF, 0xEEEEEE, 0xEEEEEE, 0x3392FF, "Login"))
-- По умолчанию кнопка имеет неактивное состояние, а также серый цвет
loginButton.disabled = true
loginButton.colors.disabled.background = 0xAAAAAA
loginButton.colors.disabled.text = 0xDDDDDD
-- При нажатии на кнопку логина идет сверка введенных данных с переменными выше, и выводится дебаг-сообщение
loginButton.onTouch = function()
	GUI.error(emailInput.text == userEmail and passwordInput.text == userPassword and "Login successfull" or "Login failed")
end

-- Создаем две переменных, в которых будут храниться состояния валидности введенных данных
local emailValid, passwordValid
-- Данная функция будет вызываться ниже после обращения к одному из текстовых полей, она необходима
-- для контроля активности кнопки логина
local function checkLoginButton()
	loginButton.disabled = not emailValid or not passwordValid

	mainContainer:draw()
	buffer.draw()
end

-- Создаем callback-функцию, вызывающуюся после ввода текста и проверяющую корректность введенного адреса
emailInput.onInputFinished = function()
	emailValid = emailInput.text and emailInput.text:match(emailRegex)
	invalidEmailLabel.hidden = emailValid
	checkLoginButton() 
end

-- Аналогично поступаем с полем для ввода пароля
passwordInput.onInputFinished = function()
	passwordValid = passwordInput.text and passwordInput.text:len() > minimumPasswordLength
	invalidPasswordLabel.hidden = passwordValid
	checkLoginButton() 
end

-- Добавляем заодно кнопку для закрытия программы
layout:addChild(GUI.button(1, 1, 40, 3, 0x336DBF, 0xEEEEEE, 0xEEEEEE, 0x336DBF, "Exit")).onTouch = function()
	mainContainer:stopEventHandling()
	buffer.clear(0x0)
	buffer.draw(true)
end

------------------------------------------------------------------------------------------

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()

```

Результат:

![enter image description here](http://i.imgur.com/CWuCLop.gif)

Пример #3: Создание собственного виджета
======

Одной из важнейших особенностей библиотеки является простота создания виджетов с нуля. К примеру, давайте сделаем панель, реагирующую на клики мыши и позволяющую рисовать на ней произвольным цветом по аналогии со школьной доской.
 
```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

---------------------------------------------------------------------

-- Создаем полноэкранный контейнер
local mainContainer = GUI.fullScreenContainer()

-- Создаем метод-обработчик событий для нашего виджета
-- Грамотнее будет вынести его создание вне функции-конструктора, дабы не засорять память
local function myWidgetEventHandler(mainContainer, object, eventData)
	if eventData[1] == "touch" or eventData[1] == "drag" then
		local x, y = eventData[3] - object.x + 1, eventData[4] - object.y + 1
		object.pixels[y] = object.pixels[y] or {}
		object.pixels[y][x] = eventData[5] == 0 and true or nil
		
		mainContainer:draw()
		buffer.draw()
	end
end

-- Аналогичным образом поступим с функцией отрисовки виджета, храня ее в единственном экземпляре в памяти
local function myWidgetDraw(object)
	-- Рисуем подложку цветом фона виджета
	buffer.square(object.x, object.y, object.width, object.height, object.colors.background, 0x0, " ")
	
	-- Перебираем пиксельную карту, отрисовывая соответствующие пиксели в экранный буфер
	for y = 1, object.height do
		for x = 1, object.width do
			if object.pixels[y] and object.pixels[y][x] then
				buffer.set(object.x + x - 1, object.y + y - 1, object.colors.paint, 0x0, " ")
			end
		end
	end
end

-- Создаем метод, возвращающий наш виджет
local function createMyWidget(x, y, width, height, backgroundColor, paintColor)
	-- Наследуемся от GUI.object, дополняем его параметрами цветов и пиксельной карты
	local object = GUI.object(x, y, width, height)
	object.colors = {background = backgroundColor, paint = paintColor}
	object.pixels = {}
	
	-- Реализуем методы отрисовки виджета и обработки событий
	object.draw = myWidgetDraw
	object.eventHandler = myWidgetEventHandler

	return object
end

---------------------------------------------------------------------

-- Добавляем темно-серую панель в контейнер
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x2D2D2D))
-- Создаем 9 экземпляров виджета-рисовалки и добавляем их в контейнер
local x, y, width, height = 2, 2, 30, 15
for j = 1, 3 do
	for i = 1, 3 do
		mainContainer:addChild(createMyWidget(x, y, width, height, 0x3C3C3C, 0xEEEEEEE))
		x = x + width + 2
	end
	x, y = 2, y + height + 1
end

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![enter image description here](http://i.imgur.com/SodpPQo.gif)

Как видите, в создании собственных виджетов нет совершенно ничего сложного, главное - обладать информацией по наиболее эффективной работе с библиотекой.

Пример #4: Углубленная работа с Layout
======

Предлагаю немного попрактиковаться в использовании layout. В качестве примера создадим контейнер-окно с четырьмя кнопками, изменяющими его размеры. Вы убедитесь, что нам ни разу не придется вручную считать координаты.

```lua
local buffer = require("doubleBuffering")
local image = require("image")
local GUI = require("GUI")

------------------------------------------------------------------------------------------

-- Создаем полноэкранный контейнер, добавляем темно-серую панель
local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x2D2D2D))

-- Добавляем в главный контенер другой контейнер, который и будет нашим окошком
local window = mainContainer:addChild(GUI.container(2, 2, 80, 25))
-- Добавляем в контейнер-окно светло-серую фоновую панель
local backgroundPanel = window:addChild(GUI.panel(1, 1, window.width, window.height, 0xDDDDDD))
-- Добавляем layout с сеткой 3х1 и такими же размерами, как у окна
local layout = window:addChild(GUI.layout(1, 1, window.width, window.height, 3, 1))

-- В ячейку 2х1 добавляем загруженное изображение с лицом Стива
layout:setCellPosition(2, 1, layout:addChild(GUI.image(1, 1, image.load("/MineOS/System/Icons/Steve.pic"))))
-- Туда же добавляем слайдер, с помощью которого будем регулировать изменение размера окна
local slider = layout:setCellPosition(2, 1, layout:addChild(GUI.slider(1, 1, 30, 0x0, 0xAAAAAA, 0x1D1D1D, 0xAAAAAA, 1, 30, 10, true, "Изменять размер на: ", "px")))
-- В ячейке 2х1 задаем вертикальную ориентацию объектов и расстояние между ними в 1 пиксель
layout:setCellDirection(2, 1, GUI.directions.vertical)
layout:setCellSpacing(2, 1, 1)

-- Cоздаем функцию, изменяющую размер окна на указанную величину
local function resizeWindow(horizontalOffset, verticalOffset)
    window.width, backgroundPanel.width, layout.width = window.width + horizontalOffset, backgroundPanel.width + horizontalOffset, layout.width + horizontalOffset
    window.height, backgroundPanel.height, layout.height = window.height + verticalOffset, backgroundPanel.height + verticalOffset, layout.height + verticalOffset

    mainContainer:draw()
    buffer.draw()
end

-- В ячейку 3х1 добавляем 4 кнопки с назначенными функциями по изменению размера окна
layout:setCellPosition(3, 1, layout:addChild(GUI.adaptiveButton(1, 1, 3, 0, 0xFFFFFF, 0x000000, 0x444444, 0xFFFFFF, "Ниже"))).onTouch = function()
    resizeWindow(0, -math.floor(slider.value))
end
layout:setCellPosition(3, 1, layout:addChild(GUI.adaptiveButton(1, 1, 3, 0, 0xFFFFFF, 0x000000, 0x444444, 0xFFFFFF, "Выше"))).onTouch = function()
    resizeWindow(0, math.floor(slider.value))
end
layout:setCellPosition(3, 1, layout:addChild(GUI.adaptiveButton(1, 1, 3, 0, 0xFFFFFF, 0x000000, 0x444444, 0xFFFFFF, "Уже"))).onTouch = function()
    resizeWindow(-math.floor(slider.value), 0)
end
layout:setCellPosition(3, 1, layout:addChild(GUI.adaptiveButton(1, 1, 3, 0, 0x3392FF, 0xFFFFFF, 0x444444, 0xFFFFFF, "Шире"))).onTouch = function()
    resizeWindow(math.floor(slider.value), 0)
end

-- В ячейке 3x1 задаем горизонтальную ориентацию кнопок и расстояние между ними в 2 пикселя
layout:setCellDirection(3, 1, GUI.directions.horizontal)
layout:setCellSpacing(3, 1, 2)
-- Далее устанавливаем выравнивание кнопок по правому нижнему краю, а также отступ от краев выравнивания в 2 пикселя по ширине и 1 пиксель по высоте
layout:setCellAlignment(3, 1, GUI.alignment.horizontal.right, GUI.alignment.vertical.bottom)
layout:setCellMargin(3, 1, 2, 1)

------------------------------------------------------------------------------------------

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

В результате получаем симпатичное окошко с четырьмя кнопками, автоматически расположенными в его правой части.

Если несколько раз нажать на кнопку "Шире" и "Выше", то окошко растянется, однако все объекты останутся на законных местах. Причем без каких-либо хардкорных расчетов вручную:

![Imgur](http://i.imgur.com/c8Ks91w.gif)

Пример #5: Анимация собственного виджета
======

Для демонстрации работы с анимациями привожу исходный код, позволяющий с абсолютного нуля создать виджет **switch** и добавить к нему анимацию перемещения.

```lua

-- Подключаем необходимые библиотеки
local color = require("color")
local buffer = require("doubleBuffering")
local GUI = require("GUI")

------------------------------------------------------------------------------------------

-- Создаем функцию, отрисовывающую свитч в экранный буфер
local function switchDraw(switch)
	local bodyX = switch.x + switch.width - switch.bodyWidth
	-- Рисуем текст свитча
	buffer.text(switch.x, switch.y, switch.colors.text, switch.text)
	-- Рисуем базовую фоновую подложку пассивного оттенка
	buffer.square(bodyX, switch.y, switch.bodyWidth, 1, switch.colors.passive, 0x0, " ")
	buffer.text(bodyX + switch.bodyWidth, switch.y, switch.colors.passive, "⠆")
	-- Рисуем подложку активного оттенка
	buffer.text(bodyX - 1, switch.y, switch.colors.active, "⠰")
	buffer.square(bodyX, switch.y, switch.pipePosition - 1, 1, switch.colors.active, 0x0, " ")
	-- Рисуем "пимпочку" свитча
	buffer.text(bodyX + switch.pipePosition - 2, switch.y, switch.colors.pipe, "⠰")
	buffer.square(bodyX + switch.pipePosition - 1, switch.y, 2, 1, switch.colors.pipe, 0x0, " ")
	buffer.text(bodyX + switch.pipePosition + 1, switch.y, switch.colors.pipe, "⠆")
end

-- Создаем функцию-обработчик событий, вызываемую при клике на свитч
local function switchEventHandler(mainContainer, switch, eventData)
	if eventData[1] == "touch" then
		-- Изменяем "состояние" свитча на противоположное и
		-- создаем анимацию, плавно перемещающую "пимпочку"
		switch.state = not switch.state
		switch:addAnimation(
			-- В качестве обработчика кадра анимации создаем функцию,
			-- устанавливающую позицию "пимпочки" в зависимости от текущей
			-- завершенности анимации.  Помним также, что animationPosition всегда
			-- находится в диапазоне [0.0; 1.0]. Если состояние свитча имеет значение false,
			-- то мы попросту инвертируем значение позиции анимации, чтобы та визуально
			-- проигрывалась в обратную сторону.
			function(mainContainer, switch, animation)
				if switch.state then
					switch.pipePosition = math.round(1 + animation.position * (switch.bodyWidth - 2))
				else	
					switch.pipePosition = math.round(1 + (1 - animation.position) * (switch.bodyWidth - 2))
				end
			end,
			-- В качестве метода .onFinish создаем функцию, удаляющую анимацию по ее завершению
			function(mainContainer, switch, animation)
				animation:delete()
			end
		-- Запускаем созданную анимацию с указанным интервалом
		):start(switch.animationDuration)
	end
end

-- Создаем объект свитча, наследуясь от GUI.object и заполняя его необходимыми свойствами
local function newSwitch(x, y, totalWidth, bodyWidth, activeColor, passiveColor, pipeColor, textColor, text, switchState)
	local switch = GUI.object(x, y, totalWidth, 1)

	switch.bodyWidth = bodyWidth
	switch.colors = {
		active = activeColor,
		passive = passiveColor,
		pipe = pipeColor,
		text = textColor
	}
	switch.text = text
	switch.state = switchState
	switch.pipePosition = switch.state and switch.bodyWidth - 1 or 1
	switch.animationDuration = 0.3	

	switch.draw = switchDraw
	switch.eventHandler = switchEventHandler

	return switch
end

------------------------------------------------------------------------------------------

-- Создаем полноэкранный контейнер и добавляем в него темно-серую фоновую панель
local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x2D2D2D))

-- Создаем гигантское поле из свитчей. Для начала указываем желаемое количество свитчей,
-- а затем зависимые от количество параметры - такие как оттенок по HSB-палитре,
-- координаты и длительность анимации
local count = 168
local hue = 0
local hueStep = 360 / count
local x, y = 3, 2
local animationDurationMin = 0.3
local animationDurationMax = 0.3
local animationDuration = animationDurationMin
local animationDurationStep = (animationDurationMax - animationDurationMin) / count

-- Добавляем в главный контейнер указанное число свитчей
for i = 1, count do
	local switchColor = color.HSBToHEX(hue, 100, 100)
	local switch = mainContainer:addChild(
		newSwitch(
			x,
			y,
			19,
			7,
			switchColor,
			0x1D1D1D,
			0xEEEEEE,
			switchColor,
			"Cвитч " .. i .. ":",
			math.random(2) == 2
		)
	)

	switch.animationDuration = animationDuration
	animationDuration = animationDuration + animationDurationStep

	hue = hue + hueStep
	y = y + switch.height + 1
	if y >= mainContainer.height then
		x, y = x + switch.width + 3, 2
	end
end

-- Отрисовываем содержимое главного контейнера в экранный буфер и выводим результат на экран
mainContainer:draw()
buffer.draw(true)
-- Запускаем обработку событий главного контейнера
mainContainer:startEventHandling()
```

Результат: 

![Imgur](http://i.imgur.com/f5aO73U.gif)
