tool
extends EditorImportPlugin

enum Presets {GLTF_GLB}

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
	if i == Presets.GLTF_GLB:
		return "Blender Gltf exporter"
func get_import_options(i):
	if i == Presets.GLTF_GLB:
		return [ ]

func globalize_workaround(val: String):
	if OS.get_name() == "Windows":
		# To run binaries with OS.execute on Windows, the Unix directory separator should be changed
		# to the Windows separator
		return val.replace("/","\\")
	else:
		return val

func import(source_file, save_path, options, platform_variants, gen_files):
	var file = File.new()
	var dir = Directory.new()
	if file.open(source_file, File.READ) != OK:
		printerr("Failed to read blend file")
		return FAILED
	file.close()
	var os_blenderexe = globalize_workaround(ProjectSettings.get_setting("blender/path"))
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
