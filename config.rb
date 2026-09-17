# =============================================================================
# User Configuration Settings
# =============================================================================

THEME_NAME = "Laser"

# =============================================================================
# Status Bar Widgets
# =============================================================================

module StatusWidgets
  # Battery level icons in ascending order (0%..100%).
  # Material Design Icons:
  # \u{f0083}: battery-alert (0%)
  # \u{f0082}..\u{f007a}: battery-10 .. battery-90
  # \u{f0079}: battery (100% full)
  BATTERY_ICONS = [
    "\u{f0083}", "\u{f0082}", "\u{f0081}", "\u{f0080}", "\u{f007f}",
    "\u{f007e}", "\u{f007d}", "\u{f007c}", "\u{f007b}", "\u{f007a}",
    "\u{f0079}"
  ].freeze

  GIT_DIFF_CMD = <<~'SH'.strip.freeze
    {
      git diff HEAD --numstat
      git ls-files -o --exclude-standard | xargs wc -l 2>/dev/null | awk '$2 != "total" && NF == 2 { print $1, 0, $2 }'
    } | awk '{ add += $1; del += $2 } END { printf "+%d/-%d", add, del }'
  SH

  def self.safe_cwd(ctx)
    cwd = ctx.pane ? ctx.pane.cwd : nil
    cwd && !cwd.empty? ? cwd : nil
  end

  def self.current_theme(section, config)
    section.add do
      theme = config.theme
      theme && !theme.empty? ? "\u{e22b} #{theme}" : ""
    end
  end

  def self.clock(section)
    section.add do
      t = Time.now
      "\u{f017} #{sprintf('%04d-%02d-%02d %02d:%02d:%02d', t.year, t.month, t.day, t.hour, t.min, t.sec)}"
    end
  end

  def self.git_branch(section)
    section.add_async(
      "git",
      "branch",
      "--show-current",
      interval: 2.0,
      cwd: ->(ctx) { safe_cwd(ctx) },
      initial: ""
    ) do |result|
      if result.success?
        branch = result.stdout.strip
        branch.empty? ? "" : "\u{e725} #{branch}"
      else
        ""
      end
    end
  end

  def self.git_diff_count(section)
    section.add_async(
      "sh",
      "-c",
      GIT_DIFF_CMD,
      interval: 2.0,
      cwd: ->(ctx) { safe_cwd(ctx) },
      initial: ""
    ) do |result|
      result.success? ? "\u{f044} #{result.stdout.strip}" : ""
    end
  end

  def self.battery_percent(section)
    return unless Toyoterm.platform == :linux

    section.add do
      result = ""

      ["BAT0", "BAT1"].each do |name|
        begin
          path = "/sys/class/power_supply/#{name}/capacity"
          content = Toyoterm.read_file(path).strip
          next if content.empty?

          percent = content.to_i
          idx = (percent / 10.0).round
          idx = 0 if idx < 0
          idx = 10 if idx > 10

          icon = BATTERY_ICONS[idx]
          result = "#{icon} #{percent}%"
          break
        rescue
          # Battery interface unavailable or unreadable
        end
      end

      result
    end
  end
end

# =============================================================================
# Main Configuration
# =============================================================================

Toyoterm.configure do |config|
  # Default shell selection
  # config.default_shell = "wsl.exe"

  config.theme = THEME_NAME
  config.scrollback_lines = 10_000
  config.leader key: "j", mods: "CTRL", timeout: 1000

  # ---------------------------------------------------------------------------
  # Font
  # ---------------------------------------------------------------------------
  config.font do |font|
    font.family = "JetBrainsMono Nerd Font"
    font.fallback = ["Hack Nerd Font"]
    font.size = 12.0
  end

  # ---------------------------------------------------------------------------
  # Window & Status Bars
  # ---------------------------------------------------------------------------
  config.window do |window|
    window.opacity = 0.95
    window.decorations = true
    window.always_on_top = false

    window.image do |img|
      img.path = nil
      img.opacity = 0.25
    end

    # Top Status Bar
    window.bar :top, interval: 1.0 do |bar|
      bar.section(:center, separator: " | ") do |section|
        section.add { "\u{f489} toyoterm" }
      end

      bar.section(:right, separator: " | ") do |section|
        StatusWidgets.current_theme(section, config)
        StatusWidgets.clock(section)
        StatusWidgets.battery_percent(section)
      end
    end

    # Bottom Status Bar
    window.bar :bottom, interval: 1.0 do |bar|
      bar.section(:left, separator: " | ") do |section|
        StatusWidgets.git_branch(section)
        StatusWidgets.git_diff_count(section)
      end

      bar.section(:right, separator: " | ") do |section|
        section.add { |ctx| ctx.pane.zoomed? ? "\u{f065} ZOOM" : "\u{f066} NORMAL" }
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Behavior
  # ---------------------------------------------------------------------------
  config.behavior do |behavior|
    behavior.allow_osc_notifications = true
  end

  # ---------------------------------------------------------------------------
  # Keybindings
  # ---------------------------------------------------------------------------
  config.keys do
    # --- Pane Navigation & Management ---
    leader("h").activate_pane(:left)
    leader("j").activate_pane(:down)
    leader("k").activate_pane(:up)
    leader("l").activate_pane(:right)
    leader("m").toggle_maximize
    leader("z").toggle_zoom
    leader("v").run { |ctx| ctx.pane.split(:right, cwd: ctx.pane.cwd) }
    leader("s").run { |ctx| ctx.pane.split(:down, cwd: ctx.pane.cwd) }

    # --- Tab Navigation & Management ---
    leader("c").run { |ctx| ctx.window.new_tab(cwd: ctx.pane.cwd) }
    leader("CTRL+j").next_tab
    (1..9).each do |n|
      leader(n.to_s).run do |ctx|
        tab = ctx.window.tabs[n - 1]
        tab.activate unless tab.nil?
      end
    end

    # --- Window & Appearance Controls ---
    leader("r").reload_config
    leader("t").command(:choose_theme)

    ctrl("-").run do
      new_size = config.font.size - 1.0
      config.font.size = new_size >= 6.0 ? new_size : 6.0
    end
    ctrl("=").run do
      new_size = config.font.size + 1.0
      config.font.size = new_size <= 48.0 ? new_size : 48.0
    end

    ctrl("[").run do
      new_opacity = config.window.opacity - 0.05
      config.window.opacity = new_opacity >= 0.1 ? new_opacity : 0.1
    end
    ctrl("]").run do
      new_opacity = config.window.opacity + 0.05
      config.window.opacity = new_opacity <= 1.0 ? new_opacity : 1.0
    end

    # --- Clipboard ---
    ctrl_shift("v").paste_clipboard

    # --- Visual Mode ---
    leader("[").toggle_visual_mode
    key("v").select_visual_selection
    key("ESCAPE").end_visual_selection
    key("y").yank_selection

    # Visual Mode Cursor Movement
    key("h").move_visual_selection(:left)
    key("j").move_visual_selection(:down)
    key("k").move_visual_selection(:up)
    key("l").move_visual_selection(:right)
    key("LEFT").move_visual_selection(:left)
    key("DOWN").move_visual_selection(:down)
    key("UP").move_visual_selection(:up)
    key("RIGHT").move_visual_selection(:right)
    key("w").move_visual_selection(:word_forward)
    key("b").move_visual_selection(:word_backward)
    key("0").move_visual_selection(:line_start)
    key("$").move_visual_selection(:line_end)
  end
end
