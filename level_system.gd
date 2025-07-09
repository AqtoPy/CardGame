extends Node2D
class_name LevelSystem

# Ссылки на ноды
@onready var level_container = $LevelContainer
@onready var level_info = $LevelInfo
@onready var level_name_label = $LevelInfo/LevelName
@onready var level_description_label = $LevelInfo/LevelDescription
@onready var enemy_preview = $LevelInfo/EnemyPreview
@onready var start_button = $LevelInfo/StartButton

# Переменные
var levels = []
var current_level = 1
var max_unlocked_level = 1
var selected_level = 0
var player_character_id = 0

func _ready():
    $BackButton.pressed.connect(return_to_main_menu)
    start_button.pressed.connect(start_selected_level)
    load_levels()
    setup_level_buttons()

func load_levels():
    levels = [
        {
            "id": 1,
            "name": "Training Grounds",
            "description": "Basic training against weak opponents",
            "enemy_id": 10,
            "unlocked": true,
            "completed": false,
            "reward": {"exp": 50, "gold": 100}
        },
        {
            "id": 2,
            "name": "Forest Outpost",
            "description": "Defeat the forest guardians",
            "enemy_id": 15,
            "unlocked": false,
            "completed": false,
            "reward": {"exp": 75, "gold": 150}
        },
        # ... добавить остальные уровни
    ]

func setup_level_buttons():
    for child in level_container.get_children():
        child.queue_free()
    
    level_container.columns = 5
    
    for level in levels:
        var button = Button.new()
        button.text = "Level %d" % level["id"]
        button.disabled = not level["unlocked"]
        
        if level["completed"]:
            button.text += " ✓"
            button.add_theme_color_override("font_color", Color.GREEN)
        
        button.pressed.connect(show_level_info.bind(level["id"]))
        level_container.add_child(button)

func show_level_info(level_id: int):
    selected_level = level_id - 1
    var level = levels[selected_level]
    
    level_name_label.text = level["name"]
    level_description_label.text = level["description"]
    
    # Загрузка персонажа врага
    var enemy_path = "res://characters/character_%d.tres" % level["enemy_id"]
    if ResourceLoader.exists(enemy_path):
        enemy_preview.load_character(load(enemy_path))
    
    level_info.show()

func start_selected_level():
    if selected_level >= 0 and selected_level < levels.size():
        var level = levels[selected_level]
        var battle_scene = preload("res://battle_scene.tscn").instantiate()
        battle_scene.initialize_battle(player_character_id, level["enemy_id"], level["id"])
        get_parent().add_child(battle_scene)
        hide()

func unlock_next_level():
    if selected_level + 1 < levels.size():
        levels[selected_level + 1]["unlocked"] = true
        max_unlocked_level = max(max_unlocked_level, selected_level + 2)
        setup_level_buttons()

func complete_current_level():
    if selected_level >= 0 and selected_level < levels.size():
        levels[selected_level]["completed"] = true
        unlock_next_level()
        setup_level_buttons()

func return_to_main_menu():
    get_parent().return_to_main_menu()

func set_player_character(id: int):
    player_character_id = id

func get_level_progress():
    var completed = 0
    for level in levels:
        if level.get("completed", false):
            completed += 1
    
    return {
        "completed": completed,
        "total": levels.size(),
        "next_level": max_unlocked_level
    }
