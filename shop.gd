extends Node2D
class_name Shop

# Экспортируемые переменные
@export var characters_per_row: int = 5
@export var cards_per_row: int = 6
@export var character_scene: PackedScene = preload("res://character_scene.tscn")
@export var card_scene: PackedScene = preload("res://card_scene.tscn")

# Ссылки на ноды
@onready var gold_label: Label = $Panel/GoldLabel
@onready var characters_grid: GridContainer = $Panel/TabContainer/Characters/ScrollContainer/GridContainer
@onready var cards_grid: GridContainer = $Panel/TabContainer/Cards/ScrollContainer/GridContainer
@onready var chests_container: VBoxContainer = $Panel/TabContainer/Chests/ScrollContainer/VBoxContainer
@onready var purchase_dialog: PopupPanel = $PurchaseDialog
@onready var dialog_text: Label = $PurchaseDialog/Label

# Переменные
var player_gold: int = 1000
var available_characters: Array[Character] = []
var available_cards: Array[Card] = []
var current_purchase: Dictionary = {}
var chest_types = {
    "common": {"price": 100, "cards": 5, "rare_chance": 0.1},
    "rare": {"price": 300, "cards": 10, "rare_chance": 0.3},
    "epic": {"price": 500, "cards": 15, "rare_chance": 0.5}
}

func _ready():
    load_available_items()
    update_gold_display()
    setup_shop_tabs()
    $Panel/CloseButton.pressed.connect(hide)
    $PurchaseDialog/YesButton.pressed.connect(confirm_purchase)
    $PurchaseDialog/NoButton.pressed.connect(cancel_purchase)

func load_available_items():
    # Загрузка персонажей
    for i in range(101):
        var path = "res://characters/character_%d.tres" % i
        if ResourceLoader.exists(path):
            var character = load(path)
            available_characters.append(character)
    
    # Создание карт для продажи
    for i in range(50):
        var card = card_scene.instantiate()
        card.card_name = "Card %d" % (i + 1)
        card.attack = randi_range(1, 5)
        card.health = randi_range(1, 5)
        card.cost = max(1, floor((card.attack + card.health) / 2))
        
        if i % 5 == 0:
            card.abilities.append("special")
        
        available_cards.append(card)

func update_gold_display():
    gold_label.text = "Gold: %d" % player_gold

func setup_shop_tabs():
    setup_characters_tab()
    setup_cards_tab()
    setup_chests_tab()

func setup_characters_tab():
    for child in characters_grid.get_children():
        child.queue_free()
    
    characters_grid.columns = characters_per_row
    
    for character in available_characters:
        var char_node = character_scene.instantiate()
        char_node.character_name = character.character_name
        char_node.class_type = character.class_type
        char_node.base_health = character.base_health
        char_node.base_attack = character.base_attack
        char_node.level = character.level
        char_node.scale = Vector2(0.7, 0.7)
        
        var button = Button.new()
        button.text = "Buy (%d gold)" % character.unlock_cost
        button.disabled = character.is_unlocked
        button.pressed.connect(_on_character_purchase.bind(character))
        
        var container = VBoxContainer.new()
        container.add_child(char_node)
        container.add_child(button)
        characters_grid.add_child(container)

func setup_cards_tab():
    for child in cards_grid.get_children():
        child.queue_free()
    
    cards_grid.columns = cards_per_row
    
    for card in available_cards:
        var card_node = card_scene.instantiate()
        card_node.card_name = card.card_name
        card_node.attack = card.attack
        card_node.health = card.health
        card_node.cost = card.cost
        card_node.abilities = card.abilities
        card_node.scale = Vector2(0.5, 0.5)
        
        var price = max(10, card.attack * 2 + card.health * 2)
        var button = Button.new()
        button.text = "Buy (%d gold)" % price
        button.pressed.connect(_on_card_purchase.bind(card, price))
        
        var container = VBoxContainer.new()
        container.add_child(card_node)
        container.add_child(button)
        cards_grid.add_child(container)

func setup_chests_tab():
    for child in chests_container.get_children():
        child.queue_free()
    
    for chest_type in chest_types:
        var hbox = HBoxContainer.new()
        
        var label = Label.new()
        label.text = "%s Chest" % chest_type.capitalize()
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        
        var price_label = Label.new()
        price_label.text = "%d gold" % chest_types[chest_type]["price"]
        
        var button = Button.new()
        button.text = "Buy"
        button.pressed.connect(_on_chest_purchase.bind(chest_type))
        
        hbox.add_child(label)
        hbox.add_child(price_label)
        hbox.add_child(button)
        chests_container.add_child(hbox)

func _on_character_purchase(character: Character):
    current_purchase = {
        "type": "character",
        "item": character,
        "price": character.unlock_cost
    }
    show_purchase_dialog("Buy %s for %d gold?" % [character.character_name, character.unlock_cost])

func _on_card_purchase(card: Card, price: int):
    current_purchase = {
        "type": "card",
        "item": card,
        "price": price
    }
    show_purchase_dialog("Buy %s for %d gold?" % [card.card_name, price])

func _on_chest_purchase(chest_type: String):
    current_purchase = {
        "type": "chest",
        "item": chest_type,
        "price": chest_types[chest_type]["price"]
    }
    show_purchase_dialog("Buy %s Chest for %d gold?" % [chest_type.capitalize(), chest_types[chest_type]["price"]])

func show_purchase_dialog(text: String):
    dialog_text.text = text
    purchase_dialog.popup_centered()

func confirm_purchase():
    if player_gold >= current_purchase["price"]:
        player_gold -= current_purchase["price"]
        update_gold_display()
        
        match current_purchase["type"]:
            "character":
                current_purchase["item"].is_unlocked = true
                print("Character unlocked: ", current_purchase["item"].character_name)
                setup_characters_tab()
            
            "card":
                var new_card = current_purchase["item"].duplicate_card()
                # Здесь нужно добавить карту в коллекцию игрока
                print("Card purchased: ", new_card.card_name)
            
            "chest":
                var cards = generate_chest_cards(current_purchase["item"])
                # Здесь нужно добавить карты в коллекцию игрока
                print("Chest opened! Got %d cards" % cards.size())
        
        purchase_dialog.hide()
    else:
        dialog_text.text = "Not enough gold!"
        await get_tree().create_timer(2.0).timeout
        purchase_dialog.hide()

func cancel_purchase():
    current_purchase = {}
    purchase_dialog.hide()

func generate_chest_cards(chest_type: String) -> Array[Card]:
    var cards: Array[Card] = []
    var chest_data = chest_types[chest_type]
    
    for i in range(chest_data["cards"]):
        var card = card_scene.instantiate()
        
        if randf() < chest_data["rare_chance"]:
            # Редкая карта
            card.card_name = "Rare Card %d" % (i + 1)
            card.attack = randi_range(3, 7)
            card.health = randi_range(3, 7)
            card.abilities = ["special"]
        else:
            # Обычная карта
            card.card_name = "Card %d" % (i + 1)
            card.attack = randi_range(1, 5)
            card.health = randi_range(1, 5)
        
        card.cost = max(1, floor((card.attack + card.health) / 2))
        cards.append(card)
    
    return cards

func add_gold(amount: int):
    player_gold += amount
    update_gold_display()

func show_shop():
    show()
    update_gold_display()
    setup_shop_tabs()
