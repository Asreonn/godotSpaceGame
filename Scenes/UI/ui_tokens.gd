class_name UITokens
extends Node

# Renkler
const COLOR_TEXT_PRIMARY := Color(0.9, 0.95, 1)
const COLOR_TEXT_MUTED := Color(0.6, 0.72, 0.85)
const COLOR_TEXT_SOFT := Color(0.8, 0.9, 1, 0.9)
const COLOR_PANEL_BG := Color(0.05, 0.08, 0.12, 0.88)
const COLOR_PANEL_BORDER := Color(0.3, 0.7, 0.9, 0.7)
const COLOR_SPLIT_BG := Color(0.08, 0.12, 0.18, 0.9)
const COLOR_SPLIT_FILL := Color(0.25, 0.7, 0.9, 0.85)
const COLOR_HOVER := Color(1.08, 1.08, 1.1, 1.0)
const COLOR_NORMAL := Color(1, 1, 1, 1)

# Boyutlar
const SPLIT_BAR_WIDTH := 160.0
const SPLIT_BAR_HEIGHT := 6.0
const CARRY_PREVIEW_CORNER := 4
const CARRY_PREVIEW_FONT_SIZE := 12

static func format_int(value: int) -> String:
	var sign := ""
	var v := value
	if v < 0:
		sign = "-"
		v = -v
	var s := str(v)
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s.substr(i, 1) + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return sign + out
