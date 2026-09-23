# =============================================================================
# Machine-specific settings (if present)
# =============================================================================
setting_file = File.join(File.dirname(__FILE__), "setting.rb")
require_relative "setting" if File.exist?(setting_file)

# =============================================================================
# Plugins
# =============================================================================
require_relative "plugins/theme"
require_relative "plugins/git"
require_relative "plugins/wallpaper"
require_relative "plugins/widget"
require_relative "plugins/keybind"

# =============================================================================
# Base Configuration
# =============================================================================
Toyoterm.configure do |config|
  # config.default_shell = "wsl.exe"

  config.theme = "Laser"
  config.scrollback_lines = 10_000

  config.leader(
    key: "j",
    mods: "CTRL",
    timeout: 1_000
  )

  config.window do |window|
    window.opacity = 0.95
    window.decorations = true
    window.always_on_top = false
  end

  config.behavior do |behavior|
    behavior.allow_osc_notifications = true
  end
end
