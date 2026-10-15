hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "auto",
})

-- Set programs that you use
local home = os.getenv("HOME") or "/home/water"
local terminal = "alacritty"
local fileManager = "thunar"
local menu = "hyprlauncher"

hl.on("hyprland.start", function()
	hl.exec_cmd(home .. "/.local/bin/at_startup")
end)

hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "22")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "22")
hl.env("SHELL", "/usr/bin/zsh")

-- Theme colours, generated into theme.lua by the theme switcher.
local theme = {
	name = "gruvbox",
	label = "Gruvbox Dark",
	active_border = "rgba(7c6f64ff)",
	inactive_border = "rgba(665c54ff)",
	shadow_color = "0xee1a1a1a",
}

do
	local loaded = { pcall(dofile, home .. "/.config/hypr/theme.lua") }
	if loaded[1] and type(loaded[2]) == "table" then
		theme = loaded[2]
	end
end

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 5,

		border_size = 0,

		col = {
			active_border = theme.active_border,
			inactive_border = theme.inactive_border,
		},

		-- Set to true to enable resizing windows by clicking and dragging on borders and gaps
		resize_on_border = false,

		-- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
		allow_tearing = false,

		layout = "dwindle",
	},

	decoration = {
		rounding = 10,
		rounding_power = 2,

		-- Change transparency of focused and unfocused windows
		active_opacity = 1.0,
		inactive_opacity = 1.0,

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = "0x000000ff",
		},

		blur = {
			enabled = true,
			size = 3,
			passes = 1,
			vibrancy = 0.1696,
		},
	},

	animations = {
		enabled = true,
	},
})

hl.curve("quick", { type = "bezier", points = { { 0.2, 0 }, { 0.1, 1 } } })
hl.curve("snap", { type = "bezier", points = { { 0.3, 1 }, { 0.4, 1 } } })
hl.curve("bounce", { type = "bezier", points = { { 0.4, 1.2 }, { 0.6, 1 } } })

hl.curve("emphasizedDecel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("menu_decel", { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })
hl.curve("menu_accel", { type = "bezier", points = { { 0.52, 0.03 }, { 0.72, 0.08 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })

hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "bounce" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.5, bezier = "bounce" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "bounce" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "bounce", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "quick" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 0.25, bezier = "quick" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 0.2, bezier = "quick" })
hl.animation({ leaf = "fade", enabled = true, speed = 0.6, bezier = "quick" })

hl.animation({ leaf = "layers", enabled = false })
hl.animation({ leaf = "layersIn", enabled = false })
hl.animation({ leaf = "layersOut", enabled = false })
hl.animation({ leaf = "fadeLayersIn", enabled = false })
hl.animation({ leaf = "fadeLayersOut", enabled = false })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "bounce", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 4, bezier = "bounce", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3, bezier = "quick", style = "slide" })

hl.animation({ leaf = "zoomFactor", enabled = true, speed = 6, bezier = "quick" })

hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 2.5, bezier = "bounce", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2.5, bezier = "quick", style = "slidevert" })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
	dwindle = {
		preserve_split = true, -- You probably want this
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
	master = {
		new_status = "master",
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
	scrolling = {
		fullscreen_on_one_column = true,
	},
})

hl.config({
	misc = {
		force_default_wallpaper = -1, -- Set to 0 or 1 to disable the anime mascot wallpapers
		disable_hyprland_logo = false, -- If true disables the random hyprland logo / anime girl background. :(

		-- error unreadable exactly when you need to read it.
		splash_font_family = "Iosevka Nerd Font",
	},
})

hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		kb_rules = "",

		follow_mouse = 1,

		sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

		touchpad = {
			natural_scroll = true,
			tap_to_click = true,
			disable_while_typing = true,
			scroll_factor = 1.0,
		},
	},
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})

-- Guarded: this runs on every reload, so an unconditional prepend would add
-- one copy of ~/.local/bin per reload.
local _bin = home .. "/.local/bin"
local _path = os.getenv("PATH") or ""
if _path:sub(1, #_bin) ~= _bin then
	hl.env("PATH", _bin .. ":" .. _path)
end
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("QT_SCALE_FACTOR", "0.90")
-- Krita (and other KDE apps) override qt6ct's [Fonts], so force the family
-- directly for all Qt apps instead.
hl.env("QT_FONT_FAMILY", "Iosevka Nerd Font")
hl.env("EDITOR", "nvim")
hl.env("VISUAL", "nvim")
hl.env("TERMINAL", "alacritty")

-- Cursor theme and size. These have to be in HYPRLAND's own environment, not
-- just an interactive shell's: the compositor reads them when it spawns
-- clients. XCURSOR_SIZE was exported in the shell but never reached the
-- compositor, so the size never actually applied.
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "22")

