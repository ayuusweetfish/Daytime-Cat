local randomPath = require 'randpath'
local sp = require 'spacepart'
local spPartition = sp.partition
local spVicinity = sp.vicinity

local groundImage = love.graphics.newImage('res/ground.png')
local groundCellSize = 120
local groundQuad = {}
for i = 1, 4 do
  groundQuad[i] = love.graphics.newQuad(
    (i - 1) * groundCellSize, 0, groundCellSize, groundCellSize,
    groundImage:getPixelDimensions()
  )
end

local cat1Image = love.graphics.newImage('res/cat1.png')
local cat2Image = love.graphics.newImage('res/cat2.png')
local cat3Image = love.graphics.newImage('res/cat3.png')
local catW, catH = cat1Image:getDimensions()

local pawImage = love.graphics.newImage('res/paw.png')
local pawW, pawH = pawImage:getDimensions()

local bush1Image = love.graphics.newImage('res/bush1.png')
local bush1W, bush1H = bush1Image:getDimensions()
local bush2Image = love.graphics.newImage('res/bush2.png')
local bush2W, bush2H = bush2Image:getDimensions()

local sleepImage = love.graphics.newImage('res/sleep.png')
local sleepW, sleepH = sleepImage:getDimensions()
local fishImage = love.graphics.newImage('res/fish.png')
local fishW, fishH = fishImage:getDimensions()

local levels = {
  -- track: seed, curv, lmin, lmax, trunc,
  -- noise: seed, spray, arcs
  {3, 20, 0, 10, 0.2,
   0, 200, 0},
  {1, 10, 0, 10, 0.5,
   3, 500, 50},
  {15, 3, 2, 2.5, 1.0,
   0, 500, 500},
  {15, 7, 3, 3.5, 1.0,
   331552, 2000, 200},
  {333152, 7, 3.5, 4, 1.0,
   0, 500, 500},
}

