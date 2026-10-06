extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var chamber = load("res://Scenes/UI/Chamber/bullet_chamber.gd").new()
	var count := 0
	for data in chamber.bullet_dictionary.values():
		var texture = load(data.chamber_scene)
		if not texture is Texture2D or texture.get_width() == 0:
			print("IMAGE_CHECK_FAIL ", data.chamber_scene)
			quit(1)
			return
		count += 1
	print("IMAGE_CHECK_PASS chamber icons=", count)
	chamber.free()
	var settings = root.get_node("SettingsManager")
	for texture in [settings.reticle, settings.reticle_clicked]:
		if not texture is Texture2D or texture.get_width() == 0:
			print("IMAGE_CHECK_FAIL cursor")
			quit(1)
			return
	print("IMAGE_CHECK_PASS normal and clicked cursors")
	var paths = ["res://Scenes/Objects/MouseReticle.tscn", "res://Scenes/Objects/Enemies/EnemyBullet.tscn"]
	for file in DirAccess.get_files_at("res://Scenes/Objects/Bullets"):
		if file.ends_with(".tscn"):
			paths.append("res://Scenes/Objects/Bullets/" + file)
	for path in paths:
		var instance = load(path).instantiate()
		var sprite = instance.get_node_or_null("Sprite2D")
		if sprite == null or sprite.texture == null:
			print("IMAGE_CHECK_FAIL ", path)
			instance.free()
			quit(1)
			return
		print("IMAGE_CHECK_PASS ", path)
		instance.free()
	quit(0)
