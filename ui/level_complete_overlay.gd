extends CanvasLayer

@onready var retry_button: Button = $Panel/VBox/Buttons/Retry;
@onready var next_button: Button = $Panel/VBox/Buttons/Next;

func _ready():
	retry_button.pressed.connect(retry);
	next_button.pressed.connect(next);
	
func retry():
	Events.retry_level.emit();
	
func next():
	Events.next_level.emit();