local sceneGame
sceneGame = function (level)
  local s = {}
  local W, H = W, H

  local trackSeed = levels[level][1]
  local trackCurv = levels[level][2]
  local trackLenMin = levels[level][3]
  local trackLenMax = levels[level][4]
  local trackTrunc = levels[level][5]
  local noiseSeed = levels[level][6]
  local noiseSpray = levels[level][7]
  local noiseArcs = levels[level][8]

  -- Generate path
  local p = randomPath(trackSeed, trackCurv, trackLenMin, trackLenMax)
  --p = randomPath(seed, 3, 2, 2.5)
  --p = randomPath(seed, 20, 0, 10)
  local scale = math.min(W, H) * 4
  for i = 1, #p do
    p[i].x = p[i].x * scale
    p[i].y = p[i].y * scale
  end
  -- Truncate
  for i = math.floor(#p * trackTrunc) + 1, #p do p[i] = nil end

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
    ty = 0
  }

  love.math.setRandomSeed(noiseSeed)
  -- Low-discrepancy noise by Halton sequence
  local halton = function (b, i)
    local f = 1
    local r = 0
    while i > 0 do
      f = f / b
      r = r + f * (i % b)
      i = math.floor(i / b)
    end
    return r
  end
  for i = 1, noiseSpray do
    local x = halton(2, noiseSeed + i)
    local y = halton(3, noiseSeed + i)
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
  for i = 1, noiseArcs do
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
    local subdiv = math.ceil(r * math.abs(ang2 - ang1) / 80)
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
    if love.math.random() * 0.5 + 0.5 < spVicinity(spTrackPaws, 180, qx, qy) then
      local tyArg = love.math.random()
      bushes[#bushes + 1] = {
        x = qx, y = qy,
        ty = (tyArg < 0.05 and 2 or (tyArg < 0.2 and 3 or 1))
      }
    end
  end

  -- Partition all paws and all bushes
  local spAllPaws = spPartition(paws)
  local spBushes = spPartition(bushes)

  -- Level title text
  local levelText = love.graphics.newText(
    love.graphics.getFont(),
    'Day ' .. level
  )
  local hintText
  if level == 1 then
    hintText = love.graphics.newText(
      love.graphics.getFont(),
      'Use arrow keys or W/S/A/D or mouse'
    )
  end

  local camX, camY = 0, 0
  local catX, catY = 0, 0

  local mouseMoveX, mouseMoveY = nil, nil

  s.move = function (x, y)
    mouseMoveX = x - W / 2
    mouseMoveY = y - H / 2
  end
  s.press = s.move

  s.release = function (x, y)
    mouseMoveX, mouseMoveY = nil, nil
  end

  local curInBush = nil
  local curInBushTime = 0
  local levelEnterTime = -1200
  local levelClearTime = -1
  local lastDirX, lastDirY = 0, -1

  s.update = function ()
    -- Move cat
    local moveX, moveY = 0, 0
    if levelClearTime < 0 then
      if mouseMoveX ~= nil then
        moveX, moveY = mouseMoveX, mouseMoveY
        local angle = math.atan2(moveY, moveX)
        lastDirX, lastDirY = 0, 0
        if angle > -3/8 * math.pi and angle < 3/8 * math.pi then
          lastDirX = 1
        elseif angle < -5/8 * math.pi or angle > 5/8 * math.pi then
          lastDirX = -1
        end
        if angle > -7/8 * math.pi and angle < -1/8 * math.pi then
          lastDirY = -1
        elseif angle > 1/8 * math.pi and angle < 7/8 * math.pi then
          lastDirY = 1
        end
      else
        if love.keyboard.isDown('w', 'up') then moveY = moveY - 1 end
        if love.keyboard.isDown('s', 'down') then moveY = moveY + 1 end
        if love.keyboard.isDown('a', 'left') then moveX = moveX - 1 end
        if love.keyboard.isDown('d', 'right') then moveX = moveX + 1 end
        if moveX ~= 0 or moveY ~= 0 then
          lastDirX, lastDirY = moveX, moveY
        end
      end
      if moveX ~= 0 or moveY ~= 0 then
        local v = 1.5 / (moveX^2 + moveY^2)^0.5
        catX = catX + v * moveX
        catY = catY + v * moveY
        if levelEnterTime < 0 then levelEnterTime = 0 end
      end
    end

    -- Check bush intersection
    local _, inBush = spVicinity(spBushes, 60, catX, catY)
    if inBush ~= curInBush then
      curInBush = inBush
      if inBush ~= nil then
        if (inBush.ty == 0 or inBush.ty == 2 or inBush.ty == 3) and inBush.visited then
          curInBushTime = 1e5
        else
          curInBushTime = 0
        end
        if inBush.ty == 0 or inBush.ty == 2 or inBush.ty == 3 then
          inBush.visited = true
        end
        if inBush.ty == 0 then
          levelClearTime = 0
        end
      end
    elseif curInBush ~= nil then
      curInBushTime = curInBushTime + 1
    end

    -- Level clear?
    if levelClearTime >= 0 then
      levelClearTime = levelClearTime + 1
      if levelClearTime == 240 then
        if level == #levels then
          _G['replaceScene'](_G['sceneText'](4))
        else
          _G['replaceScene'](sceneGame(level + 1))
        end
      end
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

    levelEnterTime = levelEnterTime + 1
  end

  s.draw = function ()
    local ox = W * 0.5 - camX
    local oy = H * 0.5 - camY

    -- Ground
    love.graphics.clear(1.00, 0.99, 0.93)
    love.graphics.setColor(1, 1, 1)
    local noiseScale = ((2^0.5) + math.pi) * 5
    for cx = math.floor((camX - W * 0.5) / groundCellSize),
             math.ceil((camX + W * 0.5) / groundCellSize) + 4 do
      for cy = math.floor((camY - H * 0.5) / groundCellSize),
               math.ceil((camY + H * 0.5) / groundCellSize) + 3 do
        local id = love.math.noise(cx * noiseScale, cy * noiseScale)
        local ty =
          id < 0.8 and 1 or
          id < 0.9 and 4 or
          id < 0.95 and 3 or 2
        love.graphics.draw(
          groundImage, groundQuad[ty],
          cx * groundCellSize - camX,
          cy * groundCellSize - camY
        )
      end
    end

    -- Paws
    love.graphics.setColor(1, 1, 1)
    for i = 1, #paws do
      local p = paws[i]
      love.graphics.draw(pawImage,
        ox + p.x, oy + p.y, p.angle,
        p.flip and -0.6 or 0.6, 0.6,
        pawW / 2, pawH / 2
      )
    end

    -- Cat
    love.graphics.setColor(1, 1, 1)
    if lastDirY == -1 then
      love.graphics.draw(cat1Image,
        ox + catX, oy + catY,
        lastDirX * math.pi / 12,
        (lastDirX < 0 and -1 or 1), 1,
        catW / 2, catH / 2)
    elseif lastDirY == 1 then
      love.graphics.draw(cat3Image,
        ox + catX, oy + catY, 0, (lastDirX <= 0 and 1 or -1), 1,
        catW / 2, catH / 2)
    else
      love.graphics.draw(cat2Image,
        ox + catX, oy + catY, 0, (lastDirX < 0 and -1 or 1), 1,
        catW / 2, catH / 2)
    end

    love.graphics.setColor(1, 1, 1)
    for i = 1, #bushes do
      local b = bushes[i]
      if b.visited then
        if b.ty == 0 then
          love.graphics.draw(sleepImage,
            ox + b.x, oy + b.y, 0, 1, 1, sleepW / 2, sleepH * 0.9)
        elseif b.ty == 2 or b.ty == 3 then
          love.graphics.draw(fishImage,
            ox + b.x, oy + b.y, 0, 1, 1, fishW / 2, fishH)
        end
      end
      if curInBush == b or not b.visited then
        local squeeze = 1
        if curInBush == b then
          if curInBush.visited then
            squeeze = squeeze * math.exp(-curInBushTime / 10) * math.max(0, 1 - curInBushTime / 120)
          elseif curInBushTime <= 600 then
            squeeze = 1 + 0.2 * math.exp(-curInBushTime / 60) * math.sin(curInBushTime / 10)
          end
        end
        if b.ty == 0 or b.ty == 2 then
          love.graphics.draw(bush2Image,
            ox + b.x, oy + b.y, 0, 1, squeeze, bush2W / 2, bush2H * 0.9)
        else
          love.graphics.draw(bush1Image,
            ox + b.x, oy + b.y, 0, 1, squeeze, bush1W / 2, bush1H * 0.9)
        end
      end
    end

    -- Level text
    if levelEnterTime < 480 then
      local alpha = math.min(1, (480 - levelEnterTime) / 120)
      love.graphics.setColor(0.1, 0.1, 0.1, alpha)
      love.graphics.draw(levelText,
        W * 0.5, H * 0.62, 0, 1, 1,
        levelText:getWidth() / 2,
        levelText:getHeight() / 2
      )
      if hintText ~= nil then
        love.graphics.draw(hintText,
          W * 0.5, H * 0.68, 0, 0.7, 0.7,
          hintText:getWidth() / 2,
          hintText:getHeight() / 2
        )
      end
    end

  --[[
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.setPointSize(4)
    love.graphics.setLineWidth(2)
    for i = 1, #p do
      love.graphics.points(ox + p[i].x, oy + p[i].y)
    end
    for i = 2, #p do
      love.graphics.line(
        ox + p[i - 1].x, oy + p[i - 1].y,
        ox + p[i].x, oy + p[i].y)
    end
    love.graphics.points(ox + catX, oy + catY)
  ]]
  end

  s.destroy = function ()
  end

  return s
end

return sceneGame
