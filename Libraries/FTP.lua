local event = require("Event")
local filesystem = require("Filesystem")

local FTP = {}

----------------------------------------------------------------------------------------------------------------

-- Connect to address:port and wait for the socket to finish connection until timeout exceeded
local function socketConnect(address, port, timeout)
    local socket, reason = component.get("internet").connect(address, port)

    local connectionStartTime = computer.uptime()
    while true do
        local success, reason = socket.finishConnect()
        if success then
            return socket
        end

        if success == nil then
            return nil, reason
        end

        if computer.uptime() - connectionStartTime > timeout then
            return nil, "connection timed out"
        end
    end    
end

-- Wait for internet_ready event until timeout exceeded
local function socketAwait(socket, timeout)
    local startTime = computer.uptime()

    while true do
        local eventType, _, socketId = event.pull(timeout - (computer.uptime() - startTime))

        if not eventType then
            return false
        end

        if eventType == "internet_ready" and socketId == socket.id() then
            return true
        end
    end
end

-- Read remaining data from the socket
local function socketReceive(socket)
    local data = ""

    while true do
        local chunk = socket.read()

        if not chunk or #chunk == 0 then
            break
        end

        data = data .. chunk
    end

    return data
end

----------------------------------------------------------------------------------------------------------------

-- FTP response line iterator
function FTP.lines(data)
    return data:gmatch("([^\r\n]+)\r\n")
end

-- Convert FTP modification time into unix timestamp
function FTP.parseTimestamp(timestamp)
    local year, month, day, hour, min, sec = timestamp:match("(%d%d%d%d)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d)")

    return os.time({
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour),
        min = tonumber(min),
        sec = tonumber(sec)                        
    })    
end

-- File information returned by MLSD/MLST commands follows key=value; format:
-- type=dir;sizd=4096;modify=20240924194606; home
function FTP.parseFileInfo(fileInfo)
    local info = {}

    for token in fileInfo:gmatch("[^; ]+") do
        local key, value = token:match("(.+)=(.+)")

        if key then
            key = key:lower()

            if key == "type" then
                info.isdir = not not value:match("dir")
            elseif key:match("siz.") then
                info.size = tonumber(value)
            elseif key == "modify" then
                info.modify = FTP.parseTimestamp(value)
            end
        else
            info.name = token
        end
    end    

    return info
end

----------------------------------------------------------------------------------------------------------------

-- Receive and parse FTP command response 
-- If the function succeedes, the return values will be first responses and a table containing all parsed responses
-- Most of the time second value may be discarded, though it may be useful when sending multiple commands in a single request
local function FTPReceiveResponse(self)
    if not socketAwait(self.controlSocket, self.responseTimeout) then
        return nil, "response timed out"
    end

    local data, reason = socketReceive(self.controlSocket)
    if not data then
        return nil, reason
    end

    local responses, response = {}
    for line in data:gmatch("[^\r\n]+\r\n") do
        if not response then 
            response = {
                content = ""
            }
        end

        local status, delimiter, content = line:match("(%d%d%d)([ -])(.+\r\n)")

        if status then
            response.content = response.content .. content

            -- Space after the status code indicates the last line of the response
            if delimiter == " " then
                response.status = tonumber(status)
                response.ok = 100 <= response.status and response.status < 400

                table.insert(responses, response)
                response = nil                
            end
        else
            response.content = response.content .. line
        end
    end
    
    if #responses < 1 then
        return nil, "no parsable responses"
    end

    return responses[1], responses
end

