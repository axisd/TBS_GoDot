extends Camera2D

class_name MainCamera

# Areas
const CAMERA_CURSOR_DIFFERENTIAL_FACTOR : int = 1
const CAMERA_CURSOR_EXTRA_DIFF : int = 0
const CAMERA_WIDTH : int = 240
const CAMERA_HEIGTH : int = 160
var RIGHT_CLAMP_MAX
var BOTTOM_CLAMP_MAX

# Camera Shake
var _duration : float = 0.0
var _period_in_ms : float = 0.0
var _amplitude : float = 0.0
var _timer : float = 0.0
var _last_shook_timer : float = 0
var _previous_x : float = 0.0
var _previous_y : float = 0.0
var _last_offset : Vector2 = Vector2(0, 0)

@onready var camera_tween : Tween = get_tree().create_tween()

signal camera_moved

func _ready():
	# Access the main camera from anywhere
	BattlefieldInfo.main_game_camera = self
	
	# Check if connected -> No idea why my two levels are bugged and the rest are okay.
	BattlefieldInfo.cursor.cursorMoved.connect(_on_Cursor_cursorMoved)
	
	# Camera Shake for battle effect
	set_process(true)

# Update the camera on cursor movement
func _on_Cursor_cursorMoved(direction, cursor_position):
	match direction:
		"up":
			if abs(position.y - cursor_position.y) <= (Cell.CELL_SIZE * CAMERA_CURSOR_DIFFERENTIAL_FACTOR):
				position += Vector2(0,-Cell.CELL_SIZE)
				emit_signal("camera_moved", position)
		"down":
			if abs((position.y + CAMERA_HEIGTH - Cell.CELL_SIZE) - cursor_position.y) <= (Cell.CELL_SIZE * CAMERA_CURSOR_DIFFERENTIAL_FACTOR):
				position += Vector2(0,Cell.CELL_SIZE)
				emit_signal("camera_moved", position)
		"left":
			if abs(position.x - cursor_position.x) <= (Cell.CELL_SIZE * CAMERA_CURSOR_DIFFERENTIAL_FACTOR):
				position += Vector2(-Cell.CELL_SIZE,0)
				emit_signal("camera_moved", position)
		"right":
			if abs((position.x + CAMERA_WIDTH - Cell.CELL_SIZE) - cursor_position.x) <= (Cell.CELL_SIZE * CAMERA_CURSOR_DIFFERENTIAL_FACTOR):
				position += Vector2(Cell.CELL_SIZE,0)
				emit_signal("camera_moved", position)
	# Clamp camera
	clampCameraPosition()


func _on_unit_moved(direction, unit_position):
	match direction:
		"Up":
			if abs(position.y - unit_position.y) <= (Cell.CELL_SIZE * (CAMERA_CURSOR_DIFFERENTIAL_FACTOR + CAMERA_CURSOR_EXTRA_DIFF)):
				position += Vector2(0,-Cell.CELL_SIZE)
				emit_signal("camera_moved", position)
		"Down":
			if abs((position.y + CAMERA_HEIGTH - Cell.CELL_SIZE) - unit_position.y) <= (Cell.CELL_SIZE * (CAMERA_CURSOR_DIFFERENTIAL_FACTOR + CAMERA_CURSOR_EXTRA_DIFF)):
				position += Vector2(0,Cell.CELL_SIZE)
				emit_signal("camera_moved", position)
		"Left":
			if abs(position.x - unit_position.x) <= (Cell.CELL_SIZE * (CAMERA_CURSOR_DIFFERENTIAL_FACTOR + CAMERA_CURSOR_EXTRA_DIFF)):
				position += Vector2(-Cell.CELL_SIZE,0)
				emit_signal("camera_moved", position)
		"Right":
			if abs((position.x + CAMERA_WIDTH - Cell.CELL_SIZE) - unit_position.x) <= (Cell.CELL_SIZE * (CAMERA_CURSOR_DIFFERENTIAL_FACTOR + CAMERA_CURSOR_EXTRA_DIFF)):
				position += Vector2(Cell.CELL_SIZE,0)
				emit_signal("camera_moved", position)
	# Clamp camera
	clampCameraPosition()

# Sets the parameters for the maximum camera movement once the level is loaded
func _on_Level_mapInformationLoaded():
	limit_bottom = (BattlefieldInfo.map_height * Cell.CELL_SIZE)
	limit_right = (BattlefieldInfo.map_width * Cell.CELL_SIZE)
	RIGHT_CLAMP_MAX = (BattlefieldInfo.map_width * Cell.CELL_SIZE) - CAMERA_WIDTH
	BOTTOM_CLAMP_MAX = (BattlefieldInfo.map_height * Cell.CELL_SIZE) - CAMERA_HEIGTH

# Prevent out of bounds for the camera
func clampCameraPosition():
	# Clamp
	position.x = clamp(position.x, 0, RIGHT_CLAMP_MAX)
	position.y = clamp(position.y, 0, BOTTOM_CLAMP_MAX)


# Shake with decreasing intensity while there's time remaining.
func _process(delta):
	# Only shake when there's shake time remaining.
	if _timer == 0:
		set_offset(Vector2())
		set_process(false)
		return
	# Only shake on certain frames.
	_last_shook_timer = _last_shook_timer + delta
	# Be mathematically correct in the face of lag; usually only happens once.
	while _last_shook_timer >= _period_in_ms:
		_last_shook_timer = _last_shook_timer - _period_in_ms
		# Lerp between [amplitude] and 0.0 intensity based on remaining shake time.
		var intensity = _amplitude * (1 - ((_duration - _timer) / _duration))
		# Noise calculation logic from http://jonny.morrill.me/blog/view/14
		var new_x = randf_range(-1.0, 1.0)
		var x_component = intensity * (_previous_x + (delta * (new_x - _previous_x)))
		var new_y = randf_range(-1.0, 1.0)
		var y_component = intensity * (_previous_y + (delta * (new_y - _previous_y)))
		_previous_x = new_x
		_previous_y = new_y
		# Track how much we've moved the offset, as opposed to other effects.
		var new_offset = Vector2(x_component, y_component)
		set_offset(get_offset() - _last_offset + new_offset)
		_last_offset = new_offset
	# Reset the offset when we're done shaking.
	_timer = _timer - delta
	if _timer <= 0:
		_timer = 0
		set_offset(get_offset() - _last_offset)

# Kick off a new screenshake effect.
func shake(duration, frequency, amplitude):
	# Don't interrupt current shake duration
	if(_timer != 0):
		return
   
	# Initialize variables.
	_duration = duration
	_timer = duration
	_period_in_ms = 1.0 / frequency
	_amplitude = amplitude
	_previous_x = randf_range(-1.0, 1.0)
	_previous_y = randf_range(-1.0, 1.0)
	# Reset previous offset, if any.
	set_offset(get_offset() - _last_offset)
	_last_offset = Vector2(0, 0)
	set_process(true)
