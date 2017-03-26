# image.load(string path): table image

> Загружает существующую картинку в формате .pic и возвращает ее
> в качестве массива (таблицы).

| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *string* | path | путь до картинки |

# image.draw(int x, int y, table image)
> Рисует на экране загруженную ранее картинку по указанным координатам.

| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | x | позиция картинки по x |
| *int* | y | позиция картинки по y |
| *table* | image | предварительно загруженная картинка |

# image.save(string path, table image [, int method])
> Сохраняет указанную картинку по указанному пути в формате .pic,
> по умолчанию используя метод кодирования 3. Рекомендуется
> использовать именно его.

| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *int* | path | позиция картинки по x |
| *table* | image | картинка, которую надо сохранить |
| *int* | method | метод кодирования |
	
# image.transform(table image, int w, int h): table image
> Изменяет размер картинки по методу интерполяции по соседним пикселям.

| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *table* | image | картинка |
| *int* | w | масштаб по ширине |
| *int* | h | масштаб по высоте |
			
# image.expand(table image, string direction, int pixelcount[, int bgColor, int textColor, int transparency, char symbol]): table image
> Расширяет указанную картинку в указанном направлении (fromRight, fromLeft, fromTop, fromBottom),
> создавая при этом пустые белые пиксели. Если указаны опциональные аргументы, то вместо пустых
> пикселей могут быть вполне конкретные значения.

| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *table* | image | картинка |
| *string* | direction | направление |
| *int* | pixelcount | к-во пикселей |
| *int* | bgcolor | цвет заливки |
| *int* | textcolor | цвет текста |
| *int* | transparency | непрозрачность |
| *char* | symbol | символ |

# image.crop(table image, string direction, int pixelCount): table image
> Обрезает указанную картинку в указанном направлении (fromRight, fromLeft, fromTop, fromBottom),
> удаляя лишние пиксели.

| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *table* | image | картинка |
| *string* | direction | направление |
| *int* | pixelcount | к-во пикселей |

# image.rotate(table image, int angle): table image
> Поворачивает указанную картинку на указанный угол. Угол может иметь
> значение 90, 180 и 270 градусов.

| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *table* | image | картинка |
| *int* | angle | угол |

# image.flipVertical(table image): table image
> Отражает указанную картинку по вертикали.

| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *table* | image | картинка |

# image.flipHorizontal(table image): table image
> Отражает указанную картинку по горизонтали.

| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *table* | image | картинка |

# image.hueSaturationBrightness(table image, int hue, int sat, int brightness): table image
> Корректирует цветовой тон, насыщенность и яркость указанной картинки.
> Значения аргументов могут быть отрицательными для уменьшения параметра
> и положительными для его увеличения. Если значение, к примеру, насыщенности
> менять не требуется, просто указывайте 0.

| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *table* | image | картинка |	
| *int* | hue | тон |	
| *int* | sat | насыщенность |	
| *int* | brightness | яркость |	

> Для удобства вы можете использовать следующие сокращения:

> image.hue(table image, int hue): table image

> image.saturation(table image, int sat): table image

> image.brightness(table image, int brightness): table image

> image.blackAndWhite(table image): table image

# image.colorBalance(table image, int r, int g, int b): table image
> Корректирует цветовые каналы изображения указанной картинки. Аргументы цветовых
> каналов могут принимать как отрицательные значения для уменьшения интенсивности канала,
> так и положительные для увеличения.

| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *table* | image | картинка |	
| *int* | r | красный |	
| *int* | g | зелёный |
| *int* | b | синий |

# image.invert(table image): table image
> Инвертирует цвета в указанной картинке.

| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *table* | image | картинка | 

# image.photoFilter(table image, int color, int transparency): table картинка
> Накладывает на указанное изображение фотофильтр с указанной прозрачностью.
> Прозрачность может быть от 0 до 255.

| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *table* | image | картинка |	
| *int* | color | цвет |	
| *int* | transparency | непрозрачность |

# image.replaceColor(table image, int color, int colorToReplace): table image
> Заменяет в указанном изображении один конкретный цвет на другой.

| Тип | Аргумент | Описание |
| ------ | ------ | ------ |
| *table* | image | картинка |	
| *int* | color | цвет который нужно заменить |	
| *int* | colorToReplace | цвет на который нужно заменить |
