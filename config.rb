# =============================================================================
# Preferences
# =============================================================================

module UserConfig
  THEME = "Laser"

  FONT_FAMILY = "JetBrainsMono Nerd Font"
  FONT_FALLBACK = ["Hack Nerd Font"].freeze
  FONT_SIZE = 12.0
  FONT_SIZE_RANGE = (6.0..48.0)

  WINDOW_OPACITY = 0.95
  OPACITY_RANGE = (0.1..1.0)

  SCROLLBACK_LINES = 10_000
  LEADER_KEY = "j"
  LEADER_MODS = "CTRL"
  LEADER_TIMEOUT = 1_000

  STATUS_SEPARATOR = " | "
  WALLPAPER = "./wallpapers/toyoterm_wallpaper.png"
end

# =============================================================================
# Status bars
# =============================================================================

module StatusWidgets
  BATTERY_NAMES = ["BAT0", "BAT1"].freeze
  BATTERY_ICONS = [
    "\u{f0083}", "\u{f0082}", "\u{f0081}", "\u{f0080}", "\u{f007f}",
    "\u{f007e}", "\u{f007d}", "\u{f007c}", "\u{f007b}", "\u{f007a}",
    "\u{f0079}"
  ].freeze

  UNIX_GIT_DIFF_COMMAND = [
    "sh",
    "-c",
    <<~'SH'.strip
      {
        git diff HEAD --numstat
        git ls-files -o --exclude-standard | xargs wc -l 2>/dev/null | awk '$2 != "total" && NF == 2 { print $1, 0, $2 }'
      } | awk '{ add += $1; del += $2 } END { printf "+%d/-%d", add, del }'
    SH
  ].freeze

  WINDOWS_GIT_DIFF_COMMAND = [
    "powershell.exe",
    "-NoProfile",
    "-NonInteractive",
    "-Command",
    <<~'POWERSHELL'.strip
      $added = 0
      $deleted = 0

      git diff HEAD --numstat | ForEach-Object {
        $parts = $_ -split "`t", 3
        $value = 0
        if ([int]::TryParse($parts[0], [ref]$value)) { $added += $value }
        $value = 0
        if ([int]::TryParse($parts[1], [ref]$value)) { $deleted += $value }
      }

      git -c core.quotepath=false ls-files -o --exclude-standard | ForEach-Object {
        try {
          $bytes = [IO.File]::ReadAllBytes((Join-Path (Get-Location) $_))
          foreach ($byte in $bytes) {
            if ($byte -eq 10) { $added++ }
          }
        } catch {}
      }

      [Console]::Write("+$added/-$deleted")
    POWERSHELL
  ].freeze

  def self.configure(window, config)
    window.bar :top do |bar|
      bar.section(:center) { |section| section.add("\u{f489} toyoterm") }

      bar.section(:right, separator: UserConfig::STATUS_SEPARATOR) do |section|
        theme(section, config)
        clock(section)
        battery(section) if Toyoterm.platform == :linux
      end
    end

    window.bar :bottom do |bar|
      bar.section(:left, separator: UserConfig::STATUS_SEPARATOR) do |section|
        git_branch(section)
        git_diff_count(section)
      end

      bar.section(:right) do |section|
        section.add, interval: 1.0 do |context|
          context.pane.zoomed? ? "\u{f065} ZOOM" : "\u{f066} NORMAL"
        end
      end
    end
  end

  def self.theme(section, config)
    section.add, interval: 5.0 do
      name = config.theme
      name && !name.empty? ? "\u{e22b} #{name}" : ""
    end
  end

  def self.clock(section)
    section.add, interval: 1.0 do
      now = Time.now
      timestamp = sprintf(
        "%04d-%02d-%02d %02d:%02d:%02d",
        now.year, now.month, now.day, now.hour, now.min, now.sec
      )
      "\u{f017} #{timestamp}"
    end
  end

  def self.git_branch(section)
    section.add_async(
      "git", "branch", "--show-current",
      interval: 2.0,
      cwd: ->(context) { pane_cwd(context) },
      initial: ""
    ) do |result|
      branch = result.success? ? result.stdout.strip : ""
      branch.empty? ? "" : "\u{e725} #{branch}"
    end
  end

  def self.git_diff_count(section)
    command = if Toyoterm.platform == :windows
                WINDOWS_GIT_DIFF_COMMAND
              else
                UNIX_GIT_DIFF_COMMAND
              end

    section.add_async(
      *command,
      interval: 2.0,
      cwd: ->(context) { pane_cwd(context) },
      initial: ""
    ) do |result|
      result.success? ? "\u{f044} #{result.stdout.strip}" : ""
    end
  end

  def self.battery(section)
    return unless Toyoterm.platform == :linux

    section.add, interval: 5.0 do
      display = ""
      BATTERY_NAMES.each do |name|
        begin
          value = File.read("/sys/class/power_supply/#{name}/capacity").strip
          next if value.empty?

          percent = value.to_i
          icon_index = (percent / 10.0).round
          icon_index = 0 if icon_index < 0
          icon_index = 10 if icon_index > 10
          display = "#{BATTERY_ICONS[icon_index]} #{percent}%"
          break
        rescue StandardError
          # Try the next conventional battery device.
        end
      end
      display
    end
  end

  def self.pane_cwd(context)
    cwd = context.pane ? context.pane.cwd : nil
    cwd && !cwd.empty? ? cwd : nil
  end
