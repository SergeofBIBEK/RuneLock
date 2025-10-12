@tool
extends CharacterBody2D
class_name Rune

@export var active: bool = true;
@export var fall_speed: float = 100.0;
@export var horizontal_speed: float = Config.CELL_SIZE;
@export var height: float = Config.CELL_SIZE;
@export var width: float = Config.CELL_SIZE * 2;

var rotation_step := 0;
var piecesLeft := 2;
var free_falling: bool = false;

enum Orientation { SQUARE, HORIZONTAL, VERTICAL };

func _ready() -> void:
	if not Engine.is_editor_hint():
		for child in get_children():
			if child is RuneHalf:
				child.tree_exiting.connect(_half_delete.bind(child))
	_adjust_collision_box();

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return;

	if active:
		var current_fall_speed = fall_speed;
		
		if Input.is_action_pressed("accelerate"):
			current_fall_speed = 1500;
		
		var v := Vector2.ZERO;
		v.y = current_fall_speed;

		if Input.is_action_just_pressed("move_right"):
			v.x += horizontal_speed;

		elif Input.is_action_just_pressed("move_left"):
			v.x -= horizontal_speed;

		if Input.is_action_just_pressed("rotate"):
			_rotate_rune();

		move_and_collide(Vector2(v.x, 0.0));

		var vertical_hit := move_and_collide(Vector2(0.0, v.y) * delta);
		
		if vertical_hit:
			position.y = round(position.y / (Config.CELL_SIZE * 0.5)) * (Config.CELL_SIZE * 0.5);
			active = false;
			velocity = Vector2.ZERO;

		var bottom_hit := _check_bottom_hit();
		var top_hit := _check_top_hit();

		if bottom_hit:
			active = false;
			velocity = Vector2.ZERO;
			
		if top_hit and (bottom_hit or vertical_hit):
			Events.level_failed.emit();
			return;
			
		if !active and not top_hit:
			Events.active_rune_finished.emit(self);
	else:
		var hit = move_and_collide(Vector2(0.0, 500) * delta);
		if hit:
			free_falling = false;
		elif _check_bottom_hit():
			free_falling = false;
		else:
			free_falling = true;

	_clamp_to_board();

func _half_delete(child_to_delete: RuneHalf):
	piecesLeft -= 1;
	var other_child_position;
	
	for child in get_children():
		if child is RuneHalf && child != child_to_delete:
			other_child_position = transform * child.position;
			child.position.x = 0;
			child.queue_redraw();
	
	if (piecesLeft == 1):
		height = Config.CELL_SIZE;
		width = Config.CELL_SIZE;
		position = other_child_position;
		_adjust_collision_box();
	elif (piecesLeft == 0):
		queue_free();

func _check_bottom_hit() -> bool:
	var board := get_parent() as Board;
	
	if board:
		var rune_bottom := position.y + (height * 0.5);
		var board_bottom := board.height;

		return rune_bottom >= board_bottom;
	else:
		return false;

func _check_top_hit() -> bool:
	var board = get_parent() as Board;
	
	if board:
		var rune_top := position.y - (height * 0.5);
		return rune_top <= 0;
	else:
		return false;

func _rotate_rune():
	var orientation = _get_orientation();
	var will_collide_right = test_move(global_transform, Vector2(10, 0));
	var will_collide_left = test_move(global_transform, Vector2(-10, 0));
	
	if will_collide_left and will_collide_right:
		return;
	
	if will_collide_right and orientation == Orientation.VERTICAL:
		position.x -= Config.CELL_SIZE;
	
	var h = height;
	var w = width;
	
	var aligned64 = position.x as int % 64;
	
	if (aligned64 == 31 || aligned64 == 63):
		aligned64 = (aligned64 + 1) % 64;
	
	rotation_step = (rotation_step + 1) % 4;
	rotation_degrees = rotation_step * 90;
	
	height = w;
	width = h;
	
	orientation = _get_orientation();
	
	if orientation == Orientation.SQUARE or orientation == Orientation.VERTICAL && not aligned64:
		position.x = snapped(position.x - (Config.CELL_SIZE * 0.5), Config.CELL_SIZE * 0.5);
	
	if orientation == Orientation.HORIZONTAL && aligned64:
		position.x = snapped(position.x + (Config.CELL_SIZE * 0.5), Config.CELL_SIZE);

func _get_orientation():	
	if height == width:
		return Orientation.SQUARE;
	if height > width:
		return Orientation.VERTICAL;
	if height < width:
		return Orientation.HORIZONTAL;

func _clamp_to_board() -> void:
	var board := get_parent() as Board;
	
	if board:
		var top := (height * 0.5);
		var left := (width * 0.5);
		var right := board.width - (width * 0.5);
		var bottom := board.height - (height * 0.5);
		position = position.clamp(Vector2(left, top), Vector2(right, bottom));
		
func _adjust_collision_box():
	var shape := RectangleShape2D.new();
	shape.size = Vector2(width - 1, height - 1);
	
	var cs := $CollisionShape2D;
	
	if cs:
		cs.shape = shape;
	queue_redraw();
