extends Node

const MOD_ICON_PATH := "res://mods-unpacked/chloecat-orbitallaser/overwrites/content/icons/"
const GAME_ICON_PATH := "res://content/icons/"

var icons := []

var iconTextures := []

func _init():
	pass
	for icon in icons:
		var overwrite = load(MOD_ICON_PATH+icon)
		iconTextures.append(overwrite)
		overwrite.take_over_path(GAME_ICON_PATH+icon)
