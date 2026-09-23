# =============================================================================
# Wallpaper Plugin
# =============================================================================

module WallpaperPlugin
  WALLPAPER_H = "./wallpapers/toyoterm_wallpaper_h.png"
  WALLPAPER_V = "./wallpapers/toyoterm_wallpaper_v.png"
  OPACITY = 0.25
end

Toyoterm.configure do |config|
  config.window do |window|
    window.image do |image|
      image.path = WallpaperPlugin::WALLPAPER_H
      image.opacity = WallpaperPlugin::OPACITY
    end
  end
end

Toyoterm.on :window_resized do |event|
  Toyoterm.configure do |config|
    config.window.image.path = event.width > event.height ? WallpaperPlugin::WALLPAPER_H : WallpaperPlugin::WALLPAPER_V
  end
end
