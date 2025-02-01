@tool
extends EditorPlugin

var dock : VgorlUtilsDock;
var _selected_nodes : Array[Node];
var _selected_paths : PackedStringArray = [];

func _enter_tree():
	dock = preload("res://addons/vgorl_utils/vgorl_utils_dock.tscn").instantiate();
	dock.undo_redo = get_undo_redo();
	dock.editor_filesystem = get_editor_interface().get_resource_filesystem();
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_BL, dock);
	get_editor_interface().get_selection().selection_changed.connect(self._on_selection_changed);
	_on_selection_changed();
	#plugin = preload("res://addons/dodo_skeleton_setup/custom_inspector.gd").new()
	#print("LOADING PLUGIN SETUP SKELLY!")
	#add_inspector_plugin(plugin)

func _process(delta: float) -> void:
	var new_sel_paths = EditorInterface.get_file_system_dock().get_selected_paths();
	if new_sel_paths != _selected_paths:
		_selected_paths = new_sel_paths;
		dock.update_utils(_selected_nodes, _selected_paths)

func _exit_tree():
	remove_control_from_docks(dock);
	dock.free();
	#remove_inspector_plugin(plugin)

func _on_selection_changed ():
	_selected_nodes = get_editor_interface().get_selection().get_selected_nodes();
	dock.update_utils(_selected_nodes, _selected_paths);
