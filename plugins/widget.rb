# =============================================================================
# Status Bar Widgets Plugin
# =============================================================================

module StatusWidgets
  SEPARATOR = " | "

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

      bar.section(:right, separator: SEPARATOR) do |section|
        theme(section, config)
        clock(section)
        battery(section) if Toyoterm.platform == :linux
      end
    end

    window.bar :bottom do |bar|
      bar.section(:left, separator: SEPARATOR) do |section|
        git_branch(section)
        git_diff_count(section)
      end

      bar.section(:right) do |section|
        zoom_status(section)
      end
    end
  end

  def self.theme(section, config)
    section.add(interval: 5.0) do
      name = config.theme
      name && !name.empty? ? "\u{e22b} #{name}" : ""
    end
  end

  def self.clock(section)
    section.add(interval: 1.0) do
      now = Time.now
      timestamp = sprintf(
        "%04d-%02d-%02d %02d:%02d:%02d",
        now.year, now.month, now.day, now.hour, now.min, now.sec
      )
      "\u{f017} #{timestamp}"
    end
  end

  def self.battery(section)
    return unless Toyoterm.platform == :linux

    section.add(interval: 5.0) do
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
    command = Toyoterm.platform == :windows ? WINDOWS_GIT_DIFF_COMMAND : UNIX_GIT_DIFF_COMMAND

    section.add_async(
      *command,
      interval: 2.0,
      cwd: ->(context) { pane_cwd(context) },
      initial: ""
    ) do |result|
      result.success? ? "\u{f044} #{result.stdout.strip}" : ""
    end
  end

  def self.zoom_status(section)
    section.add(interval: 1.0) do |context|
      begin
        context.pane && context.pane.zoomed? ? "\u{f065} ZOOM" : "\u{f066} NORMAL"
      rescue StandardError
        "\u{f066} NORMAL"
      end
    end
  end

  def self.pane_cwd(context)
    begin
      cwd = context.pane ? context.pane.cwd : nil
      cwd && !cwd.empty? ? cwd : nil
    rescue StandardError
      nil
    end
  end
end

Toyoterm.configure do |config|
  config.window do |window|
    StatusWidgets.configure(window, config)
  end
end
