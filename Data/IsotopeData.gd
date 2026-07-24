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
		"sprite_color": Color(0.2, 0.8, 0.3),  # green
		"proton_tint": Color(0.95, 0.25, 0.25)  # red
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
		"sprite_color": Color(0.9, 0.5, 0.2),  # orange
		"proton_tint": Color(1.0, 0.45, 0.2)  # orange-red
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
		"sprite_color": Color(0.8, 0.3, 0.8),  # purple
		"proton_tint": Color(0.95, 0.35, 0.8)  # magenta
	},
	"U-234": {
		"name": "Uranium-234",
		"mass_number": 234,
		"protons": 92,
		"neutrons": 142,
		"decay_type": "alpha",
		"next_isotope": "Th-230",
		"timer_range": [100, 140],
		"disk_radius": 68.0,
		"sprite_color": Color(0.3, 0.7, 0.4),  # darker green
		"proton_tint": Color(0.9, 0.3, 0.3)  # dark red
	},
	"Th-230": {
		"name": "Thorium-230",
		"mass_number": 230,
		"protons": 90,
		"neutrons": 140,
		"decay_type": "alpha",
		"next_isotope": "Ra-226",
		"timer_range": [80, 130],
		"disk_radius": 66.0,
		"sprite_color": Color(0.85, 0.6, 0.25),  # warm orange
		"proton_tint": Color(0.95, 0.5, 0.25)  # bright orange
	},
	"Ra-226": {
		"name": "Radium-226",
		"mass_number": 226,
		"protons": 88,
		"neutrons": 138,
		"decay_type": "alpha",
		"next_isotope": "Rn-222",
		"timer_range": [70, 110],
		"disk_radius": 64.0,
		"sprite_color": Color(0.3, 0.9, 0.6),  # bright cyan-green
		"proton_tint": Color(0.4, 0.95, 0.7)  # bright teal
	},
	"Rn-222": {
		"name": "Radon-222",
		"mass_number": 222,
		"protons": 86,
		"neutrons": 136,
		"decay_type": "alpha",
		"next_isotope": "Po-218",
		"timer_range": [50, 90],
		"disk_radius": 62.0,
		"sprite_color": Color(0.5, 0.5, 0.9),  # light blue (gas)
		"proton_tint": Color(0.6, 0.6, 0.95)  # pale blue
	},
	"Po-218": {
		"name": "Polonium-218",
		"mass_number": 218,
		"protons": 84,
		"neutrons": 134,
		"decay_type": "alpha",
		"next_isotope": "Pb-214",
		"timer_range": [30, 60],  # shorter timer
		"disk_radius": 60.0,
		"sprite_color": Color(0.9, 0.9, 0.3),  # yellow
		"proton_tint": Color(0.95, 0.95, 0.4)  # bright yellow
	},
	"Pb-214": {
		"name": "Lead-214",
		"mass_number": 214,
		"protons": 82,
		"neutrons": 132,
		"decay_type": "beta",
		"next_isotope": "Bi-214",
		"timer_range": [40, 80],
		"disk_radius": 58.0,
		"sprite_color": Color(0.65, 0.65, 0.75),  # light lead
		"proton_tint": Color(0.75, 0.6, 0.4)  # tan
	},
	"Bi-214": {
		"name": "Bismuth-214",
		"mass_number": 214,
		"protons": 83,
		"neutrons": 131,
		"decay_type": "beta",
		"next_isotope": "Po-214",
		"timer_range": [35, 70],
		"disk_radius": 58.0,
		"sprite_color": Color(0.9, 0.4, 0.6),  # pink
		"proton_tint": Color(0.95, 0.5, 0.65)  # bright pink
	},
	"Po-214": {
		"name": "Polonium-214",
		"mass_number": 214,
		"protons": 84,
		"neutrons": 130,
		"decay_type": "alpha",
		"next_isotope": "Pb-210",
		"timer_range": [20, 50],  # very short timer
		"disk_radius": 58.0,
		"sprite_color": Color(0.95, 0.85, 0.2),  # bright yellow
		"proton_tint": Color(1.0, 0.9, 0.3)  # intense yellow
	},
	"Pb-210": {
		"name": "Lead-210",
		"mass_number": 210,
		"protons": 82,
		"neutrons": 128,
		"decay_type": "beta",
		"next_isotope": "Bi-210",
		"timer_range": [60, 100],
		"disk_radius": 56.0,
		"sprite_color": Color(0.7, 0.7, 0.8),  # medium lead
		"proton_tint": Color(0.8, 0.6, 0.45)  # brown
	},
	"Bi-210": {
		"name": "Bismuth-210",
		"mass_number": 210,
		"protons": 83,
		"neutrons": 127,
		"decay_type": "beta",
		"next_isotope": "Po-210",
		"timer_range": [50, 90],
		"disk_radius": 56.0,
		"sprite_color": Color(0.85, 0.5, 0.7),  # lighter pink
		"proton_tint": Color(0.9, 0.6, 0.75)  # soft pink
	},
	"Po-210": {
		"name": "Polonium-210",
		"mass_number": 210,
		"protons": 84,
		"neutrons": 126,
		"decay_type": "alpha",
		"next_isotope": "Pb-206",
		"timer_range": [40, 80],
		"disk_radius": 56.0,
		"sprite_color": Color(1.0, 0.8, 0.1),  # gold/yellow
		"proton_tint": Color(1.0, 0.85, 0.2)  # golden
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
		"sprite_color": Color(0.6, 0.6, 0.7),  # silver/lead
		"proton_tint": Color(0.8, 0.55, 0.35)  # warm brown
	}
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

# Get proton fill tint color for an isotope
func get_proton_tint(isotope_key: String) -> Color:
	var data = get_isotope(isotope_key)
	if data.is_empty() or not data.has("proton_tint"):
		return Color(0.95, 0.25, 0.25)
	return data.proton_tint
