extends Control

# Bug Crush: 8x8 match-3. Drag a bug onto a neighbour (or tap two
# neighbours) to swap. 3+ in a row or column pop with a bounce, the bugs
# above fall down, new bugs drop in, and matches chain into combos.
# Shuffle button rescues a board with no moves left.

const COLS := 8
const ROWS := 8
const NTYPES := 6
const SCARAB := 6
const SCARAB_EVERY := 5000
const SCARAB_BONUS := 250

var BugScript := preload("res://scripts/bug.gd")

var cell := 80
var origin := Vector2.ZERO
var grid: Array = []
var busy := false
var score := 0
var best := 0
var selected := Vector2i(-1, -1)

var press_active := false
var press_cell := Vector2i(-1, -1)
var press_pos := Vector2.ZERO
var dragged := false

var title_label: Label
var score_label: Label
var best_label: Label
var hint_label: Label
var msg_label: Label
var sel_ring: Control
var shuffle_btn: Button
var email_btn: Button
var x_btn: Button
var rotate_overlay: ColorRect
var rotate_title: Label
var rotate_sub: Label
var game_font: Font
var sfx: AudioStreamPlayer
var current_level := 1
var next_scarab_at := SCARAB_EVERY
var _play_beaconed := false
var banner_label: Label
var title_col := Color(0.65, 0.95, 0.7)
var title_bug_active := false
var title_pulse: Tween
var idle_timer := 0.0
var shimmy_active := false
var shimmy_group: Array = []
var shimmy_origs: Array = []
var shimmy_elapsed := 0.0
const IDLE_AFTER := 3.0
var smash_stream := preload("res://audio/smash.wav")
const THRESHOLDS := [1500, 4000, 7500, 12000]
const THEMES := [
	[Color(0, 0, 0), Color(0.6, 0.82, 0.55), Color(0.78, 0.92, 0.72), Color(0.72, 0.89, 0.66)],
	[Color(0.02, 0.02, 0.14), Color(0.35, 0.55, 0.85), Color(0.55, 0.70, 0.90), Color(0.48, 0.62, 0.82)],
	[Color(0.14, 0.02, 0.14), Color(0.62, 0.42, 0.85), Color(0.76, 0.62, 0.90), Color(0.68, 0.54, 0.82)],
	[Color(0.14, 0.03, 0.02), Color(0.85, 0.45, 0.30), Color(0.90, 0.66, 0.50), Color(0.82, 0.58, 0.42)],
	[Color(0.0, 0.12, 0.12), Color(0.20, 0.75, 0.70), Color(0.50, 0.85, 0.80), Color(0.42, 0.77, 0.72)],
	[Color(0.14, 0.02, 0.06), Color(0.85, 0.30, 0.45), Color(0.92, 0.60, 0.70), Color(0.84, 0.52, 0.62)],
	[Color(0.12, 0.08, 0.0), Color(0.85, 0.65, 0.20), Color(0.95, 0.80, 0.45), Color(0.87, 0.72, 0.38)],
	[Color(0.02, 0.08, 0.14), Color(0.40, 0.70, 0.95), Color(0.65, 0.85, 0.98), Color(0.57, 0.77, 0.90)],
	[Color(0.04, 0.12, 0.02), Color(0.55, 0.85, 0.30), Color(0.75, 0.92, 0.55), Color(0.67, 0.84, 0.47)],
	[Color(0.08, 0.02, 0.16), Color(0.70, 0.50, 1.0), Color(0.82, 0.70, 1.0), Color(0.74, 0.62, 0.92)],
	[Color(0.14, 0.05, 0.03), Color(0.95, 0.55, 0.40), Color(0.98, 0.75, 0.60), Color(0.90, 0.67, 0.52)],
	[Color(0.06, 0.06, 0.08), Color(0.75, 0.75, 0.80), Color(0.88, 0.88, 0.92), Color(0.80, 0.80, 0.84)],
]
var bg_col := Color(0, 0, 0)
var frame_col := Color(0.6, 0.82, 0.55)
var chk_a := Color(0.78, 0.92, 0.72)
var chk_b := Color(0.72, 0.89, 0.66)
var splat3_stream := preload("res://audio/splat3.wav")
var splat4_stream := preload("res://audio/splat4.wav")
var splat5_stream := preload("res://audio/splat5.wav")


