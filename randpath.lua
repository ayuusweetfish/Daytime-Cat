-- Random path generation
local randseed = love.math.setRandomSeed
local rand = love.math.random

-- Segment-segment distance
-- https://stackoverflow.com/a/67102941
local distSegSeg = function (ax, ay, bx, by, cx, cy, dx, dy)
  local rx, ry = cx - ax, cy - ay
  local ux, uy = bx - ax, by - ay
  local vx, vy = dx - cx, dy - cy

  local ru = rx * ux + ry * uy
  local rv = rx * vx + ry * vy
  local uu = ux^2 + uy^2
  local uv = ux * vx + uy * vy
  local vv = vx^2 + vy^2

  local det = uu*vv - uv*uv
  local s, t

  local clamp = function (x)
    if x <= 0 then return 0
    elseif x >= 1 then return 1
    else return x end
  end

  if det < 1e-6*uu*vv then
    s = clamp(ru/uu)
    t = 0
  else
    s = clamp((ru*vv - rv*uv)/det)
    t = clamp((ru*uv - rv*uu)/det)
  end

  local S = clamp((t*uv + ru)/uu)
  local T = clamp((s*uv - rv)/vv)

  local Ax, Ay = ax + S * ux, ay + S * uy
  local Bx, By = cx + T * vx, cy + T * vy
  return math.sqrt((Bx - Ax)^2 + (By - Ay)^2)
end

local randomPathKeypoints = function (seed, curv, minLen, maxLen)
  randseed(seed)

local generate = function ()
  local pts = {{x = 0, y = 0}}
  local th = rand() * math.pi * 2
  local ema = 0

  local TURN_LIMIT = math.pi/180 * curv
  local EMA_MAX = math.pi/180 * curv * 10
  local EMA_MIN = math.pi/180 * curv * 4

  for _ = 1, 1000 do
    local x, y = pts[#pts].x, pts[#pts].y
    local turn = (rand() * 2 - 1) * math.pi/180 * curv
    local nema = ema * 0.95 + math.abs(turn)
    while nema > EMA_MAX do
      turn = turn * 0.5
      nema = ema * 0.95 + math.abs(turn)
    end
    while nema < EMA_MIN do
      turn = turn * 2
      nema = ema * 0.95 + math.abs(turn)
    end
    ema = nema
    th = th + turn
    pts[#pts + 1] = {
      x = x + math.cos(th),
      y = y + math.sin(th),
    }
  end
  -- Simplify
  local newpts = {}
  local M = 10
  for i = 1, M do
    newpts[i] = pts[math.floor(1.5 + (i-1) * (#pts-1) / (M-1))]
  end
  pts = newpts
  -- Normalize
  local xmin, xmax = 1e8, -1e8
  local ymin, ymax = 1e8, -1e8
  for i = 1, #pts do
    xmin = math.min(xmin, pts[i].x)
    xmax = math.max(xmax, pts[i].x)
    ymin = math.min(ymin, pts[i].y)
    ymax = math.max(ymax, pts[i].y)
  end
  local scale = math.max(math.abs(xmin), xmax, math.abs(ymin), ymax)
  for i = 1, #pts do
    pts[i].x = pts[i].x / scale
    pts[i].y = pts[i].y / scale
  end
  -- Check total length
  local sumLen = 0
  for i = 1, #pts - 1 do
    sumLen = sumLen + math.sqrt(
      (pts[i].x - pts[i + 1].x)^2 +
      (pts[i].y - pts[i + 1].y)^2
    )
  end
  if sumLen < minLen or sumLen > maxLen then
    return nil
  end
  -- Check self-intersection
  for i = 3, M do
    if distSegSeg(
      pts[i - 2].x, pts[i - 2].y,
      pts[i - 2].x + 1e-3, pts[i - 2].y + 1e-3,
      pts[i - 1].x, pts[i - 1].y,
      pts[i].x, pts[i].y
    ) < 0.2 then
      return nil
    end
  end
  for i = 4, M do
    for j = 2, i - 2 do
      local d = distSegSeg(
        pts[i - 1].x, pts[i - 1].y,
        pts[i].x, pts[i].y,
        pts[j - 1].x, pts[j - 1].y,
        pts[j].x, pts[j].y
      )
      if d < 0.2 then
        return nil
      end
    end
  end
  return pts, sumLen
end

  local pts, sumLen
  repeat
    pts, sumLen = generate()
  until pts ~= nil

  return pts, sumLen
end

local lerp = function (t, t0, t1, x0, x1)
  return ((t1 - t) * x0 + (t - t0) * x1) / (t1 - t0)
end

-- Returns: x, y, new index
local CatmullRomSpline = function (t, pts, index)
  local n = #pts
  while index <= #pts - 4 and t > pts[index + 2].knot do
    index = index + 1
  end

  local t0, t1, t2, t3 =
    pts[index + 0].knot, pts[index + 1].knot,
    pts[index + 2].knot, pts[index + 3].knot
  local interpolate = function (x0, x1, x2, x3)
    local a1 = lerp(t, t0, t1, x0, x1)
    local a2 = lerp(t, t1, t2, x1, x2)
    local a3 = lerp(t, t2, t3, x2, x3)
    local b1 = lerp(t, t0, t2, a1, a2)
    local b2 = lerp(t, t1, t3, a2, a3)
    local c1 = lerp(t, t1, t2, b1, b2)
    return c1
  end

  local x0, x1, x2, x3 =
    pts[index + 0].x, pts[index + 1].x,
    pts[index + 2].x, pts[index + 3].x
  local y0, y1, y2, y3 =
    pts[index + 0].y, pts[index + 1].y,
    pts[index + 2].y, pts[index + 3].y
  local x = interpolate(x0, x1, x2, x3)
  local y = interpolate(y0, y1, y2, y3)
  return x, y, index
end

local randomPath = function (seed, curv, minLen, maxLen)
  local pts, totalLen = randomPathKeypoints(seed, curv, minLen, maxLen)

  -- Complete endpoints
  local flip = function (p, q)
    return {x = p.x * 2 - q.x, y = p.y * 2 - q.y}
  end
  table.insert(pts, 1, flip(pts[2], pts[1]))
  table.insert(pts, #pts + 1, flip(pts[#pts - 1], pts[#pts]))

  -- Calculate knot values
  local sumKnot = 0
  pts[1].knot = 0
  for i = 2, #pts do
    sumKnot = sumKnot + (
      (pts[i].x - pts[i - 1].x)^2 +
      (pts[i].y - pts[i - 1].y)^2
    )^0.25  -- Centripetal
    pts[i].knot = sumKnot
  end

  local knotStart = pts[2].knot
  local knotLen = pts[#pts - 1].knot - knotStart

  local newpts = {}
  local N = math.ceil(1000 * totalLen)
  local i = 1
  for j = 0, N do
    local x, y, ni = CatmullRomSpline(knotStart + knotLen * j / N, pts, i)
    newpts[#newpts + 1] = {x = x, y = y}
    i = ni
  end

  local sampledLen = 0
  local cumLen = {}
  for i = 1, N - 1 do
    local l = (
      (newpts[i + 1].x - newpts[i].x)^2 +
      (newpts[i + 1].y - newpts[i].y)^2
    )^0.5
    sampledLen = sampledLen + l
    cumLen[i] = sampledLen
  end

  -- Equal-space
  local eqpts = {}
  local M = math.ceil(100 * totalLen)
  local i = 1
  for j = 0, M do
    while i < N and cumLen[i] < sampledLen * j / M do
      i = i + 1
    end
    eqpts[#eqpts + 1] = newpts[i]
  end

  return eqpts
end

return randomPath
