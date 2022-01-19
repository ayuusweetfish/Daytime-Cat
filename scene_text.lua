local sceneGame = require 'scene_game'

local sceneText
sceneText = function (ty)
  local s = {}
  local W, H = W, H

  local strings = {
    [1] = "-  Daytime Cat  -\n ",
    [2] = "I'm not like other cats.\nI sleep at night and come out by day.",
    [3] = "So I ask them to leave me alone.\nI follow their pawprints to reunite with them.",
    [4] = "It's not easy, but for me daylight is enjoyable.\nThose cats don't get to appreciate this.",
    [10] = "There are a thousand ways to live a cat's life.\nEnjoying the daytime is one of them.",
    [11] = "Thank you for playing > <\n ",
    [20] = "Cats have a sharp sense of smell.",
    [21] = "When I stop, it helps me find the way.",
    [22] = "With it, I'm not afraid of getting lost.",
  }
  local images = {
    [2] = 'res/cat2.png',
    [3] = 'res/sleep.png',
    [4] = 'res/paw.png',
    [10] = 'res/cat3.png',
    [11] = 'res/fish.png',
    [20] = 'res/think.png',
    [22] = 'res/bush1.png',
  }

  local specialFn
  if ty == 21 then
    local paw = love.graphics.newImage('res/paw.png')
    local pawW, pawH = paw:getDimensions()
    local cat = love.graphics.newImage('res/cat2.png')
    local T = 0
    specialFn = function (ty) -- ty = 1: update; 2: draw
      if ty == 1 then
        T = T + 1
        return
      end
      local x0, y0 = 1372, 2042
      local r = 1590
      local a = 4.1
      local b = 4.6
      local scale = 0.6
      for i = 0, 15 do
        local t = a + (b - a) * i / 15
        local r = (i % 2 == 0 and r - 20 or r + 20)
        local xt = (math.sin(T / 120) + 1) / 2
        x = xt * (1 - math.abs(6 - i) / 6)
        local tint = 1 - x * 0.6
        local scale = 0.6 + x * 0.1
        local alpha = 1 - 0.8 * xt * (1 - x)
        love.graphics.setColor(tint, tint, tint, alpha)
        love.graphics.draw(paw,
          x0 + math.cos(t) * r,
          y0 + math.sin(t) * r,
          t + math.pi,
          (i % 2 == 0 and -scale or scale), scale,
          pawW / 2, pawH / 2)
      end
      love.graphics.setColor(1, 1, 1)
      love.graphics.draw(cat, 630, 460)
    end
  end

  local text = love.graphics.newText(
    love.graphics.getFont(),
    strings[ty]
  )
  local subtext
  if ty == 1 then
    subtext = love.graphics.newText(
      love.graphics.getFont(),
      'Click or press left/right arrows'
    )
  elseif ty == 11 then
    subtext = love.graphics.newText(
      love.graphics.getFont(),
      '-  Daytime Cat  -'
    )
  end

  local goNext = function ()
    if strings[ty + 1] == nil then
      if ty < 10 then
        _G['replaceScene'](sceneGame(1))
      elseif ty < 20 then
        -- No-op
      else
        _G['replaceScene'](sceneGame(3))
      end
    else
      _G['replaceScene'](sceneText(ty + 1), 'fadeOrange')
    end
  end
  local goPrev = function ()
    if strings[ty - 1] ~= nil then
      _G['replaceScene'](sceneText(ty - 1), 'fadeOrange')
    end
  end

  s.press = function (x, y)
  end

  s.move = function (x, y)
  end

  s.release = function (x, y)
    goNext()
  end

  local lastKeyNext = false
  local lastKeyPrev = false

  s.update = function ()
    local curKeyNext = love.keyboard.isDown('space', 'return', 'down', 'right', 'n', 's', 'd')
    if lastKeyNext and not curKeyNext then
      goNext()
    end
    lastKeyNext = curKeyNext

    local curKeyPrev = love.keyboard.isDown('up', 'left', 'p', 'w', 'a')
    if lastKeyPrev and not curKeyPrev then
      goPrev()
    end
    lastKeyPrev = curKeyPrev

    if specialFn then specialFn(1) end
  end

  local image
  local imageW, imageH
  if images[ty] ~= nil then
    image = love.graphics.newImage(images[ty])
    imageW, imageH = image:getDimensions()
  end
  s.draw = function ()
    love.graphics.clear(1.00, 0.99, 0.93)
    if specialFn then specialFn(2) end

    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.draw(text,
      W * 0.5, H * 0.48, 0, 1, 1,
      text:getWidth() / 2,
      text:getHeight() / 2
    )

    if subtext ~= nil then
      love.graphics.draw(subtext,
        W * 0.5, H * 0.52, 0, 0.7, 0.7,
        subtext:getWidth() / 2,
        subtext:getHeight() / 2
      )
    end
    if image ~= nil then
      love.graphics.setColor(1, 1, 1)
      love.graphics.draw(image,
        W * 0.85, H * 0.72, 0, 1, 1,
        imageW / 2, imageH / 2
      )
    end
  end

  s.destroy = function ()
  end

  return s
end

return sceneText
