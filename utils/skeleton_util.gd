@tool
extends VgorlUtil

func _ready():
	super();
	expose_resource_field("Jiggle Settings", "JiggleSettings");

func new_jiggle (skeleton: Skeleton3D, jiggle: JiggleBone):
	skeleton.add_child(jiggle);
	jiggle.owner = skeleton.owner;

func free_jiggle (skeleton: Skeleton3D, jiggle: JiggleBone):
	skeleton.remove_child(jiggle);

func _on_setup_physics_btn_pressed() -> void:
	for skeleton: Skeleton3D in nodes:
		undo_redo.create_action("Setup physics for Skeleton3D", UndoRedo.MERGE_ALL, skeleton);
		for bone in skeleton.get_bone_count():
			var bone_name = skeleton.get_bone_name(bone);
			if bone_name.begins_with("P_"):
				var jiggle = JiggleBone.new();
				jiggle.bone_name = bone_name;
				jiggle.name = bone_name.replace("P_", "Jiggle_");
				if exposed_fields["Jiggle Settings"].val:
					jiggle.settings = (exposed_fields["Jiggle Settings"].val as Resource).duplicate();
				else:
					jiggle.settings = JiggleSettings.new();
				undo_redo.add_do_method(self, "new_jiggle", skeleton, jiggle);
				undo_redo.add_undo_method(self, "free_jiggle", skeleton, jiggle);
				undo_redo.add_do_reference(jiggle);
		undo_redo.commit_action();


func _on_remove_physics_btn_pressed() -> void:
	for skeleton: Skeleton3D in nodes:
		undo_redo.create_action("Remove physics from Skeleton3D", UndoRedo.MERGE_ALL, skeleton);
		for child in skeleton.get_children():
			if child is JiggleBone:
				undo_redo.add_do_method(self, "free_jiggle", child);
				undo_redo.add_undo_reference(child);
		undo_redo.commit_action();
