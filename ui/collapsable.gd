@tool
extends VBoxContainer;

class_name Collapsable;

signal toggled(open: bool);

var body : Container;

func _ready() -> void:
	body = $Body;

func _on_head_toggled(toggled_on: bool) -> void:
	body.visible = toggled_on;
	toggled.emit(toggled_on);
