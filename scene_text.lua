local sceneGame = require 'scene_game'

local sceneText
sceneText = function (ty)
  local s = {}

  local strings = {
    [1] = "-  Daytime Cat  -\n ",
    [2] = "I'm not like other cats.\nI sleep at night and come out by day.",
    [3] = "So I ask them to leave me alone.\nI follow their pawprints to reunite with them.",
    [4] = "It's not easy, but for me daylight is enjoyable.\nThose cats don't get to appreciate this.",
    [10] = "There are a thousand ways to live a cat's life.\nEnjoying the daytime is one of them.",
    [11] = "Thank you for playing > <\n ",
  }
  local images = {
    [2] = 'res/cat2.png',
    [3] = 'res/sleep.png',
    [4] = 'res/paw.png',
    [10] = 'res/cat3.png',
    [11] = 'res/fish.png',
  }

  local text = love.graphics.newText(
    love.graphics.getFont(),
    strings[ty]
  )
  local subtext
  if ty == 1 then
    subtext = love.graphics.newText(
      love.graphics.getFont(),
      'Click or press right arrow'
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
      else
        -- No-op
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
  end

  local image
  local imageW, imageH
  if images[ty] ~= nil then
    image = love.graphics.newImage(images[ty])
    imageW, imageH = image:getDimensions()
  end
  s.draw = function ()
    love.graphics.clear(1.00, 0.99, 0.93)
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
