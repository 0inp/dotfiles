local statusline_config = function()
  local mini_statusline = require 'mini.statusline'
  mini_statusline.setup {
    use_icons = true,
    content = {
      active = function()
        local m = require 'mini.statusline'

        local fnamemodify = vim.fn.fnamemodify

        local project_name = function()
          local current_project_folder = fnamemodify(vim.fn.getcwd(), ':t')
          local parent_project_folder = fnamemodify(vim.fn.getcwd(), ':h:t')
          return parent_project_folder .. '/' .. current_project_folder
        end

        local lazy_plug_count = function()
          local stats = require('lazy').stats()
          return ' ' .. stats.count
        end

        local lazy_startup = function()
          local stats = require('lazy').stats()
          local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
          return ' ' .. ms .. 'ms'
        end

        local lazy_updates = function()
          return require('lazy.status').updates()
        end

        local wtf = function()
          return require('wtf').get_status()
        end

        local auto_format_indicator = function()
          if vim.g.vin_autoformat_enabled then
            return '󰉶 On'
          else
            return '󰉶 Off'
          end
        end

        local mode, mode_hl = m.section_mode { trunc_width = 120 }

        local spell = vim.wo.spell and (m.is_truncated(120) and 'S' or 'SPELL') or ''
        local wrap = vim.wo.wrap and (m.is_truncated(120) and 'W' or 'WRAP') or ''
        local git = m.section_git { trunc_width = 75 }
        local diagnostics = m.section_diagnostics { trunc_width = 75 }
        local searchcount = m.section_searchcount { trunc_width = 75 }
        local location = m.section_location { trunc_width = 120 }
        local fileinfo = m.section_fileinfo { trunc_width = 125 }
        local filename = MiniStatusline.section_filename { trunc_width = 140 }
        local colorscheme_name = vim.g.colors_name or 'default'
        local colorscheme = m.is_truncated(200) and '' or ' ' .. colorscheme_name

        return m.combine_groups {
          { hl = mode_hl, strings = { mode } },
          {
            hl = 'Function',
            strings = (m.is_truncated(250) and { git } or { project_name(), git }),
          },

          '%<', -- Mark general truncate point

          { hl = 'Comment', strings = { filename, location, diagnostics } },

          '%=', -- End left alignment

          { hl = 'Comment', strings = { searchcount } },
          {
            hl = 'Comment',
            strings = (m.is_truncated(120) and {} or {
              wtf(),
              wrap,
              spell,
              auto_format_indicator(),
              lazy_plug_count(),
              lazy_updates(),
              lazy_startup(),
              colorscheme,
            }),
          },
          { hl = mode_hl, strings = { fileinfo } },
        }
      end,
    },
    set_vim_settings = false,
  }
end

return {
  {
    'echasnovski/mini.ai',
    version = false,
    event = 'VeryLazy',
    config = function(_, opts)
      require('mini.ai').setup(opts)
    end,
  },
  {
    'echasnovski/mini.pairs',
    version = false,
    event = 'VeryLazy',
    config = function(_, opts)
      require('mini.pairs').setup(opts)
    end,
  },
  {
    'echasnovski/mini.starter',
    version = false,
    event = 'VeryLazy',
    config = function(_, opts)
      require('mini.starter').setup(opts)
    end,
  },
  {
    'echasnovski/mini.surround',
    version = false,
    event = 'VeryLazy',
    config = function(_, opts)
      require('mini.surround').setup(opts)
    end,
  },
  {
    'echasnovski/mini.statusline',
    version = false,
    event = 'VeryLazy',
    config = statusline_config,
  },
}