class FlyDraw extends Control:
	func _ellipse(cx: float, cy: float, rx: float, ry: float, rot: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in range(28):
			var a := i / 28.0 * TAU
			var x := cos(a) * rx
			var y := sin(a) * ry
			pts.append(Vector2(cx + x * cos(rot) - y * sin(rot), cy + x * sin(rot) + y * cos(rot)))
		draw_colored_polygon(pts, col)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var cx := w / 2.0
		var cy := h / 2.0
		_ellipse(cx - w * 0.28, cy - h * 0.30, w * 0.30, h * 0.16, -0.5, Color(1, 1, 1, 0.45))
		_ellipse(cx + w * 0.28, cy - h * 0.30, w * 0.30, h * 0.16, 0.5, Color(1, 1, 1, 0.45))
		_ellipse(cx, cy, w * 0.30, h * 0.22, 0.0, Color(0.15, 0.15, 0.15))
		draw_circle(Vector2(cx, cy - h * 0.22), h * 0.14, Color(0.1, 0.1, 0.1))
		draw_circle(Vector2(cx - w * 0.07, cy - h * 0.24), h * 0.07, Color(0.9, 0.1, 0.1))
		draw_circle(Vector2(cx + w * 0.07, cy - h * 0.24), h * 0.07, Color(0.9, 0.1, 0.1))
		for sg in [-1, 1]:
			draw_line(Vector2(cx + sg * w * 0.15, cy + h * 0.10), Vector2(cx + sg * w * 0.30, cy + h * 0.38), Color(0.1, 0.1, 0.1), 6.0)
			draw_line(Vector2(cx + sg * w * 0.05, cy + h * 0.16), Vector2(cx + sg * w * 0.10, cy + h * 0.42), Color(0.1, 0.1, 0.1), 6.0)
		draw_line(Vector2(cx - w * 0.04, cy - h * 0.34), Vector2(cx - w * 0.16, cy - h * 0.48), Color(0.1, 0.1, 0.1), 4.0)
		draw_line(Vector2(cx + w * 0.04, cy - h * 0.34), Vector2(cx + w * 0.16, cy - h * 0.48), Color(0.1, 0.1, 0.1), 4.0)


class SelRing extends Control:
	func _draw() -> void:
		draw_arc(size / 2.0, size.x * 0.46, 0, TAU, 40, Color(1, 0.85, 0.1), 6.0)


# Aggregate-only popularity counting: one fire-and-forget beacon per
# event to /bug-crush-track/beacon (same origin, no cookies, no IDs,
# no scores). If the tracker is down the game plays on unaffected.
func _beacon(event: String, level: int = -1, kind: String = "") -> void:
	if not OS.has_feature("web"):
		return
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free())
	var body := {"event": event}
	if level >= 0:
		body["level"] = level
	if kind != "":
		body["kind"] = kind
	if http.request("/bug-crush-track/beacon",
			["Content-Type: application/json"],
			HTTPClient.METHOD_POST, JSON.stringify(body)) != OK:
		http.queue_free()


func _ready() -> void:
	game_font = load("res://fonts/LuckiestGuy-Regular.ttf")
	_init_share_js()
	sfx = AudioStreamPlayer.new()
	add_child(sfx)
	_load_best()
	_layout()
	_build_labels()
	_build_board()
	get_viewport().size_changed.connect(_on_resize)
	var title_timer := Timer.new()
	title_timer.wait_time = 30.0
	title_timer.autostart = true
	title_timer.timeout.connect(_on_title_bug)
	add_child(title_timer)
	_update_orientation()
	_beacon("load")
	queue_redraw()


func _layout() -> void:
	var vs := get_viewport_rect().size
	size = vs
	if vs.x >= vs.y:
		cell = int(max(40, (vs.y - 340) / ROWS))
	else:
		cell = int(min(vs.x * 0.94 / COLS, (vs.y - 400) / ROWS))
		cell = int(max(40, cell))
	var bw := cell * COLS
	origin = Vector2((vs.x - bw) / 2.0, 285 + max(0.0, (vs.y - 285 - cell * ROWS) / 2.0))