local mainMod = "SUPER" -- the stock declaration lived in the block replaced above

local stepW = 136 -- 10% of this 1366x768 panel, rounded
local stepH = 76

-- --- launchers; the app launcher is Super+Space, as in niri ---
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))

hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + ALT + E", hl.dsp.exec_cmd("alacritty -e yazi"))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("noctalia msg panel-open launcher"))

-- The Spotify web app, installed as a Firefox PWA.
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("limusic-app"))

-- Noctalia owns the bar and launcher now, so toggle-waybar is gone. The
-- wallpaper switcher survives as a wrapper over Noctalia's own wallpaper IPC
-- (wallpaper-next / wallpaper-random / wallpaper-set), keeping the old folder
-- argument that matuwall used to provide.
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(home .. "/.local/bin/wallpaper-switcher"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("noctalia msg bar-toggle"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd("smile"))
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("scratch"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:scratch" }))

-- https://github.com/samine825/Hypr3D
--
-- hl.plugin is nil when the plugin is not loaded, so this has to be guarded: a
-- config block referencing an absent plugin is a config error.
if hl.plugin.hypr3d then
	local hypr3d = hl.plugin.hypr3d

	hypr3d.config({
		world = {
			grid = true,
		},
		windows = {
			window_scale = 0.25,
			spawn_distance = 2,
		},
		player = {
			-- spawn is the FEET (eyes ride kEyeHeight = 1.62 above), so y = 0
			-- stands on the grid. x = -3 because yaw = atan2(-x, z), which turns
			-- the camera to face the character standing at the origin.
			spawn = { -3, 0, 0 },
			flying = false,
			move_speed = 2.5,
			collision = true,
		},
		scene = {
			-- Positions come from each model's own bounds: feet are at the
			-- accessor min-Y, so every lift below is that value scaled.

			-- Downloaded model. 1.899 m, centred, feet at y = -0.95.
			warrior = {
				mesh = {
					path = home .. "/.local/share/hypr3d/models/warrior/source/model.glb",
					transform = { position = { 0, 0.95, 0 } },
					flat = false,
				},
				collision = true,
				static = true,
			},

			-- CesiumMan, Khronos sample, CC-BY-4.0. Rigged human, 1.138 m
			-- with feet at y = -0.569; scaled 1.5x that lift is 0.854.
			cesiumman = {
				mesh = {
					path = home .. "/.local/share/hypr3d/models/khronos/CesiumMan.glb",
					transform = {
						position = { 0, 0.854, -3 },
						rotation = { 0, 180, 0 },
						scale = { 1.5, 1.5, 1.5 },
					},
					flat = false,
				},
				collision = true,
				static = true,
			},

			-- Fox, Khronos sample, CC0-1.0, so no attribution is owed.
			-- Modelled 79 m tall in a running pose, so scale is 0.012 to bring
			-- it to about 0.95 m; feet at y = -0.122 scale to 0.0015.
			fox = {
				mesh = {
					path = home .. "/.local/share/hypr3d/models/khronos/Fox.glb",
					transform = {
						position = { 0, 0.0015, 3.5 },
						rotation = { 0, 200, 0 },
						scale = { 0.012, 0.012, 0.012 },
					},
					flat = false,
				},
				collision = true,
				static = true,
			},
		},
	})
end

-- --- window management ---
hl.bind(mainMod .. " + Q", hl.dsp.window.close())

hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))

hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
-- --- focus: Left/Right walk columns, Up/Down walk windows inside one ---
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- --- move, as niri's Mod+Ctrl+Arrow ---
hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.move({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.resize({ x = -stepW, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = stepW, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -stepH, relative = true }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = stepH, relative = true }))

-- --- workspaces 1-10, and move the focused window to one ---
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + U", hl.dsp.exec_cmd(home .. "/.local/bin/power-menu"))
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.exec_cmd(home .. "/.local/bin/logout-session"))
hl.bind(mainMod .. " + c", hl.dsp.exec_cmd(home .. "/.local/bin/clipboard-history"))

hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("noctalia msg session lock"))

-- --- drag and resize with the mouse ---
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

local winRegion =
	[==[hyprctl -j activewindow | jq -r 'if .size then "\(.size[0])x\(.size[1])+\(.at[0])+\(.at[1])" else "" end']==]
