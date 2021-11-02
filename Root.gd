extends Node

enum COLLISION {credits,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,q,end}

onready var collayer = ['credits','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','q','end']

onready var levels = get_tree().get_nodes_in_group('levels')
onready var menu = get_node("Settings")

onready var billiard = $Billiard
onready var goalPlayer = $GoalPlayer
onready var fallPlayer = $FallPlayer
onready var contact = $Contact
onready var active_level = levels[COLLISION.a]
onready var cage = $cage

onready var soundvolume = menu.get_soundvol()

#var fall_sound = preload('res://sounds/zapsplat_cartoon_descend_wobble_low_pitched_71601.mp3')
#var goal_sound = preload('res://sounds/zapsplat_cartoon_flutter_delicate_64209.mp3')

func _ready():
	load_level()
	menu.load2()
#	$Flippers.follow = billiard
#	contact.fallStreak = 5
	contact.link = billiard
	billiard.global_position = active_level.checkpoint.global_position
	contact.connect('slap', billiard, 'apply_central_impulse')
	active_level.arrive()
	for level in levels:
		level.connect('fall', self, 'move_down')
		level.connect('goal', self, 'move_up')

func move_down(level, pos):
#	animate transition
	var current = get_level(collayer[level]) 
	var next = get_level(collayer[level-1])
	current.go_away(false)
	next.arrive()
	active_level = next
#	soundPlayer.set_stream(fall_sound)
	if soundvolume > 0:
		fallPlayer.play()
	contact.fallStreak += 1
	print('next '+ next.name)
	print(pos)

func move_up(level, pos):
#	animate transition
	var current = get_level(collayer[level]) 
	var next = get_level(collayer[level+1])
	current.go_away(true)
	next.arrive()
	if next.name == 'end':
		$Billiard/Camera2D.zoom = Vector2(1.25, 1.25)
	active_level = next
#	soundPlayer.set_stream(goal_sound)
#	soundPlayer.set_volume_db(-2000.0)
	if soundvolume > 0:
		goalPlayer.play()
	contact.fallStreak = 0
#	print(soundPlayer.get_volume_db())	
#	soundPlayer.set_volume_db(0.0)
	print('next '+ next.name)
	print(pos)
 
func get_level(lvlName):
	for level in levels:
		if level.name == lvlName:
			return level

func _unhandled_input(event):
	if event.is_action_pressed("ui_focus_next"):
#		print('point')
#		checkpoint()
		cheat()

func checkpoint():
	print('point')
	var pos = active_level.checkpoint.global_position
	cage.global_position = billiard.global_position
	yield(get_tree().create_timer(0.25), "timeout")
	billiard.global_position = pos
	cage.global_position = Vector2()

func cheat():
	get_tree().reload_current_scene()

func _on_Settings_menu(on):
	if on:
		billiard.set_visible(true)
		contact.set_visible(true)
		menu.menu_switch(false, Vector2())
	else:
		billiard.set_visible(false)
		contact.set_visible(false)
		menu.menu_switch(true, billiard.global_position)

# Note: This can be called from anywhere inside the tree. This function is
# path independent.
# Go through everything in the persist category and ask them to return a
# dict of relevant variables.
func save_level():
	print('save level')
	var save_game = File.new()
	save_game.open("user://savelevel.save", File.WRITE)
	# Store the save dictionary as a new line in the save file.
	save_game.store_line(to_json({'active_level': active_level.name}))
	save_game.close()

# Note: This can be called from anywhere inside the tree. This function
# is path independent.
func load_level():
	var save_game = File.new()
	if not save_game.file_exists("user://savelevel.save"):
		return # Error! We don't have a save to load.

	save_game.open("user://savelevel.save", File.READ)
	var node_data = parse_json(save_game.get_line())

	active_level = get_level(node_data["active_level"])

	save_game.close()

func _on_Settings_sound_changed(vol):
	if soundvolume > 0:
		if vol == 0:
			contact.sounds = false
	if soundvolume == 0:
		if vol > 0:
			contact.sounds = true
	soundvolume = vol

func _on_Settings_invert_controls(switch):
		contact.inverted = switch

func _on_Settings_save_quit():
	save_level()
	get_tree().quit()
