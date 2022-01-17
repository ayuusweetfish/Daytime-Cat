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
  local rsq = r * r
  for cx = cellCoord(x - r), cellCoord(x + r) do
    for cy = cellCoord(y - r), cellCoord(y + r) do
      local t = ptsPart[cellId(cx, cy)]
      if t ~= nil then
        for i = 1, #t do
          local p = t[i]
          local dsq = (x - p.x)^2 + (y - p.y)^2
          if dsq <= rsq then
            return true
          end
        end
      end
    end
  end
  return false
end

return {
  partition = partition,
  vicinity = vicinity,
}
