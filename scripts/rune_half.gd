@tool
extends Node2D
class_name RuneHalf

var height: float = Config.CELL_SIZE;
var width: float = Config.CELL_SIZE;
var color: Config.ColorId = Config.ColorId.RED:
	set = set_color;
	
@export var side: int = 1;

func _ready() -> void:
	var colorOptionCount = Config.ColorId.keys().size();
	color = (randi() % colorOptionCount) as Config.ColorId;
	queue_redraw();

func _draw():
	var rect := Rect2(
		Vector2(-width * 0.5, -height * 0.5) + Vector2(0.5, 0.5),
		Vector2(width - 1, height - 1)
	);
	
	var col: Color = Config.COLOR_MAP.get(color, Color(0.6, 0.6, 0.6));
	draw_rect(rect, col, true);

func set_color(v: Config.ColorId):
	color = v;
	queue_redraw();
