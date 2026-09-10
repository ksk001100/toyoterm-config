THEME_NAME = "TokyoNight"

def clock
  result = Toyoterm.spawn("date", "+%Y-%m-%d %H:%M:%S")
  result.success? ? result.stdout.strip : ''
rescue
  ''
end

def battery_percent
  ["BAT0", "BAT1"].each do |name|
    begin
      value = Toyoterm.read_file("/sys/class/power_supply/#{name}/capacity").strip
      icons = [
        "\u{f0079}", "\u{f0079}", "\u{f0082}",
        "\u{f0081}", "\u{f0080}", "\u{f007f}",
        "\u{f007e}", "\u{f007d}", "\u{f007c}",
        "\u{f007b}", "\u{f007a}"
      ]
      icon = icons[(value.to_i / 10.0).round]
      return "#{icon} #{value}%" unless value.empty?
    rescue
      # Desktops and systems with a differently named battery have no battery item.
    end
  end
  ""
end

def git_branch(ctx)
  cwd = ctx.pane.cwd
  return '' if cwd.nil?

  result = Toyoterm.spawn('git', 'branch', '--show-current', cwd: cwd)
  result.success? ? "\u{eC6f} #{result.stdout.strip}" : ''
end

def git_diff_stat(ctx)
  result = Toyoterm.spawn(
    'sh', '-c', 
    '{ git diff HEAD --numstat; git ls-files -o --exclude-standard | xargs wc -l 2>/dev/null | awk \'$2 != "total" && NF==2 {print $1, 0, $2}\'; } | awk \'{add += $1; del += $2} END {printf "+%d/-%d", add, del}\'',
    cwd: ctx.pane.cwd
  )
  result.success? ? "\u{f044} #{result.stdout.strip}" : ''
end

Toyoterm.configure do |config|
  config.theme = THEME_NAME
  config.font do |font|
    font.family = "JetBrainsMono Nerd Font"
    font.fallback = ["Hack Nerd Font"]
    font.size = 12.0
    font.weight = 400
  end

  config.window.opacity = 0.95
  config.scrollback_lines = 10_000
  config.window.decorations = false
  config.window.always_on_top = false
  config.leader key: "j", mods: "CTRL", timeout: 1000

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
    (1..9).each do |n|
      leader(n).run do |ctx|
        tab = ctx.window.tabs[n - 1]
        tab.activate unless tab.nil?
      end
    end
    ctrl('-').run { config.font.size -= 1 }
    ctrl('=').run { config.font.size += 1 }
    ctrl('[').run { config.window.opacity -= 0.05 }
    ctrl(']').run { config.window.opacity += 0.05 }

    # visual mode
    leader("[").toggle_visual_mode
    key("v").select_visual_selection
    key("ESCAPE").end_visual_selection
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

  config.window.bar :top, interval: 1.0 do |bar|
    bar.add(:right) do |ctx|
      parts = []
      parts << "\u{e22b} #{THEME_NAME}"
      parts << "\u{f017} #{clock}"

      battery = battery_percent
      parts << battery unless battery.empty?
      parts.join(" | ") 
    end

    bar.add(:center, "\u{f489} toyoterm")
  end

  config.window.bar :bottom, interval: 1.0 do |bar|
    bar.add(:left) do |ctx|
      parts = []
      branch = git_branch(ctx)
      stat = git_diff_stat(ctx)
      parts << branch unless branch.empty?
      parts << stat unless stat.empty?
      parts.join(' | ')
    end
    bar.add(:right) { |ctx| ctx.pane.zoomed? ? "\u{f065} ZOOM" : "\u{f066} NORMAL" }
  end
end
