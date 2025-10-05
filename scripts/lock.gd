@tool
extends StaticBody2D
class_name Lock

var height: float = Config.CELL_SIZE;
var width: float = Config.CELL_SIZE;

@export var color: Config.ColorId = Config.ColorId.RED:
	set = set_color;

func _ready() -> void:
	var colorOptionCount = Config.ColorId.keys().size();
	color = (randi() % colorOptionCount) as Config.ColorId;
	
	var shape := RectangleShape2D.new();
	shape.size = Vector2(width, height);
	
	var cs := $CollisionShape2D;
	
	if cs:
		cs.shape = shape;
	queue_redraw();

func _draw():
	var rect := Rect2(
		Vector2(-width * 0.5, -height * 0.5) + Vector2(0.5, 0.5),
		Vector2(width - 1, height - 1)
	);
	
	var col: Color = Config.COLOR_MAP.get(color, Color(0.6, 0.6, 0.6));
	draw_rect(rect, col.darkened(0.4), true);

func _notification(what):
	if what == NOTIFICATION_EXIT_TREE:
		if not Engine.is_editor_hint():
			Events.lock_cleared.emit();

func set_color(v: Config.ColorId):
	color = v;
	queue_redraw();
