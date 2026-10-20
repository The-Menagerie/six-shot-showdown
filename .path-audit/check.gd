extends SceneTree

func _initialize() -> void:
	call_deferred("_audit")

func _audit() -> void:
	var paths: Array[String] = []
	_collect("res://", paths)
	for path in paths:
		print("AUDIT_BEGIN|", path)
		var resource = load(path)
		var ok = resource != null
		if resource is Script:
			ok = resource.can_instantiate()
		print("AUDIT_RESULT|", "OK" if ok else "FAIL", "|", path)
	quit()

func _collect(path: String, paths: Array[String]) -> void:
	var dir = DirAccess.open(path)
	if dir == null:
		return
	for file in dir.get_files():
		if file.get_extension() in ["tscn", "tres", "gd"]:
			paths.append(path.path_join(file))
	for folder in dir.get_directories():
		if not folder.begins_with("."):
			_collect(path.path_join(folder), paths)
