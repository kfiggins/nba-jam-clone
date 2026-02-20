extends Node2D
## Draws basketball court markings: half-court line, center circle, and 3-point arcs.

const COURT_TOP := 100.0
const COURT_BOTTOM := 620.0
const COURT_LEFT := 100.0
const COURT_RIGHT := 1180.0
const COURT_CENTER_X := 640.0
const COURT_CENTER_Y := 360.0
const BASKET_RIGHT_X := 1130.0
const BASKET_LEFT_X := 150.0
const CENTER_CIRCLE_RADIUS := 60.0
const LINE_COLOR := Color(1, 1, 1, 0.4)
const LINE_WIDTH := 2.0


func _draw() -> void:
	# Half-court line
	draw_line(Vector2(COURT_CENTER_X, COURT_TOP), Vector2(COURT_CENTER_X, COURT_BOTTOM), LINE_COLOR, LINE_WIDTH)

	# Center circle
	draw_arc(Vector2(COURT_CENTER_X, COURT_CENTER_Y), CENTER_CIRCLE_RADIUS, 0, TAU, 32, LINE_COLOR, LINE_WIDTH)

	# 3-point arcs
	var three_pt_radius := GameConfig.data.three_point_distance
	if three_pt_radius <= 0:
		return

	var court_half_height := COURT_CENTER_Y - COURT_TOP  # 260
	var clamped_ratio := clampf(court_half_height / three_pt_radius, -1.0, 1.0)
	var half_angle := asin(clamped_ratio)

	# Right basket arc (faces left toward center court)
	var right_center := Vector2(BASKET_RIGHT_X, COURT_CENTER_Y)
	draw_arc(right_center, three_pt_radius, PI - half_angle, PI + half_angle, 32, LINE_COLOR, LINE_WIDTH)

	# Left basket arc (faces right toward center court)
	var left_center := Vector2(BASKET_LEFT_X, COURT_CENTER_Y)
	draw_arc(left_center, three_pt_radius, -half_angle, half_angle, 32, LINE_COLOR, LINE_WIDTH)

	# Straight sideline portions (from arc endpoints to baseline) when arc doesn't reach sidelines
	if three_pt_radius < court_half_height:
		var arc_y_offset := three_pt_radius
		# Right basket: horizontal lines to right baseline
		draw_line(Vector2(BASKET_RIGHT_X, COURT_CENTER_Y - arc_y_offset), Vector2(COURT_RIGHT, COURT_CENTER_Y - arc_y_offset), LINE_COLOR, LINE_WIDTH)
		draw_line(Vector2(BASKET_RIGHT_X, COURT_CENTER_Y + arc_y_offset), Vector2(COURT_RIGHT, COURT_CENTER_Y + arc_y_offset), LINE_COLOR, LINE_WIDTH)
		# Left basket: horizontal lines to left baseline
		draw_line(Vector2(BASKET_LEFT_X, COURT_CENTER_Y - arc_y_offset), Vector2(COURT_LEFT, COURT_CENTER_Y - arc_y_offset), LINE_COLOR, LINE_WIDTH)
		draw_line(Vector2(BASKET_LEFT_X, COURT_CENTER_Y + arc_y_offset), Vector2(COURT_LEFT, COURT_CENTER_Y + arc_y_offset), LINE_COLOR, LINE_WIDTH)
