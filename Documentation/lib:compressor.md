*Функция compressor.pack(pathToCompressedFile, ...)*:

	Эта функция позволяет сжать данные и поместить их в сжатом виде в архив.
**Аргументы функции**:

	pathToCompressedFile: Путь к архиву, в который нужно поместить сжатые данные.
	
	... : многоточием тут является перечень объектов, указанных через запятую. Каждый объект
	является путем до папки, файлы в которой надо сжать.Ниже следует пример:
	
	compressor.pack("/test1.pkg", "/MineOS/System/OS/", "/etc/")
	
*Функция compressor.unpack(pathToCompressedFile, pathWhereToUnpack)*:

	Эта функция позволяет прочитать архив со сжатыми данными и распаковать их в указанную папку.
	
**Аргументы функции**:

	pathToCompressedFile: Путь к архиву, который нужно распаковать.
	
	pathWhereToUnpack: Путь к папке, куда нужно распаковать.Ниже следует пример:
	
	compressor.unpack("/test1.pkg", "/papkaUnpacked/")
	
*Функция compressor.unpack(pathToCompressedFile, pathWhereToUnpack)*:

	Эта функция позволяет прочитать архив со сжатыми данными и распаковать их в указанную папку.
	
**Аргументы функции**:

	pathToCompressedFile: Путь к архиву, который нужно распаковать.
	
	pathWhereToUnpack: Путь к папке, куда нужно распаковать.Ниже следует пример:
	
	compressor.unpack("/test1.pkg", "/papkaUnpacked/")
