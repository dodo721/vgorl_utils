@tool
extends VgorlUtil;

class_name BoneAttachmentUtil;

func _ready() -> void:
	super();

func extract_child (bone: BoneAttachment3D, child: Node3D, remote: RemoteTransform3D):
	assert(bone.get_children().has(child), "Tried to extract node that is not a child of bone attachment: " + bone.name + ", " + child.name);
	child.name = bone.name + "_" + child.name;
	bone.remove_child(child);
	bone.add_sibling(child);
	child.owner = bone.owner;
	remote.remote_path = child.get_path();
	remote.name = "RemoteTransform_" + child.name;
	bone.add_child(remote);
	remote.owner = bone.owner;

func unextract_child (bone: BoneAttachment3D, remote: RemoteTransform3D):
	assert(bone.get_children().has(remote), "Tried to unextract remote that is not a child of bone attachment: " + bone.name + ", " + remote.name);
	var child := remote.get_node(remote.remote_path);
	child.get_parent().remove_child(child);
	bone.add_child(child);
	child.name = child.name.replace(bone.name + "_", "");
	child.owner = bone.owner;
	bone.remove_child(remote);

func _on_extract_children_btn_pressed() -> void:
	for bone: BoneAttachment3D in nodes:
		undo_redo.create_action("Extract BoneAttachment children with RemoteTransform", UndoRedo.MERGE_ALL, bone);
		for child: Node3D in bone.get_children():
			var remote := RemoteTransform3D.new();
			undo_redo.add_do_method(self, "extract_child", bone, child, remote);
			undo_redo.add_undo_method(self, "unextract_child", bone, remote);
			undo_redo.add_do_reference(remote);
		undo_redo.commit_action();
