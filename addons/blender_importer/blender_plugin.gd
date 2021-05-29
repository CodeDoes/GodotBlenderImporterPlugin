tool
extends EditorPlugin

var import_plugins = []

func _enter_tree():
	var path = null
	var property_info = {
		"name": "blender/path",
		"type": TYPE_STRING,
	}
	
	# Set some sane default paths for each OS and their File Selectors
	match OS.get_name():
		"Windows":
			path = "C:\\Program Files\\Blender Foundation\\Blender 2.83\\blender.exe"

			property_info["hint"] = PROPERTY_HINT_GLOBAL_FILE
			property_info["hint_string"] = "*.exe"
		"OSX":
			path = "/Applications/Blender.app"

			property_info["hint"] = PROPERTY_HINT_GLOBAL_DIR
			property_info["hint_string"] = "*.app"
		"X11":
			path = "/usr/bin/blender"
			
			property_info["hint"] = PROPERTY_HINT_GLOBAL_FILE
			property_info["hint_string"] = "*"

	var editor_settings := get_editor_interface().get_editor_settings()

	# If there isn't a property for the path yet, use the defaults
	if !editor_settings.has_setting("blender/path"):
		editor_settings.set_setting("blender/path", path)

	editor_settings.add_property_info(property_info)
	
	for P in [
#		preload("res://addons/blender_importer/blender_escn_exporter_import_plugin.gd"),
		preload("res://addons/blender_importer/blender_gltf_exporter_import_plugin.gd"),
	]:
		var p = P.new(editor_settings)
		add_import_plugin(p)
		import_plugins.append(p)

func _exit_tree():
	for p in import_plugins:
		remove_import_plugin(p)
#		p.free()
		
	import_plugins = []

