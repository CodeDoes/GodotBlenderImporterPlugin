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

	# Check if the blend file can be read
	if file.open(source_file, File.READ) != OK:
		printerr("Failed to read blend file")
		return FAILED
	file.close()

	# Get the global path to the Blender executable, blend file and the destination file
	var os_blenderexe = globalize_workaround(ProjectSettings.get_setting("blender/path"))
	var os_sourcefile = globalize_workaround(ProjectSettings.globalize_path(source_file))
	var os_filename = globalize_workaround(ProjectSettings.globalize_path(save_path))

	# Build the python expression for running the glTF exporter
	var os_pyexpr = "import bpy,sys;print(' '.join(sys.argv));bpy.ops.export_scene.gltf(filepath=r'%s')"%os_filename

	# Run Blender with the above Python expression, keep note of the stdout for debug purposes
	var out = []
	var exit_code = OS.execute(
		os_blenderexe,
		["--background", os_sourcefile, "--python-expr", os_pyexpr],
		true,
		out,
		true
	)
	print(PoolStringArray(out).join("\n"))

	# Check if the export worked
	if exit_code == 0:
		# Check for the final glb file
		var err = file.open(os_filename + ".glb", File.READ)
		if err != OK:
			printerr("Failed to read gltf intermediary file. Error code ", err)
			return FAILED
		file.close()

		# Tell the editor to load the scene using EditorSceneImporter
		var pack = PackedScene.new()
		# TODO: Add options for the import flags and FPS
		var scene = EditorSceneImporter.new().import_scene_from_other_importer(save_path + ".glb", 0, 0)

		# Pack the Node into a PackedScene to be saved
		pack.pack(scene)

		# Save the scene
		err = ResourceSaver.save("%s.%s" % [save_path, get_save_extension()], pack)
		if err != OK:
			printerr("Failed to save final SCN file ", pack, " Error code: ", err)
			return err
		return OK
	else:
		return FAILED
