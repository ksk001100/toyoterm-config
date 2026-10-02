# toyoterm-config

```bash
git clone https://github.com/ksk001100/toyoterm-config ~/.config/toyoterm
cd ~/.config/toyoterm && echo 'Toyoterm.configure do |config|
  # config.default_shell = "wsl.exe"

  config.theme = "Laser"
  config.scrollback_lines = 10_000

  config.font do |font|
    font.family = "JetBrainsMono Nerd Font"
    font.fallback = ["Hack Nerd Font"].freeze
    font.size = 20.0
  end

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
end' > setting.rb
```
