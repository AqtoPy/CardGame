extends Node2D
class_name BattleSystem

# Ссылки на ноды
@onready var player_character = $PlayerArea/CharacterDisplay
@onready var enemy_character = $EnemyArea/CharacterDisplay
@onready var player_hand = $PlayerArea/Hand
@onready var enemy_hand = $EnemyArea/Hand
@onready var player_deck_count = $PlayerArea/DeckCount
@onready var enemy_deck_count = $EnemyArea/DeckCount
@onready var player_discard_count = $PlayerArea/DiscardPile
@onready var enemy_discard_count = $EnemyArea/DiscardPile
@onready var battle_log = $BattleLog
@onready var end_turn_button = $EndTurnButton
@onready var battle_result = $BattleResult

# Переменные
var player_deck: Array[Card] = []
var enemy_deck: Array[Card] = []
var player_discard: Array[Card] = []
var enemy_discard: Array[Card] = []
var current_level: int = 1
var turn: int = 0
var game_state: String = "setup" # setup, player_turn, enemy_turn, ended

func _ready():
    end_turn_button.pressed.connect(end_turn)
    battle_result/ContinueButton.pressed.connect(close_battle)
    hide_battle_result()

func initialize_battle(player_char_id: int, enemy_char_id: int, level: int):
    current_level = level
    load_characters(player_char_id, enemy_char_id)
    create_decks()
    start_battle()

func load_characters(player_id: int, enemy_id: int):
    var player_path = "res://characters/character_%d.tres" % player_id
    var enemy_path = "res://characters/character_%d.tres" % enemy_id
    
    if ResourceLoader.exists(player_path):
        player_character.load_character(load(player_path))
    
    if ResourceLoader.exists(enemy_path):
        enemy_character.load_character(load(enemy_path))

func create_decks():
    # Очищаем колоды
    player_deck.clear()
    enemy_deck.clear()
    player_discard.clear()
    enemy_discard.clear()
    
    # Создаем базовые колоды
    for i in range(20):
        var player_card = create_card_for_character(player_character.class_type)
        var enemy_card = create_card_for_character(enemy_character.class_type)
        player_deck.append(player_card)
        enemy_deck.append(enemy_card)
    
    player_deck.shuffle()
    enemy_deck.shuffle()
    update_deck_counts()

func create_card_for_character(class_type: String) -> Card:
    var card = preload("res://card_scene.tscn").instantiate()
    
    match class_type:
        "warrior":
            card.card_name = "Warrior Card"
            card.attack = randi_range(2, 4)
            card.health = randi_range(3, 5)
        "mage":
            card.card_name = "Mage Card"
            card.attack = randi_range(3, 5)
            card.health = randi_range(1, 3)
            if randf() > 0.7:
                card.abilities.append("spell")
        "rogue":
            card.card_name = "Rogue Card"
            card.attack = randi_range(1, 4)
            card.health = randi_range(2, 3)
            if randf() > 0.5:
                card.abilities.append("quick")
        _:
            card.card_name = "Basic Card"
            card.attack = randi_range(1, 3)
            card.health = randi_range(1, 3)
    
    card.cost = max(1, floor((card.attack + card.health) / 3))
    return card

func start_battle():
    game_state = "setup"
    turn = 0
    battle_log.text = "Battle started!\n"
    
    # Раздача начальных карт
    draw_cards(player_hand, player_deck, 3)
    draw_cards(enemy_hand, enemy_deck, 3)
    
    game_state = "player_turn"
    log_message("Your turn starts")

func draw_cards(hand: Node2D, deck: Array, count: int):
    for i in range(count):
        if deck.size() == 0:
            reshuffle_discard(deck == player_deck)
            if deck.size() == 0:
                break
        
        var card = deck.pop_back()
        hand.add_child(card)
        card.position = Vector2(i * 120, 0)
        card.card_played.connect(_on_card_played.bind(card, deck == player_deck))
    
    update_deck_counts()

func reshuffle_discard(is_player: bool):
    if is_player:
        player_deck = player_discard.duplicate()
        player_deck.shuffle()
        player_discard.clear()
        log_message("Player reshuffled discard pile into deck")
    else:
        enemy_deck = enemy_discard.duplicate()
        enemy_deck.shuffle()
        enemy_discard.clear()
        log_message("Enemy reshuffled discard pile into deck")

func update_deck_counts():
    player_deck_count.text = "Deck: %d" % player_deck.size()
    enemy_deck_count.text = "Deck: %d" % enemy_deck.size()
    player_discard_count.text = "Discard: %d" % player_discard.size()
    enemy_discard_count.text = "Discard: %d" % enemy_discard.size()

func _on_card_played(card: Card, is_player: bool):
    if (is_player and game_state != "player_turn") or (!is_player and game_state != "enemy_turn"):
        return
    
    var target = enemy_character if is_player else player_character
    var attacker = player_character if is_player else enemy_character
    
    # Применяем карту
    card.play_card(target)
    log_message("%s plays %s" % [attacker.character_name, card.card_name])
    
    # Перемещаем карту в сброс
    if is_player:
        player_discard.append(card)
    else:
        enemy_discard.append(card)
    
    card.queue_free()
    
    # Проверяем смерть персонажа
    check_character_death()

func check_character_death():
    if player_character.current_health <= 0:
        end_battle(false)
    elif enemy_character.current_health <= 0:
        end_battle(true)

func end_turn():
    if game_state != "player_turn":
        return
    
    game_state = "enemy_turn"
    log_message("Enemy turn starts")
    
    # Ход врага (простая ИИ)
    await get_tree().create_timer(1.0).timeout
    
    for card in enemy_hand.get_children():
        _on_card_played(card, false)
        await get_tree().create_timer(0.5).timeout
    
    # Завершение хода врага
    game_state = "player_turn"
    turn += 1
    
    # Раздача карт
    draw_cards(player_hand, player_deck, 1)
    draw_cards(enemy_hand, enemy_deck, 1)
    
    log_message("Your turn starts")

func end_battle(victory: bool):
    game_state = "ended"
    end_turn_button.disabled = true
    
    var reward = calculate_reward(victory)
    show_battle_result(victory, reward)
    
    if victory:
        player_character.add_experience(reward["exp"])
        log_message("Victory! Gained %d exp and %d gold" % [reward["exp"], reward["gold"]])
    else:
        log_message("Defeat! Try again")

func calculate_reward(victory: bool) -> Dictionary:
    var reward = {
        "exp": current_level * 50,
        "gold": current_level * 30
    }
    
    if victory:
        reward["exp"] *= 2
        reward["gold"] *= 1.5
    
    return reward

func show_battle_result(victory: bool, reward: Dictionary):
    battle_result/Label.text = "Victory!" if victory else "Defeat!"
    battle_result/RewardLabel.text = "Reward:\n%d EXP\n%d Gold" % [reward["exp"], reward["gold"]]
    battle_result.show()

func hide_battle_result():
    battle_result.hide()

func close_battle():
    get_parent().finish_battle(enemy_character.current_health <= 0, calculate_reward(enemy_character.current_health <= 0))

func log_message(message: String):
    battle_log.text += message + "\n"
    battle_log.scroll_vertical = battle_log.get_line_count()
