extends Node2D
@onready var timer_label: Label = %TimerLabel
@onready var best_time_label: Label = %BestTimeLabel
@onready var pause_menu: CanvasLayer = %PauseMenu
@onready var completion_screen: CanvasLayer = %CompletionScreen
@onready var completion_time_label: Label = %CompletionTimeLabel
@onready var personal_best_label: Label = %PersonalBestLabel
@onready var new_record_label: Label = %NewRecordLabel
@export var save_path: String = "user://best_time.save"
var elapsed_time: float = 0.0
var timer_running: bool = true
var best_time: float = -1.0
var file: FileAccess

func format_time(time: float) -> String:
	var minutes: int = int(time / 60)
	var seconds: float = fmod(time, 60.0)
	return "%02d:%05.2f" % [minutes, seconds]
func _ready() -> void:
	load_best_time()


func _process(delta: float) -> void:
	timer(delta)
	timer_text()
	best_time_text()
	pause_game()
	restart_level()

func _on_finish_line_level_completed() -> void:
	if not timer_running:
		return
	timer_running = false
	timer_running = false
	completion_time_label.text = "Time: " + format_time(elapsed_time)
	if best_time == -1.0 or elapsed_time < best_time:
		best_time = elapsed_time
		save_best_time()
		new_record_label.visible = true
	else:
		new_record_label.visible = false
	personal_best_label.text = "Best: " + format_time(best_time)
	completion_screen.visible = true
	get_tree().paused = true

func timer(delta:float) -> void:
	if timer_running == true:
	
		elapsed_time = elapsed_time + delta

func timer_text() -> void:
	timer_label.text = format_time(elapsed_time)


func best_time_text() -> void:
	if best_time < 0:
		best_time_label.text = "Best: --:--.--"
	else:
		best_time_label.text = "Best: " + format_time(best_time)
func save_best_time() -> void:
	file = FileAccess.open(save_path, FileAccess.WRITE)
	if file != null:
		file.store_float(best_time)
		file.close()


func load_best_time() -> void:
	if FileAccess.file_exists(save_path):
		file = FileAccess.open(save_path, FileAccess.READ)
		if file != null:
			best_time = file.get_float()
			file.close()

func restart_level() -> void:
	if Input.is_action_just_pressed("Reset"):
		get_tree().reload_current_scene()

func pause_game() -> void:
	if timer_running and Input.is_action_just_pressed("Menu"):
		pause_menu.visible = true
		get_tree().paused = true


func _on_resume_pressed() -> void:
	pause_menu.visible = false
	get_tree().paused = false
	


func _on_restart_pressed() -> void:
	get_tree().paused = false
	pause_menu.visible = false
	get_tree().reload_current_scene()



func _on_level_select_pressed() -> void:
	get_tree().paused = false
	pause_menu.visible = false
	get_tree().change_scene_to_file("res://Scenes/Menus/level_select.tscn")


func _on_close_game_pressed() -> void:
	get_tree().quit()


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_level_select_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Menus/level_select.tscn")
