tool
extends EditorPlugin

var import_plugin

func _enter_tree():
	import_plugin = preload("import_plugin.gd").new()
	ProjectSettings.set_initial_value("blender_importer/path_to_executable", "")

	var property_info = {
		"name": "blender_importer/path_to_executable",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_GLOBAL_FILE,
		"hint_string": "*.exe"
	}
	
	ProjectSettings.add_property_info(property_info)
	add_import_plugin(import_plugin)

func _exit_tree():
	remove_import_plugin(import_plugin)
	import_plugin = null

