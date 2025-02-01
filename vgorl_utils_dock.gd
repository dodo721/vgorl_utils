@tool
extends Control

class_name VgorlUtilsDock;

var util_nodes : Dictionary[String, VgorlUtil];
var util_resources : Dictionary[String, VgorlUtil];
var undo_redo : EditorUndoRedoManager;
var editor_filesystem : EditorFileSystem;

func _ready() -> void:
	var util_nodes_in: Dictionary[Variant, VgorlUtil] = {
		"Skeleton3D": $SkeletonUtils,
	};
	util_nodes = _expand_util_types(util_nodes_in);
	var util_resources_in: Dictionary[Variant, VgorlUtil] = {
		["AudioStreamGenerator",
		"AudioStreamInteractive",
		"AudioStreamMicrophone",
		"AudioStreamMP3",
		"AudioStreamOggVorbis",
		"AudioStreamPlaylist",
		"AudioStreamPolyphonic",
		"AudioStreamRandomizer",
		"AudioStreamSynchronized",
		"AudioStreamWAV"]: $AudioUtils,
	};
	util_resources = _expand_util_types(util_resources_in);
	for node_type in util_nodes:
		var util = util_nodes[node_type];
		util.undo_redo = undo_redo;

func update_utils (nodes: Array[Node], paths: Array[String]):
	# Reset selection
	for node_type in util_nodes:
		util_nodes[node_type].reset_selection();
	for resource_type in util_resources:
		util_resources[resource_type].reset_selection();
	# Build up new selection
	for node_type in util_nodes:
		var matched_nodes: Array[Node] = [];
		for node in nodes:
			if node.get_class() == node_type:
				matched_nodes.append(node);
		util_nodes[node_type].add_nodes(matched_nodes);
	for resource_type in util_resources:
		var matched_paths: Array[String];
		for path in paths:
			var res_type = editor_filesystem.get_file_type(path);
			if resource_type == res_type:
				matched_paths.append(path);
		util_resources[resource_type].add_resource_paths(matched_paths);

func _expand_util_types(util_dict: Dictionary[Variant, VgorlUtil]) -> Dictionary[String, VgorlUtil]:
	var res_dict : Dictionary[String, VgorlUtil] = {};
	for key in util_dict:
		if key is String:
			res_dict[key] = util_dict[key];
		elif key is Array:
			for subkey: String in key:
				res_dict[subkey] = util_dict[key];
		else:
			printerr("Funny key type in util_dict expansion: ", key.get_class(), ", value: ", key, ", ignoring");
	return res_dict;

func _on_hide_unselected_toggled(toggled_on: bool) -> void:
	for node_type in util_nodes:
		var util : VgorlUtil = util_nodes[node_type];
		util.hide = toggled_on;
	for res_type in util_resources:
		var util : VgorlUtil = util_resources[res_type];
		util.hide = toggled_on;
