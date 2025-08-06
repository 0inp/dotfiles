local home = os.getenv("HOME")
local jdtls_path = home .. "/.config/local/share/nvim/mason/packages/jdtls"
local lombok_path = jdtls_path .. "/lombok.jar"
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local workspace_dir = home .. "/dev/jdtls_data/" .. project_name
return {
  {
    "mfussenegger/nvim-jdtls",
    opts = {
      -- Ensure jdtls starts with Java 21
      full_cmd = function()
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
      end,
      settings = {
        java = {
          configuration = {
            runtimes = {
              {
                name = "JavaSE-21",
                path = "/Users/spoint/.jenv/versions/21",
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
              -- url = "file:///Users/spoint/dev/twilio-reactor/twilio-checkstyle/src/main/resources/java_format_checkstyle.xml",
              url = "file://" .. home .. "/dotfiles/nvim/.config/nvim/formatter/java_format_checkstyle.xml",
            },
          },
          completion = {
            importOrder = { "java", "javax", "com", "org" },
          },
        },
      },
    },
  },
}
