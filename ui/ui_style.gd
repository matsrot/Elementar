class_name UIStyle
extends RefCounted
## Cores e helpers de estilo compartilhados pela interface (visual do mockup do inventário).

const BG := Color(0.078, 0.122, 0.180)            # fundo azul-marinho
const PANEL := Color(0.106, 0.165, 0.239)         # painéis
const CELL := Color(0.165, 0.216, 0.282)          # células vazias da tabela
const CELL_HOVER := Color(0.227, 0.290, 0.376)
const YELLOW := Color(0.957, 0.784, 0.298)        # destaque (elementos que o jogador tem)
const TEXT := Color(0.910, 0.933, 0.961)
const MUTED := Color(0.624, 0.690, 0.769)
const DARK := Color(0.078, 0.122, 0.180)
const NO_BORDER := Color(0, 0, 0, 0)
const LOCKED_TEXT := Color(0.42, 0.49, 0.59)       # símbolo de elemento ainda não coletado
const UNAVAILABLE := Color(0.118, 0.160, 0.225)    # fundo de elemento que ainda não existe no jogo
const FAINT_TEXT := Color(0.33, 0.40, 0.50)        # símbolo de elemento que ainda não existe no jogo
const YELLOW_LIGHT := Color(1.0, 0.93, 0.62)       # borda dos elementos coletados


static func box(color: Color, border: Color = NO_BORDER, border_w: int = 0, radius: int = 0, margin: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb


## Fonte pixelada opcional: coloque um .ttf em res://assets/fonts/titulo.ttf
static func title_font() -> Font:
	if ResourceLoader.exists("res://assets/fonts/titulo.ttf"):
		return load("res://assets/fonts/titulo.ttf") as Font
	return null


static func style_title(label: Label, size: int = 22) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", TEXT)
	var f := title_font()
	if f != null:
		label.add_theme_font_override("font", f)


static func style_symbol(label: Label, color: Color, size: int = 16) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	var f := title_font()
	if f != null:
		label.add_theme_font_override("font", f)



const USE_SUBSCRIPTS := true   # se o "₂" aparecer como quadradinho, troque por false

## Converte "H2O" em "H₂O".
static func formula(f: String) -> String:
	if not USE_SUBSCRIPTS:
		return f
	var subs := ["₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉"]
	var out := ""
	for ch in f:
		if ch >= "0" and ch <= "9":
			out += subs[int(ch)]
		else:
			out += ch
	return out


static func style_button(b: Button, bg: Color, fg: Color, size: int = 16) -> void:
	for state in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(state, box(bg, NO_BORDER, 0, 3, 10))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, fg)
	b.add_theme_font_size_override("font_size", size)
