# =============================================================================
# Keybindings Plugin
# =============================================================================

module KeybindConfig
  FONT_SIZE_RANGE = (6.0..48.0)
  OPACITY_RANGE = (0.1..1.0)
end

Toyoterm.configure do |config|
  config.keys do
    # -------------------------------------------------------------------------
    # Pane navigation and layout
    # -------------------------------------------------------------------------
    { "h" => :left, "j" => :down, "k" => :up, "l" => :right }.each do |key, direction|
      leader(key).activate_pane(direction)
    end
    leader("v").run { |context| context.pane.split(:right, cwd: context.pane.cwd) }
    leader("s").run { |context| context.pane.split(:down, cwd: context.pane.cwd) }
    leader("z").toggle_zoom
    leader("m").toggle_maximize

    # -------------------------------------------------------------------------
    # Tabs
    # -------------------------------------------------------------------------
    leader("c").run { |context| context.window.new_tab(cwd: context.pane.cwd) }
    leader("CTRL+j").next_tab
    (1..9).each do |number|
      leader(number.to_s).run do |context|
        tab = context.window.tabs[number - 1]
        tab.activate if tab
      end
    end

    # -------------------------------------------------------------------------
    # Configuration and Features
    # -------------------------------------------------------------------------
    leader("r").reload_config
    leader("t").command(:choose_theme)
    leader("b").command(:select_branch)

    # -------------------------------------------------------------------------
    # Font size & Opacity adjustments
    # -------------------------------------------------------------------------
    ctrl("-").run do
      config.font.size = [config.font.size - 1.0, KeybindConfig::FONT_SIZE_RANGE.begin].max
    end
    ctrl("=").run do
      config.font.size = [config.font.size + 1.0, KeybindConfig::FONT_SIZE_RANGE.end].min
    end
    ctrl("[").run do
      config.window.opacity = [config.window.opacity - 0.05, KeybindConfig::OPACITY_RANGE.begin].max
    end
    ctrl("]").run do
      config.window.opacity = [config.window.opacity + 0.05, KeybindConfig::OPACITY_RANGE.end].min
    end

    # -------------------------------------------------------------------------
    # Clipboard
    # -------------------------------------------------------------------------
    case Toyoterm.platform
    when :macos
      primary("v").paste_clipboard
    when :windows
      ctrl("v").paste_clipboard
    when :linux
      ctrl_shift("v").paste_clipboard
    end

    # -------------------------------------------------------------------------
    # Vim-like visual selection (inactive outside visual mode)
    # -------------------------------------------------------------------------
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
    }.each do |key_name, direction|
      key(key_name).move_visual_selection(direction)
    end
  end
end
