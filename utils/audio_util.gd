@tool
extends VgorlUtil;

class_name AudioUtil;

func _ready() -> void:
	super();
	expose_bool_field("Use Regex");

func _on_group_rand_btn_pressed() -> void:
	pass;

func _create_randomizer (path: String):
	var randomizer = AudioStreamRandomizer.new();
	for i in loaded_resources.size():
		var resource = loaded_resources[i];
		randomizer.add_stream(i, resource);
	ResourceSaver.save(randomizer, path, ResourceSaver.FLAG_CHANGE_PATH);
