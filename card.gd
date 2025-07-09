extends Node2D
class_name Card

# Экспортируемые переменные
@export var card_name: String = "Card"
@export var attack: int = 1
@export var health: int = 1
@export var cost: int = 1
@export var abilities: Array[String] = []
@export var level: int = 1
@export var experience: int = 0
@export var max_level: int = 10
@export var upgrade_cost: int = 50

# Ссылки на ноды
@onready var name_label: Label = $NameLabel
@onready var attack_label: Label = $AttackLabel
@onready var health_label: Label = $HealthLabel
@onready var abilities_label: Label = $AbilitiesLabel

func _ready():
    update_card_display()

func update_card_display():
    name_label.text = "%s (Lvl %d)" % [card_name, level]
    attack_label.text = "ATK: %d" % attack
    health_label.text = "HP: %d" % health
    abilities_label.text = "Abilities: %s" % ", ".join(abilities)

func add_experience(amount: int):
    experience += amount
    if experience >= get_required_exp():
        level_up()

func get_required_exp() -> int:
    return level * 100

func level_up():
    if level < max_level:
        level += 1
        experience = 0
        attack += 1
        health += 2
        update_card_display()
        return true
    return false

func use_ability(target):
    for ability in abilities:
        match ability:
            "heal":
                target.health += 5
                print("%s uses heal!" % card_name)
            "poison":
                target.add_status("poison", 3)
                print("%s poisons the target!" % card_name)
            "double_attack":
                target.health -= attack * 2
                print("%s attacks twice!" % card_name)
            _:
                print("%s uses unknown ability: %s" % [card_name, ability])

func play_card(target):
    target.health -= attack
    if abilities.size() > 0:
        use_ability(target)
    print("%s played against target!" % card_name)

func duplicate_card() -> Card:
    var new_card = Card.new()
    new_card.card_name = card_name
    new_card.attack = attack
    new_card.health = health
    new_card.cost = cost
    new_card.abilities = abilities.duplicate()
    new_card.level = level
    new_card.experience = experience
    new_card.max_level = max_level
    new_card.upgrade_cost = upgrade_cost
    return new_card
