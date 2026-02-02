extends Node

signal player_entered_base_station(base: Node2D, player: Node2D)
signal player_exited_base_station(base: Node2D, player: Node2D)

signal laser_damage_requested(target: Node2D, amount: float)
signal laser_impact_pulse_requested(target: Node2D)
