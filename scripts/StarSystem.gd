# StarSystem.gd
# Estrutura de dados de um sistema estelar.
# Completamente desacoplado da renderização — pode ser usado pela simulação histórica headless.
class_name StarSystem
extends RefCounted

## Tipos de estrela com suas cores representativas
enum StarType {
	YELLOW,   # Tipo G — como o Sol
	RED,      # Tipo M — anã vermelha
	BLUE,     # Tipo O/B — gigante azul
	ORANGE,   # Tipo K — anã laranja
	WHITE,    # Tipo A — anã branca
	GIANT,    # Gigante laranja/vermelha
}

## Tipos de planeta com bioma principal
enum PlanetType {
	TERRAN,      # Oceanos + continentes
	ARID,        # Deserto
	ARCTIC,      # Gelo
	VOLCANIC,    # Vulcânico
	GAS_GIANT,   # Gigante gasoso
	BARREN,      # Rochoso/estéril
	TOXIC,       # Atmosfera tóxica
}

# --- Identificação ---
var id: int                      # Índice único
var name: String                 # Nome gerado proceduralmente
var position: Vector2            # Posição no mapa galáctico (em pixels do espaço do universo)

# --- Propriedades estelares ---
var star_type: StarType
var star_color: Color

# --- Planetas ---
var planets: Array[Dictionary]   # Cada dict: {type, name, resources}

# --- Recursos estratégicos ---
var resources: Dictionary        # {mineral, energia, influencia, raridade}

# --- Estado político ---
var faction_id: int = -1         # -1 = desabitado/neutro
var is_colonized: bool = false
var population: float = 0.0      # Em bilhões

# --- Conexões de hiperespaço ---
var connections: Array[int]      # IDs dos sistemas vizinhos conectados

# --- Histórico ---
var history_events: Array[Dictionary] = []  # Eventos que ocorreram neste sistema


static func star_type_color(type: StarType) -> Color:
	match type:
		StarType.YELLOW:  return Color(1.0, 0.95, 0.4)
		StarType.RED:     return Color(1.0, 0.3, 0.2)
		StarType.BLUE:    return Color(0.4, 0.7, 1.0)
		StarType.ORANGE:  return Color(1.0, 0.6, 0.2)
		StarType.WHITE:   return Color(0.9, 0.95, 1.0)
		StarType.GIANT:   return Color(1.0, 0.4, 0.1)
		_:                return Color(1.0, 1.0, 0.8)


static func star_type_name(type: StarType) -> String:
	match type:
		StarType.YELLOW:  return "Anã Amarela"
		StarType.RED:     return "Anã Vermelha"
		StarType.BLUE:    return "Gigante Azul"
		StarType.ORANGE:  return "Anã Laranja"
		StarType.WHITE:   return "Anã Branca"
		StarType.GIANT:   return "Gigante Vermelha"
		_:                return "Estrela"


static func planet_type_color(type: PlanetType) -> Color:
	match type:
		PlanetType.TERRAN:    return Color(0.28, 0.58, 0.55) # Muted Teal/Blue-green
		PlanetType.ARID:      return Color(0.72, 0.60, 0.45) # Soft Sand
		PlanetType.ARCTIC:    return Color(0.65, 0.78, 0.85) # Pale Ice Blue
		PlanetType.VOLCANIC:  return Color(0.65, 0.35, 0.30) # Muted Rust
		PlanetType.GAS_GIANT: return Color(0.65, 0.58, 0.60) # Muted Mauve/Brown
		PlanetType.BARREN:    return Color(0.45, 0.42, 0.45) # Slate Gray
		PlanetType.TOXIC:     return Color(0.45, 0.60, 0.40) # Muted Sage Green
		_:                    return Color(0.5, 0.5, 0.5)
