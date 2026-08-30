# GalaxyGenerator.gd
# Motor de geração procedural de galáxia.
# Totalmente desacoplado da renderização — pode rodar headless para testes.
#
# Algoritmo:
# 1. Distribui sistemas em padrão espiral usando equações paramétricas.
# 2. Adiciona ruído aleatório para evitar aparência perfeita demais.
# 3. Conecta sistemas próximos via triangulação de Delaunay simplificada
#    (aproximação: cada sistema conecta aos N vizinhos mais próximos dentro
#    de um raio máximo — suficiente para o MVP, sem biblioteca externa).
class_name GalaxyGenerator
extends RefCounted

const MIN_SYSTEMS: int = 200
const MAX_SYSTEMS: int = 400
const GALAXY_RADIUS: float = 8000.0      # Raio total em unidades do universo
const MIN_DISTANCE: float = 250.0        # Distância mínima entre sistemas
const MAX_CONNECTION_DIST: float = 850.0 # Distância máxima para conexão de hiperespaço
const MAX_CONNECTIONS: int = 4           # Máx. conexões por sistema
const ARM_COUNT: int = 3                 # Braços espirais

var _rng: RandomNumberGenerator
var _name_gen: NameGenerator
var systems: Array[StarSystem] = []

# Distribuição de tipos de estrela (probabilidades acumuladas)
const STAR_TYPE_WEIGHTS: Array[float] = [0.35, 0.65, 0.72, 0.87, 0.94, 1.0]


func _init(seed_value: int) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value
	_name_gen = NameGenerator.new(seed_value + 9999)


func generate() -> Array[StarSystem]:
	systems.clear()
	var system_count: int = _rng.randi_range(MIN_SYSTEMS, MAX_SYSTEMS)

	print("[GalaxyGenerator] Gerando %d sistemas com seed %d..." % [system_count, _rng.seed])

	var positions: Array[Vector2] = _generate_positions(system_count)
	_create_systems(positions)
	_connect_systems()

	print("[GalaxyGenerator] Geração concluída. %d sistemas, %d conexões totais." % [
		systems.size(),
		_count_total_connections()
	])

	return systems


# --- Geração de posições ---

