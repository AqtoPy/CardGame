extends Node2D
class_name Deck

# Экспортируемые переменные
@export var deck_name: String = "Default Deck"
@export var max_cards: int = 30
@export var character_id: int = 0

# Ссылки на ноды
@onready var name_label: Label = $Panel/NameLabel
@onready var count_label: Label = $Panel/CountLabel
@onready var card_container: Node2D = $CardContainer
@onready var shuffle_button: Button = $ShuffleButton

# Переменные
var cards: Array[Card] = []
var character: Character = null
var selected_card: Card = null

func _ready():
    shuffle_button.pressed.connect(_on_shuffle_pressed)
    initialize(character_id)

func initialize(char_id: int):
    character_id = char_id
    load_character()
    create_starting_deck()
    update_display()

func load_character():
    var path = "res://characters/character_%d.tres" % character_id
    if ResourceLoader.exists(path):
        character = load(path)
        deck_name = "%s's Deck" % character.character_name

func create_starting_deck():
    cards.clear()
    
    # Базовые карты
    for i in range(15):
        var card = create_basic_card()
        cards.append(card)
    
    # Классовые карты
    if character:
        for i in range(5):
            var card = create_class_card(character.class_type)
            cards.append(card)
    
    shuffle()

func create_basic_card() -> Card:
    var card = preload("res://card_scene.tscn").instantiate()
    card.card_name = "Basic Card"
    card.attack = randi_range(1, 3)
    card.health = randi_range(1, 3)
    card.cost = max(1, floor((card.attack + card.health) / 2))
    return card

func create_class_card(class_type: String) -> Card:
    var card = preload("res://card_scene.tscn").instantiate()
    
    match class_type:
        "warrior":
            card.card_name = "Warrior's Strike"
            card.attack = randi_range(3, 5)
            card.health = randi_range(2, 4)
            card.abilities = ["cleave"]
        "mage":
            card.card_name = "Magic Bolt"
            card.attack = randi_range(2, 4)
            card.health = randi_range(1, 3)
            card.abilities = ["spell_damage"]
        "rogue":
            card.card_name = "Poison Dagger"
            card.attack = randi_range(1, 3)
            card.health = randi_range(1, 3)
            card.abilities = ["poison"]
        _:
            card.card_name = "Class Card"
            card.attack = randi_range(2, 4)
            card.health = randi_range(2, 4)
    
    card.cost = max(1, floor((card.attack + card.health) / 2))
    return card

func shuffle():
    cards.shuffle()
    update_display()
    print("Deck shuffled")

func draw_card() -> Card:
    if cards.size() > 0:
        var card = cards.pop_back()
        update_display()
        return card
    return null

func add_card(card: Card):
    if cards.size() < max_cards:
        cards.append(card)
        update_display()
        return true
    return false

func remove_card(card_index: int) -> Card:
    if card_index >= 0 and card_index < cards.size():
        var card = cards.pop_at(card_index)
        update_display()
        return card
    return null

func update_display():
    name_label.text = deck_name
    count_label.text = "Cards: %d/%d" % [cards.size(), max_cards]
    
    # Очищаем контейнер и отображаем верхние 5 карт
    for child in card_container.get_children():
        child.queue_free()
    
    for i in range(min(5, cards.size())):
        var card = cards[cards.size() - 1 - i].duplicate_card()
        card.position = Vector2(i * 50, 0)
        card.scale = Vector2(0.5, 0.5)
        card_container.add_child(card)

func _on_shuffle_pressed():
    shuffle()

func get_card_list() -> Array:
    return cards.duplicate()

func save_deck():
    var save_data = {
        "deck_name": deck_name,
        "character_id": character_id,
        "cards": []
    }
    
    for card in cards:
        save_data["cards"].append({
            "name": card.card_name,
            "attack": card.attack,
            "health": card.health,
            "cost": card.cost,
            "abilities": card.abilities,
            "level": card.level
        })
    
    return save_data

func load_deck(save_data: Dictionary):
    deck_name = save_data.get("deck_name", "Default Deck")
    character_id = save_data.get("character_id", 0)
    load_character()
    
    cards.clear()
    for card_data in save_data.get("cards", []):
        var card = preload("res://card_scene.tscn").instantiate()
        card.card_name = card_data.get("name", "Card")
        card.attack = card_data.get("attack", 1)
        card.health = card_data.get("health", 1)
        card.cost = card_data.get("cost", 1)
        card.abilities = card_data.get("abilities", [])
        card.level = card_data.get("level", 1)
        cards.append(card)
    
    update_display()
