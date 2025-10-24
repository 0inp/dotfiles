local home = vim.env.HOME
local jdtls_path = home .. "/.config/local/share/nvim/mason/packages/jdtls"
local lombok_path = jdtls_path .. "/lombok.jar"

local function build_cmd(workspace_dir)
  return {
    "/Users/spoint/.jenv/versions/21/bin/java",
    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "-Xmx1g",
    "--add-modules=ALL-SYSTEM",
    "--add-opens",
    "java.base/java.util=ALL-UNNAMED",
    "--add-opens",
    "java.base/java.lang=ALL-UNNAMED",
    "-javaagent:" .. lombok_path,
    "-jar",
    jdtls_path .. "/plugins/org.eclipse.equinox.launcher_1.7.0.v20250519-0528.jar",
    "-configuration",
    jdtls_path .. "/config_mac",
    "-data",
    workspace_dir,
  }
end

local function build_settings()
  return {
    java = {
      configuration = {
        runtimes = {
          {
            name = "JavaSE-21",
            path = "/Users/spoint/.jenv/versions/21",
            default = true,
          },
          {
            name = "JavaSE-11",
            path = "/Users/spoint/.jenv/versions/11",
          },
        },
      },
      format = {
        enabled = true,
        settings = {
          profile = "TwilioCheckstyle",
          url = "file://" .. home .. "/dotfiles/nvim/.config/nvim/formatter/java_format_checkstyle.xml",
        },
      },
      completion = {
        importOrder = { "java", "javax", "com", "org" },
      },
    },
  }
end

local function build_config()
  local root_dir = require("jdtls.setup").find_root({ "gradlew", "mvnw", ".git" })
  if not root_dir then
    return nil
  end

  local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
  local workspace_dir = home .. "/dev/jdtls_data/" .. project_name

  if vim.fn.isdirectory(workspace_dir) == 0 then
    vim.fn.mkdir(workspace_dir, "p")
  end

  return {
    cmd = build_cmd(workspace_dir),
    settings = build_settings(),
  }
end

local function start_jdtls()
  local config = build_config()
  if not config then
    return
  end
  require("jdtls").start_or_attach(config)
end

return {
  {
    "mfussenegger/nvim-jdtls",
    ft = { "java" },
    config = function()
      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("LazyJdtls", { clear = true }),
        pattern = "*.java",
        callback = start_jdtls,
        desc = "Start or attach jdtls when entering Java buffers",
      })

      start_jdtls()
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "groovy",
      })
    end,
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "groovyls" })
    end,
  },
}