func _build_labels() -> void:
	var light := Color(0.95, 0.97, 0.95)
	title_label = _label("BUG CRUSH", Vector2(0, origin.y - 104), 72, title_col)
	title_label.anchor_right = 1.0
	title_label.size = Vector2(size.x, 96)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_constant_override("outline_size", 6)
	title_label.add_theme_color_override("font_outline_color", Color(1, 0.85, 0.1))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	score_label = _label("Score: 0", Vector2(0, origin.y - 176), 54, light)
	score_label.size = Vector2(size.x, 64)
	score_label.anchor_right = 1.0
	score_label.size = Vector2(size.x, 64)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label = _label("Best: %d" % best, Vector2(0, 24), 28, light)
	best_label.anchor_right = 1.0
	best_label.size = Vector2(size.x, 36)
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label = _label("Drag a bug to swap!", Vector2(20, origin.y - 216), 26, Color(0.6, 0.75, 0.65))
	msg_label = _label("", Vector2(20, origin.y - 216), 30, Color(0.95, 0.45, 0.2))
	msg_label.visible = false
	sel_ring = SelRing.new()
	sel_ring.visible = false
	add_child(sel_ring)
	shuffle_btn = Button.new()
	shuffle_btn.text = "Shuffle"
	shuffle_btn.position = Vector2(size.x - 150, 30)
	shuffle_btn.size = Vector2(130, 52)
	if game_font != null:
		shuffle_btn.add_theme_font_override("font", game_font)
		shuffle_btn.add_theme_font_size_override("font_size", 28)
	shuffle_btn.pressed.connect(_on_shuffle)
	add_child(shuffle_btn)
	var share_y := origin.y + cell * ROWS + 24
	var btn_w := int(min(190, (size.x - 48) / 2.0))
	var pair_w := btn_w * 2 + 16
	var x0 := (size.x - pair_w) / 2.0
	email_btn = _share_button("Email Score", Vector2(x0, share_y), btn_w)
	email_btn.pressed.connect(_on_email_share)
	x_btn = _share_button("Post to X", Vector2(x0 + btn_w + 16, share_y), btn_w)
	x_btn.pressed.connect(_on_x_share)
	title_label.pivot_offset = Vector2(size.x / 2.0, 48)
	banner_label = _label("", Vector2(0, origin.y + cell * ROWS / 2 - 40), 64, Color(1, 0.85, 0.1))
	banner_label.anchor_right = 1.0
	banner_label.size = Vector2(size.x, 80)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.add_theme_constant_override("outline_size", 6)
	banner_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	banner_label.visible = false
	rotate_overlay = ColorRect.new()
	rotate_overlay.color = Color(0, 0, 0)
	title_label.pivot_offset = Vector2(size.x / 2.0, 48)
	banner_label.position = Vector2(0, origin.y + cell * ROWS / 2 - 40)
	banner_label.size = Vector2(size.x, 80)
	rotate_overlay.size = size
	add_child(rotate_overlay)
	rotate_title = _label("ROTATE YOUR PHONE", Vector2(0, size.y / 2 - 60), 44, light)
	rotate_title.anchor_right = 1.0
	rotate_title.size = Vector2(size.x, 56)
	rotate_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotate_sub = _label("Bug Crush plays in portrait", Vector2(0, size.y / 2 + 10), 28, Color(0.6, 0.75, 0.65))
	rotate_sub.anchor_right = 1.0
	rotate_sub.size = Vector2(size.x, 36)
	rotate_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _share_button(text: String, pos: Vector2, w: int) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(w, 56)
	if game_font != null:
		b.add_theme_font_override("font", game_font)
		b.add_theme_font_size_override("font_size", 26)
	add_child(b)
	return b


func _init_share_js() -> void:
	if not OS.has_feature("web"):
		return
	var js := """
window.__bugcrush_share = async function(b64, name, text) {
  try {
    var bin = atob(b64);
    var arr = new Uint8Array(bin.length);
    for (var i = 0; i < bin.length; i++) arr[i] = bin.charCodeAt(i);
    var file = new File([arr], name, {type: 'image/png'});
    if (navigator.canShare && navigator.canShare({files: [file]})) {
      await navigator.share({files: [file], title: 'Bug Crush', text: text});
      return;
    }
  } catch (e) {}
  var a = document.createElement('a');
  a.href = 'data:image/png;base64,' + b64;
  a.download = name;
  document.body.appendChild(a);
  a.click();
  a.remove();
  window.open('https://twitter.com/intent/tweet?text=' + encodeURIComponent(text), '_blank');
};
"""
	JavaScriptBridge.eval(js)


func _score_text() -> String:
	return "I scored %d in Bug Crush! Can you beat it? Play here: https://ucii.sportgen-ai.com/bug-crush/" % score


