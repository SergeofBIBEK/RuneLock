@tool
extends Node2D
class_name RuneHalf

var height: float = Config.CELL_SIZE;
var width: float = Config.CELL_SIZE;
var color: Config.ColorId = Config.ColorId.RED:
	set = set_color;
	
@export var side: int = 1;
@onready var particles := $Art/Sparkles as GPUParticles2D
@onready var ap := $Art/AnimationPlayer;

func _ready() -> void:
	var colorOptionCount = Config.ColorId.keys().size();
	color = (randi() % colorOptionCount) as Config.ColorId;
	set_glow_color();
	set_particle_color();
	queue_redraw();

func set_glow_color():
	var sprite := $Art as Sprite2D;
	var sprite_floaters := $Floaters as Sprite2D;
	
	if sprite == null || sprite_floaters == null:
		push_error("Node 'Art' or 'Floaters' not found.");
		return;

	var mat := sprite.material;
	var mat_floaters := sprite_floaters.material;
	if mat == null || mat_floaters == null:
		push_error("'Art' or 'Floaters' has no material. Did you add the ShaderMaterial?");
		return;

	if not (mat is ShaderMaterial || mat_floaters is ShaderMaterial):
		push_error("'Art' or 'Floaters' material is not a ShaderMaterial.");
		return;

	if not mat.resource_local_to_scene:
		mat = mat.duplicate();
		mat.resource_local_to_scene = true;
		sprite.material = mat;
	
	if not mat_floaters.resource_local_to_scene:
		mat_floaters = mat_floaters.duplicate();
		mat_floaters.resource_local_to_scene = true;
		sprite_floaters.material = mat_floaters;

	var col: Color = Config.COLOR_MAP.get(color, Color.WHITE);
	
	mat.set_shader_parameter("emission_color", Vector3(col.r, col.g, col.b));
	mat_floaters.set_shader_parameter("emission_color", Vector3(col.r, col.g, col.b));

func set_particle_color():
	var pm := particles.process_material;
	
	if pm != null:
		pm = pm.duplicate();
		pm.resource_local_to_scene = true;
		particles.process_material = pm;
		
	var grad := Gradient.new();
	var col: Color = Config.COLOR_MAP.get(color, Color.WHITE) * 2.0;
	var c1 := col;
	c1.a = 0.8;
	var c2 := col;
	c2.a = 0.0;
	
	grad.colors = PackedColorArray([c1,c2]);
	
	var tex := GradientTexture1D.new();
	tex.gradient = grad;
	pm.color_ramp = tex;

func destroy():
	if ap.has_animation("explode"):
		ap.play("explode", -1, 2.0);
		await ap.animation_finished;
	queue_free();

func set_color(v: Config.ColorId):
	color = v;
	set_glow_color();
	set_particle_color();
	queue_redraw();
