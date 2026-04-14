extends Node

var _loading: Dictionary = {}
var _warmed: Dictionary = {}
var _audio_cache: Array = []

## Start loading a scene in the background
func preload_scene(path: String):
	if path in _loading:
		return
	_loading[path] = null
	ResourceLoader.load_threaded_request(path)

## Check if scene is loaded
func is_loaded(path: String) -> bool:
	return ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED

## Warm up by loading all dependencies and pre-decoding audio
func warmup_scene(path: String):
	if path in _warmed:
		return

	# Load all dependencies recursively
	var deps = ResourceLoader.get_dependencies(path)
	for dep in deps:
		var dep_path = dep.get_slice("::", 2) if "::" in dep else dep
		if ResourceLoader.exists(dep_path):
			var res = load(dep_path)
			if res:
				_audio_cache.append(res)  # Keep in memory
				# Pre-decode WAV files for DSP
				if res is AudioStreamWAV:
					beat.warmup_audio(res)
					await get_tree().process_frame  # Yield to keep UI responsive

	# Also load the scene itself
	if not is_loaded(path):
		if path not in _loading:
			preload_scene(path)
		while not is_loaded(path):
			await get_tree().process_frame

	_warmed[path] = true

## Preload audio and keep in memory
func preload_audio(path: String):
	ResourceLoader.load_threaded_request(path)
	while ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_LOADED:
		await get_tree().process_frame
	var audio = ResourceLoader.load_threaded_get(path)
	_audio_cache.append(audio)

## Change to a scene (waits if still loading)
func change_scene(path: String):
	if path not in _loading:
		preload_scene(path)
	while not is_loaded(path):
		await get_tree().process_frame
	var scene = ResourceLoader.load_threaded_get(path)
	_loading.erase(path)
	get_tree().change_scene_to_packed(scene)
