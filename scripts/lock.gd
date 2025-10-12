@tool
extends StaticBody2D
class_name Lock

var height: float = Config.CELL_SIZE;
var width: float = Config.CELL_SIZE;

@export var color: Config.ColorId = Config.ColorId.RED:
	set = set_color;

@onready var ap := $Art/AnimationPlayer;

func _ready() -> void:
	var colorOptionCount = Config.ColorId.keys().size();
	color = (randi() % colorOptionCount) as Config.ColorId;
	set_glow_color();
	
	var shape := RectangleShape2D.new();
	shape.size = Vector2(width, height);
	
	var cs := $CollisionShape2D;
	
	if cs:
		cs.shape = shape;
	queue_redraw();

func set_glow_color():
	var sprite := $Art as Sprite2D;
	if sprite == null:
		push_error("Node 'Art' not found.");
		return;

	var mat := sprite.material
	if mat == null:
		push_error("'Art' has no material. Did you add the ShaderMaterial?");
		return;

	if not (mat is ShaderMaterial):
		push_error("'Art' material is not a ShaderMaterial.");
		return;

	if not mat.resource_local_to_scene:
		mat = mat.duplicate();
		mat.resource_local_to_scene = true;
		sprite.material = mat;

	var col: Color = Config.COLOR_MAP.get(color, Color.WHITE);
	
	mat.set_shader_parameter("emission_color", Vector3(col.r, col.g, col.b));

func _notification(what):
	if what == NOTIFICATION_EXIT_TREE:
		if not Engine.is_editor_hint():
			Events.lock_cleared.emit();

func destroy():
	if ap.has_animation("explode"):
		ap.play("explode", -1, 2.0);
		await ap.animation_finished;
		
	queue_free();

func set_color(v: Config.ColorId):
	color = v;
	set_glow_color();
	queue_redraw();
