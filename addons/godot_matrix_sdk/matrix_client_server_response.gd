@icon("res://addons/godot_matrix_sdk/matrix_icon.svg")
extends Resource
class_name MatrixClientServerResponse

var status: Error
var message: String
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