hl.bind("ALT + Print", hl.dsp.exec_cmd('grim -g "$(echo ' .. winRegion .. ')" - | wl-copy'))
-- Screenshots. Super+P was bound to hypr3d.toggle, which silently did nothing
-- because the plugin isn't installed (and has since left the AUR).
-- hyprshot is a shell script built for Hyprland and copies to the clipboard
-- automatically, unlike flameshot (a 73MB Qt app that needs Ctrl+C pressed).
-- Screenshots: slurp + grim, no daemon (~0 MB idle). Each one lands on the
-- clipboard AND saves to ~/Pictures/Screenshots, then notifies via mako.
-- NOTE: in this Lua API an uppercase letter in a key string means Shift is part
-- of the binding, so these use lowercase "p"/"v".
hl.bind("SUPER + p", hl.dsp.exec_cmd(home .. "/.local/bin/screenshot region"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(home .. "/.local/bin/screenshot full"))
hl.bind("SUPER + v", hl.dsp.exec_cmd(home .. "/.local/bin/screenshot window"))

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightness-step up"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightness-step down"), { repeating = true })

hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd(home .. "/.local/bin/power-mode"))

hl.on("hyprland.start", function()
	hl.exec_cmd("pkill -x dunst 2>/dev/null; true")
	hl.exec_cmd("systemctl --user restart xdg-desktop-portal.service")

	-- Shell. Noctalia replaces waybar (bar), mako (notifications), rofi
	-- (launcher) and matuwall (wallpaper). It is native C++/OpenGL ES rather
	-- than Quickshell, and measures ~250 MB resident here - far below the
	-- 1.3 GB DankMaterialShell needed on this 8 GB machine.
	--
	-- pkill first so a stale instance can't stack a second bar.
	hl.exec_cmd("pkill -x waybar 2>/dev/null; true")
	hl.exec_cmd("pkill -x mako 2>/dev/null; true")
	hl.exec_cmd("pkill -x cava 2>/dev/null; true")
	hl.exec_cmd("pkill -x eww 2>/dev/null; true")
	hl.exec_cmd("pkill -9 -x quickshell 2>/dev/null; true")
	hl.exec_cmd("pkill -x noctalia 2>/dev/null; true")
	hl.exec_cmd("setsid noctalia --daemon >/dev/null 2>&1 &")

	hl.exec_cmd("awww-daemon")
	hl.exec_cmd(
		"sleep 1; awww restore || awww img -- "
			.. home
			.. "/Pictures/Wallpapers/a_river_running_through_a_small_town.jpg"
	)

	-- Clipboard ownership + history. These used to be started from here, but
	-- the referenced script never existed (only clipboard-history does), so the
	-- line failed silently on every login and nothing held the clipboard.
	-- The real services are systemd units and are enabled at boot; starting them
	-- here as well is harmless and makes a fresh login work without a re-login.
	hl.exec_cmd("systemctl --user start cliphist.service cliphist-store.service 2>/dev/null; true")

	-- Session services.
	hl.exec_cmd("nm-applet")
	hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")

	-- EasyEffects audio daemon, started HIDDEN so it only lives in the tray.
	-- EasyEffects 8.3.0 has no --minimized flag; --hide-window is its
	-- equivalent - effects stay applied while the window stays out of the way.
	-- Alacritty used to be started here; removed so no terminal pops open at
	-- login. It still launches on demand from Super+Return etc.
	hl.exec_cmd("pkill -x easyeffects 2>/dev/null; true")
	hl.exec_cmd("sleep 2; easyeffects --hide-window")

	hl.exec_cmd("hypridle")
end)

local suppressMaximizeRule = hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },

	move = "20 monitor_h-120",
	float = true,
})

hl.window_rule({
	name = "planify-special-workspace",
	match = { class = "^(io.github.alainm23.planify)$" },

	workspace = "special:planify",
})

hl.window_rule({
	name = "planify-floating",
	match = { class = "^(io.github.alainm23.planify)$" },

	float = true,
	size = "812 568",
	move = "276 44",
})

hl.window_rule({
	name = "dankcalendar-special-workspace",
	match = { class = "^com[.]danklinux[.]dankcalendar$" },

	workspace = "special:dank",
})

-- No float/size/move rule for Dank Calendar: it tiles like any other window.

hl.window_rule({
	name = "terminal-no-shadow",
	match = { class = "^Alacritty$" },
	no_shadow = true,
})

-- For Noctalia Color templates
require("noctalia").apply_theme()
