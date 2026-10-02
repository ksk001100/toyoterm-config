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