-- Send FTP command and receive response
-- command argument may be either a string or a table containing multiple commands
local function FTPSendCommand(self, command)
    command = (type(command) == "table" and table.concat(command, "\r\n") or command) .. "\r\n"

    -- Seems like windows IIS ftp server doesn't like large command blobs
    for i = 1, math.ceil(#command / self.commandChunkSize) do
        local result, reason = self.controlSocket.write(
            command:sub(
                self.commandChunkSize * (i - 1) + 1, 
                self.commandChunkSize * i
            )
        )
    
        if not result then
            return nil, reason
        end
    end

    return self:receiveResponse()
end

-- Enter passive mode, send command and read data connection
local function FTPSendPassiveModeCommand(self, command)
    local result, reason = self:beginNegotiation()
    if not result then
        return nil, reason
    end

    local response, reason = self:sendCommand(command)
    if not response then
        self:endNegotiation()
        return nil, reason
    end    

    if not response.ok then
        self:endNegotiation()
        return nil, "command failed: " .. response.content
    end

    local data, reason = self:receiveData()
    self:endNegotiation()

    if not data then
        return nil, reason
    end

    return data
end

-- Enter passive mode and establish data connection
local function FTPBeginNegotiation(self)
    if self.dataSocket then
        return nil, "data connection already open"
    end

    local response, reason = self:sendCommand("PASV")
    if not response then
        return nil, reason
    end

    if not response.ok then
        return nil, "unable to enter passive mode: " .. response.content
    end

    local digits = {response.content:match("(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)")}
    if #digits ~= 6 then
        return nil, "unable to enter passive mode: malformed response"
    end

    local dataSocket, reason = socketConnect(
        table.concat(digits, ".", 1, 4), 
        tonumber(digits[5]) * 256 + tonumber(digits[6]),
        self.responseTimeout
    )

    if not dataSocket then
        return nil, reason
    end

    self.dataSocket = dataSocket
    return true
end

-- Close data connection
local function FTPEndNegotiation(self)
    if not self.dataSocket then
        return nil, "data connection was not open"
    end

    self.dataSocket.close()
    self.dataSocket = nil

    return true
end

-- Read data response
local function FTPReceiveData(self)
    if not self.dataSocket then
        return nil, "data connection was not open"
    end

    return socketReceive(self.dataSocket)
end

-- Send data through the data connection
local function FTPSendData(self, data)
    if not self.dataSocket then
        return nil, "data connection was not open"
    end

    return self.dataSocket.write(data)
end

-- Close FTP connection
local function FTPClose(self)
    if self.controlSocket then
        self.controlSocket.close()
        self.controlSocket = nil
    end

    if self.dataSocket then
        self.dataSocket.close()
        self.dataSocket = nil
    end
end

----------------------------------------------------------------------------------------------------------------

local function pizda(response)
    return not response or not response.ok
end

local function cyka(response, ...)
    if not response then
        return nil, ...
    end

    if not response.ok then
        return nil, response.content
    end
end

local function getParentDirectory(path)
    local directory, filename = path:match("^(.*/)([^/]+)/?$")
    if not directory then
        return nil, path
    end

    return directory, filename
end

----------------------------------------------------------------------------------------------------------------

local function FTPSetCacheValue(self, key, value)
    self.cache[key] = value ~= nil and {computer.uptime(), value} or nil
end

local function FTPGetCacheValue(self, key)
    local currentTime = computer.uptime()
    for key, entry in pairs(self.cache) do
        if currentTime - entry[1] > self.cacheTimeout then
            self.cache[key] = nil
        end
    end

    local entry = self.cache[key]
    if entry then
        return entry[2]
    end
end

----------------------------------------------------------------------------------------------------------------

-- Keep connection alive
local function FTPKeepAlive(self)
    local response, reason = self:sendCommand("PWD")
    if not response then
        return nil, reason
    end

    return true
end

-- Login
local function FTPLogin(self, username, password)
    local response, reason = self:sendCommand("USER " .. username)
    if pizda(response) then
        return cyka(response, reason)
    end

    local response, reason = self:sendCommand("PASS " .. password)
    if pizda(response) then
        return cyka(response, reason)
    end

    return true
end

-- Set negotiation mode
local function FTPSetMode(self, mode)
    local response, reason = self:sendCommand("TYPE " .. mode)
    if pizda(response) then
        return cyka(response, reason)
    end

    return true
end

-- Get working directory
local function FTPGetWorkingDirectory(self, useCache)
    if self.cacheTimeout and useCache then
        local cache = self:getCacheValue("getWorkingDirectory")

        if cache then
            return cache
        end
    end

    local response, reason = self:sendCommand("PWD")
    if pizda(response) then
        return cyka(response, reason)
    end

    local path = response.content:match("\"(.+)\"")
    if not path then
        return nil, "unexpected response: " .. response.content
    end

    if self.cacheTimeout then
        self:setCacheValue("getWorkingDirectory", path)
    end

    return path
end

-- Set working directory
local function FTPChangeWorkingDirectory(self, path)
    if self.cacheTimeout then
        self:setCacheValue("getWorkingDirectory")
    end

    local response, reason = self:sendCommand("CWD " .. path)
    if pizda(response) then
        return cyka(response, reason)
    end
    
    return true
end

-- Get file size
local function FTPGetFileSize(self, path)
    local response, reason = self:sendCommand("SIZE " .. path)
    if pizda(response) then
        return cyka(response, reason)
    end
    
    return tonumber(response.content)
end

-- Returns absolute path
local function FTPResolvePath(self, path, useCache)
    if path:match("^/.*") then
        return path
    end

    local directory, reason = self:getWorkingDirectory(useCache)
    if not directory then
        return nil, reason
    end

    return directory .. "/" .. path
end

-- This function is used internally by listDirectory and fileInfo methods
local function FTPRequestFilesInformation(self, fileNames)
    local commands = { "PWD" }

    for _, path in pairs(fileNames) do
        -- One way to find out whether entry is directory or not without MLSD/MLST is to try to CWD to it
        table.insert(commands, "CWD "  .. path)
        table.insert(commands, "MDTM " .. path)
        table.insert(commands, "SIZE " .. path)
    end
    
    local success, responsesOrReason = self:sendCommand(commands)
    if not success then
        return nil, responsesOrReason
    end
    
    local workingDirectory = table.remove(responsesOrReason, 1).content:match("\"(.+)\"")

    local list = {}
    for _, path in pairs(fileNames) do
        local entry = {}
        entry.name = path:match("/([^/]+)$") or path
        entry.isdir = table.remove(responsesOrReason, 1).ok

        local response = table.remove(responsesOrReason, 1)
        entry.modify = response.ok and FTP.parseTimestamp(response.content) or 0

        local response = table.remove(responsesOrReason, 1)
        entry.size = response.ok and tonumber(response.content) or 0

        table.insert(list, entry)
    end

    self:changeWorkingDirectory(workingDirectory)
    return list
end

-- List directory entries with their type, size and modification time
local function FTPListDirectory(self, path, useCache)
    local reason
    path, reason = self:resolvePath(path, useCache)
    if not path then
        return nil, "unable to resolve path: " .. reason
    end

    local cacheKey = "listDirectory@" .. path
    if self.cacheTimeout and useCache then
        local cache = self:getCacheValue(cacheKey)

        if cache then
            return cache
        end
    end

    local list = {}
    if self.features.MLSD then
        local data, reason = self:sendPassiveModeCommand("MLSD " .. path)
        if not data then
            return nil, reason
        end

        for line in FTP.lines(data) do
            local info = FTP.parseFileInfo(line)

            if not info.name:match("[^%.]*%.%.?$") then
                table.insert(list, info)
            end
        end
    else
        -- No MLSD :(
        local data, reason = self:sendPassiveModeCommand("NLST " .. path)
        if not data then
            return nil, reason
        end

        local fileNames = {}
        for name in FTP.lines(data) do
            if not name:match("[^%.]*%.%.?$") then
                table.insert(fileNames, name)
            end
        end

        local reason
        list, reason = self:requestFilesInformation(fileNames)
        if not list then
            return nil, reason
        end
    end

    -- Sort files by name
    table.sort(
        list,
        function(a, b)
            return a.name < b.name
        end
    )

    if self.cacheTimeout then
        self:setCacheValue(cacheKey, list)
    end

    return list
end

-- Returns information about the requested file
local function FTPGetFileInfo(self, path, useCache)
    local reason
    path, reason = self:resolvePath(path, useCache)
    if not path then
        return nil, "unable to resolve path: " .. reason
    end

    local cacheKey = "getFileInfo@" .. path
    if self.cacheTimeout and useCache then
        -- Check for getFileInfo cache
        local cache = self:getCacheValue(cacheKey)
        if cache then
            return cache
        end

        -- Check for listDirectory cache
        local directory, filename = getParentDirectory(path)
        if directory then
            local cache = self:getCacheValue("listDirectory@" .. directory)
            
            if cache then
                for i = 1, #cache do
                    if cache[i].name == filename then
                        return cache[i]
                    end
                end
            end
        end
    end

    local info
    if self.features.MLST then
        local response, reason = self:sendCommand("MLST " .. path)
        if not response then
            return nil, reason
        end

        local data = response.content:match("^ ([^\r\n]+)\r\n$")
        if not data then
            return nil, "unparsable response"
        end

        info = FTP.parseFileInfo(data)
    else
        local result, reason = self:requestFilesInformation({ path })
        if not result then
            return nil, reason
        end

        info = result[1]
    end

    if self.cacheTimeout then
        self:setCacheValue(cacheKey, info)
    end

    return info
end

local function FTPFileExists(self, path, useCache)
    local directory, filename = getParentDirectory(path)
    if directory == "/" then
        return true
    end

    local list, reason = self:listDirectory(directory or "", useCache)
    if not list then
        return nil, reason
    end

    for i = 1, #list do
        if list[i].name == filename then
            return true
        end
    end

    return false
end

-- Delete file or directory recursively
local function FTPRemoveFile(self, path, useCache)
    local info, reason = self:getFileInfo(path, useCache)
    if not info then
        return nil, reason
    end

    if info.isdir then
        local list = self:listDirectory(path, useCache)
        for i = 1, #list do
            if list[i].name ~= "." and list[i].name ~= ".." then
                local success, reason = self:removeFile((path .. "/" .. list[i].name):gsub("/+", "/"))
                
                if not success then
                    return nil, reason
                end
            end
        end
        
        local response, reason = self:sendCommand("RMD " .. path)
        if pizda(response) then
            return cyka(response, reason)
        end
    else
        local response, reason = self:sendCommand("DELE " .. path)
        if pizda(response) then
            return cyka(response, reason)
        end
    end

    return true
end

-- Create directory
local function FTPMakeDirectory(self, path)
    local response, reason = self:sendCommand("MKD " .. path)
    if pizda(response) then
        return cyka(response, reason)
    end

    return true
end

-- Rename file
local function FTPRenameFile(self, from, to)
    local response, reason = self:sendCommand("RNFR " .. from)
    if pizda(response) then
        return cyka(response, reason)
    end

    local response, reason = self:sendCommand("RNTO " .. to)
    if pizda(response) then
        return cyka(response, reason)
    end

    return true
end

----------------------------------------------------------------------------------------------------------------

-- Read file by path
-- Each received fragment is passed into callback function
local function FTPReadFile(self, path, callback, chunkSize)
    local result, reason = self:beginNegotiation()
    if not result then
        return nil, "negotiation failed: " .. result
    end

    local response, reason = self:sendCommand("RETR " .. path)
    if pizda(response) then
        self:endNegotiation()
        return cyka(response, reason)
    end
    
    while true do
        local chunk, reason = self.dataSocket.read(chunkSize or math.huge)
        if not chunk or #chunk == 0 then
            self:endNegotiation()

            if reason then
                return nil, "unable to receive data: " .. reason
            end

            break
        end

        local success, reason = pcall(callback, chunk)
        if not success then
            self:endNegotiation()
            return nil, "callback error: " .. reason
        end
    end

    self:endNegotiation()
    return true
end

-- Read whole remote file into the memory
local function FTPReadFileToMemory(self, path)
    local buffer = ""
    local success, reason = self:readFile(
        path,
        function(chunk)
            buffer = buffer .. chunk
        end
    )

    if not success then
        return nil, reason
    end

    return buffer
end

-- Read whole remote file into the local filesystem
local function FTPReadFileToFilesystem(self, path, savePath)
    local file = filesystem.open(savePath, "w")
    if not file then
        return nil, "could not open file for writing"
    end

    local success, reason = self:readFile(
        path,
        function(chunk)
            file:write(chunk)
        end
    )

    file:close()
    return not not success, reason
end

-- Write file
-- Data is obtained from the callback function until it returns nil
local function FTPWriteFile(self, path, callback)
    local result, reason = self:beginNegotiation()
    if not result then
        return nil, "negotiation failed: " .. result
    end

    local response, reason = self:sendCommand("STOR " .. path)
    if pizda(response) then
        self:endNegotiation()
        return cyka(response, reason)
    end
    
    while true do
        local sucess, chunkOrReason = pcall(callback)
        if not sucess then
            self:endNegotiation()
            return false, "callback error: " .. chunkOrReason
        end

        if not chunkOrReason then
            break
        end

        self:sendData(chunkOrReason)
    end

    self:endNegotiation()

    local result, reason = self:receiveResponse()
    if not result or not result.ok then
        return nil, reason or result.content
    end

    return true
end

-- Write file from memory
local function FTPWriteFileFromMemory(self, path, data)
    local chunkSize = 8192
    local chunkIndex = 0

    local result, reason = self:writeFile(
        path,
        function()
            local chunk = data:sub(chunkIndex * chunkSize + 1, (chunkIndex + 1) * chunkSize)
            chunkIndex = chunkIndex + 1

            if #chunk == 0 then
                return
            end

            return chunk
        end
    )

    if not result then
        return nil, reason
    end

    return true
end

-- Write file from local filesystem
local function FTPWriteFileFromFilesystem(self, path, localPath)
    local file, reason = filesystem.open(localPath, "r")
    if not file then
        return nil, reason
    end

    local result, reason = self:writeFile(
        path,
        function()
            local chunk = file:read(math.huge)
            if not chunk or #chunk == 0 then
                return
            end

            return chunk
        end
    )

    file:close()

    if not result then
        return nil, reason
    end

    return true
end

----------------------------------------------------------------------------------------------------------------

-- Connect to the FTP server
function FTP.connect(address, port, responseTimeout)
    local self = {}

    self.commandChunkSize = 256

    self.responseTimeout = responseTimeout or 1
    self.cacheTimeout = 1
    self.cache = {}

    local controlSocket, reason = socketConnect(address, port, self.responseTimeout)
    if not controlSocket then
        return nil, reason
    end

    self.controlSocket = controlSocket

    self.receiveResponse = FTPReceiveResponse
    self.sendCommand = FTPSendCommand
    self.sendPassiveModeCommand = FTPSendPassiveModeCommand
    self.beginNegotiation = FTPBeginNegotiation
    self.endNegotiation = FTPEndNegotiation
    self.receiveData = FTPReceiveData
    self.sendData = FTPSendData
    self.close = FTPClose

    self.setCacheValue = FTPSetCacheValue
    self.getCacheValue = FTPGetCacheValue

    self.keepAlive = FTPKeepAlive
    self.login = FTPLogin
    self.setMode = FTPSetMode
    self.getWorkingDirectory = FTPGetWorkingDirectory
    self.changeWorkingDirectory = FTPChangeWorkingDirectory
    self.getFileSize = FTPGetFileSize
    self.resolvePath = FTPResolvePath
    self.requestFilesInformation = FTPRequestFilesInformation
    self.listDirectory = FTPListDirectory
    self.getFileInfo = FTPGetFileInfo
    self.fileExists = FTPFileExists
    self.removeFile = FTPRemoveFile
    self.makeDirectory = FTPMakeDirectory
    self.renameFile = FTPRenameFile

    self.readFile = FTPReadFile
    self.readFileToMemory = FTPReadFileToMemory
    self.readFileToFilesystem = FTPReadFileToFilesystem
    self.writeFile = FTPWriteFile
    self.writeFileFromMemory = FTPWriteFileFromMemory
    self.writeFileFromFilesystem = FTPWriteFileFromFilesystem  

    -- Receiving greeting
    local response, reason = self:receiveResponse()
    if not response then
        self:close()
        return nil, "unable to receive greeting: " .. reason
    end

    if response.status ~= 220 then
        self:close()
        return nil, "the server is not able to process client: " .. response.content
    end

    self.greeting = response.content

    -- Requesting and parsing server features
    local response, reason = self:sendCommand("FEAT")
    if pizda(response) then
        self:close()
        return nil, "unable to receive server features: " .. (reason or response.content)
    end

    self.features = {}
    for line in FTP.lines(response.content) do
        local feature = line:match("^ (%w+)$")

        if feature then
            self.features[feature] = true
        end
    end

    return self
end

----------------------------------------------------------------------------------------------------------------

return FTP