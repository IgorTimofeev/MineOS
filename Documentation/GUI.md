

О библиотеке
======
GUI - многофункциональная графическая библиотека, отлаженная под использование маломощными компьютерами с максимально возможной производительностью. Она поддерживает множество элементов интерфейса: от привычных кнопок, слайдеров, текстовых полей и картинок до графиков и инструментов работы с цветовыми режимами. Быстродействие достигается за счет использования двойной буферизации и сложных группировочных алгоритмов.

К примеру, моя операционная система и среда разработки полностью реализованы методами данной библиотеки:

![Imgur](http://i.imgur.com/U1Jybei.png?1)

![Imgur](http://i.imgur.com/RPozLwZ.png?1)

Пусть синтаксис и обилие текста вас не пугают, в документации имеется множество наглядных иллюстрированных примеров и практических задач.

Установка
======

| Зависимость | Функционал |
| ------ | ------ |
| *[advancedLua](https://github.com/IgorTimofeev/OpenComputers/blob/master/lib/advancedLua.lua)* | Дополнение стандартных библиотек Lua множеством функций: быстрой сериализацией таблиц, переносом строк, методами обработки бинарных данных и т.д. |
| *[doubleBuffering](https://github.com/IgorTimofeev/OpenComputers/blob/master/lib/doubleBuffering.lua)* | Низкоуровневая библиотека двойной буферизации для максималььно быстрой отрисовки графики с поддержкой полу-пиксельных методов |
| *[color](https://github.com/IgorTimofeev/OpenComputers/blob/master/lib/color.lua)* | Низкоуровневая библиотека для работы с цветом, предоставляющая методы получения цветовых каналов, различные палитры и конверсию цвета в 8-битный формат |
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

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *function* | :**addItem**( *string* text, *boolean* disabled, *string* shortcut, *int* color )| Добавить в контекстное меню элемент с указанными параметрами. При параметре disabled элемент не будет реагировать на клики мышью. Каждый элемент может иметь собственный callback-метод .**onTouch** для последующей обработки данных |
| *function* | :**addSeparator**()| Добавить в контекстное меню визуальный разделитель |
| *table* | .**items** | Таблица элементов контекстного меню |

Пример реализации контекстного меню:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

buffer.clear(0x0)
local contextMenu = GUI.contextMenu(2, 2)
contextMenu:addItem("New")
contextMenu:addItem("Open").onTouch = function()
	-- Do something to open file or whatever
end
contextMenu:addSeparator()
contextMenu:addItem("Save", true)
contextMenu:addItem("Save as")
contextMenu:show()
```

Результат:

![enter image description here](http://i89.fastpic.ru/big/2017/0402/20/d7d5f14ca47ecef72aec535293e88320.png)

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

buffer.clear(0x0)
GUI.error("Something went wrong here, my friend")
```

Результат:

![enter image description here](http://i.imgur.com/8sjD4T3.png)

Методы для создания контейнеров
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

Каждый контейнер - это группировщик для других объектов, его поведение очень похоже на папку, содержащую множество вложенных файлов и других папок.

Все дочерние элементы контейнера имеют свою *localPosition* в контейнере (к примеру, *{x = 4, y = 2}*). После добавления дочернего элемента в контейнер для дальнейших рассчетов используется именно его локальная позиция. Для получения глобальных (экранных) координат дочернего элемента необходимо обращаться к *element.x* и *element.y*. Глобальная (экранная) позиция дочерних элементов рассчитывается при каждой отрисовке содержимого контейнера. Таким образом, изменяя глобальные координаты дочернего элемента вручную, вы, в сущности, ничего не добьётесь.

Наглядно система иерархии и позиционирования контейнеров и дочерних элементов представлена на следущем изображении:

![Imgur](http://i.imgur.com/nU2bLU8.png?1)

У контейнеров имеется немаловажная особенность: любой дочерний элемент, выступающий за границы контейнера, будет отрисован только в рамках размера этого контейнера:

![Imgur](http://i.imgur.com/PMtOpNS.png?1)

Для добавления в контейнер дочернего элемента используйте синтаксическую конструкцию :**addChild**(**<Объект>**). При этом глобальные координаты объекта становятся локальными. К примеру, для добавления кнопки на локальную позицию *x = 5, y = 10* используйте :**addChild**(GUI.**button**(5, 10, ...)). В контейнер можно добавлять другие контейнеры, а в добавленные - еще одни, создавая сложные иерархические цепочки и группируя дочерние объекты по своему усмотрению.

Наконец, самая важная особенность контейнеров - это автоматизированная обработка системных событий. Для запуска обработки событий необходимо вызвать метод :**startEventHandling**. После этого при каждом событии текущий контейнер и всего его вложенные объекты будут рекурсивно проанализированы на наличие метода-обработчика .**eventHandler**.

Если метод-обработчик имеется, то он будет вызван со следующими аргументами: *container* mainContainer, *object* object, *table* eventData, где первым аргументом является контейнер, обрабатывающий события, вторым является текущий рассматриваемый объект обработчика событий, а третьим - таблица с данными события. Все объекты, перечисленные ниже, уже имеются собственный .**eventHandler** - к примеру, кнопка автоматически нажимается, слайдер перемещается влево-вправо, а селектор цвета открывает палитру для выбора желаемого оттенка. Все это реализовано именно на методе-обработчике. 

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

Ключевая деталь обработчика событий в том, что если событие "экранное", то есть относящееся к клику пользователя на монитор (touch, drag, drop, scroll), то метод-обработчик объекта будет вызван только в том случае, если пользователь "кликнул" на него, после чего обработка событий для оставшихся необработанных дочерних элементов завершится. Если событие не относится к экрану (key_down, clipboard и т.д.), или же объект не имеет метода-обработчика, то обработка оставшихся дочерних элементов продолжится в прежнем виде.

Если необходимо прекратить обработку событий, то необходимо вызвать метод :**stopEventHandling**.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *function* | :**addChild**( *table* child ): *table* child| Добавить произвольный объект в контейнер в качестве дочернего - таким образом вы способны создавать собственные виджеты с индивидуальными особенностями. Уточняю, что у добавляемого объекта **обязательно** должен иметься метод *:draw* (подробнее см. ниже). При добавлении объекта его глобальные координаты становятся локальными |
| *function* | :**deleteChildren**(): *table* container | Удалить все дочерние элементы контейнера |
| *function* | :**draw**(): *table* container | Рекурсивная отрисовка содержимого контейнера в порядке очереди его дочерних элементов. Обращаю внимание на то, что данный метод осуществляет отрисовку только в экранный буфер. Для отображения изменений на экране необходимо использовать метод библиотеки двойного буфера *.draw()* |
| *function* | :**startEventHandling**([*float* delay]): *table* container | Запуск обработчика событий для данного контейнера и всех вложенных в него дочерних элементов. Параметр *delay* аналогичен таковому в computer.**pullSignal** |
| *function* | :**stopEventHandling**(): *table* container | Остановка обработчика событий для данного контейнера |

GUI.**fullScreenContainer**( ): *table* container
-----------------------------------------------------

Создать объект контейнера на основе текущего разрешения экранного буфера.

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

Layout является наследником GUI.**container**, автоматически располагающим дочерние объекты внутри себя. К примеру, если вам хочется визуально красиво отобразить множество объектов, не тратя время на ручной расчет координат, то layout создан для вас. На картинке ниже хорошо поясняется суть:
![Imgur](http://i.imgur.com/SuNHweA.png?1)
Видно, что имеется layout, состоящий из 9 ячеек, каждая из которых может иметь собственную ориентацию объектов, расстояние между ними, а также выравнивание. Границы ячеек условны, и существуют лишь для расчета позиции дочерних объектов, так что дочерние объекты могут без проблем выходить за них.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *int* | .**columnCount**| Количество рядов сетки |
| *int* | .**rowCount**| Количество строк сетки |
| *function* | :**setGridSize**(*int* columnCount, *int* columnCount): *layout* layout | Установить размер сетки. Все объекты, находящиеся вне диапазона нового размера, должны быть размещены в сетке заново через :**setCellPosition**()  |
| *function* | :**setCellPosition**(*int* column, *int* row, *object* child): *object* child| Назначить дочернему объекту layout конкретную ячейку сетки. В одной ячейке может располагаться сколь угодно много объектов. |
| *function* | :**setCellDirection**(*int* column, *int* row, *enum* direction): *layout* layout | Назначить ячейке сетки ориентацию дочерних объектов. Поддерживаются GUI.directions.horizontal и GUI.directions.vertical |
| *function* | :**setCellAlignment**(*int* column, *int* row, *enum* GUI.alignment.vertical, *enum* GUI.alignment.horizontal): *layout* layout | Назначить ячейке сетки метод выравнивания дочерних объектов. Поддерживаются все 9 вариантов |
| *function* | :**setCellSpacing**(*int* column, *int* row, *int* spacing): *layout* layout | Назначить ячейке сетки расстояние в пикселях между объектами. По умолчанию оно равняется 1 |

Пример реализации layout:
```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

-- Создаем полноэкранный контейнер, добавляем на него изображение с малиной и полупрозрачную черную панель
local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.image(1, 1, require("image").load("/MineOS/Pictures/Raspberry.pic")))
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x000000, 40))

-- Добавляем к контейнеру layout с сеткой размером 5x1
local layout = mainContainer:addChild(GUI.layout(1, 1, mainContainer.width, mainContainer.height, 5, 1))

-- Добавяляем в layout 9 кнопок, назначая им соответствующие позиции в сетке
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

![Imgur](http://i.imgur.com/LnBhKaN.png?1)

Также мы можем модифицировать код, чтобы кнопки группировались в 3 колонки, а расстояние между ними было равным 4 пикселям:

```lua
-- Изменяем размер сетки на 3x1
layout:setGridSize(3, 1)
-- Устанавливаем расстояние между объектами для каждой колонки
for column = 1, 3 do
	layout:setCellSpacing(column, 1, 4)
end
-- Обновляем позиции трех последних кнопок, чтобы они принадлежали третьей колонке
layout:setCellPosition(3, 1, layout.children[7])
layout:setCellPosition(3, 1, layout.children[8])
layout:setCellPosition(3, 1, layout.children[9])
```
Результат:

![Imgur](http://i.imgur.com/QD0BqWx.png?1)

Более подробно работа с layout рассмотрена в практическом примере 4 в конце документа.

Методы для создания виджетов
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

Помимо координат GUI.**object** может иметь несколько индивидуальных свойств отрисовки и поведения, описанных разработчиком. Однако имеются универсальные свойства, имеющиеся у каждого экземпляра объекта:

| Тип свойства| Свойство |Описание |
| ------ | ------ | ------ |
| *function* | :**draw**() | Обязательный метод, вызываемый для отрисовки виджета на экране. Он может быть определен пользователем любым удобным для него образом. Повторюсь, что данный метод осуществляет отрисовку только в экранный буфер, а не на экран. |
| *function* | :**isClicked**( *int* x, *int* y ): *boolean* isClicked | Метод для проверки валидности клика на объект. Используется родительскими методами контейнеров и удобен для ручной проверки пересечения указанных координат с расположением объекта на экране |
| *boolean* | .**hidden** | Является ли объект скрытым. Если объект скрыт, то его отрисовка и анализ системных событий игнорируются |
| *boolean* | .**disabled** | Является ли объект отключенным. Если объект отключен, то все системные события при обработке игнорируются |

После добавления виджета-объекта в контейнер с помощью метода *:addChild* он приобретает дополнительные свойства для удобства использования:

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
| *function* | :**delete**() | Удалить этот объект из родительского контейнера. Грубо говоря, это удобный способ самоуничтожения объекта |
| *callback-function* | .**eventHandler**(*container* mainContainer, *object* object, *table* eventData) | Необязательный метод для обработки системных событий, вызываемый обработчиком родительского контейнера. Если он имеется у рассматриваемого объекта, то будет вызван с соотвествующими аргументами |

При желании вы можете сделать абсолютно аналогичные или технически гораздо более продвинутые виджеты без каких-либо затруднений. Подробнее о создании собственных виджетов см. практические примеры в конце документации. Однако далее перечислены виджеты, уже созданные мной на основе описанных выше инструкций. 

GUI.**panel**( x, y, width, height, color, [transparency] ): *table* panel
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | height | Высота объекта |
| *int* | color | Цвет панели |
| [*byte* | transparency] | Опциональная прозрачность панели |

Создать объект типа "панель", представляющий собой закрашенный прямоугольник с определенной опциональной прозрачностью. В большинстве случаев служит декоративным элементом, однако способен обрабатывать индивидуальный метод *.onTouch()*.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *callback-function* | .**onTouch**( *table* eventData )| Метод, вызываемый после нажатия на панель в обработчике событий |

Пример реализации панели:
```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

local mainContainer = GUI.fullScreenContainer()

local panel1 = mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, math.floor(mainContainer.height / 2), 0x444444))
mainContainer:addChild(GUI.panel(1, panel1.height, mainContainer.width, mainContainer.height - panel1.height + 1, 0x880000))

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![enter image description here](http://i91.fastpic.ru/big/2017/0402/46/d2516c735ef5a92d294caa560aa87546.png)

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

Имеется также три альтернативных варианта кнопки: 

 - GUI.**adaptiveButton**(...), отличающаяся тем, что вместо *width* и *height* использует отступ в пикселях со всех сторон от текста. Она удобна для автоматического расчета размера кнопки без получения размера текста.
 - GUI.**framedButton**(...), эквивалентный GUI.**button** за исключением того, что отрисовывается в рамочном режиме.
 - GUI.**adaptiveFramedButton**(...), отрисовывающийся по такому же методу, что и GUI.**framedButton** и рассчитывающийся по аналогии с GUI.**adaptiveButton.**

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

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x0))

mainContainer:addChild(GUI.button(2, 2, 30, 3, 0xFFFFFF, 0x000000, 0xAAAAAA, 0x000000, "Button text")).onTouch = function()
	-- Do something on button click
end

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![enter image description here](http://i89.fastpic.ru/big/2017/0402/a4/054d171e923c7631f032ba5d12c6d7a4.png)

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
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x0))

mainContainer:addChild(GUI.label(2, 2, mainContainer.width, mainContainer.height, 0xFFFFFF, "Centered text")):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.center))

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![enter image description here](http://i91.fastpic.ru/big/2017/0402/06/9b1d66cb137abaa67076e979d7ddc206.png)

GUI.**inputTextBox**( x, y, width, height, backgroundColor, textColor, backgroundFocusedColor, textFocusedColor, text, [placeholderText, eraseTextOnFocus, textMask, highlightLuaSyntax, autocompleteVariables] ): *table* inputTextBox
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | height | Высота объекта |
| *int* | backgroundColor | Цвет поля ввода |
| *int* | textColor | Цвет текста поля ввода |
| *int* | backgroundFocusedColor | Цвет поля ввода в состоянии *focused* |
| *int* | textFocusedColor |Цвет текста поля ввода в состоянии *focused* |
| *string* | text | Введенный на момент создания поля текст |
| [*string* | placeholderText] | Текст, появляющийся при условии, что *text* == nil |
| [*boolean* | eraseTextOnFocus] | Необходимо ли удалять текст при активации ввода |
| [*string* | textMask] | Символ-маска для вводимого текста. Полезно для создания поля ввода пароля |
| [*boolean* | highlightLuaSyntax] | Режим подсветки синтаксиса Lua для вводимой строки. Цвет текста при этом игнорируется |
| [*boolean* | autocompleteVariables] | Режим автодополнения текстовых данных на основе поиска таковых переменных в оперативной памяти |

Создать объект типа "поле ввода текста", предназначенный для ввода и анализа текстовых данных с клавиатуры. Объект универсален и подходит как для создания простых форм для ввода логина/пароля, так и для сложных структур наподобие интерпретаторов команд. К примеру, окно *палитры* выше целиком и полностью основано на использовании этого объекта.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *callback-function* | .**validator**( *string* text )| Метод, вызывающийся после окончания ввода текста в поле. Если возвращает *true*, то текст в текстовом поле меняется на введенный, в противном случае введенные данные игнорируются. К примеру, в данном методе удобно проверять, является ли введенная текстовая информация числом через *tonumber()* |
| *callback-function* | .**onInputFinished**( *string* text, *table* eventData )| Метод, вызываемый после ввода данных в обработчике событий |

Пример реализации поля ввода:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x0))

local inputTextBox = mainContainer:addChild(GUI.inputTextBox(2, 2, 32, 3, 0xEEEEEE, 0x555555, 0xEEEEEE, 0x2D2D2D, nil, "Type number here", true, nil, nil, nil))
inputTextBox.validator = function(text)
	if tonumber(text) then return true end
end
inputTextBox.onInputFinished = function()
	-- Do something when input finished
end

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![enter image description here](http://i89.fastpic.ru/big/2017/0402/37/4cca31bccfea2d08c5e0e6fb9c7e1937.png)


![enter image description here](http://i89.fastpic.ru/big/2017/0402/04/709cff165b64efd64d6346ecec188704.png)

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

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x0))

local slider = mainContainer:addChild(GUI.slider(4, 2, 30, 0xFFDB40, 0xEEEEEE, 0xFFDB80, 0xBBBBBB, 0, 100, 50, true, "Prefix: ", " postfix"))
slider.roundValues = true
slider.onValueChanged = function(value)
	-- Do something when slider's value changed
end

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![enter image description here](http://i89.fastpic.ru/big/2017/0402/76/3caab6877dfc1541fd094b491e653476.png)

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

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x0))

local switch1 = mainContainer:addChild(GUI.switch(2, 2, 8, 0xFFDB40, 0xAAAAAA, 0xEEEEEE, true))
local switch2 = mainContainer:addChild(GUI.switch(12, 2, 8, 0xFFDB40, 0xAAAAAA, 0xEEEEEE, false))
switch2.onStateChanged = function(state)
	-- Do something when switch's state changed
end

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()

```

Результат:

![enter image description here](http://i91.fastpic.ru/big/2017/0402/c7/d93ec986446887714c2f238d3db45cc7.png)

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

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x0))

mainContainer:addChild(GUI.colorSelector(2, 2, 30, 3, 0xFF55FF, "Choose color")).onTouch = function()
	-- Do something after choosing color
end

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![enter image description here](http://i91.fastpic.ru/big/2017/0402/24/59bbe68f569420588cf88f7aa0124124.png)

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
| *function* | :**addItem**( *string* text, *boolean* disabled, *string* shortcut, *int* color )| Добавить в комбо-бокс элемент с указанными параметрами. При параметре disabled элемент не будет реагировать на клики мышью. Каждый элемент может иметь собственный callback-метод .**onTouch** для последующей обработки данных |
| *function* | :**addSeparator**()| Добавить визуальный в комбо-бокс разделитель |
| *table* | .**items** | Таблица элементов комбо-бокса |
| *int* | .**currentItem** | Индекс выбранного элемента комбо-бокса |

Пример реализации комбо-бокса:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x0))

local comboBox = mainContainer:addChild(GUI.comboBox(2, 2, 30, 3, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x999999))
comboBox:addItem(".PNG")
comboBox:addItem(".JPG").onTouch = function()
	-- Do something when .JPG was selected
end
comboBox:addItem(".GIF")
comboBox:addSeparator()
comboBox:addItem(".PSD")

comboBox.onItemSelected = function(item)
	-- Do something after item selection
end

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![enter image description here](http://i89.fastpic.ru/big/2017/0402/33/bbc9428db996ef8a8fb9d5df78087733.png)

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

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x0))

local menu = mainContainer:addChild(GUI.menu(1, 1, mainContainer.width, 0xEEEEEE, 0x2D2D2D, 0x3366CC, 0xFFFFFF, nil))
menu:addItem("MineCode IDE", 0x0)
menu:addItem("File").onTouch = function(eventData)
	local contextMenu = GUI.contextMenu(eventData[3], eventData[4] + 1)
	contextMenu:addItem("New")
	contextMenu:addItem("Open").onTouch = function()
		-- Do something to open file or whatever
	end
	contextMenu:addSeparator()
	contextMenu:addItem("Save")
	contextMenu:addItem("Save as")
	contextMenu:show()
end
menu:addItem("Edit")
menu:addItem("View")
menu:addItem("About")

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![enter image description here](http://i91.fastpic.ru/big/2017/0402/17/6c49644e775ec55221808ae931157817.png)

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

![enter image description here](http://i89.fastpic.ru/big/2017/0402/f1/ef1da27531ccf899eb9eb59c010180f1.png)

GUI.**scrollBar**( x, y, width, height, backgroundColor, foregroundColor, minimumValue, maximumValue, value, shownValueCount, onScrollValueIncrement, thinHorizontalMode ): *table* scrollBar
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
| *boolean* | thinHorizontalMode | Режим отображения scrollBar в полупиксельном виде при горизонтальной ориентации |

Создать объект типа "ScrollBar", предназначенный для визуальной демонстрации числа показанных объектов на экране. Сам по себе практически не используется, полезен в совокупности с другими виджетами.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *callback-function* | .**onTouch**( *table* eventData )| Метод, вызываемый при клике на скорллбар. Значение скроллбара будет изменяться автоматически в указанном диапазоне |
| *callback-function* | .**onScroll**( *table* eventData )| Метод, вызываемый при использовании колеса мыши на скроллбаре. Значение скроллбара будет изменяться в зависимости от величины *.onScrollValueIncrement* |

Пример реализации ScrollBar:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x0))

local scrollBar = mainContainer:addChild(GUI.scrollBar(2, 2, 1, 30, 0xEEEEEE, 0x3366CC, 1, 100, 1, 10, 1, false))
scrollBar.onTouch = function()
	-- Do something on scrollBar touch
end

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![enter image description here](http://i89.fastpic.ru/big/2017/0402/90/b78e291e777f9bcb84802ef6451bc790.png)

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


GUI.**treeView**( x, y, width, height, backgroundColor, textColor, selectionBackgroundColor, selectionTextColor, arrowColor, scrollBarPrimaryColor, scrollBarSecondaryColor, workPath ): *table* treeView
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | height | Высота объекта |
| *int* or *nil* | backgroundColor | Цвет фона TreeView |
| *int* | textColor | Цвет текста TreeView |
| *int* | selectionBackgroundColor | Цвет выделения фона TreeView |
| *int* | selectionTextColor | Цвет выделения текста TreeView |
| *int* | arrowColor | Цвет стрелки директорий TreeView |
| *int* | scrollBarPrimaryColor | Первичный цвет скроллбара TreeView |
| *int* | scrollBarSecondaryColor | Вторичный цвет скроллбара TreeView |
| *string* | workPath | Стартовая директория TreeView |

Создать объект типа "TreeView", предназначенный для навигации по файловой системе в виде иерархического древа. При клике на директорию будет показано ее содержимое, а во время прокрутки колесиком мыши содержимое будет "скроллиться" в указанном направлении.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *callback-function* | .**onFileSelected**( *int* currentFile )| Метод, вызываемый после выбора файла в TreeView |

Пример реализации TreeView:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x0))

local treeView = mainContainer:addChild(GUI.treeView(2, 2, 30, 41, 0xCCCCCC, 0x2D2D2D, 0x3C3C3C, 0xEEEEEE, 0x666666, 0xEEEEEE, 0x3366CC, "/"))
treeView.onFileSelected = function(filePath)
	-- Do something when file was selected
end

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()

```

Результат:

![enter image description here](http://i89.fastpic.ru/big/2017/0402/d2/25b46010c6050d65ed4894c9092a0fd2.png)

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

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x0))

