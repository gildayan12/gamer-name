extends Resource
class_name ApparelItem

enum Slot { HEAD, CHEST, LEGS, FEET, ACCESSORY }

@export var id: String
@export var display_name: String
@export var texture: Texture2D
@export var slot: Slot
@export var price: int = 0
@export var is_starter: bool = false
@export var tint: Color = Color.WHITE
