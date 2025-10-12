@tool
extends Node2D
class_name Board

@export var columns: int = 8 : set = set_columns;
@export var rows: int = 16 : set = set_rows;

var min_columns: int = 2;
var min_rows: int = 2;

var width: int = 8 * Config.CELL_SIZE;
var height: int = 16 * Config.CELL_SIZE;

@export var bg_color: Color = Color("#1e1e1e") : set = set_bg_color;
@export var border_px: float = 2.0 : set = set_border_px;
@export var border_color: Color = Color.WHITE : set = set_border_color;

@export var draw_grid: bool = false : set = set_draw_grid;
@export var grid_cell: Vector2i = Vector2i(Config.CELL_SIZE, Config.CELL_SIZE) : set = set_grid_cell;
@export var grid_color: Color = Color(1, 1, 1, 0.06) : set = set_grid_color;

var game_over := false;
var win := false;
var lock_count: int = 0;

const RUNE_SCENE: PackedScene = preload("res://scenes/rune/Rune.tscn");
const LOCK_SCENE: PackedScene = preload("res://scenes/lock/lock.tscn");

func _ready():
	if not Engine.is_editor_hint():
		Events.active_rune_finished.connect(_on_rune_finished);
		Events.game_over.connect(_on_game_over);
		Events.lock_cleared.connect(_on_lock_cleared);
	
	_spawn_random_locks(15);
	_spawn_new_rune();
	queue_redraw();

func _on_lock_cleared():
	lock_count -= 1;
	if lock_count == 0:
		win = true;
		print('game won!');

func _on_rune_finished(_rune: Rune) -> void:
	await _cascade();
	
	_spawn_new_rune();

func _cascade():
	while true:
		var runs = _scan_board();
		
		if runs.is_empty():
			break;

		for run in runs:
			for node in run.nodes:
				await node.destroy();
		
		var quiet := 0;
		
		while true:
			await get_tree().physics_frame;

			var someone_moving := false
			
			var all_runes = get_children().filter(_filter_runes);

			for rune in all_runes:
				if _rune_is_moving(rune):
					someone_moving = true;
					break;
			
			if someone_moving:
				quiet = 0;
			else:
				quiet += 1;
			if quiet >= 4:
				break;

func _rune_is_moving(rune: Rune):
	return rune.free_falling;

func _on_game_over():
	game_over = true;
	
func _scan_board():
	var runesAndLocks: Array = [];
	
	for child in get_children():
		if (child is Lock):
			runesAndLocks.append({
				'cell': _cell_from_position(child.position),
				'color': child.color,
				'type': "Lock",
				'node': child,
			});
		if (child is Rune):
			for runeChild in child.get_children():
				if (runeChild is RuneHalf):
					var pos_in_board: Vector2 = child.transform * (runeChild as Node2D).position
					runesAndLocks.append({
						'cell': _cell_from_position(pos_in_board),
						'color': runeChild.color,
						'type': 'Rune Half',
						'node': runeChild
					});
					
	return _find_line_runs(runesAndLocks);
	
func _push_run_if_valid(results: Array, color: int, run_cells: PackedVector2Array, min_len: int, empty: int, node_map: Dictionary) -> void:
	if color != empty and run_cells.size() >= min_len:
		var nodes := []
		for c in run_cells:
			var key: Vector2i = Vector2i(c);
			if node_map.has(key):
				nodes.append(node_map[key]);
		results.append({
			"color": color,
			"nodes": nodes
		});

