extends CanvasLayer

@onready var retry_button: Button = $Panel/VBox/Buttons/Retry;

func _ready():
	retry_button.pressed.connect(retry);
	
func retry():
	Events.retry_level.emit();
