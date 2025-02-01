@tool
extends VgorlUtil;

class_name AudioUtil;

func _ready() -> void:
	super();
	$FileDialog.file_selected.connect(_create_randomizer);
	$FileDialog.initial_position = Window.WindowInitialPosition.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN;
	$FileDialog.add_filter("*.tres, *.res", "All Recognized");

func _on_group_rand_btn_pressed() -> void:
	$FileDialog.current_path = resource_paths[0].get_base_dir() + "/" + "randomizer.tres";
	$FileDialog.show();

func _create_randomizer (path: String):
	var randomizer = AudioStreamRandomizer.new();
	for i in loaded_resources.size():
		var resource = loaded_resources[i];
		randomizer.add_stream(i, resource);
	ResourceSaver.save(randomizer, path, ResourceSaver.FLAG_CHANGE_PATH);
