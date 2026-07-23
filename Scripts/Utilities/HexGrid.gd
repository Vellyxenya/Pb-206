class_name HexGrid

static var HEX_RADIUS := 22.0  # Distance between hex centers

# Convert axial hex coordinates to pixel position (pointy-top orientation)
static func hex_to_pixel(q: int, r: int) -> Vector2:
	var x = HEX_RADIUS * sqrt(3.0) * (q + r * 0.5)
	var y = HEX_RADIUS * 1.5 * r
	return Vector2(x, y)

# Get N positions in hexagonal pattern, concentric around (0,0).
# Generates a large candidate grid, sorts by distance, takes closest N.
static func get_hex_positions(count: int, center: Vector2 = Vector2.ZERO) -> Array[Vector2]:
	var candidates: Array[Vector2] = []
	var grid_size := 7  # Covers up to ring 4 (61 positions), enough for U-238's 38

	for q in range(-grid_size, grid_size + 1):
		for r in range(-grid_size, grid_size + 1):
			candidates.append(hex_to_pixel(q, r))

	candidates.sort_custom(func(a, b): return a.length_squared() < b.length_squared())

	var result: Array[Vector2] = []
	for i in range(min(count, candidates.size())):
		result.append(center + candidates[i])
	return result
