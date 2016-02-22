
local fs = require("filesystem")
local buffer = require("doubleBuffering")
local filemanager = {}

local massiv = {
  {
    name = "Root",
    showContent = true,
    content = {
      {
        name = "File1",
      },
      {
        name = "File2",
      },
      {
        name = "Folder1",
        showContent = true,
        content = {
          {
            name = "FileInFolder1",
          },
          {
            name = "FileInFolder2",
          },
          {
            name = "FolderInFolder1",
            showContent = true,
            content = {
              {
                name = "FileInFolderInFolder1",
              },
            },
          },
        },
      },
      {
        name = "File3",
      },
      {
        name = "File4",
      },
    },
  },
}

filemanager.colors = {
  background = 0xcccccc,
  text = 0x262626,
  scrollBar = 0x444444,
  scrollBarPipe = 0x24c0ff,
}

local function recursiveDraw(x, y, array)
  for i = 1, #array do
    
    if array[i].content then
      if array[i].showContent then
        buffer.text(x, y, filemanager.colors.text, "∨ ▄ " .. array[i].name)
        y = y + 1
        _, y = recursiveDraw(x + 2, y, array[i].content)
      else
        buffer.text(x, y, filemanager.colors.text, "> ▄ " .. array[i].name)
        y = y + 1
      end
    else
      buffer.text(x, y, filemanager.colors.text, "  • " .. array[i].name)
      y = y + 1
    end
  end

  return x, y
end

function filemanager.draw(x, y, width, height, path, fromElement)
  buffer.square(x, y, width, height, filemanager.colors.background, 0xFFFFFF, " ")

  buffer.setDrawLimit(x, y, width - 2, height)
  recursiveDraw(x + 1, y, massiv)
  buffer.resetDrawLimit()

  buffer.scrollBar(x + width - 1, y, 1, height, #massiv, 1, filemanager.colors.scrollBar, filemanager.colors.scrollBarPipe)
end

return filemanager









