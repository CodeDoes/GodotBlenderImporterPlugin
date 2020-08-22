tool
extends EditorImportPlugin
enum Presets {GLTF_GLB}
class PySet:
	extends Object
	var value:Array
func newPySet(val:Array):
	var ins = PySet.new()
	ins.value = val
	return ins
func get_importer_name():
	return "blender.gltf"

func get_visible_name():
	return "Blender GLTF XImporter"

func get_recognized_extensions():
	return ["blend"]

func get_save_extension():
	return "scn"

func get_resource_type():
	return "PackedScene"

func get_preset_count():
	return 1

func get_preset_name(i):
	if i==Presets.GLTF_GLB:
		return "Blender Gltf exporter"
func get_import_options(i):
	if i==Presets.GLTF_GLB:
		return [ ]
func quote(val):
	return '"%s"'%val
func escape_quotes(val:String):
	return val.replace("\\","\\\\").replace('"','\\"').replace("'","\\'")
func gdval2py(v):
	if v is String:
		return '"%s"'%v
	elif v is Array:
		var r = PoolStringArray([])
		for i in v:
			r.append(gdval2py(i))
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
		return '{%s}'%r.join(", ")
	else:
		return String(v)

func globalize_workaround(val:String):
	if OS.get_name()=="Windows":
		return val.replace("/","\\")
	else:
		return val
func flags_to_namelist(val:int,namelist:Array):
	var result = []
	for i in namelist.size():
		if (1<<i & val)>0:
			result.append(namelist[i].to_upper())
	return result
func get_cache_dir():
	if OS.get_name()=="Windows":
		return "%TEMP%\\Godot\\"
	elif OS.get_name()=="OSX":
		return "~/Library/Caches/Godot/"
	elif OS.get_name()=="X11":
		return "~/.cache/godot/"
var addon_cache_dir = "res://addons/blender_importer/cache/"
		
func import(source_file, save_path, options, platform_variants, gen_files):
	var file = File.new()
	var dir = Directory.new()
	if file.open(source_file, File.READ) != OK:
		printerr("Failed to read blend file")
		return FAILED
	file.close()
	var os_blenderexe = globalize_workaround("C:\\Program Files\\Blender Foundation\\Blender 2.83\\blender.exe")
	var os_sourcefile = globalize_workaround(ProjectSettings.globalize_path(source_file))
	
	var filename = addon_cache_dir + save_path.get_file() + ".glb"
	var os_filename = globalize_workaround(ProjectSettings.globalize_path(filename))
	var os_pyexpr = "import bpy,sys;print(' '.join(sys.argv));bpy.ops.export_scene.gltf(filepath=r'%s')"%os_filename
	
	var out = []
	var exit_code = OS.execute(os_blenderexe,
		["--background", os_sourcefile, "--python-expr", os_pyexpr],
		true,out,true)
	print(os_sourcefile)
	print(os_pyexpr)
	print(PoolStringArray(out).join("\n"))
	if exit_code==0:
		var err = file.open(os_filename,File.READ)
		if err!=OK:
			printerr(err," Failed to read gltf intermediary file")
			return FAILED
		file.close()
#		var floader = ResourceFormatLoader.new()
		var pscene = ResourceLoader.load(filename)
		var save_name = save_path+"."+get_save_extension()
		err = ResourceSaver.save(save_name,pscene)
		if err!=OK:
			printerr(err," Failed to save final scn file ",pscene)
			return err
		return OK
	else:
		return FAILED
