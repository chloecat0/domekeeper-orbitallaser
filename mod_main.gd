extends Node

const MYMODNAME_LOG = "chloecat-orbitallaser"
const MYMODNAME_MOD_DIR = "chloecat-orbitallaser/"

var dir = ""
var ext_dir = ""
var trans_dir = ""

func _init():
	ModLoaderLog.info("Init", MYMODNAME_LOG)
	dir = ModLoaderMod.get_unpacked_dir() + MYMODNAME_MOD_DIR
	ext_dir = dir + "extensions/"
	trans_dir = dir + "translations/"
	
	# Add translations
	ModLoaderMod.add_translation(trans_dir + "orbitallaser_text.en.translation")
	
	# Add extensions
#	ModLoaderMod.install_script_extension(ext_dir + "main.gd")

func _ready():
	ModLoaderLog.info("Done", MYMODNAME_LOG)
	add_to_group("mod_init")

func modInit():
	Data.registerDome("domeOL")
	GameWorld.unlockElement("domeOL")
	
	var pathToModYaml : String = "res://mods-unpacked/chloecat-orbitallaser/yaml/upgrades.yaml"
	ModLoaderLog.info("Trying to parse YAML: %s" % pathToModYaml, MYMODNAME_LOG)
	Data.parseUpgradesYaml(pathToModYaml)
	
	# This signal can be used to test the mod
	#StageManager.connect("level_ready", self, "testMod")
