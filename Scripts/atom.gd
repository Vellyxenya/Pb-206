extends Node2D

const NucleusScene = preload("res://Scenes/nucleus.tscn")

@export var isotope_key: String = "U-238"

var mass_number: int
var disk_radius: float
var isotope_name: String

func _ready():
	load_isotope_data()
	spawn_nuclei()

func load_isotope_data():
	var data = IsotopeData.get_isotope(isotope_key)
	if data.is_empty():
		push_error("Failed to load isotope: " + isotope_key)
		return
	
	isotope_name = data.name
	mass_number = data.mass_number
	disk_radius = data.disk_radius
	
	print("Loaded isotope: ", isotope_name, " (", mass_number, ")")

func spawn_nuclei():
	var proton_count = IsotopeData.get_proton_count(isotope_key)
	var neutron_count = IsotopeData.get_neutron_count(isotope_key)
	var nucleus_count = proton_count + neutron_count - 200  # mass - 200
	
	print("Spawning ", proton_count, " protons + ", neutron_count, " neutrons")
	
	# Get hexagonal grid positions
	var hex_positions = HexGrid.get_hex_positions(nucleus_count, Vector2.ZERO)
	
	var nuclei_spawned = 0
	
	# Spawn protons first
	for i in range(proton_count):
		if nuclei_spawned >= nucleus_count:
			break
		var nucleus = NucleusScene.instantiate()
		nucleus.position = hex_positions[nuclei_spawned]
		nucleus.set_type(nucleus.NucleusType.PROTON)
		add_child(nucleus)
		nuclei_spawned += 1
	
	# Then spawn neutrons
	for i in range(neutron_count):
		if nuclei_spawned >= nucleus_count:
			break
		var nucleus = NucleusScene.instantiate()
		nucleus.position = hex_positions[nuclei_spawned]
		nucleus.set_type(nucleus.NucleusType.NEUTRON)
		add_child(nucleus)
		nuclei_spawned += 1
