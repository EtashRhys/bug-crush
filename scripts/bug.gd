extends Control

# One cartoon bug, drawn entirely in code (no image files needed).
# bug_type: 0 ladybug, 1 bee, 2 ant, 3 caterpillar, 4 butterfly, 5 spider.

var bug_type: int = 0


func _draw() -> void:
	var c := size / 2.0
	var r := size.x * 0.36
	match bug_type:
		0:
			_draw_ladybug(c, r)
		1:
			_draw_bee(c, r)
		2:
			_draw_ant(c, r)
		3:
			_draw_caterpillar(c, r)
		4:
			_draw_butterfly(c, r)
		5:
			_draw_spider(c, r)


func _eye(pos: Vector2, r: float) -> void:
	draw_circle(pos, r, Color.WHITE)
	draw_circle(pos + Vector2(r * 0.3, 0), r * 0.5, Color.BLACK)


func _ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(24):
		var a := i / 24.0 * TAU
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)


func _draw_ladybug(c: Vector2, r: float) -> void:
	draw_circle(c, r, Color(0.9, 0.15, 0.15))
	draw_circle(c + Vector2(0, -r * 0.75), r * 0.5, Color(0.1, 0.1, 0.1))
	for d in [Vector2(-0.45, -0.3), Vector2(0.45, -0.3), Vector2(-0.5, 0.35), Vector2(0.5, 0.35), Vector2(0, 0.05)]:
		draw_circle(c + d * r, r * 0.16, Color(0.1, 0.1, 0.1))
	_eye(c + Vector2(-r * 0.2, -r * 0.85), r * 0.14)
	_eye(c + Vector2(r * 0.2, -r * 0.85), r * 0.14)


func _draw_bee(c: Vector2, r: float) -> void:
	draw_circle(c, r, Color(1.0, 0.8, 0.1))
	_ellipse(c + Vector2(-r * 0.7, -r * 0.7), r * 0.45, r * 0.3, Color(1, 1, 1, 0.85))
	_ellipse(c + Vector2(r * 0.7, -r * 0.7), r * 0.45, r * 0.3, Color(1, 1, 1, 0.85))
	for dx in [-0.5, 0.0, 0.5]:
		var x: float = dx * r
		var h := sqrt(max(0.0, r * r - x * x))
		draw_line(c + Vector2(x, -h), c + Vector2(x, h), Color(0.1, 0.1, 0.1), r * 0.28)
	_eye(c + Vector2(-r * 0.3, -r * 0.55), r * 0.14)
	_eye(c + Vector2(r * 0.3, -r * 0.55), r * 0.14)


func _draw_ant(c: Vector2, r: float) -> void:
	var dark := Color(0.15, 0.1, 0.08)
	draw_line(c + Vector2(-0.2, 0), c + Vector2(-0.4, r), dark, r * 0.12)
	draw_line(c + Vector2(0.3, 0), c + Vector2(0.5, r), dark, r * 0.12)
	draw_line(c + Vector2(-0.2, 0), c + Vector2(-0.4, -r), dark, r * 0.12)
	draw_line(c + Vector2(0.3, 0), c + Vector2(0.5, -r), dark, r * 0.12)
	draw_circle(c + Vector2(-r * 0.55, 0), r * 0.55, dark)
	draw_circle(c, r * 0.42, dark)
	draw_circle(c + Vector2(r * 0.6, 0), r * 0.5, dark)
	draw_line(c + Vector2(r * 0.7, -r * 0.3), c + Vector2(r * 1.1, -r * 0.9), dark, r * 0.1)
	draw_line(c + Vector2(r * 0.7, -r * 0.3), c + Vector2(r * 1.2, -r * 0.5), dark, r * 0.1)
	_eye(c + Vector2(r * 0.7, -r * 0.15), r * 0.14)


func _draw_caterpillar(c: Vector2, r: float) -> void:
	var greens := [Color(0.3, 0.8, 0.3), Color(0.25, 0.7, 0.25)]
	for i in range(4):
		var x := (-1.05 + i * 0.7) * r
		draw_circle(c + Vector2(x, 0), r * 0.36, greens[i % 2])
	draw_circle(c + Vector2(1.05 * r, 0), r * 0.36, Color(0.2, 0.6, 0.2))
	_eye(c + Vector2(1.05 * r - r * 0.12, -r * 0.15), r * 0.12)
	_eye(c + Vector2(1.05 * r + r * 0.12, -r * 0.15), r * 0.12)


func _draw_butterfly(c: Vector2, r: float) -> void:
	_ellipse(c + Vector2(-r * 0.6, -r * 0.1), r * 0.7, r * 0.5, Color(0.95, 0.5, 0.75))
	_ellipse(c + Vector2(r * 0.6, -r * 0.1), r * 0.7, r * 0.5, Color(0.95, 0.5, 0.75))
	_ellipse(c + Vector2(-r * 0.5, r * 0.5), r * 0.5, r * 0.35, Color(0.65, 0.4, 0.9))
	_ellipse(c + Vector2(r * 0.5, r * 0.5), r * 0.5, r * 0.35, Color(0.65, 0.4, 0.9))
	draw_line(c + Vector2(0, -r * 0.7), c + Vector2(0, r * 0.7), Color(0.2, 0.15, 0.25), r * 0.22)
	draw_line(c + Vector2(0, -r * 0.7), c + Vector2(-r * 0.4, -r * 1.1), Color(0.2, 0.15, 0.25), r * 0.08)
	draw_line(c + Vector2(0, -r * 0.7), c + Vector2(r * 0.4, -r * 1.1), Color(0.2, 0.15, 0.25), r * 0.08)
	_eye(c + Vector2(-r * 0.12, -r * 0.6), r * 0.1)
	_eye(c + Vector2(r * 0.12, -r * 0.6), r * 0.1)


func _draw_spider(c: Vector2, r: float) -> void:
	var dark := Color(0.35, 0.2, 0.55)
	for i in range(8):
		var a := i / 8.0 * TAU + 0.3
		var dir := Vector2(cos(a), sin(a))
		draw_line(c + dir * r * 0.6, c + dir * r * 1.25, dark, r * 0.1)
	draw_circle(c, r * 0.75, Color(0.55, 0.3, 0.85))
	draw_circle(c + Vector2(0, -r * 0.7), r * 0.4, dark)
	_eye(c + Vector2(-r * 0.2, -r * 0.75), r * 0.1)
	_eye(c + Vector2(r * 0.2, -r * 0.75), r * 0.1)
	_eye(c + Vector2(-r * 0.35, -r * 0.55), r * 0.08)
	_eye(c + Vector2(r * 0.35, -r * 0.55), r * 0.08)
