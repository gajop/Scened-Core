AbstractTerrainModifyCommand = Command:extends{}
AbstractTerrainModifyCommand.className = "AbstractTerrainModifyCommand"

Math = Math or {}

function Math.RoundInt(x, step)
    x = math.round(x)
    return x - x % step
end

local function rotate(x, y, rotation)
    return x * math.cos(rotation) - y * math.sin(rotation),
           x * math.sin(rotation) + y * math.cos(rotation)
end

local function GetRotatedSize(size, rotation)
    return size * (
        math.abs(math.sin(rotation)) +
        math.abs(math.cos(rotation))
    )
end

local once = true
local function generateMap(size, delta, shapeName, rotation, origSize)
    local greyscale = SB.model.terrainManager:getShape(shapeName)
    local sizeX, sizeZ = greyscale.sizeX, greyscale.sizeZ
    local map = { sizeX = sizeX, sizeZ = sizeZ }
    local res = greyscale.res

    local scaleX = sizeX / (size)
    local scaleZ = sizeZ / (size)
    local parts = size / Game.squareSize + 1

    local diffSize = size - origSize
    local function getIndex(x, z)
        local rx = math.min(sizeX-1, math.max(0, math.floor(scaleX * x)))
        local rz = math.min(sizeZ-1, math.max(0, math.floor(scaleZ * z)))
        local indx = rx * sizeX + rz
        return indx
    end
    -- interpolates between four nearest points based on their distance
    local function interpolate(x, z)
        local rxRaw = scaleX * x
        local rzRaw = scaleZ * z
        local rx = math.floor(rxRaw)
        local rz = math.floor(rzRaw)
        local indx = rx * sizeX + rz

        local i = (rxRaw > rx) and 1 or -1
        local j = (rzRaw > rz) and 1 or -1
        local dx = 1 - (rxRaw - rx)
        local dz = 1 - (rzRaw - rz)

        local value = res[indx] * dx * dz
                    + res[indx + i * sizeX] * (1 - dx) * dz
                    + res[indx + j] * dx * (1 - dz)
                    + res[indx + i * sizeX + j] * (1 - dx) * (1 - dz)

        local w = dx * dx + (1 - dx) * dz + dx * (1 - dz) + (1 - dx) * (1 - dz)
        return value
    end

    Spring.Echo("diffSize", diffSize)
    for x = 0, size, Game.squareSize do
        for z = 0, size, Game.squareSize do
            -- local rx, rz = x, z
            local rx, rz = x - size, z - size
            rx, rz = rotate(rx, rz, rotation)
            rx, rz = rx + size, rz + size
    --        rx, rz = rx + diffSize, rz + diffSize
            if once then
                Spring.Echo(("%d:%d, %d:%d"):format(x, z, rx, rz))
            end
            local diff
            local indx = getIndex(rx, rz)
            if indx > sizeX + 1 and indx < sizeX * (sizeX - 1) - 1 then
                diff = interpolate(rx, rz)
            else
                diff = res[indx]
            end
            map[x + z * parts] = diff * delta
        end
    end
    once = true
    return map
end

local maps = {}
--  FIXME: ugly, rework
local function getMap(size, delta, shapeName, rotation, origSize)
    local map = nil

    local mapsByShape = maps[shapeName]
    if not mapsByShape then
        mapsByShape = {}
        maps[shapeName] = mapsByShape
    end

    local mapsBySize = mapsByShape[size]
    if not mapsBySize then
        mapsBySize = {}
        mapsByShape[size] = mapsBySize
    end

    local mapsByRotation = mapsBySize[rotation]
    if not mapsByRotation then
        mapsByRotation = {}
        mapsBySize[rotation] = mapsByRotation
    end

    local map = mapsByRotation[delta]
    if not map then
        map = generateMap(size, delta, shapeName, rotation, origSize)
        mapsByRotation[delta] = map
    end
    return map
end

function AbstractTerrainModifyCommand:GetHeightMapFunc(isUndo)
    return function()
        local rotation = math.rad(self.opts.rotation)
        local size = self.opts.size
        local rotatedSize = GetRotatedSize(size, rotation)
        size = Math.RoundInt(size, Game.squareSize)
        rotatedSize = Math.RoundInt(rotatedSize, Game.squareSize)

        local origSize = size
        size = rotatedSize

        local map = getMap(size, self.opts.strength, self.opts.shapeName, rotation, origSize)

        local centerX = self.opts.x
        local centerZ = self.opts.z
        local parts = size / Game.squareSize + 1
        local dsh = Math.RoundInt((size - origSize) / 2, Game.squareSize)
        local startX = Math.RoundInt(centerX - size + dsh, Game.squareSize)
        local startZ = Math.RoundInt(centerZ - size + dsh, Game.squareSize)

        if not isUndo then
            -- calculate the changes only once so redoing the command is faster
            if self.changes == nil then
                self.changes = self:GenerateChanges({
                    startX = startX,
                    startZ = startZ,
                    parts  = parts,
                    size   = size,
                    isUndo = isUndo,
                    map    = map,
                })
            end
            for x = 0, size, Game.squareSize do
                for z = 0, size, Game.squareSize do
                    local delta = self.changes[x + z * parts]
                    if delta ~= nil then
                        Spring.AddHeightMap(
                            x + startX,
                            z + startZ,
                            delta
                        )
                    end
                end
            end
        else
            for x = 0, size, Game.squareSize do
                for z = 0, size, Game.squareSize do
                    local delta = self.changes[x + z * parts]
                    if delta ~= nil then
                        Spring.AddHeightMap(
                            x + startX,
                            z + startZ,
                            -delta
                        )
                    end
                end
            end
        end
    end
end

function AbstractTerrainModifyCommand:execute()
    -- set it only once
    if self.canExecute == nil then
        -- check if shape is available
        self.canExecute = SB.model.terrainManager:getShape(self.opts.shapeName) ~= nil
    end
    if self.canExecute then
        Spring.SetHeightMapFunc(self:GetHeightMapFunc(false))
    end
end

function AbstractTerrainModifyCommand:unexecute()
    if self.canExecute then
        Spring.SetHeightMapFunc(self:GetHeightMapFunc(true))
    end
end
