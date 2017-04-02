

О библиотеке
------------
GUI - многофункциональная графическая библиотека, отлаженная под использование маломощными компьютерами с максимально возможной производительностью. Она поддерживает множество элементов интерфейса: от привычных кнопок, слайдеров, текстовых полей и картинок до графиков и инструментов работы с цветовыми режимами. Быстродействие достигается за счет использования тройной буферизации и сложных группировочных алгоритмов.

К примеру, моя операционная система и среда разработки полностью реализованы методами данной библиотеки:

![Imgur](http://i.imgur.com/U1Jybei.png?1)

![Imgur](http://i.imgur.com/RPozLwZ.png?1)

Пусть синтаксис и обилие текста вас не пугают, в документации имеется множество наглядных иллюстрированных примеров и практических задач.

Установка
---------
| Зависимость | Функционал |
| ------ | ------ |
| *[advancedLua](https://github.com/IgorTimofeev/OpenComputers/blob/master/lib/advancedLua.lua)* | Дополнение стандартных библиотек Lua особыми функциями, такими как быстрая сериализация таблиц, перенос строк, округление чисел и т.д. |
| *[colorlib](https://github.com/IgorTimofeev/OpenComputers/blob/master/lib/colorlib.lua)* | Низкоуровневая библиотека для обработки цветовых каналов в бинарном режиме |
| *[image](https://github.com/IgorTimofeev/OpenComputers/blob/master/lib/image.lua)* | Работа со сжатым форматом изображений OCIF и различные операции по обработке и трансформированию результирующих изображений|
| *[doubleBuffering](https://github.com/IgorTimofeev/OpenComputers/blob/master/lib/doubleBuffering.lua)* | Низкоуровневая библиотека тройной (несмотря на название) буферизации для быстрой отрисовки графики с поддержкой полу-пиксельных методов и шрифта Брайля |
| *[syntax](https://github.com/IgorTimofeev/OpenComputers/blob/master/lib/syntax.lua)* | Подсветка lua-синтаксиса для виджета CodeView |
| *[palette](https://github.com/IgorTimofeev/OpenComputers/blob/master/lib/palette.lua)* | Библиотека-окно для работы с цветом в режиме HSV и выборе конкретных цветовых данных для виджета ColorSelector |

Вы можете использовать имеющиеся выше ссылки для установки зависимостей вручную или запустить автоматический [установщик](https://pastebin.com/ryhyXUKZ), загружающий все необходимые файлы за вас:

    pastebin run ryhyXUKZ

Standalone-методы
---------

Библиотека имеет несколько полезных независимых методов, упрощающих разработку программ. К таковым относятся, к примеру, котекстное меню и информационное alert-окно.

GUI.**contextMenu**( x, y ): *table* contextMenu
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата меню по оси x |
| *int* | y | Координата меню по оси y |

Открыть по указанным координатам котекстное меню и ожидать выбора пользователя. При выборе какого-либо элемента будет вызыван его callback-метод .**onTouch**, если таковой имеется.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *function* | :**addItem**( *string* text, *boolean* disabled, *string* shortcut, *int* color )| Добавить в контекстное меню элемент с указанными параметрами. При параметре disabled элемент не будет реагировать на клики мышью. Каждый элемент может иметь собственный callback-метод .**onTouch** для последующей обработки данных |
| *function* | :**addSeparator**()| Добавить в контекстное меню визуальный разделитель |
| *table* | .**items** | Таблица элементов котекстного меню |

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

GUI.**error**( text, [parameters] )
------------------------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *string* | text | Текст информационного окна |
| *table* | parameters | Опциональные параметры информационного окна. К примеру, {title = {text = "Alert", color = 0xFFDB40}, backgroundColor = 0x2D2D2D} добавит окну желтый заголовок и сделает фон окна темно-серым |

Показать отладочное окно с текстовой информацией. Слишком длинная строка будет автоматически перенесена. Для закрытия окна необходимо использовать клавишу return или нажать на кнопку "ОК".

Пример реализации:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

buffer.clear(0x0)
GUI.error("Something went wrong here, my friend", {title = {text = "Alert", color = 0xFFDB40}})

```

Результат:

![enter image description here](http://i90.fastpic.ru/big/2017/0402/99/c2b151738ce348c213ff5d1d45053e99.png)

Методы для создания окон и контейнеров
-------------------------------
Вся библиотека делится на две основные кострукции: контейнеры и виджеты. Контейнер предназначен для группировки нескольких виджетов в единую структуру и их конвеерной обработки, поэтому в первую очередь необходимо изучить особенности работы с контейнерами и окнами.

GUI.**container**( x, y, width, height ): *table* container
-----------------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | height | Высота объекта |

Каждый контейнер - это объект-группировщик для других объектов, описанных ниже. К примеру, при изменении позиции контейнера на экране все его дочерние элементы будут также смещены на соответствующие координаты. Контейнер также содержит все основные методы по добавлению дочерних элементов (виджетов) и работе с ними.

Все дочерние элементы контейнера имеют свою *localPosition* в контейнере (к примеру, *{x = 4, y = 2}*),  при добавлении нового элемента в контейнер используются именно локальные координаты.  Для получения глобальных (экранных) координат дочернего элемента необходимо обращаться к *element.x* и *element.y*. Глобальная (экранная) позиция дочерних элементов рассчитывается при каждой отрисовке содержимого контейнера. Таким образом,  изменяя глобальные координаты дочернего элемента вручную, вы, в сущности, ничего не добьетесь.

Наглядно система иерархии и позиционирования контейнеров и дочерних элементов представлена на следущем изображении:

![enter image description here](http://i91.fastpic.ru/big/2017/0402/71/219099e171ab91e6e9511a803a194c71.png)


Для добавления в контейнер любого существующего виджета (см. ниже) используйте синтаксическую конструкцию **:addОбъект(...)**. К примеру, для добавления кнопки используйте *:addButton*, а для добавления изображения *:addImage*. Кроме того, в контейнер можно добавлять другие контейнеры, а в добавленные - еще одни, создавая сложные иерархические цепочки и группируя дочерние объекты по своему усмотрению. Ниже перечислены дополнительные методы контейнера, способные оказаться полезными

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *function* | :**addОбъект**( *table* object ): *table* object| Добавить в контейнер один из объектов-шаблонов, перечисленных ниже. Как уже было сказано, для добавления, к примеру, объекта GUI.**chart** используйте метод :**addChart**(...) |
| *function* | :**addChild**( *table* child ): *table* child| Добавить произвольный объект в контейнер в качестве дочернего - таким образом вы способны создавать собственные виджеты с индивидуальными особенностями. Уточняю, что у добавляемого объекта **обязательно** должен иметься метод *:draw* (подробнее см. ниже). При добавлении объекта его глобальные координаты становятся локальными |
| *function* | :**deleteChildren**()| Удалить все дочерние элементы контейнера |
| *function* | :**getClickedObject**(*int* x, *int* y): *table* object or *nil*| Получить объект по указанным координатам, используя иерархический порядок расположения элементов. То есть при наличии двух объектов на одних и тех же координатах будет выдан тот, что находится ближе к глазам пользователя. Вложенные контейнеры для данного метода являются *невидимыми*  |
| *function* | :**draw**(): *table* container | Рекурсивная отрисовка содержимого контейнера в порядке очереди его дочерних элементов. Обращаю внимание на то, что данный метод осуществляет отрисовку только в экранный буфер. Для отображения изменений на экране необходимо использовать метод библиотеки тройного буфера *.draw()* |

GUI.**window**( x, y, width, height ): *table* window
-----------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | height | Высота объекта |

Создание объекта типа "окно" для дальнейшей работы. Каждое окно - это наследник объекта объекта типа "контейнер" (см. выше), содержащий дополнительные методы обработки системных событий и возврата данных окна. Для удобства имеется метод  GUI.**fullScreenWindow**( ): *table* window, создающий окно по размеру экранного буфера.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *function* | :**handleEvents**([*int* timeout]) | Запустить обработчик событий и ожидать действий со стороны пользователя. К примеру, при нажатии на кнопку на экране система автоматически определит "нажатый" элемент, осуществит нажатие кнопки и отрисовку. Опциональный аргумент *timeout* эквивалентен аналогичному аргументу в *computer.pullSignal(timeout)* |
| *callback-function* | .**onTouch**(*table* eventData) | Метод, вызывающийся при каждом событии типа *touch* |
| *callback-function* | .**onDrag**(*table* eventData) | Метод, вызывающийся при каждом событии типа *drag* |
| *callback-function* | .**onScroll**(*table* eventData) | Метод, вызывающийся при каждом событии типа *scroll* |
| *callback-function* | .**onKeyDown**(*table* eventData) | Метод, вызывающийся при каждом событии типа *key_down* |
| *callback-function* | .**onAnyEvent**(*table* eventData) | Метод, вызывающийся *всегда*, при любом событии. Полезен для дальнейшей обработки разработчиком |
| *callback-function* | .**onDrawStarted**() | Метод, вызывающийся до начала отрисовки содержимого окна в экранный буфер |
| *callback-function* | .**onDrawFinished**() | Метод, вызывающийся после отрисовки содержимого окна в экранный буфер |
| *function* | :**returnData**(...)| Закрыть окно и вернуть множество данных любого типа |
| *function* | :**close**() | Закрыть окно без возврата данных|

Методы для создания виджетов
----------------------------
После понимания концепции контейнеров можно с легкостью приступить к добавлению виджетов в созданное окно или контейнер. Каждый виджет - это наследник объекта типа GUI.**object**

GUI.**object**( x, y, width, height ): *table* object
-----------------------------------------------------
| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | Координата объекта по оси x |
| *int* | y | Координата объекта по оси y |
| *int* | width | Ширина объекта |
| *int* | height | Высота объекта |

Помимо координат GUI.**object** может иметь несколько индивидуальных свойств  отрисовки и поведения, описанных разработчиком.  Однако имеются универсальные свойства, имеющиеся у каждого экземпляра объекта:

| Тип свойства| Свойство |Описание |
| ------ | ------ | ------ |
| *function* | :**draw**() | Обязательный метод, вызываемый для отрисовки виджета на экране. Он может быть определен пользователем любым удобным для него образом. Повторюсь, что данный метод осуществляет отрисовку только в экранный буфер, а не на экран. |
| *function* | :**isClicked**( *int* x, *int* y ): *boolean* isClicked | Метод для проверки валидности клика на объект. Используется родительскими методами контейнеров и удобен для ручной проверки пересечения указанных координат с расположением объекта на экране |
| *boolean* | .**isHidden** | Является ли объект скрытым. Если объект скрыт, от его отрисовка и анализ системных событий игнорируются |

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

При желании вы можете сделать абсолютно аналогичные или технически гораздо более продвинутые виджеты без каких-либо затруднений. Подробнее о создании собственных виджетов см. практические примеры в конце документации. Однако далее перечислены виджеты, уже созданные мной на основе описанных выше инструкций. 

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

Создать объект типа "кнопка". Каждая кнопка имеет два состояния (*isPressed = true/false*), автоматически переключаемые оконным методом *handleEvents*. Для назначения какого-либо действия кнопке после ее нажатия создайте для нее метод *.onTouch()*.

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

local window = GUI.fullScreenWindow()
window:addPanel(1, 1, window.width, window.height, 0x0)

window:addButton(2, 2, 30, 3, 0xFFFFFF, 0x000000, 0xAAAAAA, 0x000000, "Button text").onTouch = function()
	-- Do something on button click
end

window:draw()
buffer.draw(true)
window:handleEvents()
```

Результат:

![enter image description here](http://i89.fastpic.ru/big/2017/0402/a4/054d171e923c7631f032ba5d12c6d7a4.png)


GUI.**panel**( x, y, width, height, color, transparency ): *table* panel
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

local window = GUI.fullScreenWindow()
window:addPanel(1, 1, window.width, window.height, 0x0)

local panel1 = window:addPanel(1, 1, window.width, math.floor(window.height / 2), 0xFFFFFF)
window:addPanel(1, panel1.height, window.width, window.height - panel1.height, 0xFF0000)

window:draw()
buffer.draw(true)
window:handleEvents()
```

Результат:

![enter image description here](http://i91.fastpic.ru/big/2017/0402/0e/f85dc0db4dd6b575920fdf79090c020e.png)

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

local window = GUI.fullScreenWindow()
window:addPanel(1, 1, window.width, window.height, 0x0)

window:addLabel(2, 2, window.width, window.height, 0xFFFFFF, "Centered text"):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.center)

window:draw()
buffer.draw(true)
window:handleEvents()
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

Создать объект типа "поле ввода текста", предназначенный для ввода и анализа текстовых данных с клавиатуры. Объект универсален и подходит как для создания простых форм для ввода логина/пароля, так и для сложных структур наподобие командных консолей. К примеру, окно *палитры* выше целиком и полностью основано на использовании этого объекта.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *callback-function* | .**validator**( *string* text )| Метод, вызывающийся после окончания ввода текста в поле. Если возвращает *true*, то текст в текстовом поле меняется на введенный, в противном случае введенные данные игнорируются. К примеру, в данном методе удобно проверять, является ли введенная текстовая информация числом через *tonumber()* |
| *callback-function* | .**onInputFinished**( *string* text, *table* eventData )| Метод, вызываемый после ввода данных в обработчике событий |

Пример реализации поля ввода:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

local window = GUI.fullScreenWindow()
window:addPanel(1, 1, window.width, window.height, 0x0)

local inputTextBox = window:addInputTextBox(2, 2, 32, 3, 0xEEEEEE, 0x555555, 0xEEEEEE, 0x2D2D2D, nil, "Type number here", true, nil, nil, nil)
inputTextBox.validator = function(text)
	if tonumber(text) then return true end
end
inputTextBox.onInputFinished = function()
	-- Do something when input finished
end

window:draw()
buffer.draw(true)
window:handleEvents()
```

Результат:

![enter image description here](http://i89.fastpic.ru/big/2017/0402/37/4cca31bccfea2d08c5e0e6fb9c7e1937.png)


![enter image description here](http://i89.fastpic.ru/big/2017/0402/04/709cff165b64efd64d6346ecec188704.png)

GUI.**horizontalSlider**( x, y, width, primaryColor, secondaryColor, pipeColor, valueColor, minimumValue, maximumValue, value, [showCornerValues, currentValuePrefix, currentValuePostfix] ): *table* horizontalSlider
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

Создать объект типа "горизонтальный слайдер", предназначенный для манипуляцией числовыми данными. Значение слайдера всегда будет варьироваться в диапазоне от минимального до максимального значений. Опционально можно указать значение поля *слайдер.**roundValues** = true*, если необходимо округлять изменяющееся число.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *callback-function* | .**onValueChanged**( *float* value, *table* eventData )| Метод, вызывающийся после изменения значения слайдера |

Пример реализации слайдера:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

local window = GUI.fullScreenWindow()
window:addPanel(1, 1, window.width, window.height, 0x0)

local slider = window:addHorizontalSlider(4, 2, 30, 0xFFDB40, 0xEEEEEE, 0xFFDB80, 0xBBBBBB, 0, 100, 50, true, "Prefix: ", " postfix")
slider.roundValues = true
slider.onValueChanged = function(value)
	-- Do something when slider's value changed
end

window:draw()
buffer.draw(true)
window:handleEvents()
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

local window = GUI.fullScreenWindow()
window:addPanel(1, 1, window.width, window.height, 0x0)

local switch1 = window:addSwitch(2, 2, 8, 0xFFDB40, 0xAAAAAA, 0xEEEEEE, true)
local switch2 = window:addSwitch(12, 2, 8, 0xFFDB40, 0xAAAAAA, 0xEEEEEE, false)
switch2.onStateChanged = function(state)
	-- Do something when switch's state changed
end

window:draw()
buffer.draw(true)
window:handleEvents()

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
| *string* | text] | Текст селектора |

Создать объект типа "селектор цвета", представляющий собой аналог кнопки, позволяющей выбрать цвет при помощи удобной палитры.

| Тип свойства | Свойство |Описание |
| ------ | ------ | ------ |
| *callback-function* | .**onTouch**( *table* eventData )| Метод, вызываемый после нажатия на селектор цвета в обработчике событий |

Пример реализации селектора цвета:

```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

local window = GUI.fullScreenWindow()
window:addPanel(1, 1, window.width, window.height, 0x0)

window:addColorSelector(2, 2, 30, 3, 0xFF55FF, "Choose color").onTouch = function()
	-- Do something after choosing color
end

window:draw()
buffer.draw(true)
window:handleEvents()
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

local window = GUI.fullScreenWindow()
window:addPanel(1, 1, window.width, window.height, 0x0)

local comboBox = window:addComboBox(2, 2, 30, 3, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x999999)
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

window:draw()
buffer.draw(true)
window:handleEvents()
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

local window = GUI.fullScreenWindow()
window:addPanel(1, 1, window.width, window.height, 0x0)

local menu = window:addMenu(1, 1, window.width, 0xEEEEEE, 0x2D2D2D, 0x3366CC, 0xFFFFFF, nil)
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

window:draw()
buffer.draw(true)
window:handleEvents()
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

local window = GUI.fullScreenWindow()
window:addPanel(1, 1, window.width, window.height, 0x0)

window:addImage(2, 2, image.load("/Furnance.pic"))

window:draw()
buffer.draw(true)
window:handleEvents()
```

Результат:

![enter image description here](http://i91.fastpic.ru/big/2017/0402/80/3b0ec81c3b2f660b9a4c6f18908f4280.png)

GUI.**progressBar**( x, y, width, primaryColor, secondaryColor, valueColor, value, thin, showValue, valuePrefix, valuePostfix ): *table* progressBar
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

local window = GUI.fullScreenWindow()
window:addPanel(1, 1, window.width, window.height, 0x0)

window:addProgressBar(2, 2, 50, 0x3366CC, 0xEEEEEE, 0xEEEEEE, 80, true, true, "Value prefix: ", " value postfix")

window:draw()
buffer.draw(true)
window:handleEvents()
```

Результат:

![enter image description here](http://i89.fastpic.ru/big/2017/0402/f1/ef1da27531ccf899eb9eb59c010180f1.png)

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

local window = GUI.fullScreenWindow()
window:addPanel(1, 1, window.width, window.height, 0x0)

local textBox = window:addTextBox(2, 2, 32, 16, 0xEEEEEE, 0x2D2D2D, {}, 1, 1, 0)
table.insert(textBox.lines, {text = "Sample colored line ", color = 0x880000})
for i = 1, 100 do
	table.insert(textBox.lines, "Sample line " .. i)
end

window:draw()
buffer.draw(true)
window:handleEvents()
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

local window = GUI.fullScreenWindow()
window:addPanel(1, 1, window.width, window.height, 0x0)

local treeView = window:addTreeView(2, 2, 30, 41, 0xCCCCCC, 0x2D2D2D, 0x3C3C3C, 0xEEEEEE, 0x666666, 0xEEEEEE, 0x3366CC, "/")
treeView.onFileSelected = function(filePath)
	-- Do something when file was selected
end

window:draw()
buffer.draw(true)
window:handleEvents()

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

local window = GUI.fullScreenWindow()
window:addPanel(1, 1, window.width, window.height, 0x0)

local codeView = window:addCodeView(2, 2, 130, 40, {}, 1, 1, 1, {}, {}, true, 2)
local file = io.open("/lib/OpenComputersGL/Main.lua", "r")
for line in file:lines() do
	line = line:gsub("\t", "  ")
	table.insert(codeView.lines, line)
	codeView.maximumLineLength = math.max(codeView.maximumLineLength, unicode.len(line))
end
file:close()

window:draw()
buffer.draw(true)
window:handleEvents()
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

local window = GUI.fullScreenWindow()
window:addPanel(1, 1, window.width, window.height, 0x0)

local chart = window:addChart(2, 2, 100, 30, 0xEEEEEE, 0xAAAAAA, 0x888888, 0xFFDB40, 0.25, 0.25, "s", "t", true, {})
for i = 1, 100 do
	table.insert(chart.values, {i, math.random(0, 80)})
end

window:draw()
buffer.draw(true)
window:handleEvents()

```

Результат:

![enter image description here](http://i91.fastpic.ru/big/2017/0402/5b/66ff353492298f6a0c9b01c0fc8a525b.png)

Практический пример #1
--------------------

 В качестве стартового примера возьмем простейшую задачу: расположим на экране 5 кнопок по вертикали и заставим их показывать окно с порядковым номером этой кнопки при нажатии на нее. Напишем следующий код:
 
```lua
-- Подключаем необходимые библиотеки
local buffer = require("doubleBuffering")
local GUI = require("GUI")

-- Создаем полноэкранное окно
local window = GUI.fullScreenWindow()
-- Добавляем на окно темно-серую панель по всей его ширине и высоте
window:addPanel(1, 1, window.width, window.height, 0x2D2D2D)

-- Создаем 5 объектов-кнопок, располагаемых все ниже и ниже
local y = 2
for i = 1, 5 do
	-- При нажатии на конкретную кнопку будет вызван указанный метод .onTouch()
	window:addButton(2, y, 30, 3, 0xEEEEEE, 0x2D2D2D, 0x666666, 0xEEEEEE, "This is button " .. i).onTouch = function()
		GUI.error("You've pressed button " .. i .. "!")
	end
	y = y + 4
end

-- Отрисовываем содержимое окно
window:draw()
-- Отрисовываем содержимое экранного буфера
buffer.draw()
-- Активируем режим обработки событий
window:handleEvents()
```
При нажатии на любую из созданных кнопок будет показываться дебаг-окно с информацией, указанной в методе *.onTouch*:

![enter image description here](http://i90.fastpic.ru/big/2017/0402/32/90656de1b96b157284fb21e2467d9632.png)

![enter image description here](http://i91.fastpic.ru/big/2017/0402/c3/e02d02fb39a28dd17220b535e59292c3.png)

Практический пример #2
--------------------

Для демонстрации возможностей библиотеки предлагаю создать кастомный виджет с нуля. К примеру, накодить панель для рисования на ней произвольным цветом по аналогии со школьной доской.
 
```lua
local buffer = require("doubleBuffering")
local GUI = require("GUI")

---------------------------------------------------------------------

-- Создаем полноэкранное окно
local window = GUI.fullScreenWindow()

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

	-- Реализуем метод клика на объект, устанавливая или удаляя пиксели в зависимости от кнопки мыши
	object.onTouch = function(eventData)
		local x, y = eventData[3] - object.x + 1, eventData[4] - object.y + 1
		object.pixels[y] = object.pixels[y] or {}
		object.pixels[y][x] = eventData[5] == 0 and true or nil
		window:draw()
		buffer.draw()
	end
	-- Дублируем метод onTouch, чтобы рисование было непрерывным
	object.onDrag = object.onTouch

	return object
end

---------------------------------------------------------------------

-- Добавляем темно-серую панель на окно
window:addPanel(1, 1, window.width, window.height, 0x2D2D2D)
-- Создаем экземпляр виджета-рисовалки и добавляем его на окно
window:addChild(createMyWidget(2, 2, 32, 16, 0x3C3C3C, 0xEEEEEEE))

window:draw()
buffer.draw(true)
window:handleEvents()
```
При нажатии на левую кнопку мыши в нашем виджете устанавливается пиксель указанного цвета, а на правую - удаляется.

![enter image description here](http://i89.fastpic.ru/big/2017/0402/fd/be80c13085824bebf68f64a329e226fd.png)

Для разнообразия модифицируем код, создав несколько виджетов с рандомными цветами:

```lua
local x = 2
for i = 1, 5 do
	window:addChild(createMyWidget(x, 2, 32, 16, math.random(0x0, 0xFFFFFF), math.random(0x0, 0xFFFFFF)))
	x = x + 34
end
```

В результате получаем 5 индивидуальных экземпляров виджета рисования:

![enter image description here](http://i90.fastpic.ru/big/2017/0402/96/96aba372bdb3c1e61007170132f00096.png)

Как видите, в создании виджетов нет совершенно ничего сложного, главное - обладать информацией по наиболее эффективной работе с библиотекой.
