extends TextureRect

enum CardType {
	BLUE,
	RED,
	GREEN
}

@export var value = 1
@export var type: CardType = CardType.BLUE
@export var can_be_played: bool = false

signal clicked

func _ready():
	$Value.text = str(value)
	match type:
		CardType.BLUE: 
			texture = preload("res://assets/cards/blue_card.png")
		CardType.RED: 
			texture = preload("res://assets/cards/red_card.png")
		CardType.GREEN: 
			texture = preload("res://assets/cards/green_card.png")


func _on_button_pressed():
	clicked.emit()

func _on_button_mouse_entered():
	if can_be_played:
		$ColorRect.modulate = Color(255, 255, 255, 0.2)

func _on_button_mouse_exited():
	if can_be_played:
		$ColorRect.modulate = Color(255, 255, 255, 0)

func _on_button_button_down():
	if can_be_played:
		$ColorRect.modulate = Color(255, 255, 255, 0.3)

func _on_button_button_up():
	if can_be_played:
		$ColorRect.modulate = Color(255, 255, 255, 0)
