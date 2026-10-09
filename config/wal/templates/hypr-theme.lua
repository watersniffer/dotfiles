local function strip(s)
	return (s:gsub("#", ""))
end

return {{
	name = "wallpaper",
	label = "Wallpaper",
	active_border   = "rgba(" .. strip("{color4}") .. "ff)",
	inactive_border = "rgba(" .. strip("{color2}") .. "ff)",
	shadow_color = "0x" .. strip("{color0}") .. "dd",
}}