func _find_line_runs(items: Array) -> Array:
	var EMPTY := -1;
	var results: Array = [];
	var min_len: int = 4;

	var grid := PackedInt32Array();
	grid.resize(columns * rows);
	for i in grid.size():
		grid[i] = EMPTY;

	var node_map := {};

	for d in items:
		if not d.has("cell") or not d.has("color"):
			continue;
		var cell_val = d["cell"]
		var pos: Vector2i;
		if cell_val is Vector2i:
			pos = cell_val;
		elif cell_val is Vector2:
			pos = Vector2i(cell_val);
		elif cell_val is Array and cell_val.size() == 2:
			pos = Vector2i(int(cell_val[0]), int(cell_val[1]));
		else:
			continue;

		if pos.x < 0 or pos.x >= columns or pos.y < 0 or pos.y >= rows:
			continue;
			
		node_map[Vector2i(pos.x, pos.y)] = d["node"];
		grid[pos.y * columns + pos.x] = int(d.get("color", EMPTY));

	for y in rows:
		var last_color := EMPTY;
		var run_cells := PackedVector2Array();
		for x in columns:
			var c := grid[y * columns + x];
			if c != EMPTY and c == last_color:
				run_cells.append(Vector2i(x, y));
			elif c != EMPTY:
				_push_run_if_valid(results, last_color, run_cells, min_len, EMPTY, node_map);
				run_cells = PackedVector2Array([Vector2i(x, y)]);
			else:
				_push_run_if_valid(results, last_color, run_cells, min_len, EMPTY, node_map);
				run_cells = PackedVector2Array();
			last_color = c;
		_push_run_if_valid(results, last_color, run_cells, min_len, EMPTY, node_map);

	for x in columns:
		var last_color := EMPTY;
		var run_cells := PackedVector2Array();
		for y in rows:
			var c := grid[y * columns + x];
			if c != EMPTY and c == last_color:
				run_cells.append(Vector2i(x, y));
			elif c != EMPTY:
				_push_run_if_valid(results, last_color, run_cells, min_len, EMPTY, node_map);
				run_cells = PackedVector2Array([Vector2i(x, y)]);
			else:
				_push_run_if_valid(results, last_color, run_cells, min_len, EMPTY, node_map);
				run_cells = PackedVector2Array();
			last_color = c
		_push_run_if_valid(results, last_color, run_cells, min_len, EMPTY, node_map);

	return results;

func set_columns(v: int):
	var new_columns = max(min_columns, v);
	columns = new_columns;
	width = new_columns * Config.CELL_SIZE;
	queue_redraw();

func set_rows(v: int):
	var new_rows = max(min_rows, v);
	rows = new_rows;
	height = new_rows * Config.CELL_SIZE;
	queue_redraw();

func set_bg_color(c:Color) -> void:
	bg_color = c;
	queue_redraw();

func set_border_px(v:float) -> void:
	border_px = max(1.0, v);
	queue_redraw();

func set_border_color(c:Color) -> void:
	border_color = c;
	queue_redraw();

func set_draw_grid(v:bool) -> void:
	draw_grid = v;
	queue_redraw();

func set_grid_cell(v:Vector2i) -> void:
	grid_cell = Vector2i(max(8, v.x), max(8, v.y));
	queue_redraw();
	
func set_grid_color(c:Color) -> void:
	grid_color = c;
	queue_redraw();

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(width, height));

	draw_rect(rect, bg_color, true);

	if border_px > 0.0:
		draw_rect(rect, border_color, false, border_px);

	if draw_grid:
		for x in range(0, width + 1, grid_cell.x):
			draw_line(Vector2(x, 0), Vector2(x, height), grid_color, 1.0);
			
		for y in range(0, height + 1, grid_cell.y):
			draw_line(Vector2(0, y), Vector2(width, y), grid_color, 1.0);

@warning_ignore_start("integer_division")
func _spawn_new_rune():
	if game_over or win:
		return;
	
	var new_rune := RUNE_SCENE.instantiate() as Rune;
	
	var starting_column = columns / 2;
	var starting_row = 1;
	var starting_x = starting_column * Config.CELL_SIZE;
	var starting_y = starting_row * Config.CELL_SIZE / 2 + 1;
	
	new_rune.position = Vector2(starting_x, starting_y);
	add_child(new_rune);
	
func _spawn_random_locks(count: int):
	var bottom_rows := rows / 2;
	var total_bottom_cells := columns * bottom_rows;
	var max_locks := int(floor(total_bottom_cells * 0.25));

	if max_locks <= 0:
		print("No room for locks in bottom half.");
		return;

	var target: int = min(count, max_locks);

	var candidates: Array[Vector2i] = [];
	var start_row := rows - bottom_rows;
	for r in range(start_row, rows):
		for c in range(columns):
			var cell := Vector2i(c, r);
			candidates.append(cell);

	if candidates.is_empty():
		print("No free cells in bottom half to place locks.");
		return;

	if target > candidates.size():
		target = candidates.size();

	candidates.shuffle();

	for i in range(target):
		var lock := LOCK_SCENE.instantiate();
		var cell: Vector2i = candidates[i];
		lock.position = _pos_from_cell(cell);
		add_child(lock);
	
	lock_count = target;
	print("Spawned %d lock(s) (requested %d, cap %d)." % [target, count, max_locks]);

func _cell_from_position(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / Config.CELL_SIZE)), int(floor(p.y / Config.CELL_SIZE)));

func _pos_from_cell(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * Config.CELL_SIZE + Config.CELL_SIZE/2, cell.y * Config.CELL_SIZE + Config.CELL_SIZE/2);

@warning_ignore_restore("integer_division")

func _filter_runes(item) -> bool:
	return item is Rune;
