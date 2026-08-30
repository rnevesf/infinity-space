# NameGenerator.gd
# Gerador de nomes procedural baseado em seed — 100% offline, sem IA/LLM.
# Cria nomes de sistemas estelares e civilizações com sílabas fonéticas.
class_name NameGenerator
extends RefCounted

var _rng: RandomNumberGenerator


func _init(seed_value: int) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value


# Sílabas pré-definidas para compor nomes com som "espacial"
const PREFIXES: Array[String] = [
	"Vel", "Kha", "Zar", "Ore", "Aen", "Tyr", "Sol", "Nar", "Ith", "Vor",
	"Cen", "Eld", "Myr", "Pho", "Ral", "Sig", "Tau", "Ux", "Ves", "Wyr",
	"Ash", "Bel", "Cal", "Den", "Eth", "Fal", "Gor", "Hel", "Ior", "Jun",
	"Ker", "Lys", "Mol", "Nex", "Osc", "Pyr", "Qui", "Rex", "Ser", "Tur",
]

const MIDDLES: Array[String] = [
	"ara", "eon", "ion", "ius", "ora", "uri", "an", "en", "is", "on",
	"al", "el", "il", "ol", "ul", "ax", "ex", "ix", "ox", "ux",
	"ath", "eth", "ith", "oth", "uth", "am", "em", "im", "om", "um",
]

const SUFFIXES: Array[String] = [
	"Prime", "Major", "Minor", "Rex", "Alta", "Nova", "Vera", "Magna",
	"Alpha", "Beta", "Gamma", "Delta", "Omega", "I", "II", "III", "IV", "V",
	"", "", "", "",  # Nomes sem sufixo (mais frequentes)
]

const FACTION_PREFIXES: Array[String] = [
	"Federação", "Império", "República", "Aliança", "Domínio", "Consórcio",
	"Tribo", "Clã", "Hegemonia", "Confederação", "Coletivo", "União",
]

const FACTION_NAMES: Array[String] = [
	"Vherani", "Krath", "Solari", "Nexari", "Tyrel", "Oresh", "Caldun",
	"Myreth", "Phoran", "Eldis", "Belvos", "Zarvak", "Urith", "Nalkor",
	"Sigar", "Taurek", "Vorath", "Cenuli", "Ashren", "Denvari",
]

const PERSON_FIRST: Array[String] = [
	"Aela", "Boran", "Cara", "Drix", "Etha", "Falor", "Genn", "Hira",
	"Ivar", "Juna", "Kess", "Lyra", "Mora", "Nath", "Orin", "Pyra",
	"Quen", "Rael", "Sera", "Thar", "Uvek", "Vela", "Wren", "Xan",
	"Yora", "Zell", "Arkon", "Belun", "Covar", "Dreya",
]

const PERSON_LAST: Array[String] = [
	"Solvar", "Krath", "Endir", "Vethis", "Orana", "Mirex", "Caldor",
	"Thyren", "Aevun", "Brolan", "Cestal", "Dalvir", "Ethrak", "Foshen",
	"Gauren", "Holvek", "Irakon", "Jessar", "Kavren", "Lorthi",
]


func star_system_name() -> String:
	var prefix: String = PREFIXES[_rng.randi() % PREFIXES.size()]
	var middle: String = MIDDLES[_rng.randi() % MIDDLES.size()]
	var suffix: String = SUFFIXES[_rng.randi() % SUFFIXES.size()]
	if suffix.is_empty():
		return prefix + middle
	return prefix + middle + " " + suffix


func faction_name() -> String:
	var prefix: String = FACTION_PREFIXES[_rng.randi() % FACTION_PREFIXES.size()]
	var name: String = FACTION_NAMES[_rng.randi() % FACTION_NAMES.size()]
	return prefix + " " + name


func person_name() -> String:
	var first: String = PERSON_FIRST[_rng.randi() % PERSON_FIRST.size()]
	var last: String = PERSON_LAST[_rng.randi() % PERSON_LAST.size()]
	return first + " " + last
