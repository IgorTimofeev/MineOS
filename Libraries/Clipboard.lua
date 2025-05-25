local Clipboard = {
    maxHistory = 2,
    history = {}
}

function Clipboard.copy(content)
  table.insert(Clipboard.history,1,content)
  while #Clipboard.history > Clipboard.maxHistory do
    table.remove(Clipboard.history, Clipboard.maxHistory + 1)
  end
end

function Clipboard.paste()
  return Clipboard.history[1]
end

return Clipboard