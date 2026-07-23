extends Node

# Centralized isotope data for all 14 decay chain isotopes
var isotopes = {
	"U-238": {
		"name": "Uranium-238",
		"mass_number": 238,
		"protons": 92,
		"neutrons": 146,
		"decay_type": "alpha",
		"next_isotope": "Th-234",
		"timer_range": [120, 180],  # 2-3 minutes
		"disk_radius": 70.0,
		"sprite_color": Color(0.2, 0.8, 0.3)  # green
	},
	"Th-234": {
		"name": "Thorium-234",
		"mass_number": 234,
		"protons": 90,
		"neutrons": 144,
		"decay_type": "beta",
		"next_isotope": "Pa-234",
		"timer_range": [90, 150],
		"disk_radius": 68.0,
		"sprite_color": Color(0.9, 0.5, 0.2)  # orange
	},
	"Pa-234": {
		"name": "Protactinium-234",
		"mass_number": 234,
		"protons": 91,
		"neutrons": 143,
		"decay_type": "beta",
		"next_isotope": "U-234",
		"timer_range": [60, 120],
		"disk_radius": 68.0,
		"sprite_color": Color(0.8, 0.3, 0.8)  # purple
	},
	"Pb-206": {
		"name": "Lead-206",
		"mass_number": 206,
		"protons": 82,
		"neutrons": 124,
		"decay_type": "stable",
		"next_isotope": null,
		"timer_range": [0, 0],
		"disk_radius": 50.0,
		"sprite_color": Color(0.6, 0.6, 0.7)  # silver/lead
	}
	# TODO: Add remaining 10 isotopes in later milestones
}

# Helper function to get isotope data
func get_isotope(isotope_key: String) -> Dictionary:
	if isotopes.has(isotope_key):
		return isotopes[isotope_key]
	else:
		push_error("Isotope not found: " + isotope_key)
		return {}

# Get nucleus count for an isotope
func get_nucleus_count(isotope_key: String) -> int:
	var data = get_isotope(isotope_key)
	if data.is_empty():
		return 6  # fallback
	return data.mass_number - 200

# Get proton count
func get_proton_count(isotope_key: String) -> int:
	var data = get_isotope(isotope_key)
	if data.is_empty():
		return 0
	return data.protons

# Get neutron count
func get_neutron_count(isotope_key: String) -> int:
	var data = get_isotope(isotope_key)
	if data.is_empty():
		return 0
	return data.neutrons