func _generate_positions(count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var attempts: int = 0
	var max_attempts: int = count * 20

	# Gera a maioria dos sistemas em padrão espiral
	var spiral_count: int = int(count * 0.80)
	# O restante em posições mais aleatórias (campo estelar difuso)
	var field_count: int = count - spiral_count

	# Núcleo galáctico — alguns sistemas bem densos no centro
	var core_count: int = int(count * 0.08)
	for i in range(core_count):
		var angle: float = _rng.randf() * TAU
		var dist: float = _rng.randf_range(0.0, GALAXY_RADIUS * 0.15)
		var pos: Vector2 = Vector2(cos(angle) * dist, sin(angle) * dist)
		if _is_valid_position(pos, positions):
			positions.append(pos)

	# Braços espirais
	for arm in range(ARM_COUNT):
		var arm_angle_offset: float = (TAU / ARM_COUNT) * arm
		var arm_systems: int = int(spiral_count / ARM_COUNT)

		for i in range(arm_systems):
			attempts = 0
			var placed: bool = false
			while not placed and attempts < 30:
				var t: float = _rng.randf()  # 0 = centro, 1 = borda
				var dist: float = t * GALAXY_RADIUS * 0.9 + GALAXY_RADIUS * 0.1
				# Ângulo espiral: quanto mais longe, mais girado
				var spiral_angle: float = arm_angle_offset + t * TAU * 0.8
				# Ruído lateral para deixar natural
				var noise: float = _rng.randf_range(-0.35, 0.35) * (dist * 0.25)
				var perp_angle: float = spiral_angle + PI * 0.5
				var pos: Vector2 = Vector2(
					cos(spiral_angle) * dist + cos(perp_angle) * noise,
					sin(spiral_angle) * dist + sin(perp_angle) * noise
				)
				if _is_valid_position(pos, positions):
					positions.append(pos)
					placed = true
				attempts += 1

	# Campo estelar difuso (estrelas espalhadas)
	for i in range(field_count):
		attempts = 0
		var placed: bool = false
		while not placed and attempts < 30:
			var angle: float = _rng.randf() * TAU
			var dist: float = sqrt(_rng.randf()) * GALAXY_RADIUS * 0.85
			var pos: Vector2 = Vector2(cos(angle) * dist, sin(angle) * dist)
			if _is_valid_position(pos, positions):
				positions.append(pos)
				placed = true
			attempts += 1

	return positions


func _is_valid_position(pos: Vector2, existing: Array[Vector2]) -> bool:
	if pos.length() > GALAXY_RADIUS:
		return false
	for other in existing:
		if pos.distance_to(other) < MIN_DISTANCE:
			return false
	return true


# --- Criação dos sistemas ---

func _create_systems(positions: Array[Vector2]) -> void:
	for i in range(positions.size()):
		var system: StarSystem = StarSystem.new()
		system.id = i
		system.position = positions[i]
		system.name = _name_gen.star_system_name()
		system.star_type = _pick_star_type()
		system.star_color = StarSystem.star_type_color(system.star_type)
		system.planets = _generate_planets(system.star_type)
		system.resources = _generate_resources()
		systems.append(system)


func _pick_star_type() -> StarSystem.StarType:
	var roll: float = _rng.randf()
	for i in range(STAR_TYPE_WEIGHTS.size()):
		if roll <= STAR_TYPE_WEIGHTS[i]:
			return i as StarSystem.StarType
	return StarSystem.StarType.YELLOW


func _generate_planets(star_type: StarSystem.StarType) -> Array[Dictionary]:
	var planets: Array[Dictionary] = []
	# Número de planetas varia por tipo de estrela
	var max_planets: int = 0
	match star_type:
		StarSystem.StarType.YELLOW:  max_planets = _rng.randi_range(2, 6)
		StarSystem.StarType.RED:     max_planets = _rng.randi_range(1, 4)
		StarSystem.StarType.BLUE:    max_planets = _rng.randi_range(0, 3)
		StarSystem.StarType.ORANGE:  max_planets = _rng.randi_range(2, 5)
		StarSystem.StarType.WHITE:   max_planets = _rng.randi_range(1, 4)
		StarSystem.StarType.GIANT:   max_planets = _rng.randi_range(3, 7)

	for i in range(max_planets):
		var planet_type: StarSystem.PlanetType = _pick_planet_type(star_type, i)
		planets.append({
			"type": planet_type,
			"name": "Planeta %s" % (i + 1),
			"color": StarSystem.planet_type_color(planet_type),
			"habitability": _planet_habitability(planet_type),
		})

	return planets


func _pick_planet_type(
		star_type: StarSystem.StarType,
		orbit_index: int) -> StarSystem.PlanetType:
	# Planetas próximos à estrela tendem a ser mais quentes
	var roll: float = _rng.randf()
	if orbit_index == 0:
		# Órbita interna: vulcânico, árido ou estéril
		if roll < 0.4: return StarSystem.PlanetType.VOLCANIC
		elif roll < 0.7: return StarSystem.PlanetType.ARID
		else: return StarSystem.PlanetType.BARREN
	elif orbit_index <= 2:
		# Zona habitável
		if star_type == StarSystem.StarType.BLUE:
			if roll < 0.5: return StarSystem.PlanetType.BARREN
			else: return StarSystem.PlanetType.ARID
		if roll < 0.3: return StarSystem.PlanetType.TERRAN
		elif roll < 0.5: return StarSystem.PlanetType.ARID
		elif roll < 0.65: return StarSystem.PlanetType.BARREN
		elif roll < 0.8: return StarSystem.PlanetType.TOXIC
		else: return StarSystem.PlanetType.ARCTIC
	else:
		# Órbita externa: gelo, gigantes gasosos
		if roll < 0.45: return StarSystem.PlanetType.GAS_GIANT
		elif roll < 0.75: return StarSystem.PlanetType.ARCTIC
		else: return StarSystem.PlanetType.BARREN


func _planet_habitability(type: StarSystem.PlanetType) -> float:
	match type:
		StarSystem.PlanetType.TERRAN:    return _rng.randf_range(0.5, 1.0)
		StarSystem.PlanetType.ARID:      return _rng.randf_range(0.1, 0.5)
		StarSystem.PlanetType.ARCTIC:    return _rng.randf_range(0.05, 0.35)
		StarSystem.PlanetType.VOLCANIC:  return 0.0
		StarSystem.PlanetType.GAS_GIANT: return 0.0
		StarSystem.PlanetType.BARREN:    return _rng.randf_range(0.0, 0.15)
		StarSystem.PlanetType.TOXIC:     return _rng.randf_range(0.0, 0.1)
		_: return 0.0


func _generate_resources() -> Dictionary:
	return {
		"minerals": _rng.randi_range(0, 10),
		"energy":   _rng.randi_range(0, 8),
		"influence": _rng.randi_range(0, 5),
		"rare":     1 if _rng.randf() < 0.08 else 0,  # 8% de chance de recurso raro
	}


# --- Conexões de hiperespaço ---

func _connect_systems() -> void:
	# Para cada sistema, encontra os N vizinhos mais próximos dentro do raio máximo
	# e cria conexões bidirecionais.
	for i in range(systems.size()):
		var sys_a: StarSystem = systems[i]
		# Coletar distâncias para todos os outros sistemas
		var distances: Array[Dictionary] = []
		for j in range(systems.size()):
			if i == j:
				continue
			var dist: float = sys_a.position.distance_to(systems[j].position)
			if dist <= MAX_CONNECTION_DIST:
				distances.append({"id": j, "dist": dist})

		# Ordenar por distância
		distances.sort_custom(func(a, b): return a.dist < b.dist)

		# Conectar aos mais próximos até o máximo
		var added: int = 0
		for entry in distances:
			if added >= MAX_CONNECTIONS:
				break
			var j: int = entry.id
			if j not in sys_a.connections:
				sys_a.connections.append(j)
				systems[j].connections.append(i)
				added += 1

	# Garantir que a galáxia seja conexa:
	# sistemas isolados (sem conexão) recebem uma ponte para o vizinho mais próximo
	for sys in systems:
		if sys.connections.is_empty():
			var nearest_id: int = _find_nearest(sys)
			if nearest_id >= 0:
				sys.connections.append(nearest_id)
				systems[nearest_id].connections.append(sys.id)


func _find_nearest(system: StarSystem) -> int:
	var best_id: int = -1
	var best_dist: float = INF
	for other in systems:
		if other.id == system.id:
			continue
		var d: float = system.position.distance_to(other.position)
		if d < best_dist:
			best_dist = d
			best_id = other.id
	return best_id


func _count_total_connections() -> int:
	var total: int = 0
	for sys in systems:
		total += sys.connections.size()
	return total / 2  # Cada conexão é contada duas vezes (bidirecional)
