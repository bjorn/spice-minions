local Grid = require "libs.jumper.grid"
local Pathfinder = require "libs.jumper.pathfinder"

local floor = math.floor

local WALKABLE = 0
local BLOCKED = 1

local blocking = {
    map = false,
    grid = false,
}

function blocking.setMap(map)
    assert(type(map) == "table", "a map please")

    if blocking.map == map then
        return
    end

    blocking.map = map
    blocking.grid = false

    blocking.cellwidth = map.tilewidth / 2
    blocking.cellheight = map.tileheight / 2

    blocking.refreshGrid()
end

function blocking.toGrid(x, y)
    return floor(x / blocking.cellwidth) + 1,
           floor(y / blocking.cellheight) + 1
end

local function contains(map, x, y)
    return x >= 1 and y >= 1 and x <= map.width * 2 and y <= map.height * 2
end

function blocking.gridCollides(gridX, gridY)
    local map = assert(blocking.map, "no map specified")

    if not contains(map, gridX, gridY) then
        return true
    end

    return blocking.grid[gridY][gridX] == BLOCKED
end

function blocking.collides(x, y)
    return blocking.gridCollides(blocking.toGrid(x,  y))
end

local function raytrace(x0, y0, x1, y1, visit)
    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)

    local x = floor(x0)
    local y = floor(y0)

    local n = 1
    local x_inc, y_inc
    local err

    if dx == 0 then
        x_inc = 0
        err = math.huge
    elseif x1 > x0 then
        x_inc = 1
        n = n + (floor(x1) - x)
        err = (floor(x0) + 1 - x0) * dy
    else
        x_inc = -1
        n = n + (x - floor(x1))
        err = (x0 - floor(x0)) * dy
    end

    if dy == 0 then
        y_inc = 0
        err = err - math.huge
    elseif y1 > y0 then
        y_inc = 1
        n = n + (floor(y1) - y)
        err = err - (floor(y0) + 1 - y0) * dx
    else
        y_inc = -1
        n = n + (y - floor(y1))
        err = err - (y0 - floor(y0)) * dx;
    end

    for i = n, 1, -1 do
        -- print("  visit", x, y, visit(x, y))
        if visit(x, y) then
            return false
        end

        if err > 0 then
            y = y + y_inc
            err = err - dx
        else
            x = x + x_inc
            err = err + dy
        end
    end

    return true
end

local function lineOfSight(x0, y0, x1, y1)
    -- print(" lineOfSight", x0, y0, x1, y1)
    return raytrace(x0, y0, x1, y1, blocking.gridCollides)
end

local function getPath(startX, startY, endX, endY, clearance)
    local map = assert(blocking.map, "no map specified")
    local startGridX, startGridY = blocking.toGrid(startX, startY)
    local endGridX, endGridY = blocking.toGrid(endX, endY)

    -- Can't find paths when either of the locations is invalid
    if not contains(map, startGridX, startGridY) or
       not contains(map, endGridX, endGridY) then
        return
    end

    if blocking.gridCollides(endGridX, endGridY) then
        return
    end

    return blocking.finder:getPath(startGridX, startGridY, endGridX, endGridY, clearance)
end

function blocking.pathExists(startX, startY, endX, endY)
    return getPath(startX, startY, endX, endY) and true or false
end

