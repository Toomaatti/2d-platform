extends StaticBody2D

@export var disappear_delay: float = 1.0
@export var respawn_delay: float = 2.0

@onready var platform_visual: Polygon2D = $Polygon2D
@onready var platform_collision: CollisionShape2D = $CollisionShape2D
@onready var trigger: Area2D = $Trigger

var triggered: bool = false


func _ready() -> void:
	trigger.body_entered.connect(_on_trigger_body_entered)


func _on_trigger_body_entered(body: Node2D) -> void:
	print("Platform triggered!")
	print("Detected: ", body.name, " | Type: ", body.get_class())
	if not body is CharacterBody2D or triggered:
		return

	triggered = true

	await get_tree().create_timer(disappear_delay).timeout

	platform_collision.set_deferred("disabled", true)
	platform_visual.hide()

	await get_tree().create_timer(respawn_delay).timeout

	platform_visual.show()
	platform_collision.set_deferred("disabled", false)

	triggered = false
