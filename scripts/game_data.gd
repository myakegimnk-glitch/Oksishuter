extends Node

var money: int = 0
var total_kills: int = 0
var highest_wave: int = 0

func add_money(amount: int) -> void:
	money += amount

func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		return true
	return false

func reset_for_new_game() -> void:
	total_kills = 0