end

# =============================================================================
# Configuration
# =============================================================================

Toyoterm.configure do |config|
  # config.default_shell = "wsl.exe"

  config.theme = UserConfig::THEME
  config.scrollback_lines = UserConfig::SCROLLBACK_LINES
  config.leader(
    key: UserConfig::LEADER_KEY,
    mods: UserConfig::LEADER_MODS,
    timeout: UserConfig::LEADER_TIMEOUT
  )

  config.font do |font|
    font.family = UserConfig::FONT_FAMILY
    font.fallback = UserConfig::FONT_FALLBACK
    font.size = UserConfig::FONT_SIZE
  end

  config.window do |window|
    window.opacity = UserConfig::WINDOW_OPACITY
    window.decorations = true
    window.always_on_top = false

    window.image do |image|
      image.path = nil
      image.opacity = 0.25
    end

    StatusWidgets.configure(window, config)
  end

  config.behavior do |behavior|
    behavior.allow_osc_notifications = true
  end

  config.keys do
    # Pane navigation and layout
    { "h" => :left, "j" => :down, "k" => :up, "l" => :right }.each do |key, direction|
      leader(key).activate_pane(direction)
    end
    leader("v").run { |context| context.pane.split(:right, cwd: context.pane.cwd) }
    leader("s").run { |context| context.pane.split(:down, cwd: context.pane.cwd) }
    leader("z").toggle_zoom
    leader("m").toggle_maximize

    # Tabs
    leader("c").run { |context| context.window.new_tab(cwd: context.pane.cwd) }
    leader("CTRL+j").next_tab
    (1..9).each do |number|
      leader(number.to_s).run do |context|
        tab = context.window.tabs[number - 1]
        tab.activate if tab
      end
    end

    # Configuration and appearance
    leader("r").reload_config
    leader("t").command(:choose_theme)

    ctrl("-").run do
      config.font.size = [config.font.size - 1.0, UserConfig::FONT_SIZE_RANGE.begin].max
    end
    ctrl("=").run do
      config.font.size = [config.font.size + 1.0, UserConfig::FONT_SIZE_RANGE.end].min
    end
    ctrl("[").run do
      config.window.opacity = [config.window.opacity - 0.05, UserConfig::OPACITY_RANGE.begin].max
    end
    ctrl("]").run do
      config.window.opacity = [config.window.opacity + 0.05, UserConfig::OPACITY_RANGE.end].min
    end

    # Clipboard
    case Toyoterm.platform
    when :macos
      primary("c").copy_selection
      primary("v").paste_clipboard
    when :windows
      ctrl("c").copy_selection
      ctrl("v").paste_clipboard
    when :linux
      ctrl_shift("c").copy_selection
      ctrl_shift("v").paste_clipboard
    end

    # Git
    leader("b").command(:select_branch)

    # Vim-like visual selection (these are inactive outside visual mode)
    leader("[").toggle_visual_mode
    key("v").select_visual_selection
    key("ESCAPE").end_visual_selection
    key("y").yank_selection

    {
      "h" => :left,
      "j" => :down,
      "k" => :up,
      "l" => :right,
      "LEFT" => :left,
      "DOWN" => :down,
      "UP" => :up,
      "RIGHT" => :right,
      "w" => :word_forward,
      "b" => :word_backward,
      "0" => :line_start,
      "$" => :line_end
    }.each do |key, direction|
      key(key).move_visual_selection(direction)
    end
  end
end
