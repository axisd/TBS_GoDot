extends Control

# No text background
var no_text_background : Resource = preload("res://assets/intro screen/intro background no text.jpg")

enum {INTRO, GAME_SELECT, WAIT}
var current_state = INTRO

var options : Array = ["New Game", "Load Game", "Options Screen"]
var current_option : String
var current_option_number : int = 0


func _ready():
	# Start music
	$"Intro Song".play(0)
	
	current_state = INTRO
	
	current_option = options[current_option_number]
	
	# Anim signal
	$"Anim".animation_finished.connect(allow_selection)
	
	# No 3 houses
	$"Intro Background".texture = no_text_background

func _input(event):
	match current_state:
		INTRO:
			# Any key
			if event is InputEventKey and event.is_pressed():
				$"Anim".play("Options Fade In")
				current_state = WAIT
		GAME_SELECT:
			if Input.is_action_just_pressed("ui_up"):
				current_option_number -= 1
				$"Options/Hand Selector".position.y -= 18
				if current_option_number < 0:
					current_option_number = 0
					current_option = options[current_option_number]
					$"Options/Hand Selector".position.y += 18
				current_option = options[current_option_number]
				$"Options/Hand Selector/Move".play(0)
			if Input.is_action_just_pressed("ui_down"):
				current_option_number += 1
				$"Options/Hand Selector".position.y += 18
				if current_option_number > options.size() - 1:
					current_option_number = options.size() - 1
					current_option = options[current_option_number]
					$"Options/Hand Selector".position.y -= 18
				current_option = options[current_option_number]
				$"Options/Hand Selector/Move".play(0)
			if Input.is_action_just_pressed("ui_accept"):
				$"Options/Hand Selector/Accept".play(0)
				process_selection()
				

func _process(delta):
	pass

func allow_selection(anim_name):
	current_state = GAME_SELECT

func process_selection():
	match current_option:
		"New Game":
			$"Anim".play("music fade out")
			set_process_input(false)
			
			# Reset game over status
			BattlefieldInfo.turn_manager.set_process(true)
			BattlefieldInfo.game_over = false
			
			# Scene change
			WorldMapScreen.current_event = Level1_WM_Event_Part10.new()
			WorldMapScreen.connect_to_scene_changer()
			SceneTransition.change_scene_to_packed(WorldMapScreen, 0.1)
		"Load Game":
			# Stop song and fade to black
			$"Anim".play("music fade out")
			set_process_input(false)
			await $Anim.animation_finished
			$"Intro Song".stop()
			
			# Make screen go dark
			$Anim.play("Fade ")
			await $Anim.animation_finished
			
			# Load the game
			BattlefieldInfo.save_load_system.is_loading_level = true
			BattlefieldInfo.save_load_system.load_game()
