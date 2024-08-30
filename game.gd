extends Node2D

@onready var end_turn_button = $EndTurnButton
@onready var stand_button = $StandButton
@onready var host: Button = $Host
@onready var join: Button = $Join
@onready var local_ip = $LocalIP
@onready var host_ip = $HostIP
@onready var player_sum_label = $PlayerSumLabel
@onready var enemy_sum_label = $EnemySumLabel
@onready var timer = $Timer
@onready var round_result_window = $RoundResultWindow
@onready var round_result_label = $RoundResultWindow/RoundResultLabel
@onready var game_result_window = $GameResultWindow
@onready var game_result_label = $GameResultWindow/GameResultLabel


var card_scene = preload("res://card.tscn")
@onready var player_hand = $PlayerHand
@onready var player_board = $PlayerBoard
@onready var enemy_board = $EnemyBoard
@onready var turn_status = $TurnStatus
@onready var player_stand = $PlayerStand
@onready var enemy_stand = $EnemyStand
@onready var player_points_view = $PlayerPointsView
@onready var enemy_points_view = $EnemyPointsView

var peer = ENetMultiplayerPeer.new()
var player_sum: int:
	set(value):
		player_sum = value
		player_sum_label.text = str(value)
		if value == 20:
			call_deferred("_on_stand_button_pressed")
var enemy_sum: int:
	set(value):
		enemy_sum = value
		enemy_sum_label.text = str(value)
var player_turn: bool:
	set(value):
		player_turn = value
		if value:
			turn_status.text = 'Ваш ход'
			call_deferred('play_default')
		else:
			turn_status.text = 'Ход противника'
var enemy_id: int

var player_is_stand: bool:
	set(value):
		player_is_stand = value
		if value:
			player_stand.show()
		else:
			player_stand.hide()
var enemy_is_stand: bool:
	set(value):
		enemy_is_stand = value
		if value:
			enemy_stand.show()
		else:
			enemy_stand.hide()
var is_played: bool
var player_points: int = 0:
	set(value):
		player_points = value
		player_points_view.points = value
		if value == 3:
			game_result_label.text = 'Вы выиграли игру'
			game_result_window.show()
var enemy_points: int = 0:
	set(value):
		enemy_points = value
		enemy_points_view.points = value
		if value == 3:
			game_result_label.text = 'Вы проиграли игру'
			game_result_window.show()


func _ready():
	peer = ENetMultiplayerPeer.new()
	local_ip.text = 'Your local ip is '
	for ip in IP.get_local_addresses():
		if ip.substr(0, 7) == '192.168':
			local_ip.text += str(ip, ' ')
	player_board.connect("child_entered_tree", add_to_enemy_board)
	player_board.connect("child_exiting_tree", remove_from_enemy_board)
	player_board.connect("child_entered_tree", check_fullness, 1)
	player_board.connect("child_entered_tree", calculate_player_count, 1)
	player_board.connect("child_exiting_tree", calculate_player_count, 1)
	enemy_board.connect("child_entered_tree", calculate_enemy_count, 1)
	enemy_board.connect("child_exiting_tree", calculate_enemy_count, 1)
	

func connected(id):
	game_result_window.show()
	enemy_id = id
	local_ip.hide()
	end_turn_button.show()
	stand_button.show()
	player_points_view.show()
	enemy_points_view.show()
	for i in range(4):
		var card = card_scene.instantiate()
		match randi_range(0, 1):
			0: 
				card.type = 0
				card.value = randi_range(1, 6)
			1:
				card.type = 1
				card.value = -randi_range(1, 6)
		player_hand.add_child(card)
		card.can_be_played = true
		card.connect("clicked", play_from_hand.bind(card))
	turn_status.show()
	if enemy_id != 1:
		player_turn = true
	else:
		player_turn = false


func _on_host_pressed():
	peer.create_server(8080, 1)
	peer.connect("peer_connected", connected)
	get_tree().set_multiplayer(SceneMultiplayer.new(), self.get_path())
	multiplayer.multiplayer_peer = peer
	joined()


func _on_join_pressed():
	peer.create_client(host_ip.text, 8080)
	peer.connect("peer_connected", connected)
	get_tree().set_multiplayer(SceneMultiplayer.new(), self.get_path())
	multiplayer.multiplayer_peer = peer
	joined()


func joined():
	host.hide()
	join.hide()
	host_ip.hide()


func play_from_hand(card):
	if !is_played and player_turn:
		player_hand.remove_child(card)
		player_board.add_child(card)
		card.can_be_played = false
		is_played = true


func play_default():
	if !player_is_stand:
		var card = card_scene.instantiate()
		card.value = randi_range(1, 10)
		card.type = 2
		player_board.add_child(card)
	else:
		end_turn()


@rpc("any_peer", "call_remote", "reliable")
func play_rpc(value, type):
	var card = card_scene.instantiate()
	card.value = value
	card.type = type
	enemy_board.add_child(card)

@rpc("any_peer", "call_remote", "reliable")
func remove_rpc(index):
	enemy_board.remove_child(enemy_board.get_child(index))

@rpc("any_peer", "call_remote", "reliable")
func set_turn_status():
	player_turn = true

@rpc("any_peer", "call_remote", "reliable")
func set_enemy_stand_status(sum):
	enemy_is_stand = true
	enemy_sum = sum


func end_turn():
	player_turn = false
	rpc("set_turn_status")
	is_played = false


@rpc("any_peer", "call_local", "reliable")
func greater_than_20():
	if player_sum > 20:
		enemy_points += 1
		round_result_label.text = 'Вы проиграли раунд'
	elif enemy_sum > 20:
		player_points += 1
		round_result_label.text = 'Вы выиграли раунд'
	round_result_window.show()
	timer.start()


func calculate_player_count(_arg):
	var sum = 0
	for child in player_board.get_children():
		sum += child.value
	player_sum = sum


func calculate_enemy_count(_arg):
	var sum = 0
	for child in enemy_board.get_children():
		sum += child.value
	enemy_sum = sum


func add_to_enemy_board(card):
	rpc("play_rpc", card.value, card.type)


func remove_from_enemy_board(card):
	rpc("remove_rpc", card.get_index())


func _on_end_turn_button_pressed():
	if player_turn:
		if player_sum > 20:
			rpc("greater_than_20")
		else:
			end_turn()


func _on_stand_button_pressed():
	if player_turn:
		if player_sum > 20:
			rpc("greater_than_20")
		else:
			player_is_stand = true
			rpc("set_enemy_stand_status", player_sum)
			if enemy_is_stand:
				rpc("calculate_result")
			else:
				end_turn()


func check_fullness(_arg):
	if player_board.get_child_count() == 9:
		call_deferred("_on_stand_button_pressed")


func clear_board():
	for child in player_board.get_children():
		player_board.remove_child(child)

@rpc("any_peer", "call_local", "reliable")
func calculate_result():
	if player_sum > enemy_sum:
		player_points += 1
		round_result_label.text = 'Вы выиграли раунд' 
	elif player_sum < enemy_sum:
		enemy_points += 1
		round_result_label.text = 'Вы проиграли раунд'
	else:
		round_result_label.text = 'Ничья в раунде'
	round_result_window.show()
	timer.start()


func _on_timer_timeout():
	round_result_window.hide()
	rpc("end_round")

@rpc("any_peer", "call_local", "reliable")
func end_round():
	clear_board()
	player_is_stand = false
	enemy_is_stand = false
	is_played = false
	if enemy_id != 1:
		player_turn = true
	else:
		player_turn = false



func _on_leave_button_pressed():
	peer.close()
	get_tree().change_scene_to_file("res://menu.tscn")
