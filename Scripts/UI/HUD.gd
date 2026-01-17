extends CanvasLayer

@onready var dodge_bar: ProgressBar = %DodgeBar
@onready var ability_bar: ProgressBar = %AbilityBar
@onready var ult_bar: ProgressBar = %UltBar

func _ready() -> void:
    # Find player in group and connect signals
    var players = get_tree().get_nodes_in_group("player")
    if players.size() > 0:
        var player = players[0]
        if player.has_signal("cooldown_updated"):
            player.cooldown_updated.connect(update_cooldown)
        if player.has_signal("ultimate_updated"):
            player.ultimate_updated.connect(update_ult)

func update_cooldown(type: String, value: float) -> void:
    # Value is 0.0 (Ready) to 1.0 (Full cooldown)
    # We invert it for the bar (1.0 = Ready, 0.0 = Empty)
    var display_value = (1.0 - value) * 100
    
    match type:
        "dodge": dodge_bar.value = display_value
        "shroom": ability_bar.value = display_value # "Grenade"

func update_ult(value: float) -> void:
    # Value is 0-100
    ult_bar.value = value
