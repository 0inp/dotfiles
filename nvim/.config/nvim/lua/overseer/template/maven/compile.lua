-- mvn clean install -PautoInstallSinglePackage -Dmaven.clean.failOnError=false -DskipTests -Dcheckstyle.skip

return {
  name = "mvn compile",
  builder = function(params)
    -- This must return an overseer.TaskDefinition
    return {
      -- cmd is the only required field
      cmd = {
        "mvn",
        "clean",
        "install",
        "-PautoInstallSinglePackage",
        "-Dmaven.clean.failOnError=false",
        "-DskipTests",
        "-Dcheckstyle.skip",
      },
      env = {
        JAVA_HOME = "/Users/spoint/.jenv/versions/11",
      },
      components = { { "on_output_quickfix", open = true }, "default" },
    }
  end,
  -- Optional fields
  desc = "Compile project bypassing tests and checktyle",
  -- Determines sort order when choosing tasks. Lower comes first.
  priority = 50,
  -- Add requirements for this template. If they are not met, the template will not be visible.
  -- All fields are optional.
  condition = {
    -- A string or list of strings
    -- Only matches when current buffer is one of the listed filetypes
    filetype = { "java" },
    -- A string or list of strings
    -- Only matches when cwd is inside one of the listed dirs
    dir = {
      "/Users/spoint/dev/twilio-reactor/",
      "/Users/spoint/dev/twilio-reactor/twilio-foundation-reactor/",
      "/Users/spoint/dev/twilio-reactor/twilio-com/",
      "/Users/spoint/dev/twilio-reactor/sendgrid/",
      "/Users/spoint/dev/twilio-reactor/segment/",
    },
  },
}
