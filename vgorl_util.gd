@tool
extends Control;

class_name VgorlUtil;

signal exposed_field_changed (var_name: String, val);
signal resources_loaded (resources: Array[Resource]);

# <ExposedField>
class ExposedField:
	
	enum ExposableType { RESOURCE, STRING, NUMBER, BOOL, ARRAY };
	
	var type : ExposableType;
	var val : Variant;
	var field_ui: Control;
	var update_ui_func : Callable;
	
	func _init (type: ExposableType, field_ui: Control, update_ui_func: Callable, use_default: bool = false, default_val: Variant = type):
		self.type = type;
		self.field_ui = field_ui;
		self.update_ui_func = update_ui_func;
		if use_default:
			self.val = default_val;
		else:
			self.val = get_type_default(type);
	
	func get_type_default (type: ExposableType) -> Variant:
		match type:
			ExposableType.RESOURCE:
				return null;
			ExposableType.STRING:
				return "";
			ExposableType.NUMBER:
				return 0;
			ExposableType.BOOL:
				return false;
			ExposableType.ARRAY:
				return [];
			_:
				printerr("Weird type (", type, ")");
				return null;
# </ExposedField>

var nodes: Array[Node] = [];
var resource_paths : Array[String] = [];
var loaded_resources : Array[Resource] = [];
var undo_redo : EditorUndoRedoManager;
var title_btn : CheckButton;
var controls : Collapsable;
var exposed_fields : Dictionary[String, ExposedField];

var selected : bool:
	get():
		return nodes.size() > 0 || resource_paths.size() > 0;

var _hide : bool = false;
var hide : bool:
	set (newval):
		_hide = newval;
		update_state();
	get:
		return _hide;


# ============= INIT =============

func _ready ():
	title_btn = $Controls/Head/Title;
	controls = $Controls;
	controls.toggled.connect(_on_collapsable_toggled);
	exposed_field_changed.connect(_on_exposed_field_change);
	resources_loaded.connect(_on_resources_loaded);

# ============= SELECTION HANDLING =============

func reset_selection():
	nodes.clear();
	resource_paths.clear();

func add_nodes (new_nodes: Array[Node]):
	nodes.append_array(new_nodes);
	update_state();

func add_resource_paths (new_resource_paths: Array[String]):
	resource_paths.append_array(new_resource_paths);
	update_state();

func update_state():
	if selected:
		controls.visible = true;
		title_btn.disabled = false;
	elif hide:
		controls.visible = false;
		title_btn.disabled = false;
		title_btn.button_pressed = false;
	else:
		controls.visible = true;
		title_btn.button_pressed = false;
		title_btn.disabled = true;


# ============= EXPOSED FIELDS =============

func expose_resource_field (var_name: String, type: String):
	assert(!field_exists(var_name), "Exposed field " + var_name + " already exists");
	var erp = EditorResourcePicker.new();
	erp.base_type = type;
	erp.resource_changed.connect(_on_resource_change.bind(var_name));
	erp.resource_selected.connect(_on_resource_selected);
	exposed_fields[var_name] = ExposedField.new(
		ExposedField.ExposableType.RESOURCE,
		erp,
		func (val):
			erp.edited_resource = val;
	)
	_setup_exposed_field_ui(var_name, erp);

func expose_string_field (var_name: String):
	assert(!field_exists(var_name), "Exposed field " + var_name + " already exists");
	var line_edit = LineEdit.new();
	line_edit.text_changed.connect(_on_text_changed.bind(var_name));
	exposed_fields[var_name] = ExposedField.new(
		ExposedField.ExposableType.STRING,
		line_edit,
		func (val):
			line_edit.text = val;
	);
	_setup_exposed_field_ui(var_name, line_edit);

func expose_number_field (var_name: String, is_float: bool = false, min: float = -1000, max: float = 1000):
	assert(!field_exists(var_name), "Exposed field " + var_name + " already exists");
	var ess = EditorSpinSlider.new();
	if is_float:
		ess.step = 0.01;
	else:
		ess.step = 1;
		ess.rounded = true;
		ess.value = min;
	ess.min_value = min;
	ess.max_value = max;
	ess.value_changed.connect(func(val):
		self.exposed_fields[var_name].val = val;
		self.exposed_field_changed.emit(var_name, val);
	);
	exposed_fields[var_name] = ExposedField.new(
		ExposedField.ExposableType.NUMBER,
		ess,
		func (val):
			ess.value = val;
	);
	_setup_exposed_field_ui(var_name, ess);

func expose_bool_field (var_name: String):
	assert(!field_exists(var_name), "Exposed field " + var_name + " already exists");
	var checkbox = CheckBox.new();
	checkbox.toggled.connect(func(val):
		exposed_fields[var_name].val = val;
		exposed_field_changed.emit(var_name, val);
	);
	exposed_fields[var_name] = ExposedField.new(
		ExposedField.ExposableType.BOOL,
		checkbox,
		func (val):
			checkbox.button_pressed = val;
	);
	_setup_exposed_field_ui(var_name, checkbox);

func remove_exposed_field (var_name: String):
	exposed_fields[var_name].field_ui.free();
	exposed_fields.erase(var_name);

func field_exists (var_name: String):
	return exposed_fields.has(var_name);

func get_field (var_name: String):
	return exposed_fields[var_name].val;

func set_field (var_name: String, val: Variant):
	exposed_fields[var_name].val = val;
	exposed_fields[var_name].update_ui_func.call(val);
	exposed_field_changed.emit(var_name, val);


# ============= PRIVATE UTILS =============

func _setup_exposed_field_ui (var_name: String, field_ui: Control):
	var box = HSplitContainer.new();
	var label = Label.new();
	box.name = var_name + "_EXPOSED_FIELD";
	label.text = var_name;
	$Controls/Body/UtilControls.add_child(box);
	box.add_child(label);
	box.add_child(field_ui);

func _load_resources():
	loaded_resources.assign(resource_paths.map(func (path): return load(path)));
	resources_loaded.emit(loaded_resources);


# ============= SIGNAL HANDLERS =============

func _on_resource_change (resource: Resource, var_name: String):
	if not resource:
		# Clear inspector
		EditorInterface.edit_node(null);
	exposed_fields[var_name].val = resource;
	exposed_field_changed.emit(var_name, resource);

func _on_resource_selected (resource: Resource, inspect: bool):
	if resource:
		EditorInterface.edit_resource(resource);

func _on_text_changed(new_text: String, var_name: String):
	exposed_fields[var_name].val = new_text;
	exposed_field_changed.emit(var_name, new_text);

func _on_collapsable_toggled (toggled_on: bool):
	if toggled_on:
		_load_resources();


# ============= VIRTUALS =============

# Override me
func _on_exposed_field_change (var_name: String, val):
	pass;

func _on_resources_loaded (resources: Array[Resource]):
	pass;
