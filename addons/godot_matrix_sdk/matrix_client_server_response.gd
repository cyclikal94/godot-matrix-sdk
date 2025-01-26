@icon("res://addons/godot_matrix_sdk/matrix_icon.svg")
class_name MatrixClientServerResponse

@export var status: Error
@export var message: String
var response: Variant

func _init(error_status: Error, msg: String, resp: Variant = null):
	self.status = error_status

	if error_status == OK:
		self.message = "Completed Successfully."
	elif msg == "":
		self.message = "No Error Message Defined."
	else:
		self.message = msg

	self.response = resp
