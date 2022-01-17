local randomPath = require 'randpath'
local sp = require 'spacepart'
local spPartition = sp.partition
local spVicinity = sp.vicinity

local pawImage = love.graphics.newImage('res/paw.png')
local pawW, pawH = pawImage:getDimensions()

local bushImage = love.graphics.newImage('res/bush1.png')
local bushW, bushH = bushImage:getDimensions()

return function ()
  local s = {}
  local W, H = W, H

  -- Generate path
  local seed = 10
  local p = randomPath(seed, 7, 3, 3.5)
  --p = randomPath(seed, 3, 2, 2.5)
  --p = randomPath(seed, 20, 0, 10)
  local scale = math.min(W, H) * 4
  for i = 1, #p do
    p[i].x = p[i].x * scale
    p[i].y = p[i].y * scale
  end

  -- Paws
  local paws = {}
  local addPaw = function (x, y, angle, flip)
    paws[#paws + 1] = {
      x = x, y = y, angle = angle,
      flip = flip,
    }
  end
  -- Bushes
  local bushes = {}

  for i = 1, #p - 1, 2 do
    -- Draw a paw
    local isLeft = (i % 4 == 1)
    local dx = p[i + 1].x - p[i].x
    local dy = p[i + 1].y - p[i].y
    local angle = math.pi / 2 + math.atan2(dy, dx)
    local nx, ny = dy * 0.7, -dx * 0.7
    addPaw(
      p[i].x + (isLeft and nx or -nx),
      p[i].y + (isLeft and ny or -ny),
      angle, isLeft
    )
  end
  -- On-track paws lookup table
  local spTrackPaws = spPartition(paws)

  bushes[#bushes + 1] = {
    x = p[#p].x,
    y = p[#p].y,
    ty = 1
  }

  love.math.setRandomSeed(333152)
  -- Low-discrepancy noise
  local x = love.math.random()
  local y = love.math.random()
  for i = 1, 2000 do
    x = (x + 2^0.5) % 1
    y = (y + 3^0.5) % 1
    local x1 = x + love.math.random() * 0.01
    local y1 = y + love.math.random() * 0.01
    local x2 = (x1 * 2 - 1) * scale
    local y2 = (y1 * 2 - 1) * scale
    if love.math.random() < spVicinity(spTrackPaws, 60, x2, y2) then
      addPaw(
        x2, y2,
        love.math.random() * math.pi * 2,
        love.math.random() < 0.5
      )
    end
  end
  -- Random arcs
  for i = 1, 200 do
    -- Random endpoints
    local px, py
    repeat
      px = (love.math.random() * 2 - 1) * scale
      py = (love.math.random() * 2 - 1) * scale
    until px*px + py * py >= 500*500
    local len = love.math.random() * 1000 + 200
    local th = love.math.random() * math.pi * 2
    local mx = px + math.cos(th) * len / 2
    local my = py + math.cos(th) * len / 2
    local qx = px + math.cos(th) * len
    local qy = py + math.cos(th) * len
    -- Random passing point
    local odev = (love.math.random() * 0.25 + 0.1) * len
    local phi = love.math.random() * math.pi * 2
    local ox = mx + math.cos(phi) * odev
    local oy = my + math.sin(phi) * odev
    -- Circumcentre
    local denom = 2 * (px * (qy - oy) + qx * (oy - py) + ox * (py - qy))
    local cx = (
      (px^2 + py^2) * (qy - oy) +
      (qx^2 + qy^2) * (oy - py) +
      (ox^2 + oy^2) * (py - qy)
    ) / denom
    local cy = (
      (px^2 + py^2) * (ox - qx) +
      (qx^2 + qy^2) * (px - ox) +
      (ox^2 + oy^2) * (qx - px)
    ) / denom
    local r = math.sqrt((px - cx)^2 + (py - cy)^2)
    local ang1 = math.atan2(py - cy, px - cx)
    local ang2 = math.atan2(qy - cy, qx - cx)
    if math.abs(ang1 - ang2) >= math.pi then
      if ang1 < 0 then ang1 = ang1 + math.pi * 2
      else ang2 = ang2 + math.pi * 2 end
    end
    -- Draw arc
    local subdiv = math.floor(r * math.abs(ang2 - ang1) / 80)
    for i = 0, subdiv do
      local outer = (i % 2 == 0)
      local r = (outer and r + 30 or r - 30)
      local angle = ang1 + (ang2 - ang1) * i / subdiv
      local x = cx + math.cos(angle) * r
      local y = cy + math.sin(angle) * r
      if love.math.random() < spVicinity(spTrackPaws, 120, x, y) then
        addPaw(x, y, angle, flipped)
      end
    end
    -- Add bush
    if love.math.random() < spVicinity(spTrackPaws, 180, qx, qy) then
      bushes[#bushes + 1] = {
        x = qx, y = qy,
        ty = 1
      }
    end
  end

  local camX, camY = 0, 0
  local catX, catY = 0, 0

  s.press = function (x, y)
  end

  s.move = function (x, y)
  end

  s.release = function (x, y)
  end

  s.update = function ()
    -- Move cat
    local moveX, moveY = 0, 0
    if love.keyboard.isDown('w', 'up') then moveY = moveY - 1 end
    if love.keyboard.isDown('s', 'down') then moveY = moveY + 1 end
    if love.keyboard.isDown('a', 'left') then moveX = moveX - 1 end
    if love.keyboard.isDown('d', 'right') then moveX = moveX + 1 end
    if moveX ~= 0 or moveY ~= 0 then
      local v = 1.5 / (moveX^2 + moveY^2)^0.5
      catX = catX + v * moveX
      catY = catY + v * moveY
    end

    -- Move camera
    local dx = catX - camX
    local dy = catY - camY
    local dsq = dx^2 + dy^2
    if dsq >= 0.1 then
      camX = camX + dx * 0.05
      camY = camY + dy * 0.05
    else
      camX, camY = catX, catY
    end
  end

  s.draw = function ()
    love.graphics.clear(0.98, 0.98, 0.98)
    local ox = W * 0.5 - camX
    local oy = H * 0.5 - camY

    love.graphics.setColor(1, 1, 1)
    for i = 1, #paws do
      local p = paws[i]
      love.graphics.draw(pawImage,
        ox + p.x, oy + p.y, p.angle,
        p.flip and -0.6 or 0.6, 0.6,
        pawW / 2, pawH / 2
      )
    end

    love.graphics.setColor(1, 1, 1)
    for i = 1, #bushes do
      local b = bushes[i]
      love.graphics.draw(bushImage,
        ox + b.x, oy + b.y, 0, 1, 1, bushW / 2, bushH / 2)
    end

    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.setPointSize(4)
    love.graphics.setLineWidth(2)
  --[[
    for i = 1, #p do
      love.graphics.points(ox + p[i].x, oy + p[i].y)
    end
    for i = 2, #p do
      love.graphics.line(
        ox + p[i - 1].x, oy + p[i - 1].y,
        ox + p[i].x, oy + p[i].y)
    end
  ]]
    love.graphics.points(ox + catX, oy + catY)
  end

  s.destroy = function ()
  end

  return s
end
