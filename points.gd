extends MarginContainer

@onready var first_point = $HBoxContainer/VBoxContainer/FirstPoint
@onready var second_point = $HBoxContainer/VBoxContainer/SecondPoint
@onready var third_point = $HBoxContainer/VBoxContainer/ThirdPoint

var gray_circle = preload("res://assets/circles/GrayCircle.png")
var red_circle = preload("res://assets/circles/RedCircle.png")

signal points_changed(new_points)

var points: int = 0:
	set(value):
		points = value
		points_changed.emit(value)

func _ready():
	connect("points_changed", change_points)


func change_points(new_points):
	match new_points:
		1: 
			first_point.texture = red_circle
			second_point.texture = gray_circle
			third_point.texture = gray_circle
		2:
			first_point.texture = red_circle
			second_point.texture = red_circle
			third_point.texture = gray_circle
		3:
			first_point.texture = red_circle
			second_point.texture = red_circle
			third_point.texture = red_circle
		_:
			first_point.texture = gray_circle
			second_point.texture = gray_circle
			third_point.texture = gray_circle
