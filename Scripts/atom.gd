extends Node2D

const NucleusScene = preload("res://Scenes/nucleus.tscn")

@export var isotope_key: String = "U-238"

var mass_number: int
var disk_radius: float
var isotope_name: String
var proton_tint: Color = Color(0.95, 0.25, 0.25)

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
	proton_tint = IsotopeData.get_proton_tint(isotope_key)
	
	print("Loaded isotope: ", isotope_name, " (", mass_number, ")")

func spawn_nuclei():
	var proton_count = IsotopeData.get_proton_count(isotope_key)
	var neutron_count = IsotopeData.get_neutron_count(isotope_key)
	var nucleus_count = proton_count + neutron_count - 200  # mass - 200
	var total_nucleons = proton_count + neutron_count
	var visible_protons = int(round(float(nucleus_count) * float(proton_count) / float(total_nucleons)))
	var visible_neutrons = nucleus_count - visible_protons
	
	print("Spawning ", nucleus_count, " nuclei: ", visible_protons, " proton visuals + ", visible_neutrons, " neutron visuals")
	
	# Get hexagonal grid positions
	var hex_positions = HexGrid.get_hex_positions(nucleus_count, Vector2.ZERO)

	# Build a mixed type list, then shuffle so protons/neutrons are spatially interleaved.
	const PROTON_TYPE := 0
	const NEUTRON_TYPE := 1
	var nucleus_types: Array[int] = []
	for i in range(visible_protons):
		nucleus_types.append(PROTON_TYPE)
	for i in range(visible_neutrons):
		nucleus_types.append(NEUTRON_TYPE)
	nucleus_types.shuffle()

	for i in range(nucleus_count):
		var nucleus = NucleusScene.instantiate()
		nucleus.position = hex_positions[i]
		nucleus.set_type(nucleus_types[i], proton_tint)
		add_child(nucleus)
