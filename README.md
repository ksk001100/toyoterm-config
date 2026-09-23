# toyoterm-config

```bash
git clone https://github.com/ksk001100/toyoterm-config ~/.config/toyoterm
cd ~/.config/toyoterm && echo 'Toyoterm.configure do |config|
  config.font do |font|
    font.family = "JetBrainsMono Nerd Font"
    font.fallback = ["Hack Nerd Font"].freeze
    font.size = 12.0
  end

  config.window do |window|
    window.opacity = 0.95
    window.decorations = true
    window.always_on_top = false
  end
end' > setting.rb
```
