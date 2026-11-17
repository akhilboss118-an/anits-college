extends Node
## Player profile, progression and run state.
## Mirrors the original's localStorage keys: anits-profile / anits-unlocked /
## anits-items (see js/menu.js and js/inventory.js).

const MAX_DAYS := 10
const START_WALLET := 200
const START_BANK := 2000
const START_ENERGY := 40
const MAX_ENERGY := 100
const FEE := 250
const FOODIE_ITEM := "foodie"

var profile: Dictionary = {}          ## {name, char, year}
var unlocked_day: int = 1
var items: Dictionary = {}            ## {id: true, fee: true, lib: true}
var drinks_tried: Dictionary = {}     ## {drink_id: true}

var wallet: int = START_WALLET
var bank: int = START_BANK
var energy: float = START_ENERGY
var boost_seconds: float = 0.0

var current_day: int = 1
var is_girl: bool = false
var uniform_year: int = 2024


func _ready() -> void:
	if profile.is_empty():
		profile = {"name": "Player", "char": "boy", "year": 2024}
	is_girl = profile.get("char", "boy") == "girl"
	uniform_year = int(profile.get("year", 2024))


func reset_progress() -> void:
	unlocked_day = 1
	items.clear()
	drinks_tried.clear()
	wallet = START_WALLET
	bank = START_BANK
	energy = START_ENERGY
	boost_seconds = 0.0
	current_day = 1
	_save_items()


func unlock(day: int) -> void:
	if day + 1 > unlocked_day and day < MAX_DAYS:
		unlocked_day = day + 1
	unlocked_day = clampi(unlocked_day, 1, MAX_DAYS)


func give_item(item_id: String) -> bool:
	if items.has(item_id):
		return false
	items[item_id] = true
	EventBus.item_gained.emit(item_id)
	_save_items()
	return true


## Documents are part of the profile: they must survive a restart so a player
## who resumes on Day 4 still carries the ID card, fee receipt and library card.
func _save_items() -> void:
	var ss: Node = get_node_or_null("/root/SaveSystem")
	if ss and ss.has_method("save_items"):
		ss.save_items(items)


func has_item(item_id: String) -> bool:
	return items.has(item_id)


func try_drink(drink_id: String) -> void:
	var is_new := not drinks_tried.has(drink_id)
	drinks_tried[drink_id] = true
	EventBus.drinks_tried_changed.emit(drinks_tried.size(), 10)
	# Ten distinct drinks is the canteen collection: the reward is a permanent
	# badge in the student bag, not a stat change, so balance is untouched.
	if is_new and drinks_tried.size() >= 10 and not items.has(FOODIE_ITEM):
		give_item(FOODIE_ITEM)
		EventBus.foodie_unlocked.emit()


func drinks_tried_count() -> int:
	return drinks_tried.size()


func can_afford(amount: int) -> bool:
	return wallet >= amount


func spend(amount: int) -> bool:
	if wallet < amount:
		return false
	wallet -= amount
	EventBus.wallet_changed.emit(wallet, bank)
	return true


func deposit(amount: int) -> bool:
	if bank < amount:
		return false
	bank -= amount
	wallet += amount
	EventBus.wallet_changed.emit(wallet, bank)
	return true


func add_energy(amount: float) -> void:
	energy = clampf(energy + amount, 0.0, float(MAX_ENERGY))
	EventBus.energy_changed.emit(energy)


## Sprinting burns energy. Emits `energy_depleted` only on the crossing to
## zero, so the HUD can react once rather than every frame.
func drain_energy(amount: float) -> void:
	if amount <= 0.0:
		return
	var before := energy
	var shown_before := int(round(energy))
	energy = maxf(0.0, energy - amount)
	# Sprinting drains every physics frame; only tell the HUD when the whole
	# number changes, so it does not restart its bar tween 60 times a second.
	if int(round(energy)) != shown_before:
		EventBus.energy_changed.emit(energy)
	if before > 0.0 and energy <= 0.0:
		EventBus.energy_depleted.emit()


func start_boost(seconds: float) -> void:
	boost_seconds = seconds
	EventBus.boost_changed.emit(boost_seconds)


func tick_boost(delta: float) -> void:
	if boost_seconds <= 0.0:
		return
	boost_seconds = maxf(0.0, boost_seconds - delta)
	EventBus.boost_changed.emit(boost_seconds)


func boost_multiplier() -> float:
	return 1.3 if boost_seconds > 0.0 else 1.0
