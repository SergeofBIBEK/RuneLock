extends Sprite2D

@export var rotation_speed : float = 2.0     # radians per second
@export var pulse_speed    : float = 1.0     # how fast it scales up/down
@export var pulse_amount   : float = 0.05     # how much to scale (0.1 = ±10%)

var _t := 0.0
var _base_scale := Vector2.ONE

func _ready() -> void:
	_base_scale = scale

func _process(delta: float) -> void:
	# rotation (simple and constant)
	rotation += rotation_speed * delta

	# pulsing scale
	_t += delta * pulse_speed
	var scale_offset = 1.0 + sin(_t) * pulse_amount
	scale = _base_scale * scale_offset
