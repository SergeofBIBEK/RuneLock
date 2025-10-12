extends Node2D

@onready var complete_overlay := $CompleteOverlay;
@onready var failed_overlay := $FailedOverlay;
@onready var board := $Board;

func _ready():
	if not Engine.is_editor_hint():
		Events.level_completed.connect(win);
		Events.level_failed.connect(lose);
		Events.retry_level.connect(retry);
		Events.next_level.connect(next_level);

func win():
	complete_overlay.show();
	board.get_tree().paused = true;
	
func lose():
	failed_overlay.show();
	board.get_tree().paused = true;

func retry():
	board.reset();
	hide_all_overlays();
	board.get_tree().paused = false;
	board.spawn_new_rune();

func next_level():
	board.desired_lock_count += 1;
	board.reset();
	hide_all_overlays();
	board.get_tree().paused = false;
	board.spawn_new_rune();
	
func hide_all_overlays():
	complete_overlay.hide();
	failed_overlay.hide();
