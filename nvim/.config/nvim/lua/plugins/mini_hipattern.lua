-- craftzdog/utils.lua
-- https://gist.github.com/craftzdog/8012c78715414de7b5608bda08c77105

--[[
 * Converts an HSL color value to RGB. Conversion formula
 * adapted from http://en.wikipedia.org/wiki/HSL_color_space.
 * Assumes h, s, and l are contained in the set [0, 1] and
 * returns r, g, and b in the set [0, 255].
 *
 * @param   Number  h       The hue
 * @param   Number  s       The saturation
 * @param   Number  l       The lightness
 * @return  Array           The RGB representation
]]
local function hslToRgb(h, s, l)
  local r, g, b

  if s == 0 then
    r, g, b = l, l, l -- achromatic
  else
    local function hue2rgb(p, q, t)
      if t < 0 then
        t = t + 1
      end
      if t > 1 then
        t = t - 1
      end
      if t < 1 / 6 then
        return p + (q - p) * 6 * t
      end
      if t < 1 / 2 then
        return q
      end
      if t < 2 / 3 then
        return p + (q - p) * (2 / 3 - t) * 6
      end
      return p
    end

    local q
    if l < 0.5 then
      q = l * (1 + s)
    else
      q = l + s - l * s
    end
    local p = 2 * l - q

    r = hue2rgb(p, q, h + 1 / 3)
    g = hue2rgb(p, q, h)
    b = hue2rgb(p, q, h - 1 / 3)
  end

  return r * 255, g * 255, b * 255
end

--[[
 * Converts an HSL color value to RGB in Hex representation.
 * @param   Number  h       The hue
 * @param   Number  s       The saturation
 * @param   Number  l       The lightness
 * @return  String           The hex representation
]]
local function hslToHex(h, s, l)
  local r, g, b = hslToRgb(h / 360, s / 100, l / 100)

  return string.format("#%02x%02x%02x", r, g, b)
end

return {
  "echasnovski/mini.hipatterns",
  opts = {
    highlighters = {
      hsl_color = {
        pattern = "[hsl%(]?%d+%.?%d?,? %d+%.?%d?%%?,? %d+%.?%d?%%?%)?",
        group = function(_, match)
          --- @type string, string, string
          local nh, ns, nl = match:match("[hsl%(]?(%d+%.?%d?),? (%d+%.?%d?)%%?,? (%d+%.?%d?)%%?%)?")
          --- @type number?, number?, number?
          local h, s, l = tonumber(nh), tonumber(ns), tonumber(nl)
          --- @type string
          local hex_color = hslToHex(h, s, l)
          return MiniHipatterns.compute_hex_color_group(hex_color, "bg")
        end,
      },
    },
  },
}