func _on_email_share() -> void:
	if not OS.has_feature("web"):
		return
	var subject := "My Bug Crush score!".uri_encode()
	var body := ("I scored %d in Bug Crush (best: %d)! Can you beat it? Play here: https://ucii.sportgen-ai.com/bug-crush/" % [score, best]).uri_encode()
	JavaScriptBridge.eval("window.location.href = 'mailto:?subject=%s&body=%s';" % [subject, body])
	_beacon("share", -1, "email")


func _on_x_share() -> void:
	if not OS.has_feature("web"):
		return
	var img := get_viewport().get_texture().get_image()
	var b64 := Marshalls.raw_to_base64(img.save_png_to_buffer())
	var text := _score_text()
	JavaScriptBridge.eval("window.__bugcrush_share('%s', 'bug-crush-score.png', `%s`);" % [b64, text])
	_beacon("share", -1, "x")


func _update_orientation() -> void:
	var landscape := size.x > size.y
	rotate_overlay.visible = landscape
	rotate_title.visible = landscape
	rotate_sub.visible = landscape


func _on_resize() -> void:
	_layout()
	title_label.position = Vector2(0, origin.y - 104)
	score_label.position = Vector2(0, origin.y - 176)
	best_label.position = Vector2(0, 24)
	hint_label.position = Vector2(20, origin.y - 216)
	msg_label.position = Vector2(20, origin.y - 216)
	shuffle_btn.position = Vector2(size.x - 150, 30)
	var share_y := origin.y + cell * ROWS + 24
	var btn_w := int(min(190, (size.x - 48) / 2.0))
	var pair_w := btn_w * 2 + 16
	var x0 := (size.x - pair_w) / 2.0
	email_btn.position = Vector2(x0, share_y)
	x_btn.position = Vector2(x0 + btn_w + 16, share_y)
	for r in ROWS:
		for c in COLS:
			var bug = grid[r][c]
			if bug != null:
				bug.size = Vector2(cell, cell)
				bug.pivot_offset = bug.size / 2.0
				bug.position = _cell_pos(r, c)
	if selected.x >= 0:
		sel_ring.size = Vector2(cell, cell)
		sel_ring.position = _cell_pos(selected.y, selected.x)
	title_label.pivot_offset = Vector2(size.x / 2.0, 48)
	banner_label.position = Vector2(0, origin.y + cell * ROWS / 2 - 40)
	banner_label.size = Vector2(size.x, 80)
	rotate_overlay.size = size
	rotate_title.position = Vector2(0, size.y / 2 - 60)
	rotate_title.size = Vector2(size.x, 56)
	rotate_sub.position = Vector2(0, size.y / 2 + 10)
	rotate_sub.size = Vector2(size.x, 36)
	_update_orientation()
	queue_redraw()


func _label(text: String, pos: Vector2, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	if game_font != null:
		l.add_theme_font_override("font", game_font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	add_child(l)
	return l


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), bg_col)
	var pad := 10.0
	draw_rect(Rect2(origin - Vector2(pad, pad), Vector2(cell * COLS + pad * 2, cell * ROWS + pad * 2)), frame_col)
	for r in ROWS:
		for c in COLS:
			var col := chk_a if (r + c) % 2 == 0 else chk_b
			draw_rect(Rect2(origin + Vector2(c * cell, r * cell), Vector2(cell, cell)), col)


func _build_board() -> void:
	grid = []
	for r in ROWS:
		var row: Array = []
		for c in COLS:
			var t := _pick_type(r, c, row)
			var bug := _make_bug(t, r, c)
			row.append(bug)
		grid.append(row)


func _pick_type(r: int, c: int, row: Array) -> int:
	for _i in range(50):
		var t := randi() % NTYPES
		if c >= 2 and row[c - 1].bug_type == t and row[c - 2].bug_type == t:
			continue
		if r >= 2 and grid[r - 1][c].bug_type == t and grid[r - 2][c].bug_type == t:
			continue
		return t
	return randi() % NTYPES


func _make_bug(t: int, r: int, c: int) -> Control:
	var bug := Control.new()
	bug.set_script(BugScript)
	bug.bug_type = t
	bug.size = Vector2(cell, cell)
	bug.pivot_offset = bug.size / 2.0
	bug.position = _cell_pos(r, c)
	add_child(bug)
	return bug


