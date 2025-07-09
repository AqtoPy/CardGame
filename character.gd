extends Node2D
class_name Character

# Экспортируемые переменные
@export var character_name: String = "Hero"
@export var class_type: String = "warrior"
@export var base_health: int = 50
@export var base_attack: int = 10
@export var abilities: Array[String] = ["basic_attack"]
@export var unlock_cost: int = 100
@export var is_unlocked: bool = false
@export var level: int = 1
@export var experience: int = 0

# Ссылки на ноды
@onready var name_label: Label = $NameLabel
@onready var class_label: Label = $ClassLabel
@onready var health_label: Label = $HealthLabel
@onready var attack_label: Label = $AttackLabel
@onready var level_label: Label = $LevelLabel
@onready var abilities_label: Label = $AbilitiesLabel

# Вычисляемые свойства
var current_health: int:
    get:
        return base_health + (level - 1) * 10

var current_attack: int:
    get:
        return base_attack + (level - 1) * 3

func _ready():
    update_character_display()

func update_character_display():
    name_label.text = character_name
    class_label.text = "Class: %s" % class_type.capitalize()
    health_label.text = "HP: %d/%d" % [current_health, base_health + (max_level - 1) * 10]
    attack_label.text = "ATK: %d" % current_attack
    level_label.text = "Level: %d" % level
    abilities_label.text = "Abilities: %s" % ", ".join(abilities)

func add_experience(amount: int) -> bool:
    experience += amount
    if experience >= get_required_exp():
        return level_up()
    update_character_display()
    return false

func get_required_exp() -> int:
    return level * 100 + (level * level * 10)

func level_up() -> bool:
    if level < max_level:
        level += 1
        experience = 0
        
        # Добавляем новую способность каждые 3 уровня
        if level % 3 == 0:
            var new_ability = get_new_ability_for_level()
            if new_ability:
                abilities.append(new_ability)
        
        update_character_display()
        return true
    return false

func get_new_ability_for_level() -> String:
    var class_abilities = {
        "warrior": ["cleave", "shield_bash", "berserk"],
        "mage": ["fireball", "frost_nova", "arcane_intellect"],
        "rogue": ["backstab", "poison", "stealth"],
        "archer": ["multi_shot", "aimed_shot", "rapid_fire"],
        "healer": ["heal", "renew", "divine_shield"],
        "tank": ["taunt", "shield_block", "last_stand"]
    }
    
    if class_abilities.has(class_type):
        var available_abilities = class_abilities[class_type]
        for ability in available_abilities:
            if not ability in abilities:
                return ability
    return ""

func use_ability(ability_index: int, target = null) -> bool:
    if ability_index < 0 or ability_index >= abilities.size():
        return false
    
    var ability = abilities[ability_index]
    
    match ability:
        "basic_attack":
            if target:
                target.take_damage(current_attack)
                print("%s uses basic attack on %s!" % [character_name, target.character_name])
            return true
        
        "fireball":
            if target:
                target.take_damage(current_attack * 1.5)
                print("%s casts fireball on %s!" % [character_name, target.character_name])
            return true
        
        "heal":
            if target:
                target.heal(current_attack * 0.8)
                print("%s heals %s!" % [character_name, target.character_name])
            return true
        
        "cleave":
            # Нужно реализовать логику для нескольких целей
            print("%s uses cleave!" % character_name)
            return true
        
        _:
            print("%s tries to use unknown ability: %s" % [character_name, ability])
            return false

func take_damage(amount: int):
    current_health -= amount
    if current_health <= 0:
        die()
    update_character_display()

func heal(amount: int):
    current_health = min(current_health + amount, base_health + (level - 1) * 10)
    update_character_display()

func die():
    print("%s has been defeated!" % character_name)
    queue_free()

func unlock():
    is_unlocked = true
    print("%s has been unlocked!" % character_name)

func duplicate_character() -> Character:
    var new_char = Character.new()
    new_char.character_name = character_name
    new_char.class_type = class_type
    new_char.base_health = base_health
    new_char.base_attack = base_attack
    new_char.abilities = abilities.duplicate()
    new_char.unlock_cost = unlock_cost
    new_char.is_unlocked = is_unlocked
    new_char.level = level
    new_char.experience = experience
    return new_char
