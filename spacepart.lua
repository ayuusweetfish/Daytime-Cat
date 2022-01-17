local SP_CELL = 100

local cellCoord = function (x) return math.floor(x / SP_CELL) end
local cellId = function (x, y) return x * 100003 + y end
local cellIdRaw = function (x, y)
  return cellId(cellCoord(x), cellCoord(y))
end

local partition = function (pts)
  local part = {}
  for i = 1, #pts do
    local p = pts[i]
    local cell = cellIdRaw(p.x, p.y)
    local t = part[cell]
    if t == nil then
      t = {}
      part[cell] = t
    end
    t[#t + 1] = pts[i]
  end
  return part
end

local vicinity = function (ptsPart, r, x, y)
  local cy1 = cellCoord(y - r)
  local cy2 = cellCoord(y + r)
  local rsq = r * r
  local best, bestObj = rsq, nil
  for cx = cellCoord(x - r), cellCoord(x + r) do
    for cy = cy1, cy2 do
      local t = ptsPart[cellId(cx, cy)]
      if t ~= nil then
        for i = 1, #t do
          local p = t[i]
          local dsq = (x - p.x)^2 + (y - p.y)^2
          if dsq < best then
            best, bestObj = dsq, p
          end
        end
      end
    end
  end
  return math.sqrt(best / rsq), bestObj
end

local forEach = function (ptsPart, x1, y1, x2, y2, fn)
  local cy1 = cellCoord(y1)
  local cy2 = cellCoord(y2) + 1
  for cx = cellCoord(x1), cellCoord(x2) + 1 do
    for cy = cy1, cy2 do
      local t = ptsPart[cellId(cx, cy)]
      if t ~= nil then for i = 1, #t do fn(t[i]) end end
    end
  end
end

return {
  partition = partition,
  vicinity = vicinity,
  forEach = forEach,
}
