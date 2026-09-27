-- anim.lua: one 32x32 RGBA frame in, idle/attack/hit frames + tags + outline out
-- usage: aseprite -b --script-param in=hero.png --script-param out=hero --script anim.lua
local inFile  = app.params["in"]
local outBase = app.params["out"]
local spr = Sprite{ fromFile = inFile }
assert(spr, "could not open " .. tostring(inFile))
local W, H = spr.width, spr.height
local layer = spr.layers[1]

-- helpers ---------------------------------------------------------------
local function srcImage()
  local cel = layer:cel(1)
  local img = Image(W, H, spr.colorMode)
  img:drawImage(cel.image, cel.position)
  return img
end
local function nearestScale(img, sw, sh)           -- nearest-neighbour resample
  local out = Image(sw, sh, img.colorMode)
  for y = 0, sh - 1 do
    for x = 0, sw - 1 do
      out:drawPixel(x, y, img:getPixel(math.floor(x * img.width / sw), math.floor(y * img.height / sh)))
    end
  end
  return out
end
local function tinted(img, r, g, b, amount)          -- blend opaque pixels towards a colour
  local pc = app.pixelColor
  local out = img:clone()
  for it in out:pixels() do
    local v = it()
    local a = pc.rgbaA(v)
    if a > 0 then
      local nr = math.floor(pc.rgbaR(v) * (1 - amount) + r * amount)
      local ng = math.floor(pc.rgbaG(v) * (1 - amount) + g * amount)
      local nb = math.floor(pc.rgbaB(v) * (1 - amount) + b * amount)
      it(pc.rgba(nr, ng, nb, a))
    end
  end
  return out
end
local function addFrame(img, dx, dy, ms)
  local fr = spr:newEmptyFrame(#spr.frames + 1)
  fr.duration = ms / 1000
  spr:newCel(layer, fr, img, Point(dx, dy))
  return fr.frameNumber
end

-- frames ----------------------------------------------------------------
local base = srcImage()
spr.frames[1].duration = 0.40                                   -- idle 1
addFrame(base, 0, -1, 400)                                      -- idle 2: 1px bob
local squash = nearestScale(base, W, H - 3)                     -- attack 1: anticipation squash
addFrame(squash, 0, 3, 80)
local stretch = nearestScale(base, W + 4, H - 1)                -- attack 2: lunge stretch
addFrame(stretch, 2, 1, 80)
addFrame(base, 0, 0, 120)                                       -- attack 3: recover
addFrame(tinted(base, 255, 255, 255, 0.85), -2, 0, 60)          -- hit 1: white flash, knock back
addFrame(tinted(base, 228, 59, 68, 0.5), -1, 0, 90)             -- hit 2: red tint

local function tag(name, from, to)
  local t = spr:newTag(from, to); t.name = name
end
tag("idle", 1, 2); tag("attack", 3, 5); tag("hit", 6, 7)

-- outline pass on every frame ----------------------------------------------
app.layer = layer
for i = 1, #spr.frames do
  app.frame = spr.frames[i]
  app.command.Outline{ ui = false, place = "outside", matrix = "circle", color = Color{ r = 0x18, g = 0x14, b = 0x25 } }
end

spr:saveAs(outBase .. ".aseprite")
app.command.ExportSpriteSheet{
  ui = false, askOverwrite = false,
  type = SpriteSheetType.ROWS, columns = 4,
  textureFilename = outBase .. "-sheet.png",
  dataFilename = outBase .. "-sheet.json",
  dataFormat = SpriteSheetDataFormat.JSON_ARRAY,
  listTags = true, listLayers = false, listSlices = false,
  shapePadding = 0, borderPadding = 0, innerPadding = 0,
}
print("frames:", #spr.frames, "tags:", #spr.tags)
