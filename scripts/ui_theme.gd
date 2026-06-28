class_name UiTheme
extends RefCounted

## Estilo visual compartilhado da UI (botões e painéis) no clima Kingdom Rush:
## cantos arredondados, borda dourada e leve sombra. Usado por HUD/menu/barras.

const GOLD := Color(0.86, 0.70, 0.34)


static func _box(bg: Color, border: Color, radius: int = 8, bw: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(bw)
	sb.border_color = border
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb


## Aplica o visual de botão (normal/hover/pressed/disabled) num Button existente.
static func style_button(b: Button) -> void:
	b.add_theme_stylebox_override("normal", _box(Color(0.16, 0.13, 0.20, 0.95), GOLD))
	b.add_theme_stylebox_override("hover", _box(Color(0.24, 0.20, 0.30, 0.98), Color(1, 0.86, 0.45)))
	b.add_theme_stylebox_override("pressed", _box(Color(0.10, 0.08, 0.14, 1.0), GOLD))
	b.add_theme_stylebox_override("disabled", _box(Color(0.12, 0.12, 0.14, 0.7), Color(0.4, 0.4, 0.4)))
	b.add_theme_color_override("font_color", Color(0.96, 0.93, 0.84))
	b.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.58))


## Painel escuro com borda dourada (para HUDs/tooltips).
static func panel_box(alpha: float = 0.82) -> StyleBoxFlat:
	var sb := _box(Color(0.08, 0.09, 0.13, alpha), GOLD, 12, 3)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 6
	return sb
