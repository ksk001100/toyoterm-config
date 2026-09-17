THEME_NAME = "Laser"

def current_theme(config, section)
  section.add { "\u{e22b} #{config.theme}" } 
end

def clock(section)
  section.add_async(
    "date",
    "+%Y-%m-%d %H:%M:%S",
    interval: 1.0,
    initial: ''
  ) do |result|
    if result.success?
      "\u{f017} #{result.stdout.strip}"
    else
      ''
    end
  end
end

def git_branch(section)
  section.add_async(
    "git",
    "branch",
    "--show-current",
    interval: 2.0,
    cwd: ->(ctx) { ctx.pane.cwd },
    initial: '' 
  ) do |result|
    if result.success? && !result.stdout.strip.empty?
      "\u{e725} #{result.stdout.strip}"
    else
      ""
    end
  end
end

def git_diff_count(section)
  section.add_async(
    "sh",
    "-c",
    '{ git diff HEAD --numstat; git ls-files -o --exclude-standard | xargs wc -l 2>/dev/null | awk \'$2 != "total" && NF==2 {print $1, 0, $2}\'; } | awk \'{add += $1; del += $2} END {printf "+%d/-%d", add, del}\'',
    interval: 2.0,
    cwd: ->(ctx) { ctx.pane.cwd },
    initial: ''
  ) do |result|
    result.success? ? "\u{f044} #{result.stdout.strip}" : ""
  end
end

def battery_percent(section)
  section.add do |ctx|
    result = ""

    ["BAT0", "BAT1"].each do |name|
      begin
        value = Toyoterm.read_file("/sys/class/power_supply/#{name}/capacity").strip

        icons = [
          "\u{f0079}", "\u{f0079}", "\u{f0082}",
          "\u{f0081}", "\u{f0080}", "\u{f007f}",
          "\u{f007e}", "\u{f007d}", "\u{f007c}",
          "\u{f007b}", "\u{f007a}"
        ]

        unless value.empty?
          icon = icons[-(value.to_i / 10.0).round]
          result = "#{icon} #{value}%"
          break
        end
      rescue
        # TODO
      end
    end

    result
  end
end

Toyoterm.configure do |config|
  # config.default_shell = "wsl.exe"
  # config.default_shell = "pwsh.exe"
  config.theme = THEME_NAME
  config.font do |font|
    font.family = "JetBrainsMono Nerd Font"
    font.fallback = ["Hack Nerd Font"]
    font.size = 12.0
  end

  config.window do |window|
    window.image do |img|
      img.path = nil
      img.opacity = 0.25
    end

    window.opacity = 0.95
    window.decorations = true
    window.always_on_top = false

    window.bar :top, interval: 1.0 do |bar|
      bar.section(:right, separator: " | ") do |section|
        current_theme(config, section)
        clock(section)
        if Toyoterm.platform == :linux
          battery_percent(section)
        end
      end

      bar.section(:center, separator: ' | ') do |section|
        section.add { "\u{f489} toyoterm" }
      end
    end

    window.bar :bottom, interval: 1.0 do |bar|
      bar.section(:left, separator: " | ") do |section|
        git_branch(section)
        git_diff_count(section)
      end

      bar.section(:right, separator: ' | ') do |section|
        section.add { |ctx| ctx.pane.zoomed? ? "\u{f065} ZOOM" : "\u{f066} NORMAL" }
      end
    end
  end

  config.scrollback_lines = 10_000
  config.leader key: "j", mods: "CTRL", timeout: 1000

  config.behavior do |behavior|
    behavior.allow_osc_notifications = true
  end

  config.keys do
    leader("h").activate_pane(:left)
    leader("j").activate_pane(:down)
    leader("k").activate_pane(:up)
    leader("l").activate_pane(:right)
    leader("m").toggle_maximize
    leader("r").reload_config
    leader("z").toggle_zoom
    ctrl_shift("v").paste_clipboard
    leader('v').run { |ctx| ctx.pane.split(:right, cwd: ctx.pane.cwd)}
    leader('s').run { |ctx| ctx.pane.split(:down, cwd: ctx.pane.cwd)}
    leader('c').run { |ctx| ctx.window.new_tab(cwd: ctx.pane.cwd)}
    leader('CTRL+j').next_tab
    ctrl('-').run { config.font.size -= 1 }
    ctrl('=').run { config.font.size += 1 }
    ctrl('[').run { config.window.opacity -= 0.05 }
    ctrl(']').run { config.window.opacity += 0.05 }
    leader('t').command(:choose_theme)
    (1..9).each do |n|
      leader(n.to_s).run do |ctx|
        tab = ctx.window.tabs[n - 1]
        tab.activate unless tab.nil?
      end
    end

    # visual mode
    leader("[").toggle_visual_mode
    key("v").select_visual_selection
    key("ESCAPE").end_visual_selection
    key("w").move_visual_selection(:word_forward)
    key("b").move_visual_selection(:word_backward)
    key("h").move_visual_selection(:left)
    key("j").move_visual_selection(:down)
    key("k").move_visual_selection(:up)
    key("l").move_visual_selection(:right)
    key("LEFT").move_visual_selection(:left)
    key("RIGHT").move_visual_selection(:right)
    key("UP").move_visual_selection(:up)
    key("DOWN").move_visual_selection(:down)
    key("0").move_visual_selection(:line_start)
    key("$").move_visual_selection(:line_end)
    key("y").yank_selection
  end
end