func _cell_pos(r: int, c: int) -> Vector2:
	return origin + Vector2(c * cell, r * cell)


func _cell_at(pos: Vector2) -> Vector2i:
	var c := int((pos.x - origin.x) / cell)
	var r := int((pos.y - origin.y) / cell)
	if c < 0 or c >= COLS or r < 0 or r >= ROWS:
		return Vector2i(-1, -1)
	return Vector2i(c, r)


func _process(delta: float) -> void:
	if shimmy_active:
		_shimmy_step(delta)
		return
	if busy or size.x > size.y:
		return
	idle_timer += delta
	if idle_timer >= IDLE_AFTER:
		_start_shimmy()


func _input(event: InputEvent) -> void:
	var is_press: bool = (event is InputEventScreenTouch and event.pressed) or event is InputEventScreenDrag or (event is InputEventMouseButton and event.pressed)
	if is_press:
		_stop_shimmy()
		idle_timer = 0.0
	if event is InputEventScreenTouch:
		if event.pressed:
			_press(event.position)
		else:
			_release(event.position)
	elif event is InputEventScreenDrag:
		_drag(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(event.position)
		else:
			_release(event.position)
	elif event is InputEventMouseMotion:
		_drag(event.position)


func _press(pos: Vector2) -> void:
	if size.x > size.y:
		return
	if busy or press_active:
		return
	press_active = true
	press_cell = _cell_at(pos)
	press_pos = pos
	dragged = false


func _drag(pos: Vector2) -> void:
	if not press_active or busy or dragged:
		return
	if press_cell.x < 0:
		return
	if pos.distance_to(press_pos) < cell * 0.35:
		return
	var d := pos - press_pos
	var dir := Vector2i(int(sign(d.x)), 0) if abs(d.x) > abs(d.y) else Vector2i(0, int(sign(d.y)))
	var target := press_cell + dir
	if target.x < 0 or target.x >= COLS or target.y < 0 or target.y >= ROWS:
		return
	if grid[press_cell.y][press_cell.x] != null and grid[press_cell.y][press_cell.x].bug_type == SCARAB:
		dragged = true
		press_active = false
		_deselect()
		_detonate(press_cell)
		return
	dragged = true
	press_active = false
	_do_swap(press_cell, target)


func _release(_pos: Vector2) -> void:
	if not press_active:
		return
	press_active = false
	if dragged or press_cell.x < 0:
		return
	_tap(press_cell)


func _tap(cell_pos: Vector2i) -> void:
	if busy:
		return
	if grid[cell_pos.y][cell_pos.x] == null:
		return
	if grid[cell_pos.y][cell_pos.x].bug_type == SCARAB:
		_deselect()
		_detonate(cell_pos)
		return
	if selected.x < 0:
		_select(cell_pos)
	elif selected == cell_pos:
		_deselect()
	elif abs(selected.x - cell_pos.x) + abs(selected.y - cell_pos.y) == 1:
		var a := selected
		_deselect()
		_do_swap(a, cell_pos)
	else:
		_select(cell_pos)


func _select(cell_pos: Vector2i) -> void:
	selected = cell_pos
	sel_ring.size = Vector2(cell, cell)
	sel_ring.position = _cell_pos(cell_pos.y, cell_pos.x)
	sel_ring.visible = true


func _deselect() -> void:
	selected = Vector2i(-1, -1)
	sel_ring.visible = false


func _swap_grid(a: Vector2i, b: Vector2i) -> void:
	var tmp = grid[a.y][a.x]
	grid[a.y][a.x] = grid[b.y][b.x]
	grid[b.y][b.x] = tmp


func _tween_pos(bug: Control, to: Vector2, dur: float) -> Tween:
	var tw := create_tween()
	tw.tween_property(bug, "position", to, dur)
	return tw


func _do_swap(a: Vector2i, b: Vector2i) -> void:
	busy = true
	if grid[a.y][a.x] == null or grid[b.y][b.x] == null:
		busy = false
		return
	hint_label.visible = false
	_swap_grid(a, b)
	var bug_a = grid[a.y][a.x]
	var bug_b = grid[b.y][b.x]
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(bug_a, "position", _cell_pos(a.y, a.x), 0.16)
	tw.tween_property(bug_b, "position", _cell_pos(b.y, b.x), 0.16)
	await tw.finished
	if _find_matches().is_empty():
		_swap_grid(a, b)
		var tw2 := create_tween()
		tw2.set_parallel(true)
		tw2.tween_property(grid[a.y][a.x], "position", _cell_pos(a.y, a.x), 0.16)
		tw2.tween_property(grid[b.y][b.x], "position", _cell_pos(b.y, b.x), 0.16)
		await tw2.finished
		busy = false
		return
	if not _play_beaconed:
		_play_beaconed = true
		_beacon("play")
	await _resolve()


func _resolve() -> void:
	var combo := 0
	while true:
		var matches := _find_matches()
		if matches.is_empty():
			break
		combo += 1
		var points := matches.size() * 10 * combo
		score += points
		score_label.text = "Score: %d" % score
		if score > best:
			best = score
			best_label.text = "Best: %d" % best
			_save_best()
		if combo > 1:
			_show_msg("COMBO x%d! +%d" % [combo, points])
		else:
			_show_msg("+%d" % points)
		var mr := _max_run()
		if mr >= 5:
			sfx.stream = splat5_stream
		elif mr == 4:
			sfx.stream = splat4_stream
		else:
			sfx.stream = splat3_stream
		sfx.play()
		await _pop(matches)
		await _gravity()
		var nl := _level_for_score(score)
		if nl > current_level:
			current_level = nl
			_beacon("level", nl)
			await _celebrate_level(nl)
	while score >= next_scarab_at:
		_spawn_scarab()
		next_scarab_at += SCARAB_EVERY
	msg_label.visible = false
	busy = false


func _show_msg(text: String) -> void:
	msg_label.text = text
	msg_label.visible = true
	msg_label.position = Vector2(20, origin.y - 216)


func _find_matches() -> Array:
	var matched := {}
	for r in ROWS:
		var c := 0
		while c < COLS:
			var bug = grid[r][c]
			if bug == null or bug.bug_type == SCARAB:
				c += 1
				continue
			var t: int = bug.bug_type
			var start := c
			while c < COLS and grid[r][c] != null and grid[r][c].bug_type == t:
				c += 1
			if c - start >= 3:
				for k in range(start, c):
					matched[Vector2i(k, r)] = true
	for c in COLS:
		var r := 0
		while r < ROWS:
			var bug = grid[r][c]
			if bug == null or bug.bug_type == SCARAB:
				r += 1
				continue
			var t: int = bug.bug_type
			var start := r
			while r < ROWS and grid[r][c] != null and grid[r][c].bug_type == t:
				r += 1
			if r - start >= 3:
				for k in range(start, r):
					matched[Vector2i(c, k)] = true
	return matched.keys()


func _max_run() -> int:
	var best_run := 0
	for r in ROWS:
		var run := 0
		var prev := -1
		for c in COLS:
			var bug = grid[r][c]
			if bug != null and bug.bug_type == SCARAB:
				run = 0
				prev = -1
			elif bug != null and bug.bug_type == prev:
				run += 1
			elif bug != null:
				run = 1
				prev = bug.bug_type
			else:
				run = 0
				prev = -1
			best_run = max(best_run, run)
	for c in COLS:
		var run := 0
		var prev := -1
		for r in ROWS:
			var bug = grid[r][c]
			if bug != null and bug.bug_type == SCARAB:
				run = 0
				prev = -1
			elif bug != null and bug.bug_type == prev:
				run += 1
			elif bug != null:
				run = 1
				prev = bug.bug_type
			else:
				run = 0
				prev = -1
			best_run = max(best_run, run)
	return best_run


func _level_for_score(s: int) -> int:
	if s < 15000:
		var lvl := 1
		for t in THRESHOLDS:
			if s >= t:
				lvl += 1
		return lvl
	return 6 + (s - 15000) / 2500


func _apply_theme(lvl: int) -> void:
	var th: Array = THEMES[(lvl - 1) % THEMES.size()]
	bg_col = th[0]
	frame_col = th[1]
	chk_a = th[2]
	chk_b = th[3]
	queue_redraw()


func _celebrate_level(lvl: int) -> void:
	var fly := FlyDraw.new()
	fly.size = Vector2(cell * 4, cell * 3)
	fly.position = Vector2(size.x + 60, -fly.size.y)
	add_child(fly)
	var target := origin + Vector2(cell * COLS / 2.0, cell * ROWS / 2.0) - fly.size / 2.0
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(fly, "position", target, 0.6)
	await tw.finished
	sfx.stream = smash_stream
	sfx.play()
	_apply_theme(lvl)
	banner_label.text = "LEVEL %d!" % lvl
	banner_label.move_to_front()
	banner_label.visible = true
	var shk := create_tween()
	shk.tween_property(self, "position", Vector2(12, -8), 0.05)
	shk.tween_property(self, "position", Vector2(-10, 6), 0.05)
	shk.tween_property(self, "position", Vector2(8, -4), 0.05)
	shk.tween_property(self, "position", Vector2.ZERO, 0.05)
	await shk.finished
	await get_tree().create_timer(0.7).timeout
	banner_label.visible = false
	var tw2 := create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(fly, "position", Vector2(-fly.size.x - 60, size.y + 60), 0.5)
	tw2.tween_property(fly, "modulate", Color(1, 1, 1, 0), 0.5)
	await tw2.finished
	fly.queue_free()


func _spawn_scarab() -> void:
	_stop_shimmy()
	var cells: Array = []
	for r in ROWS:
		for c in COLS:
			var b = grid[r][c]
			if b != null and b.bug_type != SCARAB:
				cells.append(Vector2i(c, r))
	if cells.is_empty():
		return
	var cell_pos: Vector2i = cells[randi() % cells.size()]
	var old = grid[cell_pos.y][cell_pos.x]
	old.queue_free()
	var bug := _make_bug(SCARAB, cell_pos.y, cell_pos.x)
	grid[cell_pos.y][cell_pos.x] = bug
	bug.scale = Vector2(0.2, 0.2)
	var tw := create_tween()
	tw.tween_property(bug, "scale", Vector2(1.15, 1.15), 0.18)
	tw.tween_property(bug, "scale", Vector2(1, 1), 0.15)
	_show_msg("GOLDEN SCARAB! Tap it to detonate!")


func _detonate(cell_pos: Vector2i) -> void:
	if busy:
		return
	busy = true
	_deselect()
	_stop_shimmy()
	var cells: Array = []
	for r in range(max(0, cell_pos.y - 2), min(ROWS, cell_pos.y + 3)):
		for c in range(max(0, cell_pos.x - 2), min(COLS, cell_pos.x + 3)):
			if grid[r][c] != null:
				cells.append(Vector2i(c, r))
	var gained := cells.size() * 10 + SCARAB_BONUS
	score += gained
	score_label.text = "Score: %d" % score
	if score > best:
		best = score
		best_label.text = "Best: %d" % best
		_save_best()
	sfx.stream = smash_stream
	sfx.play()
	var shk := create_tween()
	shk.tween_property(self, "position", Vector2(14, -10), 0.05)
	shk.tween_property(self, "position", Vector2(-12, 8), 0.05)
	shk.tween_property(self, "position", Vector2(10, -6), 0.05)
	shk.tween_property(self, "position", Vector2.ZERO, 0.05)
	_show_msg("SCARAB BOOM! +%d" % gained)
	_beacon("bomb")
	await _pop(cells)
	await _gravity()
	await _resolve()
	busy = false


func _start_shimmy() -> void:
	idle_timer = 0.0
	var types: Array = []
	for r in ROWS:
		for c in COLS:
			var b = grid[r][c]
			if b != null and b.bug_type not in types:
				types.append(b.bug_type)
	if types.is_empty():
		return
	var t: int = types[randi() % types.size()]
	shimmy_group = []
	shimmy_origs = []
	for r in ROWS:
		for c in COLS:
			var b = grid[r][c]
			if b != null and b.bug_type == t:
				shimmy_group.append(b)
				shimmy_origs.append(b.position)
	if shimmy_group.is_empty():
		return
	shimmy_active = true
	shimmy_elapsed = 0.0


func _shimmy_step(delta: float) -> void:
	shimmy_elapsed += delta
	var s := sin(shimmy_elapsed * 55.0)
	for i in shimmy_group.size():
		var b = shimmy_group[i]
		b.rotation = s * 0.35
		b.position.x = shimmy_origs[i].x + s * 7.0
	if shimmy_elapsed >= 1.2:
		_stop_shimmy()
		idle_timer = 0.0


func _stop_shimmy() -> void:
	if shimmy_active:
		for i in shimmy_group.size():
			shimmy_group[i].rotation = 0.0
			shimmy_group[i].position = shimmy_origs[i]
		shimmy_group = []
		shimmy_origs = []
		shimmy_active = false
		shimmy_elapsed = 0.0


func _on_title_bug() -> void:
	if busy or title_bug_active or size.x > size.y:
		return
	title_bug_active = true
	title_label.add_theme_color_override("font_color", Color(0.8, 0.3, 1.0))
	title_label.add_theme_color_override("font_outline_color", Color(1, 1, 1))
	title_pulse = create_tween()
	title_pulse.set_loops()
	title_pulse.tween_property(title_label, "scale", Vector2(1.06, 1.06), 0.25)
	title_pulse.tween_property(title_label, "scale", Vector2(1, 1), 0.25)
	var bug := Control.new()
	bug.set_script(BugScript)
	bug.bug_type = randi() % NTYPES
	var bs := cell * 1.2
	bug.size = Vector2(bs, bs)
	bug.pivot_offset = bug.size / 2.0
	var from_left := randi() % 2 == 0
	var start_x := -bs if from_left else size.x + bs
	bug.position = Vector2(start_x, -bs)
	add_child(bug)
	bug.move_to_front()
	var target := Vector2(size.x / 2.0 - bs / 2.0, title_label.position.y + 48 - bs / 2.0)
	var wig := create_tween()
	wig.set_loops()
	wig.tween_property(bug, "rotation", -0.25, 0.18)
	wig.tween_property(bug, "rotation", 0.25, 0.18)
	var tw := create_tween()
	tw.tween_property(bug, "position", target, 2.4)
	await tw.finished
	wig.kill()
	bug.rotation = 0
	sfx.stream = splat3_stream
	sfx.play()
	var ex := create_tween()
	ex.set_parallel(true)
	ex.tween_property(bug, "scale", Vector2(1.8, 1.8), 0.25)
	ex.tween_property(bug, "modulate", Color(1, 1, 1, 0), 0.25)
	ex.tween_property(title_label, "scale", Vector2(1.12, 1.12), 0.12)
	await ex.finished
	bug.queue_free()
	if title_pulse != null and title_pulse.is_valid():
		title_pulse.kill()
	title_label.scale = Vector2(1, 1)
	title_label.add_theme_color_override("font_color", title_col)
	title_label.add_theme_color_override("font_outline_color", Color(1, 0.85, 0.1))
	title_bug_active = false


func _pop(cells: Array) -> void:
	var popped: Array = []
	var tw := create_tween()
	tw.set_parallel(true)
	for key in cells:
		var bug = grid[key.y][key.x]
		if bug == null:
			continue
		grid[key.y][key.x] = null
		popped.append(bug)
		tw.tween_property(bug, "scale", Vector2(1.4, 1.4), 0.12)
		tw.tween_property(bug, "scale", Vector2.ZERO, 0.18).set_delay(0.12)
		tw.tween_property(bug, "modulate", Color(1, 1, 1, 0), 0.18).set_delay(0.12)
	await tw.finished
	for bug in popped:
		bug.queue_free()


func _gravity() -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	for c in COLS:
		var write := ROWS - 1
		for r in range(ROWS - 1, -1, -1):
			var bug = grid[r][c]
			if bug == null:
				continue
			if r != write:
				grid[write][c] = bug
				grid[r][c] = null
				tw.tween_property(bug, "position", _cell_pos(write, c), 0.22)
			write -= 1
		for r in range(write, -1, -1):
			var t := randi() % NTYPES
			var bug := _make_bug(t, r, c)
			grid[r][c] = bug
			bug.position = origin + Vector2(c * cell, (r - write - 1) * cell - cell)
			tw.tween_property(bug, "position", _cell_pos(r, c), 0.28)
	await tw.finished


func _on_shuffle() -> void:
	if busy:
		return
	for r in ROWS:
		for c in COLS:
			if grid[r][c] == null:
				return
	busy = true
	hint_label.visible = false
	_deselect()
	var types: Array = []
	for r in ROWS:
		for c in COLS:
			types.append(grid[r][c].bug_type)
	types.shuffle()
	var i := 0
	for r in ROWS:
		for c in COLS:
			grid[r][c].bug_type = types[i]
			grid[r][c].queue_redraw()
			i += 1
	await _resolve()


func _load_best() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://bugcrush.cfg") == OK:
		best = int(cfg.get_value("game", "best", 0))


func _save_best() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "best", best)
	cfg.save("user://bugcrush.cfg")
