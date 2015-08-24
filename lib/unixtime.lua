local unixtime = {}

----------------------------------------------------------------------------------------

function unixtime.convert(unix, timezone)
    
    --Проверить аргументы
    checkArg(1, unix, "number")
    
    --Часовой пояс
    timezone = timezone or 3

    --Коорекция времени
    local t_correction = timezone * 3600 

    --
    local lastmod = tonumber(string.sub(tostring(unix), 1, -4)) + t_correction
    -- Вариант 4, все в куче, как мы привыкли, в правильном формате
    --local dt = os.date('%d.%m.%Y %H:%M:%S', lastmod)
    local dt = os.date('%d.%m.%Y', lastmod)
    return dt
end

----------------------------------------------------------------------------------------

return unixtime
