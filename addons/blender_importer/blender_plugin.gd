tool
extends EditorPlugin

var import_plugins = []

func _enter_tree():
	ProjectSettings.set("blender/path", "C:\\Program Files\\Blender Foundation\\Blender 2.83\\blender.exe")
	var property_info = {
		"name": "blender/path",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_GLOBAL_FILE,
		"hint_string": "*.exe"
	}	
	ProjectSettings.add_property_info(property_info)
	
	for P in [
#		preload("res://addons/blender_importer/blender_escn_exporter_import_plugin.gd"),
		preload("res://addons/blender_importer/blender_gltf_exporter_import_plugin.gd"),
		]:
		var p = P.new()
		add_import_plugin(p)
		import_plugins.append(p)

func _exit_tree():
	for p in import_plugins:
		remove_import_plugin(p)
#		p.free()
		
	import_plugins = []