function blocking.findPath(startX, startY, endX, endY)
    -- print("findPath", startX, startY, endX, endY)
    local path = getPath(startX, startY, endX, endY)
    if not path then
        return
    end

    if blocking.finder:getFinder() == "JPS" and #path._nodes > 1 then
        path:fill()
    end

    --[[
    print(('Path found! Length: %.2f'):format(path:getLength()))
    for node, count in path:nodes() do
        print(('Step: %d - x: %d - y: %d'):format(count, node:getX(), node:getY()))
    end
    --]]

    local map = blocking.map
    local waypoints = {}
    local lastRequiredGridX, lastRequiredGridY
    local previousGridX, previousGridY

    for node, count in path:nodes() do
        local gridX, gridY = node:getX(), node:getY()

        if previousGridX then
            if lineOfSight(lastRequiredGridX + 0.5, lastRequiredGridY + 0.5, gridX + 0.5, gridY + 0.5) then
                previousGridX, previousGridY = gridX, gridY
            else
                local x = (previousGridX-1) * (blocking.cellwidth)
                local y = (previousGridY-1) * (blocking.cellheight)
                x = x + blocking.cellwidth / 2
                y = y + blocking.cellheight / 2
                waypoints[#waypoints + 1] = { x = x, y = y }
                lastRequiredGridX, lastRequiredGridY = previousGridX, previousGridY
            end

            previousGridX, previousGridY = gridX, gridY
        else
            lastRequiredGridX, lastRequiredGridY = startX / blocking.cellwidth + 0.5,
                                                   startY / blocking.cellheight + 0.5
            previousGridX, previousGridY = lastRequiredGridX, lastRequiredGridY
        end
    end

    -- use the destination as the last waypoint
    waypoints[#waypoints + 1] = { x = endX, y = endY }

    return waypoints
end

function blocking.refreshGrid()
    local map = assert(blocking.map, "no map specified")

    -- Generate grid and finder instances on-demand
    local groundLayer = map.layers[1]
    local grid = {}

    for y = 1, map.height do
        local row1 = {}
        local row2 = {}

        for x = 1, map.width do
            local topLeft, topRight, bottomLeft, bottomRight = WALKABLE, WALKABLE, WALKABLE, WALKABLE
            local tile = groundLayer.data[y][x]

            local terrain = tile.terrain
            if terrain then
                local topLeftTerrain = terrain[1]
                local topRightTerrain = terrain[2]
                local bottomLeftTerrain = terrain[3]
                local bottomRightTerrain = terrain[4]

                topLeft = topLeftTerrain.properties.block and BLOCKED or WALKABLE
                topRight = topRightTerrain.properties.block and BLOCKED or WALKABLE
                bottomLeft = bottomLeftTerrain.properties.block and BLOCKED or WALKABLE
                bottomRight = bottomRightTerrain.properties.block and BLOCKED or WALKABLE
            end

            row1[x*2-1] = topLeft
            row1[x*2] = topRight
            row2[x*2-1] = bottomLeft
            row2[x*2] = bottomRight
        end

        grid[y*2-1] = row1
        grid[y*2] = row2
    end

    --[[
    print("{")
    for y,row in ipairs(grid) do
        print("   {",table.concat(row, ","),"}")
    end
    print("}")
    --]]

    blocking.grid = grid
    blocking.finder = Pathfinder(Grid(grid), 'ASTAR', WALKABLE)
end

function blocking.blockRectangle(x, y, width, height)
    width = (width or 1) - 1
    height = (height or 1) - 1
    local gridStartX, gridStartY = blocking.toGrid(x, y)
    local gridEndX, gridEndY = blocking.toGrid(x + width, y + height)

    return math.max(1, gridStartX),
           math.max(1, gridStartY),
           math.min(gridEndX, blocking.map.width * 2),
           math.min(gridEndY, blocking.map.height * 2)
end

function blocking.addDynamicBlock(x, y, width, height)
    local gridStartX, gridStartY, gridEndX, gridEndY = blocking.blockRectangle(x, y, width, height)
    local grid = blocking.grid

    for x = gridStartX, gridEndX do
        for y = gridStartY, gridEndY do
            grid[y][x] = grid[y][x] + 1
        end
    end
end

function blocking.removeDynamicBlock(x, y, width, height)
    local gridStartX, gridStartY, gridEndX, gridEndY = blocking.blockRectangle(x, y, width, height)
    local grid = blocking.grid

    for x = gridStartX, gridEndX do
        for y = gridStartY, gridEndY do
            grid[y][x] = grid[y][x] - 1
        end
    end
end

function blocking.draw()
    local grid = blocking.grid
    local w,h = blocking.cellwidth, blocking.cellheight
    local drawRange = blocking.map.drawRange

    love.graphics.setColor(255,0,128,128)

    for y = math.max(1, drawRange.sy*2-1), math.min(#grid, drawRange.ey*2) do
        local row = grid[y]
        for x = math.max(1, drawRange.sx*2-1), math.min(#row, drawRange.ex*2) do
            if row[x] ~= WALKABLE then
                love.graphics.setColor(255,0,128,128*row[x])
                love.graphics.rectangle("line", (x-1) * w, (y-1) * h, w, h)
                love.graphics.rectangle("fill", (x-1) * w, (y-1) * h, w, h)
            end
        end
    end

    love.graphics.setColor(255,255,255,255)
end

return blocking
