local unixtime = {}

----------------------------------------------------------------------------------------

--(установить для своего часового пояса, -12 : +13, например: -2 или 6)
local TIME_ZONE = 2  

--(не изменять!)
local t_correction = TIME_ZONE * 3600 

local function getTimeHost()
    local file = io.open('UNIX.tmp', 'w')
    file:write('')
    file:close()
    local lastmod = tonumber(string.sub(fs.lastModified('UNIX.tmp'), 1, -4)) + t_correction
    
    --print(lastmod)


    -- Вариант 1
    --local data = os.date('%x', lastmod)
    --local time = os.date('%X', lastmod)
    --return data, time

    -- Вариант 2, eсли нужно все по отдельности
    --local year = os.date('%Y', lastmod)
    --local month = os.date('%m', lastmod)
    --local day = os.date('%d', lastmod)
    --local weekday = os.date('%A', lastmod)
    --local hour = os.date('%H', lastmod)
    --local minute  = os.date('%M', lastmod)
    --local sec  = os.date('%S', lastmod)    
    --return year, month, day, weekday, hour, minute, sec

    -- Вариант 3, но есть нюанс, если число минут(часов) 5, то и будет выдано 5, а не 05!
    --local dt = os.date('*t', lastmod)
    --return dt.year, dt.month, dt.day, dt.hour, dt.min, dt.sec
    
    -- Вариант 4, все в куче, как мы привыкли, в правильном формате
    local dt = os.date('%Y.%m.%d %H:%M:%S', lastmod)
    return dt
end

print(getTimeHost())


function unixtime.convert(unix, timezone)
  timezone = timezone or 3

end

----------------------------------------------------------------------------------------

return unixtime