local codeView = mainContainer:addCodeView(2, 2, 130, 40, {}, 1, 1, 1, {}, {}, true, 2)
local file = io.open("/lib/OpenComputersGL/Main.lua", "r")
for line in file:lines() do
	line = line:gsub("\t", " ")
	table.insert(codeView.lines, line)
	codeView.maximumLineLength = math.max(codeView.maximumLineLength, unicode.len(line))
end
file:close()

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![enter image description here](http://i89.fastpic.ru/big/2017/0402/a9/a00b12a34bf367940dccde93d28b03a9.png)

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

Практический пример #1
======

 В качестве стартового примера возьмем простейшую задачу: расположим на экране 5 кнопок по вертикали и заставим их показывать окно с порядковым номером этой кнопки при нажатии на нее. Напишем следующий код:
 
```lua
-- Подключаем необходимые библиотеки
local buffer = require("doubleBuffering")
local GUI = require("GUI")

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

-- Отрисовываем содержимое окно
mainContainer:draw()
-- Отрисовываем содержимое экранного буфера
buffer.draw()
-- Активируем режим обработки событий
mainContainer:startEventHandling()
```
При нажатии на любую из созданных кнопок будет показываться дебаг-окно с информацией, указанной в методе *.onTouch*:

![enter image description here](http://i90.fastpic.ru/big/2017/0402/32/90656de1b96b157284fb21e2467d9632.png)

![enter image description here](http://i91.fastpic.ru/big/2017/0402/c3/e02d02fb39a28dd17220b535e59292c3.png)

Практический пример #2
======

Поскольку в моде OpenComputers имеется интернет-плата, я написал небольшой клиент для работы с VK.com. Разумеется, для этого необходимо реализовать авторизацию на серверах, вводя свой e-mail/номер телефона и пароль к аккаунту. В качестве тренировки привожу часть кода, отвечающую за это.
 
```lua
-- Подключаем библиотеки
local image = require("image")
local buffer = require("doubleBuffering")
local GUI = require("GUI")

-- Создаем контейнер с синей фоновой панелью
local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x002440))

-- Указываем размеры полей ввода текста и кнопок
local elementWidth, elementHeight = 40, 3
local x, y = math.floor(mainContainer.width / 2 - elementWidth / 2), math.floor(mainContainer.height / 2) - 2

-- Загружаем и добавляем изображение логотипа "нашей компании"
local logotype = image.load("/MineOS/Applications/VK.app/Resources/VKLogo.pic")
mainContainer:addChild(GUI.image(math.floor(mainContainer.width / 2 - image.getWidth(logotype) / 2) - 2, y - image.getHeight(logotype) - 1, logotype)); y = y + 2

-- Создаем поле для ввода адреса почты
local emailTextBox = mainContainer:addChild(GUI.inputTextBox(x, y, elementWidth, elementHeight, 0xEEEEEE, 0x777777, 0xEEEEEE, 0x2D2D2D, nil, "E-mail", false, nil, nil, nil))
-- Создаем красный текстовый лейбл, показывающийся только в том случае, когда адрес почты неверен
local invalidEmailLabel = mainContainer:addChild(GUI.label(emailTextBox.localPosition.x + emailTextBox.width + 2, y + 1, mainContainer.width, 1, 0xFF5555, "Invalid e-mail")); y = y + elementHeight + 1
invalidEmailLabel.isHidden = true
-- Создаем callback-функцию, вызывающуюся после ввода текста и проверяющую корректность введенного адреса
emailTextBox.onInputFinished = function(text)
	invalidEmailLabel.isHidden = text:match("%w+@%w+%.%w+") and true or false
	mainContainer:draw()
	buffer.draw()
end
-- Создаем поле для ввода пароля
mainContainer:addChild(GUI.inputTextBox(x, y, elementWidth, elementHeight, 0xEEEEEE, 0x777777, 0xEEEEEE, 0x2D2D2D, nil, "Password", false, "*", nil, nil)); y = y + elementHeight + 1

-- Добавляем малоприметную кнопку для закрытия программы
mainContainer:addChild(GUI.button(mainContainer.width, 1, 1, 1, 0x002440, 0xEEEEEE, 0x002440, 0xAAAAAA, "X")).onTouch = function()
	mainContainer:stopEventHandling()
	buffer.clear(0x0)
	buffer.draw(true)
end

-- Добавляем кнопку для логина
mainContainer:addChild(GUI.button(x, y, elementWidth, elementHeight, 0x666DFF, 0xEEEEEE, 0xEEEEEE, 0x666DFF, "Login")).onTouch = function()
	-- Код, выполняемый при успешном логине
end

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

Результат:

![enter image description here](http://i.imgur.com/PT0AUGR.png?1)

![enter image description here](http://i.imgur.com/dphuFtb.png?1)

![enter image description here](http://i.imgur.com/LXfsT0o.png?1)

Практический пример #3
======

Для демонстрации возможностей библиотеки предлагаю создать кастомный виджет с нуля. К примеру, создать панель, реагирующую на клики мыши, позволяющую рисовать на ней произвольным цветом по аналогии со школьной доской.
 
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

-- Создаем метод, возвращающий кастомный виджет
local function createMyWidget(x, y, width, height, backgroundColor, paintColor)
	-- Наследуемся от GUI.object, дополняем его параметрами цветов и пиксельной карты
	local object = GUI.object(x, y, width, height)
	object.colors = {background = backgroundColor, paint = paintColor}
	object.pixels = {}
	
	-- Реализуем метод отрисовки виджета
	object.draw = function(object)
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

	object.eventHandler = myWidgetEventHandler

	return object
end

-- Добавляем темно-серую панель в контейнер
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x2D2D2D))
-- Создаем экземпляр виджета-рисовалки и добавляем его в контейнер
mainContainer:addChild(createMyWidget(2, 2, 32, 16, 0x3C3C3C, 0xEEEEEEE))

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```
---------------------------------------------------------------------
При нажатии на левую кнопку мыши в нашем виджете устанавливается пиксель указанного цвета, а на правую - удаляется.

![enter image description here](http://i89.fastpic.ru/big/2017/0402/fd/be80c13085824bebf68f64a329e226fd.png)

Для разнообразия модифицируем код, создав несколько виджетов с рандомными цветами:
```lua
local x = 2
for i = 1, 5 do
	mainContainer:addChild(createMyWidget(x, 2, 32, 16, math.random(0x0, 0xFFFFFF), math.random(0x0, 0xFFFFFF)))
	x = x + 34
end
```

В результате получаем 5 индивидуальных экземпляров виджета рисования:

![enter image description here](http://i90.fastpic.ru/big/2017/0402/96/96aba372bdb3c1e61007170132f00096.png)

Как видите, в создании собственных виджетов нет совершенно ничего сложного, главное - обладать информацией по наиболее эффективной работе с библиотекой.

Практический пример #4
======

Предлагаю немного попрактиковаться в использовании layout. В качестве примера создадим контейнер-окно, в котором нам не придется ни разу вручную считать координаты при измененнии его размеров.

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

---------------------------------------------------------------------

-- Создаем полноэкранный контейнер, добавляем на него изображение с малиной и полупрозрачную черную панель
local mainContainer = GUI.fullScreenContainer()

-- Добавляем в главный контенер другой контейнер, который и будет нашим окошком
local window = mainContainer:addChild(GUI.container(2, 2, 80, 25))
-- Добавляем в контейнер-окно светло-серую фоновую панель
local backgroundPanel = window:addChild(GUI.panel(1, 1, window.width, window.height, 0xCCCCCC))

-- Добавляем layout размером 3x1 чуть меньший, чем размер окна 
local layout = window:addChild(GUI.layout(3, 2, window.width - 4, window.height - 2, 3, 1))

-- В ячейку 2х1 добавляем загруженное изображение и label с определенным текстом
layout:setCellPosition(2, 1, layout:addChild(GUI.image(1, 1, image.load("/MineOS/System/OS/Icons/Steve.pic"))))
layout:setCellPosition(2, 1, layout:addChild(GUI.label(1, 1, 10, 1, 0x0, "Картиночка" ):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)))
-- В ячейке 2х1 задаем вертикальную ориентацию объектов и расстояние между ними в 1 пиксель
layout:setCellDirection(2, 1, GUI.directions.vertical)
layout:setCellSpacing(2, 1, 1)

-- В ячейку 3х1 добавляем 3 кнопки
layout:setCellPosition(3, 1, layout:addChild(GUI.adaptiveButton(1, 1, 3, 0, 0xFFFFFF, 0x000000, 0x444444, 0xFFFFFF, "Подробности")))
layout:setCellPosition(3, 1, layout:addChild(GUI.adaptiveButton(1, 1, 3, 0, 0xFFFFFF, 0x000000, 0x444444, 0xFFFFFF, "Отмена")))
layout:setCellPosition(3, 1, layout:addChild(GUI.adaptiveButton(1, 1, 3, 0, 0x3392FF, 0xFFFFFF, 0x444444, 0xFFFFFF, "OK"))).onTouch = function()
	-- При нажатии на кнопку "ОК" наше окно растянется на 10 пикселей
	window.width, backgroundPanel.width, layout.width = window.width + 10, backgroundPanel.width + 10, layout.width + 10
	mainContainer:draw()
	buffer.draw()
end
-- В ячейке 3ч1 задаем горизонтальную ориентацию объектов, расстояние между ними в 2 пикселя, а также выравнивание по правому верхнему краю
layout:setCellDirection(3, 1, GUI.directions.horizontal)
layout:setCellSpacing(3, 1, 2)
layout:setCellAlignment(3, 1, GUI.alignment.horizontal.right, GUI.alignment.vertical.bottom)

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()
```

В результате получаем симпатичное окошко с тремя кнопками, автоматически расположенными в его правой части:

![Imgur](http://i.imgur.com/aCB4FDU.png?1)

Если несколько раз нажать на кнопку "ОК", то окошко растянется, однако все объекты останутся на законных местах. Причем без каких-либо хардкорных расчетов вручную:

![Imgur](http://i.imgur.com/MyMiiDU.png?1)