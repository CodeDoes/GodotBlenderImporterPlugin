tool
extends EditorImportPlugin
enum Presets {GODOT_ADDON}
class PySet:
	extends Object
	var value:Array
func newPySet(val:Array):
	prints("pyset val",val)
	var ins = PySet.new()
	ins.value = val
	return ins
func get_importer_name():
	return "blender.scene"

func get_visible_name():
	return "Blender Scene Importer"

func get_recognized_extensions():
	return ["blend"]

func get_save_extension():
	return "tscn"

func get_resource_type():
	return "PackedScene"

func get_preset_count():
	return 1

func get_preset_name(i):
	if i==Presets.GODOT_ADDON:
		return "Blender with Godot Addon"
var godot_addon_object_types = "Empty,Camera,Light,Armature,Geometry"
func get_import_options(i):
	if i==Presets.GODOT_ADDON:
		return [
			{"name": "use_visible_objects", "default_value": false},
			{"name": "use_mesh_modifiers", "default_value": true},
			{"name": "object_types", 
				"default_value": (1<<godot_addon_object_types.split(",").size())-1, 
				"property_hint":PROPERTY_HINT_FLAGS,
				"hint_string":godot_addon_object_types},
			{"name": "export_animations", "default_value": true},
			{"name": "use_stashed_action", "default_value": true},
			{"name": "use_beta_features", "default_value": true},
			{"name": "use_export_selected", "default_value": false,
				"usage":0},#hidden
			]
func quote(val):
	return '"%s"'%val
func escape_quotes(val:String):
	return val.replace('"','\\"').replace("'","\\'")
func gdval2py(v):
#	prints("typeof:",typeof(v),v)
	if v is String:
		return '"%s"'%v
	elif v is Array:
		var r = PoolStringArray([])
		for i in v:
			r.append(gdval2py(i))
		print("var Arr %s"%[v])
		return '[%s]'%r.join(", ")
	elif v is Dictionary:
		var r = PoolStringArray()
		for ik in v.keys():
			var iv = v[ik]
			r.append("\"%s\":%s"%[ik,gdval2py(iv)])
		return "{%s}"%r.join(", ")
	elif v is PySet:
		var r = PoolStringArray([])
		for i in v.value:
			r.append(gdval2py(i))
		print("var Set %s"%[v])
		return '{%s}'%r.join(", ")
	else:
		return String(v)

func globalize_workaround(val:String):
	if OS.get_name()=="Windows":
		return val.replace(":/","://").replace("/","\\")
	else:
		return val
func flags_to_namelist(val:int,namelist:Array):
	var result = []
	for i in namelist.size():
#		prints("i:",1<<i,val, 1<<i | val)
		if (1<<i & val)>0:
			result.append(namelist[i].to_upper())
	print("i result ",result)
	return result
func import(source_file, save_path, options, platform_variants, gen_files):
	print("start")
	var file = File.new()
	if file.open(source_file, File.READ) != OK:
		return FAILED
	
	options["object_types"]=newPySet(flags_to_namelist(options["object_types"],godot_addon_object_types.split(",")))
	print("\noptions:\n",options)
	var filename = save_path + "." + get_save_extension()
	var os_filename = globalize_workaround(ProjectSettings.globalize_path(filename))
	var os_sourcefile = globalize_workaround(ProjectSettings.globalize_path(source_file))
	var os_pyexpr = escape_quotes('import io_scene_godot,bpy,sys;dest=r"%s";io_scene_godot.export(dest,%s)'%[os_filename,gdval2py(options)])
	print("\n")
	prints(os_pyexpr)
	var os_blenderexe = globalize_workaround(ProjectSettings.get("blender_importer/path_to_executable"))
	print(os_filename)
#	print(os_sourcefile)
#	print(os_pyexpr)
#	print(os_blenderexe)
	var out = []
	var exit_code = OS.execute(os_blenderexe,
		["--background", os_sourcefile, "--python-expr", os_pyexpr],
		true,out,true)
	print("out:\n",PoolStringArray(out).join("\n"))
	print("exit_code: ",exit_code)
	prints("gen_files",gen_files)
	print("done")
	if exit_code==0:
		var pscene = ResourceLoader.load(filename,"PackedScene")
		ResourceSaver.save(filename,pscene)
		return OK
	else:
		return FAILED
