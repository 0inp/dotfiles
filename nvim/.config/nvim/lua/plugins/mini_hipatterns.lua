-- Converts HSL to RGB.
-- https://www.w3.org/TR/css-color-3/#hsl-color
--
---@param h string The hue value in degrees.
---@param s string The saturation value in percent.
---@param l string The lightness value in percent.
---@return integer, integer, integer
local function hsl_to_rgb(h, s, l)
  h, s, l = h % 360, s / 100, l / 100
  if h < 0 then
    h = h + 360
  end
  local function f(n)
    local k = (n + h / 30) % 12
    local a = s * math.min(l, 1 - l)
    return l - a * math.max(-1, math.min(k - 3, 9 - k, 1))
  end
  return f(0) * 255, f(8) * 255, f(4) * 255
end

return {
  "nvim-mini/mini.hipatterns",
  opts = function(_, opts)
    local hipatterns = require("mini.hipatterns")
    opts.highlighters = vim.tbl_extend("force", opts.highlighters or {}, {
      rgb_triplet = {
        pattern = "%f[%d]()%d+ %d+ %d+()%f[%D]",
        group = function(_, _, data)
          local style = "bg" -- 'fg' or 'bg'
          local full = data.full_match
          local r, g, b = full:match("(%d+)[,%s]+(%d+)[,%s]+(%d+)")
          r, g, b = tonumber(r), tonumber(g), tonumber(b)
          local hex = string.format("#%02x%02x%02x", r, g, b)
          return hipatterns.compute_hex_color_group(hex, style)
        end,
        extmark_opts = { priority = 1500 },
      },
      hsl_color = {
        pattern = "hsl%(%d+, ?%d+%%, ?%d+%%%)",
        group = function(_, match)
          local style = "bg" -- 'fg' or 'bg'
          local hue, saturation, lightness = match:match("hsl%((%d+), ?(%d+)%%, ?(%d+)%%%)")

          local red, green, blue = hsl_to_rgb(hue, saturation, lightness)
          local hex = string.format("#%02x%02x%02x", red, green, blue)
          return hipatterns.compute_hex_color_group(hex, style)
        end,
      },
    })
  end,
}
