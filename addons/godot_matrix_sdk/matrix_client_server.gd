@icon("res://addons/godot_matrix_sdk/matrix_icon.svg")
extends Node
## A component that can be used to interact with the Matrix Client-Server API
class_name MatrixClientServer

## Matrix Homeserver
@export var homeserver: String
## Matrix Access Token
@export var access_token: String
var mxid: String
var localpart: String
var homeserver_delegated: String
var wellknown: JSON
var headers: PackedStringArray

func _request() -> HTTPRequest:
	var http_request: HTTPRequest = HTTPRequest.new()
	add_child(http_request)
	return http_request

func _int_to_bool_string(bool_as_int: int) -> String:
	if bool_as_int == 0:
		return "false"
	elif bool_as_int == 1:
		return "true"
	else:
		return ""

func _int_to_string(int_to_str: int) -> String:
	if int_to_str != -9999:
		return str(int_to_str)
	else:
		return ""

## Validate provided string is a MXID (`@exanple:matrix.org`)
func mxid_validate(matrix_id: String) -> bool:
	var validation: RegEx = RegEx.new()
	validation.compile(r"^@[a-zA-Z0-9._=-]+:[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
	if validation.search(matrix_id):
		return true
	else:
		return false

## Split a MXID (`@exanple:matrix.org`) into localpart and homeserver
## Used by `mxid_to_localpart` and `mxid_to_homeserver`
func _mxid_split(matrix_id: String, to: bool) -> MatrixClientServerResponse:
	if self.mxid_validate(matrix_id) == false:
		return MatrixClientServerResponse.new(FAILED, "MXID validation failed. Use `mxid_validate()` for true/false validation of MXID.")

	var requested_part: int = 0 if to else 1
	var split: RegEx = RegEx.new()
	split.compile(r"^@([a-zA-Z0-9._=-]+):([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})$")
	var split_result: RegExMatch = split.search(matrix_id)
	if split_result:
		var split_array: Array = [split_result.get_string(1),split_result.get_string(2)]
		return MatrixClientServerResponse.new(OK, "", split_array[requested_part])
	else:
		return MatrixClientServerResponse.new(FAILED, "Split of validated MXID failed! Something went wrong!")

## Return localpart of provided `matrix_id`
## I.e. `@example:matrix.org` returns `example`
func mxid_to_localpart(matrix_id: String) -> MatrixClientServerResponse:
	return _mxid_split(matrix_id, true)

## Return homeserver of provided `matrix_id`
## I.e. `@example:matrix.org` returns `matrix.org`
func mxid_to_homeserver(matrix_id: String) -> MatrixClientServerResponse:
	return _mxid_split(matrix_id, false)

## Validate the provided `url` string is a valid URL
func url_validate(url: String) -> bool:
	var validation: RegEx = RegEx.new()
	validation.compile(r"^((http|https):\/\/)?([a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,})(:([0-9]{1,5}))?(\/([^\s]*))?$")
	if validation.search(url):
		return true
	else:
		return false

## Format provided `url` string to confirm protocol (`http` / `https`) and no trailing `/`
## If provided `url` has no protocol, `https://` is added by default
func url_formatter(url: String) -> MatrixClientServerResponse:
	var formatter: RegEx = RegEx.new()
	# URL Pattern Matching Group Examples
	# Group 1: `http://` or `https://`
	# Group 2: `http` or `https`
	# Group 3: `sub.domain.com`
	# Group 5: `:1234`
	# Group 6: `1234`
	# Group 7: `/path`
	# Group 8: `path`
	formatter.compile(r"^((http|https):\/\/)?([a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,})(:([0-9]{1,5}))?(\/([^\s]*))?$")
	var formatter_result: RegExMatch = formatter.search(url)
	if formatter_result:
		var protocol: String = formatter_result.get_string(1)
		var domain: String = formatter_result.get_string(3)
		var port: String = formatter_result.get_string(5)
		var path: String = formatter_result.get_string(7)
		if path.ends_with("/"):
			path = path.left(-1)
		if protocol == "":
			protocol = "https://"
		return MatrixClientServerResponse.new(OK, "", "{protocol}{domain}{port}{path}".format({"protocol":protocol,"domain":domain,"port":port,"path":path}))
	else:
		return MatrixClientServerResponse.new(FAILED, "Provided string is not a valid URL.")


#func get_account_data(user_mxid: String, data_type: String) -> MatrixClientServerResponse:
	#var http_request: HTTPRequest = _request()
	#var url = homeserver + "/_matrix/client/v3/user/" + user_mxid + "/account_data/" + data_type
	#var request = http_request.request(url, headers, HTTPClient.METHOD_GET)
#
	#if request != OK:
		#http_request.queue_free()
		#return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")
#
	#var account_data_http_response : Array = await http_request.request_completed
	#var json: JSON = JSON.new()
	#var json_parsed: int = json.parse(account_data_http_response[3].get_string_from_utf8())
#
	#if json_parsed != OK:
		#http_request.queue_free()
		#return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + account_data_http_response[3].get_string_from_utf8())
#
	#var response_body: Dictionary = json.get_data()
	#var account_data : Dictionary = {
		#"response_status": account_data_http_response[0],
		#"response_code": account_data_http_response[1],
		#"headers": account_data_http_response[2],
		#"body": response_body,
	#}
#
	#http_request.queue_free()
#
	#if account_data.response_code == 200:
		#return MatrixClientServerResponse.new(OK, "The account data content for the given type.", account_data)
	#elif account_data.response_code == 401:
		#return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", account_data)
	#elif account_data.response_code == 403:
		#return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The access token provided is not authorized to retrieve this user's account data. Errcode: `M_FORBIDDEN`.", account_data)
	#elif account_data.response_code == 404:
		#return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "No account data has been provided for this user with the given `type`. Errcode: `M_NOT_FOUND`.", account_data)
	#else:
		#return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned - " + str(account_data.response_code) + ".")

############################################
## Matrix Client-Server Client Config API ##
############################################

## Set some account data for the user.
## Set some account data for the client. This config is only visible to the user
##		that set the account data. The config will be available to clients through the
##		top-level `account_data` field in the homeserver response to
##		[/sync](#get_matrixclientv3sync).
##
## Parameters:
## - userId: String - The ID of the user to set account data for. The access token must be
##		authorized to make requests for this user ID.
## - type: String - The event type of the account data to set. Custom types should be
##		namespaced to avoid clashes.
## - data: Dictionary - The content of the account data. - {'custom_account_data_key': 'custom_config_value'}
func set_account_data(data: Dictionary, userId: String, type: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/user/" + userId + "/account_data/" + type + ""
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_PUT, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The account data was successfully added.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, "The request body is not a JSON object. Errcode: `M_BAD_JSON` or `M_NOT_JSON`.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "The access token provided is not authorized to modify this user's account  data. Errcode: `M_FORBIDDEN`.", output)
	elif output.response_code == 405:
		return MatrixClientServerResponse.new(FAILED, "This `type` of account data is controlled by the server; it cannot be modified by clients. Errcode: `M_BAD_JSON`.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Get some account data for the user.
## Get some account data for the client. This config is only visible to the user
##		that set the account data.
##
## Parameters:
## - userId: String - The ID of the user to get account data for. The access token must be
##		authorized to make requests for this user ID.
## - type: String - The event type of the account data to get. Custom types should be
##		namespaced to avoid clashes.
func get_account_data(userId: String, type: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/user/" + userId + "/account_data/" + type + ""
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The account data content for the given type.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "The access token provided is not authorized to retrieve this user's account  data. Errcode: `M_FORBIDDEN`.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "No account data has been provided for this user with the given `type`. Errcode: `M_NOT_FOUND`.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Set some account data for the user that is specific to a room.
## Set some account data for the client on a given room. This config is only
##		visible to the user that set the account data. The config will be delivered to
##		clients in the per-room entries via [/sync](#get_matrixclientv3sync).
##
## Parameters:
## - userId: String - The ID of the user to set account data for. The access token must be
##		authorized to make requests for this user ID.
## - roomId: String - The ID of the room to set account data on.
## - type: String - The event type of the account data to set. Custom types should be
##		namespaced to avoid clashes.
## - data: Dictionary - The content of the account data. - {'custom_account_data_key': 'custom_account_data_value'}
func set_account_data_per_room(data: Dictionary, userId: String, roomId: String, type: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/user/" + userId + "/rooms/" + roomId + "/account_data/" + type + ""
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_PUT, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The account data was successfully added.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, "The request body is not a JSON object (errcode `M_BAD_JSON` or `M_NOT_JSON`), or the given `roomID` is not a valid room ID (errcode `M_INVALID_PARAM`).", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "The access token provided is not authorized to modify this user's account  data. Errcode: `M_FORBIDDEN`.", output)
	elif output.response_code == 405:
		return MatrixClientServerResponse.new(FAILED, "This `type` of account data is controlled by the server; it cannot be modified by clients. Errcode: `M_BAD_JSON`.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Get some account data for the user that is specific to a room.
## Get some account data for the client on a given room. This config is only
##		visible to the user that set the account data.
##
## Parameters:
## - userId: String - The ID of the user to get account data for. The access token must be
##		authorized to make requests for this user ID.
## - roomId: String - The ID of the room to get account data for.
## - type: String - The event type of the account data to get. Custom types should be
##		namespaced to avoid clashes.
func get_account_data_per_room(userId: String, roomId: String, type: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/user/" + userId + "/rooms/" + roomId + "/account_data/" + type + ""
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The account data content for the given type.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, "The given `roomID` is not a valid room ID. Errcode: `M_INVALID_PARAM`.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "The access token provided is not authorized to retrieve this user's account  data. Errcode: `M_FORBIDDEN`.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "No account data has been provided for this user and this room with the  given `type`. Errcode: `M_NOT_FOUND`.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#############################################
## Matrix Client-Server Administration API ##
#############################################

## Gets information about a particular user.
## Gets information about a particular user.
##
##		This API may be restricted to only be called by the user being looked
##		up, or by a server admin. Server-local administrator privileges are not
##		specified in this document.
##
## Parameters:
## - userId: String - The user to look up.
func get_who_is(userId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/admin/whois/" + userId + ""
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The lookup was successful.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#############################################################
## Matrix Client-Server Account Administrative Contact API ##
#############################################################

## Gets a list of a user's third-party identifiers.
## Gets a list of the third-party identifiers that the homeserver has
##		associated with the user's account.
##
##		This is *not* the same as the list of third-party identifiers bound to
##		the user's Matrix ID in identity servers.
##
##		Identifiers in this list may be used by the homeserver as, for example,
##		identifiers that it will accept to reset the user's account password.
func get_account3_p_i_ds() -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/account/3pid"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The lookup was successful.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Adds contact information to the user's account.
## Adds contact information to the user's account.
##
##		This endpoint is deprecated in favour of the more specific `/3pid/add`
##		and `/3pid/bind` endpoints.
##
##		**Note:**
##		Previously this endpoint supported a `bind` parameter. This parameter
##		has been removed, making this endpoint behave as though it was `false`.
##		This results in this endpoint being an equivalent to `/3pid/bind` rather
##		than dual-purpose.
func post3_p_i_ds(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/account/3pid"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The addition was successful.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "The credentials could not be verified with the identity server.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Adds contact information to the user's account.
## This API endpoint uses the [User-Interactive Authentication API](/client-server-api/#user-interactive-authentication-api).
##
##		Adds contact information to the user's account. Homeservers should use 3PIDs added
##		through this endpoint for password resets instead of relying on the identity server.
##
##		Homeservers should prevent the caller from adding a 3PID to their account if it has
##		already been added to another user's account on the homeserver.
func add3_p_i_d(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/account/3pid/add"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The addition was successful.", output)
	elif output.response_code == 401:
		return MatrixClientServerResponse.new(FAILED, "The homeserver requires additional authentication information.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Binds a 3PID to the user's account through an Identity Service.
## Binds a 3PID to the user's account through the specified identity server.
##
##		Homeservers should not prevent this request from succeeding if another user
##		has bound the 3PID. Homeservers should simply proxy any errors received by
##		the identity server to the caller.
##
##		Homeservers should track successful binds so they can be unbound later.
func bind3_p_i_d(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/account/3pid/bind"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The addition was successful.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Deletes a third-party identifier from the user's account
## Removes a third-party identifier from the user's account. This might not
##		cause an unbind of the identifier from the identity server.
##
##		Unlike other endpoints, this endpoint does not take an `id_access_token`
##		parameter because the homeserver is expected to sign the request to the
##		identity server instead.
func delete3pid_from_account(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/account/3pid/delete"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The homeserver has disassociated the third-party identifier from the user.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Removes a user's third-party identifier from an identity server.
## Removes a user's third-party identifier from the provided identity server
##		without removing it from the homeserver.
##
##		Unlike other endpoints, this endpoint does not take an `id_access_token`
##		parameter because the homeserver is expected to sign the request to the
##		identity server instead.
func unbind3pid_from_account(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/account/3pid/unbind"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The identity server has disassociated the third-party identifier from the user.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Begins the validation process for an email address for association with the user's account.
## The homeserver must check that the given email address is **not**
##		already associated with an account on this homeserver. This API should
##		be used to request validation tokens when adding an email address to an
##		account. This API's parameters and response are identical to that of
##		the [`/register/email/requestToken`](/client-server-api/#post_matrixclientv3registeremailrequesttoken)
##		endpoint. The homeserver should validate
##		the email itself, either by sending a validation email itself or by using
##		a service it has control over.
func request_token_to3_p_i_d_email(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/account/3pid/email/requestToken"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "An email was sent to the given address. Note that this may be an email containing the validation token or it may be informing the user of an error.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, "The third-party identifier is already in use on the homeserver, or the request was invalid. The error code `M_SERVER_NOT_TRUSTED` can be returned if the server does not trust/support the identity server provided in the request.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "The homeserver does not allow the third-party identifier as a contact option.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Begins the validation process for a phone number for association with the user's account.
## The homeserver must check that the given phone number is **not**
##		already associated with an account on this homeserver. This API should
##		be used to request validation tokens when adding a phone number to an
##		account. This API's parameters and response are identical to that of
##		the [`/register/msisdn/requestToken`](/client-server-api/#post_matrixclientv3registermsisdnrequesttoken)
##		endpoint. The homeserver should validate
##		the phone number itself, either by sending a validation message itself or by using
##		a service it has control over.
func request_token_to3_p_i_d_m_s_i_s_d_n(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/account/3pid/msisdn/requestToken"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "An SMS message was sent to the given phone number.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, "The third-party identifier is already in use on the homeserver, or the request was invalid. The error code `M_SERVER_NOT_TRUSTED` can be returned if the server does not trust/support the identity server provided in the request.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "The homeserver does not allow the third-party identifier as a contact option.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


###########################################
## Matrix Client-Server Room Banning API ##
###########################################

## Ban a user in the room.
## Ban a user in the room. If the user is currently in the room, also kick them.
##
##		When a user is banned from a room, they may not join it or be invited to it until they are unbanned.
##
##		The caller must have the required power level in order to perform this operation.
##
## Parameters:
## - roomId: String - The room identifier (not alias) from which the user should be banned.
## - data: Dictionary - {'reason': 'Telling unfunny jokes', 'user_id': '@cheeky_monkey:matrix.org'}
func ban(data: Dictionary, roomId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/ban"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The user has been kicked and banned from the room.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "You do not have permission to ban the user from the room. A meaningful `errcode` and description error text will be returned. Example reasons for rejections are:  - The banner is not currently in the room. - The banner's power level is insufficient to ban users from the room.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Unban a user from the room.
## Unban a user from the room. This allows them to be invited to the room,
##		and join if they would otherwise be allowed to join according to its join rules.
##
##		The caller must have the required power level in order to perform this operation.
##
## Parameters:
## - roomId: String - The room identifier (not alias) from which the user should be unbanned.
## - data: Dictionary - {'user_id': '@cheeky_monkey:matrix.org', 'reason': "They've been banned long enough"}
func unban(data: Dictionary, roomId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/unban"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The user has been unbanned from the room.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "You do not have permission to unban the user from the room. A meaningful `errcode` and description error text will be returned. Example reasons for rejections are:  - The unbanner's power level is insufficient to unban users from the room.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


###########################################
## Matrix Client-Server Capabilities API ##
###########################################

## Gets information about the server's capabilities.
## Gets information about the server's supported feature set
##		and other relevant capabilities.
func get_capabilities() -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/capabilities"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The capabilities of the server.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


############################################
## Matrix Client-Server Room Creation API ##
############################################

## Create a new room
## Create a new room with various configuration options.
##
##		The server MUST apply the normal state resolution rules when creating
##		the new room, including checking power levels for each event. It MUST
##		apply the events implied by the request in the following order:
##
##		1. The `m.room.create` event itself. Must be the first event in the
##		   room.
##
##		2. An `m.room.member` event for the creator to join the room. This is
##		   needed so the remaining events can be sent.
##
##		3. A default `m.room.power_levels` event, giving the room creator
##		   (and not other members) permission to send state events. Overridden
##		   by the `power_level_content_override` parameter.
##
##		4. An `m.room.canonical_alias` event if `room_alias_name` is given.
##
##		5. Events set by the `preset`. Currently these are the `m.room.join_rules`,
##		   `m.room.history_visibility`, and `m.room.guest_access` state events.
##
##		6. Events listed in `initial_state`, in the order that they are
##		   listed.
##
##		7. Events implied by `name` and `topic` (`m.room.name` and `m.room.topic`
##		   state events).
##
##		8. Invite events implied by `invite` and `invite_3pid` (`m.room.member` with
##		   `membership: invite` and `m.room.third_party_invite`).
##
##		The available presets do the following with respect to room state:
##
##		| Preset                 | `join_rules` | `history_visibility` | `guest_access` | Other |
##		|------------------------|--------------|----------------------|----------------|-------|
##		| `private_chat`         | `invite`     | `shared`             | `can_join`     |       |
##		| `trusted_private_chat` | `invite`     | `shared`             | `can_join`     | All invitees are given the same power level as the room creator. |
##		| `public_chat`          | `public`     | `shared`             | `forbidden`    |       |
##
##		The server will create a `m.room.create` event in the room with the
##		requesting user as the creator, alongside other keys provided in the
##		`creation_content`.
func create_room(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/createRoom"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "Information about the newly created room.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, " The request is invalid. A meaningful `errcode` and description error text will be returned. Example reasons for rejection include:  - The request body is malformed (`errcode` set to `M_BAD_JSON`   or `M_NOT_JSON`).  - The room alias specified is already taken (`errcode` set to   `M_ROOM_IN_USE`).  - The initial state implied by the parameters to the request is   invalid: for example, the user's `power_level` is set below   that necessary to set the room name (`errcode` set to   `M_INVALID_ROOM_STATE`).  - The homeserver doesn't support the requested room version, or   one or more users being invited to the new room are residents   of a homeserver which does not support the requested room version.   The `errcode` will be `M_UNSUPPORTED_ROOM_VERSION` in these   cases.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


############################################
## Matrix Client-Server Cross Signing API ##
############################################

## Upload cross-signing keys.
## Publishes cross-signing keys for the user.
##
##		This API endpoint uses the [User-Interactive Authentication API](/client-server-api/#user-interactive-authentication-api).
##
##		User-Interactive Authentication MUST be performed, except in these cases:
##		- there is no existing cross-signing master key uploaded to the homeserver, OR
##		- there is an existing cross-signing master key and it exactly matches the
##		  cross-signing master key provided in the request body. If there are any additional
##		  keys provided in the request (self-signing key, user-signing key) they MUST also
##		  match the existing keys stored on the server. In other words, the request contains
##		  no new keys.
##
##		This allows clients to freely upload one set of keys, but not modify/overwrite keys if
##		they already exist. Allowing clients to upload the same set of keys more than once
##		makes this endpoint idempotent in the case where the response is lost over the network,
##		which would otherwise cause a UIA challenge upon retry.
func upload_cross_signing_keys(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/keys/device_signing/upload"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The provided keys were successfully uploaded.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, "The input was invalid in some way. This can include one of the following error codes:  * `M_INVALID_SIGNATURE`: For example, the self-signing or   user-signing key had an incorrect signature. * `M_MISSING_PARAM`: No master key is available.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "The public key of one of the keys is the same as one of the user\'s device IDs, or the request is not authorized for any other reason.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Upload cross-signing signatures.
## Publishes cross-signing signatures for the user.
##
##		The signed JSON object must match the key previously uploaded or
##		retrieved for the given key ID, with the exception of the `signatures`
##		property, which contains the new signature(s) to add.
func upload_cross_signing_signatures(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/keys/signatures/upload"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The provided signatures were processed.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


################################################
## Matrix Client-Server device management API ##
################################################

## List registered devices for the current user
## Gets information about all devices for the current user.
func get_devices() -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/devices"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "Device information", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Get a single device
## Gets information on a single device, by device id.
##
## Parameters:
## - deviceId: String - The device to retrieve.
func get_device(deviceId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/devices/" + deviceId + ""
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "Device information", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The current user has no device with the given ID.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Update a device
## Updates the metadata on the given device.
##
## Parameters:
## - deviceId: String - The device to update.
## - data: Dictionary - New information for the device. - {'display_name': 'My other phone'}
func update_device(data: Dictionary, deviceId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/devices/" + deviceId + ""
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_PUT, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The device was successfully updated.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The current user has no device with the given ID.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Delete a device
## This API endpoint uses the [User-Interactive Authentication API](/client-server-api/#user-interactive-authentication-api).
##
##		Deletes the given device, and invalidates any access token associated with it.
##
## Parameters:
## - deviceId: String - The device to delete.
func delete_device(deviceId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/devices/" + deviceId + ""
	var request = http_request.request(url, headers, HTTPClient.METHOD_DELETE)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The device was successfully removed, or had been removed previously.", output)
	elif output.response_code == 401:
		return MatrixClientServerResponse.new(FAILED, "The homeserver requires additional authentication information.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Bulk deletion of devices
## This API endpoint uses the [User-Interactive Authentication API](/client-server-api/#user-interactive-authentication-api).
##
##		Deletes the given devices, and invalidates any access token associated with them.
func delete_devices(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/delete_devices"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The devices were successfully removed, or had been removed previously.", output)
	elif output.response_code == 401:
		return MatrixClientServerResponse.new(FAILED, "The homeserver requires additional authentication information.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


############################################
## Matrix Client-Server Event Context API ##
############################################

## Get events and state around the specified event.
## This API returns a number of events that happened just before and
##		after the specified event. This allows clients to get the context
##		surrounding an event.
##
##		*Note*: This endpoint supports lazy-loading of room member events. See
##		[Lazy-loading room members](/client-server-api/#lazy-loading-room-members) for more information.
##
## Parameters:
## - roomId: String - The room to get events from.
## - eventId: String - The event to get context around.
## - limit: (Optional) int - The maximum number of context events to return. The limit applies
##		to the sum of the `events_before` and `events_after` arrays. The
##		requested event ID is always returned in `event` even if `limit` is
##		0. Defaults to 10.
## - filter: (Optional) String - A JSON `RoomEventFilter` to filter the returned events with. The
##		filter is only applied to `events_before`, `events_after`, and
##		`state`. It is not applied to the `event` itself. The filter may
##		be applied before or/and after the `limit` parameter - whichever the
##		homeserver prefers.
##
##		See [Filtering](/client-server-api/#filtering) for more information.
func get_event_context(roomId: String, eventId: String, limit: int = -9999, filter: String = "") -> MatrixClientServerResponse:
	var optional_url_params: String = ""
	optional_url_params = "" if _int_to_string(limit) == "" else "limit=" + _int_to_string(limit)
	optional_url_params = optional_url_params + ( "" if str(filter) == "" else "&filter=" + str(filter) )
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/context/" + eventId + "" + "?" + optional_url_params
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The events and state surrounding the requested event.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


###########################################
## Matrix Client-Server Room Joining API ##
###########################################

## Invite a user to participate in a particular room.
## *Note that there are two forms of this API, which are documented separately.
##		This version of the API requires that the inviter knows the Matrix
##		identifier of the invitee. The other is documented in the
##		[third-party invites](/client-server-api/#third-party-invites) section.*
##
##		This API invites a user to participate in a particular room.
##		They do not start participating in the room until they actually join the
##		room.
##
##		Only users currently in a particular room can invite other users to
##		join that room.
##
##		If the user was invited to the room, the homeserver will append a
##		`m.room.member` event to the room.
##
## Parameters:
## - roomId: String - The room identifier (not alias) to which to invite the user.
## - data: Dictionary - {'user_id': '@cheeky_monkey:matrix.org', 'reason': 'Welcome to the team!'}
func invite_user(data: Dictionary, roomId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/invite "
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The user has been invited to join the room, or was already invited to the room.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, " The request is invalid. A meaningful `errcode` and description error text will be returned. Example reasons for rejection include:  - The request body is malformed (`errcode` set to `M_BAD_JSON`   or `M_NOT_JSON`).  - One or more users being invited to the room are residents of a   homeserver which does not support the requested room version. The   `errcode` will be `M_UNSUPPORTED_ROOM_VERSION` in these cases.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "You do not have permission to invite the user to the room. A meaningful `errcode` and description error text will be returned. Example reasons for rejections are:  - The invitee has been banned from the room. - The invitee is already a member of the room. - The inviter is not currently in the room. - The inviter's power level is insufficient to invite users to the room.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


############################################
## Matrix Client-Server Client Config API ##
############################################

## Upload end-to-end encryption keys.
## Publishes end-to-end encryption keys for the device.
func upload_keys(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/keys/upload"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The provided keys were successfully uploaded.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Download device identity keys.
## Returns the current devices and identity keys for the given users.
func query_keys(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/keys/query"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The device information", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Claim one-time encryption keys.
## Claims one-time keys for use in pre-key messages.
func claim_keys(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/keys/claim"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The claimed keys.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Query users with recent device key updates.
## Gets a list of users who have updated their device identity keys since a
##		previous sync token.
##
##		The server should include in the results any users who:
##
##		* currently share a room with the calling user (ie, both users have
##		  membership state `join`); *and*
##		* added new device identity keys or removed an existing device with
##		  identity keys, between `from` and `to`.
##
## Parameters:
## - from: String - The desired start point of the list. Should be the `next_batch` field
##		from a response to an earlier call to [`/sync`](/client-server-api/#get_matrixclientv3sync). Users who have not
##		uploaded new device identity keys since this point, nor deleted
##		existing devices with identity keys since then, will be excluded
##		from the results.
## - to: String - The desired end point of the list. Should be the `next_batch`
##		field from a recent call to [`/sync`](/client-server-api/#get_matrixclientv3sync) - typically the most recent
##		such call. This may be used by the server as a hint to check its
##		caches are up to date.
func get_keys_changes(from: String, to: String) -> MatrixClientServerResponse:
	var url_params: String = ""
	url_params = "?from=" + str(from) + "&to=" + str(to)
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/keys/changes" + "?" + url_params
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The list of users who updated their devices.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


###########################################
## Matrix Client-Server Room Kicking API ##
###########################################

## Kick a user from the room.
## Kick a user from the room.
##
##		The caller must have the required power level in order to perform this operation.
##
##		Kicking a user adjusts the target member's membership state to be `leave` with an
##		optional `reason`. Like with other membership changes, a user can directly adjust
##		the target member's state by making a request to `/rooms/<room id>/state/m.room.member/<user id>`.
##
## Parameters:
## - roomId: String - The room identifier (not alias) from which the user should be kicked.
## - data: Dictionary - {'reason': 'Telling unfunny jokes', 'user_id': '@cheeky_monkey:matrix.org'}
func kick(data: Dictionary, roomId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/kick"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The user has been kicked from the room.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "You do not have permission to kick the user from the room. A meaningful `errcode` and description error text will be returned. Example reasons for rejections are:  - The kicker is not currently in the room. - The kickee is not currently in the room. - The kicker's power level is insufficient to kick users from the room.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


###########################################
## Matrix Client-Server Room Listing API ##
###########################################

## Lists the user's current rooms.
## This API returns a list of the user's current rooms.
func get_joined_rooms() -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/joined_rooms"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "A list of the rooms the user is in.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#############################################
## Matrix Client-Server Room Directory API ##
#############################################

## Gets the visibility of a room in the directory
## Gets the visibility of a given room on the server's public room directory.
##
## Parameters:
## - roomId: String - The room ID.
func get_room_visibility_on_directory(roomId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/directory/list/room/" + roomId + ""
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The visibility of the room in the directory", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The room is not known to the server", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Sets the visibility of a room in the room directory
## Sets the visibility of a given room in the server's public room
##		directory.
##
##		Servers may choose to implement additional access control checks
##		here, for instance that room visibility can only be changed by
##		the room creator or a server administrator.
##
## Parameters:
## - roomId: String - The room ID.
## - data: Dictionary - The new visibility for the room on the room directory. - {'visibility': 'public'}
func set_room_visibility_on_directory(data: Dictionary, roomId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/directory/list/room/" + roomId + ""
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_PUT, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The visibility was updated, or no change was needed.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The room is not known to the server", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Lists the public rooms on the server.
## Lists the public rooms on the server.
##
##		This API returns paginated responses. The rooms are ordered by the number
##		of joined members, with the largest rooms first.
##
## Parameters:
## - limit: (Optional) int - Limit the number of results returned.
## - since: (Optional) String - A pagination token from a previous request, allowing clients to
##		get the next (or previous) batch of rooms.
##		The direction of pagination is specified solely by which token
##		is supplied, rather than via an explicit flag.
## - server: (Optional) String - The server to fetch the public room lists from. Defaults to the
##		local server. Case sensitive.
func get_public_rooms(limit: int = -9999, since: String = "", server: String = "") -> MatrixClientServerResponse:
	var optional_url_params: String = ""
	optional_url_params = "" if _int_to_string(limit) == "" else "limit=" + _int_to_string(limit)
	optional_url_params = optional_url_params + ( "" if str(since) == "" else "&since=" + str(since) )
	optional_url_params = optional_url_params + ( "" if str(server) == "" else "&server=" + str(server) )
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/publicRooms" + "?" + optional_url_params
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "A list of the rooms on the server.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Lists the public rooms on the server with optional filter.
## Lists the public rooms on the server, with optional filter.
##
##		This API returns paginated responses. The rooms are ordered by the number
##		of joined members, with the largest rooms first.
##
## Parameters:
## - server: (Optional) String - The server to fetch the public room lists from. Defaults to the
##		local server. Case sensitive.
## - data: Dictionary - Options for which rooms to return. - {'limit': 10, 'filter': {'generic_search_term': 'foo', 'room_types': [None, 'm.space']}, 'include_all_networks': False, 'third_party_instance_id': 'irc'}
func query_public_rooms(data: Dictionary, server: String = "") -> MatrixClientServerResponse:
	var optional_url_params: String = ""
	optional_url_params = "" if str(server) == "" else "server=" + str(server)
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/publicRooms" + "?" + optional_url_params
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "A list of the rooms on the server.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#####################################################
## Matrix Client-Server Registration and Login API ##
#####################################################

## Get the supported login types to authenticate users
## Gets the homeserver's supported login types to authenticate users. Clients
##		should pick one of these and supply it as the `type` when logging in.
func get_login_flows() -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/login"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The login types the homeserver supports", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Authenticates the user.
## Authenticates the user, and issues an access token they can
##		use to authorize themself in subsequent requests.
##
##		If the client does not supply a `device_id`, the server must
##		auto-generate one.
##
##		The returned access token must be associated with the `device_id`
##		supplied by the client or generated by the server. The server may
##		invalidate any access token previously associated with that device. See
##		[Relationship between access tokens and devices](/client-server-api/#relationship-between-access-tokens-and-devices).
func login(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/login"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The user has been authenticated.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, "Part of the request was invalid. For example, the login type may not be recognised.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "The login attempt failed. This can include one of the following error codes:   * `M_FORBIDDEN`: The provided authentication data was incorrect     or the requested device ID is the same as a cross-signing key     ID.   * `M_USER_DEACTIVATED`: The user has been deactivated.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#####################################################
## Matrix Client-Server Registration and Login API ##
#####################################################

## Optional endpoint to generate a single-use, time-limited, `m.login.token` token.
## Optional endpoint - the server is not required to implement this endpoint if it does not
##		intend to use or support this functionality.
##
##		This API endpoint uses the [User-Interactive Authentication API](/client-server-api/#user-interactive-authentication-api).
##
##		An already-authenticated client can call this endpoint to generate a single-use, time-limited,
##		token for an unauthenticated client to log in with, becoming logged in as the same user which
##		called this endpoint. The unauthenticated client uses the generated token in a `m.login.token`
##		login flow with the homeserver.
##
##		Clients, both authenticated and unauthenticated, might wish to hide user interface which exposes
##		this feature if the server is not offering it. Authenticated clients can check for support on
##		a per-user basis with the [`m.get_login_token`](/client-server-api/#mget_login_token-capability) capability,
##		while unauthenticated clients can detect server support by looking for an `m.login.token` login
##		flow with `get_login_token: true` on [`GET /login`](/client-server-api/#post_matrixclientv3login).
##
##		In v1.7 of the specification, transmission of the generated token to an unauthenticated client is
##		left as an implementation detail. Future MSCs such as [MSC3906](https://github.com/matrix-org/matrix-spec-proposals/pull/3906)
##		might standardise a way to transmit the token between clients.
##
##		The generated token MUST only be valid for a single login, enforced by the server. Clients which
##		intend to log in multiple devices must generate a token for each.
##
##		With other User-Interactive Authentication (UIA)-supporting endpoints, servers sometimes do not re-prompt
##		for verification if the session recently passed UIA. For this endpoint, servers MUST always re-prompt
##		the user for verification to ensure explicit consent is gained for each additional client.
##
##		Servers are encouraged to apply stricter than normal rate limiting to this endpoint, such as maximum
##		of 1 request per minute.
func generate_login_token(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v1" + "/login/get_token"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The login token an unauthenticated client can use to log in as the requesting user.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, "The request was malformed, or the user does not have an ability to generate tokens for their devices, as implied by the [User-Interactive Authentication API](/client-server-api/#user-interactive-authentication-api).  Clients should verify whether the user has an ability to call this endpoint with the [`m.get_login_token`](/client-server-api/#mget_login_token-capability) capability.", output)
	elif output.response_code == 401:
		return MatrixClientServerResponse.new(FAILED, "The homeserver requires additional authentication information.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#####################################################
## Matrix Client-Server Registration and Login API ##
#####################################################

## Invalidates a user access token
## Invalidates an existing access token, so that it can no longer be used for
##		authorization. The device associated with the access token is also deleted.
##		[Device keys](/client-server-api/#device-keys) for the device are deleted alongside the device.
func logout(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/logout"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The access token used in the request was successfully invalidated.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Invalidates all access tokens for a user
## Invalidates all access tokens for a user, so that they can no longer be used for
##		authorization. This includes the access token that made this request. All devices
##		for the user are also deleted. [Device keys](/client-server-api/#device-keys) for the device are
##		deleted alongside the device.
##
##		This endpoint does not use the [User-Interactive Authentication API](/client-server-api/#user-interactive-authentication-api) because
##		User-Interactive Authentication is designed to protect against attacks where the
##		someone gets hold of a single access token then takes over the account. This
##		endpoint invalidates all access tokens for the user, including the token used in
##		the request, and therefore the attacker is unable to take over the account in
##		this way.
func logout_all(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/logout/all"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The user's access tokens were successfully invalidated.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


####################################
## Matrix Client-Server Rooms API ##
####################################

## Get a list of events for this room
## This API returns a list of message and state events for a room. It uses
##		pagination query parameters to paginate history in the room.
##
##		*Note*: This endpoint supports lazy-loading of room member events. See
##		[Lazy-loading room members](/client-server-api/#lazy-loading-room-members) for more information.
##
## Parameters:
## - roomId: String - The room to get events from.
## - from: String - The token to start returning events from. This token can be obtained
##		from a `prev_batch` or `next_batch` token returned by the `/sync` endpoint,
##		or from an `end` token returned by a previous request to this endpoint.
##
##		This endpoint can also accept a value returned as a `start` token
##		by a previous request to this endpoint, though servers are not
##		required to support this. Clients should not rely on the behaviour.
##
##		If it is not provided, the homeserver shall return a list of messages
##		from the first or last (per the value of the `dir` parameter) visible
##		event in the room history for the requesting user.
## - to: String - The token to stop returning events at. This token can be obtained from
##		a `prev_batch` or `next_batch` token returned by the `/sync` endpoint,
##		or from an `end` token returned by a previous request to this endpoint.
## - dir: String - The direction to return events from. If this is set to `f`, events
##		will be returned in chronological order starting at `from`. If it
##		is set to `b`, events will be returned in *reverse* chronological
##		order, again starting at `from`.
## - limit: (Optional) int - The maximum number of events to return. Default: 10.
## - filter: (Optional) String - A JSON RoomEventFilter to filter returned events with.
func get_room_events(roomId: String, from: String, to: String, dir: String, limit: int = -9999, filter: String = "") -> MatrixClientServerResponse:
	var url_params: String = ""
	url_params = "?from=" + str(from) + "&to=" + str(to) + "&dir=" + str(dir)
	var optional_url_params: String = ""
	optional_url_params = "" if _int_to_string(limit) == "" else "limit=" + _int_to_string(limit)
	optional_url_params = optional_url_params + ( "" if str(filter) == "" else "&filter=" + str(filter) )
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/messages" + "?" + url_params + optional_url_params
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "A list of messages with a new token to request more.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "You aren't a member of the room. ", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


############################################
## Matrix Client-Server Notifications API ##
############################################

## Gets a list of events that the user has been notified about
## This API is used to paginate through the list of events that the
##		user has been, or would have been notified about.
##
## Parameters:
## - from: String - Pagination token to continue from. This should be the `next_token`
##		returned from an earlier call to this endpoint.
## - limit: int - Limit on the number of events to return in this request.
## - only: String - Allows basic filtering of events returned. Supply `highlight`
##		to return only events where the notification had the highlight
##		tweak set.
func get_notifications(from: String, limit: int, only: String) -> MatrixClientServerResponse:
	var url_params: String = ""
	url_params = "?from=" + str(from) + "&limit=" + str(limit) + "&only=" + str(only)
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/notifications" + "?" + url_params
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "A batch of events is being returned", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


###################################
## Matrix Client-Server Sync API ##
###################################

## Listen on the event stream.
## This will listen for new events and return them to the caller. This will
##		block until an event is received, or until the `timeout` is reached.
##
##		This endpoint was deprecated in r0 of this specification. Clients
##		should instead call the [`/sync`](/client-server-api/#get_matrixclientv3sync)
##		endpoint with a `since` parameter. See
##		the [migration guide](https://matrix.org/docs/guides/migrating-from-client-server-api-v-1#deprecated-endpoints).
##
## Parameters:
## - from: String - The token to stream from. This token is either from a previous
##		request to this API or from the initial sync API.
## - timeout: int - The maximum time in milliseconds to wait for an event.
func get_events(from: String, timeout: int) -> MatrixClientServerResponse:
	var url_params: String = ""
	url_params = "?from=" + str(from) + "&timeout=" + str(timeout)
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/events" + "?" + url_params
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The events received, which may be none.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, "Bad pagination `from` parameter.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Get the user's current state.
## This returns the full state for this user, with an optional limit on the
##		number of messages per room to return.
##
##		This endpoint was deprecated in r0 of this specification. Clients
##		should instead call the [`/sync`](/client-server-api/#get_matrixclientv3sync)
##		endpoint with no `since` parameter. See
##		the [migration guide](https://matrix.org/docs/guides/migrating-from-client-server-api-v-1#deprecated-endpoints).
##
## Parameters:
## - limit: int - The maximum number of messages to return for each room.
## - archived: bool - Whether to include rooms that the user has left. If `false` then
##		only rooms that the user has been invited to or has joined are
##		included. If set to `true` then rooms that the user has left are
##		included as well. By default this is `false`.
func initial_sync(limit: int, archived: bool) -> MatrixClientServerResponse:
	var url_params: String = ""
	url_params = "?limit=" + str(limit) + "&archived=" + str(archived)
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/initialSync" + "?" + url_params
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The user's current state.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "There is no avatar URL for this user or this user does not exist.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Get a single event by event ID.
## Get a single event based on `event_id`. You must have permission to
##		retrieve this event e.g. by being a member in the room for this event.
##
##		This endpoint was deprecated in r0 of this specification. Clients
##		should instead call the
##		[/rooms/{roomId}/event/{eventId}](/client-server-api/#get_matrixclientv3roomsroomideventeventid) API
##		or the [/rooms/{roomId}/context/{eventId](/client-server-api/#get_matrixclientv3roomsroomidcontexteventid) API.
##
## Parameters:
## - eventId: String - The event ID to get.
func get_one_event(eventId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/events/" + eventId + ""
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The full event.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The event was not found or you do not have permission to read this event.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#####################################
## Matrix Client-Server OpenID API ##
#####################################

## Get an OpenID token object to verify the requester's identity.
## Gets an OpenID token object that the requester may supply to another
##		service to verify their identity in Matrix. The generated token is only
##		valid for exchanging for user information from the federation API for
##		OpenID.
##
##		The access token generated is only valid for the OpenID API. It cannot
##		be used to request another OpenID access token or call `/sync`, for
##		example.
##
## Parameters:
## - userId: String - The user to request an OpenID token for. Should be the user who
##		is authenticated for the request.
## - data: Dictionary - An empty object. Reserved for future expansion. - {}
func request_open_id_token(data: Dictionary, userId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/user/" + userId + "/openid/request_token"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "OpenID token information. This response is nearly compatible with the response documented in the [OpenID Connect 1.0 Specification](http://openid.net/specs/openid-connect-core-1_0.html#TokenResponse) with the only difference being the lack of an `id_token`. Instead, the Matrix homeserver's name is provided.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#########################################
## Matrix Client-Server Sync Guest API ##
#########################################

## Listen on the event stream of a particular room.
## This will listen for new events related to a particular room and return
##		them to the caller. This will block until an event is received, or until
##		the `timeout` is reached.
##
##		This API is the same as the normal `/events` endpoint, but can be
##		called by users who have not joined the room.
##
##		Note that the normal `/events` endpoint has been deprecated. This
##		API will also be deprecated at some point, but its replacement is not
##		yet known.
##
## Parameters:
## - from: String - The token to stream from. This token is either from a previous
##		request to this API or from the initial sync API.
## - timeout: int - The maximum time in milliseconds to wait for an event.
## - room_id: (Optional) String - The room ID for which events should be returned.
func peek_events(from: String, timeout: int, room_id: String = "") -> MatrixClientServerResponse:
	var url_params: String = ""
	url_params = "?from=" + str(from) + "&timeout=" + str(timeout)
	var optional_url_params: String = ""
	optional_url_params = "" if str(room_id) == "" else "room_id=" + str(room_id)
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/events " + "?" + url_params + optional_url_params
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The events received, which may be none.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, "Bad pagination `from` parameter.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#######################################
## Matrix Client-Server Presence API ##
#######################################

## Update this user's presence state.
## This API sets the given user's presence state. When setting the status,
##		the activity time is updated to reflect that activity; the client does
##		not need to specify the `last_active_ago` field. You cannot set the
##		presence state of another user.
##
## Parameters:
## - userId: String - The user whose presence state to update.
## - data: Dictionary - The updated presence state. - {'presence': 'online', 'status_msg': 'I am here.'}
func set_presence(data: Dictionary, userId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/presence/" + userId + "/status"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_PUT, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The new presence state was set.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Get this user's presence state.
## Get the given user's presence state.
##
## Parameters:
## - userId: String - The user whose presence state to get.
func get_presence(userId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/presence/" + userId + "/status"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The presence state for this user.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "You are not allowed to see this user's presence status.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "There is no presence state for this user. This user may not exist or isn't exposing presence information to you.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


######################################
## Matrix Client-Server Profile API ##
######################################

## Set the user's display name.
## This API sets the given user's display name. You must have permission to
##		set this user's display name, e.g. you need to have their `access_token`.
##
## Parameters:
## - userId: String - The user whose display name to set.
## - data: Dictionary - The new display name information. - {'displayname': 'Alice Margatroid'}
func set_display_name(data: Dictionary, userId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/profile/" + userId + "/displayname"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_PUT, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The display name was set.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Get the user's display name.
## Get the user's display name. This API may be used to fetch the user's
##		own displayname or to query the name of other users; either locally or
##		on remote homeservers.
##
## Parameters:
## - userId: String - The user whose display name to get.
func get_display_name(userId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/profile/" + userId + "/displayname"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The display name for this user.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "The server is unwilling to disclose whether the user exists and/or has a display name.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "There is no display name for this user or this user does not exist.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Set the user's avatar URL.
## This API sets the given user's avatar URL. You must have permission to
##		set this user's avatar URL, e.g. you need to have their `access_token`.
##
## Parameters:
## - userId: String - The user whose avatar URL to set.
## - data: Dictionary - The new avatar information. - {'avatar_url': 'mxc://matrix.org/wefh34uihSDRGhw34'}
func set_avatar_url(data: Dictionary, userId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/profile/" + userId + "/avatar_url"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_PUT, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The avatar URL was set.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Get the user's avatar URL.
## Get the user's avatar URL. This API may be used to fetch the user's
##		own avatar URL or to query the URL of other users; either locally or
##		on remote homeservers.
##
## Parameters:
## - userId: String - The user whose avatar URL to get.
func get_avatar_url(userId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/profile/" + userId + "/avatar_url"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The avatar URL for this user.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "The server is unwilling to disclose whether the user exists and/or has an avatar URL.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "There is no avatar URL for this user or this user does not exist.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Get this user's profile information.
## Get the combined profile information for this user. This API may be used
##		to fetch the user's own profile information or other users; either
##		locally or on remote homeservers.
##
## Parameters:
## - userId: String - The user whose profile information to get.
func get_user_profile(userId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/profile/" + userId + ""
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The profile information for this user.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "The server is unwilling to disclose whether the user exists and/or has profile information.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "There is no profile information for this user or this user does not exist.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


###################################
## Matrix Client-Server Push API ##
###################################

## Gets the current pushers for the authenticated user
## Gets all currently active pushers for the authenticated user.
func get_pushers() -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/pushers"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The pushers for this user.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Modify a pusher for this user on the homeserver.
## This endpoint allows the creation, modification and deletion of [pushers](/client-server-api/#push-notifications)
##		for this user ID. The behaviour of this endpoint varies depending on the
##		values in the JSON body.
##
##		If `kind` is not `null`, the pusher with this `app_id` and `pushkey`
##		for this user is updated, or it is created if it doesn't exist. If
##		`kind` is `null`, the pusher with this `app_id` and `pushkey` for this
##		user is deleted.
func post_pusher(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/pushers/set"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The pusher was set.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, "One or more of the pusher values were invalid.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#########################################
## Matrix Client-Server Push Rules API ##
#########################################

## Retrieve all push rulesets.
## Retrieve all push rulesets for this user. Currently the only push ruleset
##		defined is `global`.
func get_push_rules() -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/pushrules/"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "All the push rulesets for this user.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Retrieve all push rules.
## Retrieve all push rules for this user.
func get_push_rules_global() -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/pushrules/global/"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "All the push rules for this user.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Retrieve a push rule.
## Retrieve a single specified push rule.
##
## Parameters:
## - kind: String - The kind of rule
##
## - ruleId: String - The identifier for the rule.
##
func get_push_rule(kind: String, ruleId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/pushrules/global/" + kind + "/" + ruleId + ""
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The specific push rule. This will also include keys specific to the rule itself such as the rule's `actions` and `conditions` if set.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The push rule does not exist.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Delete a push rule.
## This endpoint removes the push rule defined in the path.
##
## Parameters:
## - kind: String - The kind of rule
##
## - ruleId: String - The identifier for the rule.
##
func delete_push_rule(kind: String, ruleId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/pushrules/global/" + kind + "/" + ruleId + ""
	var request = http_request.request(url, headers, HTTPClient.METHOD_DELETE)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The push rule was deleted.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The push rule does not exist.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Add or change a push rule.
## This endpoint allows the creation and modification of user defined push
##		rules.
##
##		If a rule with the same `rule_id` already exists among rules of the same
##		kind, it is updated with the new parameters, otherwise a new rule is
##		created.
##
##		If both `after` and `before` are provided, the new or updated rule must
##		be the next most important rule with respect to the rule identified by
##		`before`.
##
##		If neither `after` nor `before` are provided and the rule is created, it
##		should be added as the most important user defined rule among rules of
##		the same kind.
##
##		When creating push rules, they MUST be enabled by default.
##
## Parameters:
## - kind: String - The kind of rule
##
## - ruleId: String - The identifier for the rule. If the string starts with a dot ("."),
##		the request MUST be rejected as this is reserved for server-default
##		rules. Slashes ("/") and backslashes ("\\") are also not allowed.
##
## - before: String - Use 'before' with a `rule_id` as its value to make the new rule the
##		next-most important rule with respect to the given user defined rule.
##		It is not possible to add a rule relative to a predefined server rule.
## - after: String - This makes the new rule the next-less important rule relative to the
##		given user defined rule. It is not possible to add a rule relative
##		to a predefined server rule.
## - data: Dictionary - The push rule data. Additional top-level keys may be present depending on the parameters for the rule `kind`. - {'pattern': 'cake*lie', 'actions': ['notify']}
func set_push_rule(data: Dictionary, kind: String, ruleId: String, before: String, after: String) -> MatrixClientServerResponse:
	var url_params: String = ""
	url_params = "?before=" + str(before) + "&after=" + str(after)
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/pushrules/global/" + kind + "/" + ruleId + "" + "?" + url_params
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_PUT, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The push rule was created/updated.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, "There was a problem configuring this push rule.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The push rule does not exist (when updating a push rule).", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Get whether a push rule is enabled
## This endpoint gets whether the specified push rule is enabled.
##
## Parameters:
## - kind: String - The kind of rule
##
## - ruleId: String - The identifier for the rule.
##
func is_push_rule_enabled(kind: String, ruleId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/pushrules/global/" + kind + "/" + ruleId + "/enabled"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "Whether the push rule is enabled.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The push rule does not exist.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Enable or disable a push rule.
## This endpoint allows clients to enable or disable the specified push rule.
##
## Parameters:
## - kind: String - The kind of rule
##
## - ruleId: String - The identifier for the rule.
##
## - data: Dictionary - Whether the push rule is enabled or not.  - {'enabled': True}
func set_push_rule_enabled(data: Dictionary, kind: String, ruleId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/pushrules/global/" + kind + "/" + ruleId + "/enabled"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_PUT, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The push rule was enabled or disabled.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The push rule does not exist.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## The actions for a push rule
## This endpoint get the actions for the specified push rule.
##
## Parameters:
## - kind: String - The kind of rule
##
## - ruleId: String - The identifier for the rule.
##
func get_push_rule_actions(kind: String, ruleId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/pushrules/global/" + kind + "/" + ruleId + "/actions"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The actions for this push rule.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The push rule does not exist.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Set the actions for a push rule.
## This endpoint allows clients to change the actions of a push rule.
##		This can be used to change the actions of builtin rules.
##
## Parameters:
## - kind: String - The kind of rule
##
## - ruleId: String - The identifier for the rule.
##
## - data: Dictionary - The action(s) to perform when the conditions for this rule are met.  - {'actions': ['notify', {'set_tweak': 'highlight'}]}
func set_push_rule_actions(data: Dictionary, kind: String, ruleId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/pushrules/global/" + kind + "/" + ruleId + "/actions"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_PUT, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The actions for the push rule were set.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The push rule does not exist.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#######################################
## Matrix Client-Server Receipts API ##
#######################################

## Send a receipt for the given event ID.
## This API updates the marker for the given receipt type to the event ID
##		specified.
##
## Parameters:
## - roomId: String - The room in which to send the event.
## - receiptType: String - The type of receipt to send. This can also be `m.fully_read` as an
##		alternative to [`/read_markers`](/client-server-api/#post_matrixclientv3roomsroomidread_markers).
##
##		Note that `m.fully_read` does not appear under `m.receipt`: this endpoint
##		effectively calls `/read_markers` internally when presented with a receipt
##		type of `m.fully_read`.
## - eventId: String - The event ID to acknowledge up to.
## - data: Dictionary - Extra receipt information to attach to `content` if any. The server will automatically set the `ts` field. - {'thread_id': 'main'}
func post_receipt(data: Dictionary, roomId: String, receiptType: String, eventId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/receipt/" + receiptType + "/" + eventId + ""
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The receipt was sent.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, "The `thread_id` is invalid in some way. For example: * It is not a string. * It is empty. * It is provided for an incompatible receipt type. * The `event_id` is not related to the `thread_id`.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


################################################
## Matrix Client-Server message redaction API ##
################################################

## Strips all non-integrity-critical information out of an event.
## Strips all information out of an event which isn't critical to the
##		integrity of the server-side representation of the room.
##
##		This cannot be undone.
##
##		Any user with a power level greater than or equal to the `m.room.redaction`
##		event power level may send redaction events in the room. If the user's power
##		level greater is also greater than or equal to the `redact` power level
##		of the room, the user may redact events sent by other users.
##
##		Server administrators may redact events sent by users on their server.
##
## Parameters:
## - roomId: String - The room from which to redact the event.
## - eventId: String - The ID of the event to redact
## - txnId: String - The [transaction ID](/client-server-api/#transaction-identifiers) for this event. Clients should generate a
##		unique ID; it will be used by the server to ensure idempotency of requests.
## - data: Dictionary - {'reason': 'Indecent material'}
func redact_event(data: Dictionary, roomId: String, eventId: String, txnId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/redact/" + eventId + "/" + txnId + ""
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_PUT, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "An ID for the redaction event.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#####################################################
## Matrix Client-Server Registration and Login API ##
#####################################################

## Refresh an access token
## Refresh an access token. Clients should use the returned access token
##		when making subsequent API calls, and store the returned refresh token
##		(if given) in order to refresh the new access token when necessary.
##
##		After an access token has been refreshed, a server can choose to
##		invalidate the old access token immediately, or can choose not to, for
##		example if the access token would expire soon anyways. Clients should
##		not make any assumptions about the old access token still being valid,
##		and should use the newly provided access token instead.
##
##		The old refresh token remains valid until the new access token or refresh token
##		is used, at which point the old refresh token is revoked.
##
##		Note that this endpoint does not require authentication via an
##		access token. Authentication is provided via the refresh token.
##
##		Application Service identity assertion is disabled for this endpoint.
func refresh(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/refresh"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "A new access token and refresh token were generated.", output)
	elif output.response_code == 401:
		return MatrixClientServerResponse.new(FAILED, "The provided token was unknown, or has already been used.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#################################################
## Matrix Client-Server Registration Token API ##
#################################################

## Query if a given registration token is still valid.
## Queries the server to determine if a given registration token is still
##		valid at the time of request. This is a point-in-time check where the
##		token might still expire by the time it is used.
##
##		Servers should be sure to rate limit this endpoint to avoid brute force
##		attacks.
##
## Parameters:
## - token: String - The token to check validity of.
func registration_token_validity(token: String) -> MatrixClientServerResponse:
	var url_params: String = ""
	url_params = "?token=" + str(token)
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v1" + "/register/m.login.registration_token/validity" + "?" + url_params
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The check has a result.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "The homeserver does not permit registration and thus all tokens are considered invalid.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#############################################
## Matrix Client-Server Report Content API ##
#############################################

## Report a room as inappropriate.
## Reports a room as inappropriate to the server, which may then notify
##		the appropriate people. How such information is delivered is left up to
##		implementations. The caller is not required to be joined to the room to
##		report it.
##
## Parameters:
## - roomId: String - The room being reported.
## - data: Dictionary - {'reason': 'this makes me sad'}
func report_room(data: Dictionary, roomId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/report"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The room has been reported successfully.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The room was not found on the homeserver.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Report an event in a joined room as inappropriate.
## Reports an event as inappropriate to the server, which may then notify
##		the appropriate people. The caller must be joined to the room to report
##		it.
##
##		It might be possible for clients to deduce whether an event exists by
##		timing the response, as only a report for an event that does exist
##		will require the homeserver to check whether a user is joined to
##		the room. To combat this, homeserver implementations should add
##		a random delay when generating a response.
##
## Parameters:
## - roomId: String - The room in which the event being reported is located.
## - eventId: String - The event to report.
## - data: Dictionary - {'score': -100, 'reason': 'this makes me sad'}
func report_event(data: Dictionary, roomId: String, eventId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/report/" + eventId + ""
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The event has been reported successfully.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The event was not found or you are not joined to the room where the event resides.  Homeserver implementations can additionally return this error if the reported event has been redacted.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


####################################
## Matrix Client-Server Rooms API ##
####################################

## Get a single event by event ID.
## Get a single event based on `roomId/eventId`. You must have permission to
##		retrieve this event e.g. by being a member in the room for this event.
##
## Parameters:
## - roomId: String - The ID of the room the event is in.
## - eventId: String - The event ID to get.
func get_one_room_event(roomId: String, eventId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/event/" + eventId + ""
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The full event.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The event was not found or you do not have permission to read this event.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Get the state identified by the type and key.
## Looks up the contents of a state event in a room. If the user is
##		joined to the room then the state is taken from the current
##		state of the room. If the user has left the room then the state is
##		taken from the state of the room when they left.
##
## Parameters:
## - roomId: String - The room to look up the state in.
## - eventType: String - The type of state to look up.
## - stateKey: String - The key of the state to look up. Defaults to an empty string. When
##		an empty string, the trailing slash on this endpoint is optional.
func get_room_state_with_key(roomId: String, eventType: String, stateKey: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/state/" + eventType + "/" + stateKey + ""
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The content of the state event.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "You aren't a member of the room and weren't previously a member of the room. ", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The room has no state with the given type or key.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Get all state events in the current state of a room.
## Get the state events for the current state of a room.
##
## Parameters:
## - roomId: String - The room to look up the state for.
func get_room_state(roomId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/state"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The current state of the room", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "You aren't a member of the room and weren't previously a member of the room. ", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Get the m.room.member events for the room.
## Get the list of members for this room.
##
## Parameters:
## - roomId: String - The room to get the member events for.
## - at: (Optional) String - The point in time (pagination token) to return members for in the room.
##		This token can be obtained from a `prev_batch` token returned for
##		each room by the sync API. Defaults to the current state of the room,
##		as determined by the server.
## - membership: (Optional) String - The kind of membership to filter for. Defaults to no filtering if
##		unspecified. When specified alongside `not_membership`, the two
##		parameters create an 'or' condition: either the membership *is*
##		the same as `membership` **or** *is not* the same as `not_membership`.
## - not_membership: (Optional) String - The kind of membership to exclude from the results. Defaults to no
##		filtering if unspecified.
func get_members_by_room(roomId: String, at: String = "", membership: String = "", not_membership: String = "") -> MatrixClientServerResponse:
	var optional_url_params: String = ""
	optional_url_params = "" if str(at) == "" else "at=" + str(at)
	optional_url_params = optional_url_params + ( "" if str(membership) == "" else "&membership=" + str(membership) )
	optional_url_params = optional_url_params + ( "" if str(not_membership) == "" else "&not_membership=" + str(not_membership) )
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/members" + "?" + optional_url_params
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "A list of members of the room. If you are joined to the room then this will be the current members of the room. If you have left the room then this will be the members of the room when you left.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "You aren't a member of the room and weren't previously a member of the room. ", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Gets the list of currently joined users and their profile data.
## This API returns a map of MXIDs to member info objects for members of the room. The current user must be in the room for it to work, unless it is an Application Service in which case any of the AS's users must be in the room. This API is primarily for Application Services and should be faster to respond than `/members` as it can be implemented more efficiently on the server.
##
## Parameters:
## - roomId: String - The room to get the members of.
func get_joined_members_by_room(roomId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/joined_members"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "A map of MXID to room member objects.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "You aren't a member of the room. ", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#####################################################
## Matrix Client-Server events in room by date API ##
#####################################################

## Get the closest event ID to the given timestamp
## Get the ID of the event closest to the given timestamp, in the
##		direction specified by the `dir` parameter.
##
##		If the server does not have all of the room history and does not have
##		an event suitably close to the requested timestamp, it can use the
##		corresponding [federation endpoint](/server-server-api/#get_matrixfederationv1timestamp_to_eventroomid)
##		to ask other servers for a suitable event.
##
##		After calling this endpoint, clients can call
##		[`/rooms/{roomId}/context/{eventId}`](#get_matrixclientv3roomsroomidcontexteventid)
##		to obtain a pagination token to retrieve the events around the returned event.
##
##		The event returned by this endpoint could be an event that the client
##		cannot render, and so may need to paginate in order to locate an event
##		that it can display, which may end up being outside of the client's
##		suitable range.  Clients can employ different strategies to display
##		something reasonable to the user.  For example, the client could try
##		paginating in one direction for a while, while looking at the
##		timestamps of the events that it is paginating through, and if it
##		exceeds a certain difference from the target timestamp, it can try
##		paginating in the opposite direction.  The client could also simply
##		paginate in one direction and inform the user that the closest event
##		found in that direction is outside of the expected range.
##
## Parameters:
## - roomId: String - The ID of the room to search
## - ts: int - The timestamp to search from, as given in milliseconds
##		since the Unix epoch.
## - dir: String - The direction in which to search.  `f` for forwards, `b` for backwards.
func get_event_by_timestamp(roomId: String, ts: int, dir: String) -> MatrixClientServerResponse:
	var url_params: String = ""
	url_params = "?ts=" + str(ts) + "&dir=" + str(dir)
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v1" + "/rooms/" + roomId + "/timestamp_to_event" + "?" + url_params
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "An event was found matching the search parameters.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "No event was found.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


####################################
## Matrix Client-Server Rooms API ##
####################################

## Snapshot the current state of a room and its most recent messages.
## Get a copy of the current state and the most recent messages in a room.
##
##		This endpoint was deprecated in r0 of this specification. There is no
##		direct replacement; the relevant information is returned by the
##		[`/sync`](/client-server-api/#get_matrixclientv3sync) API. See the
##		[migration guide](https://matrix.org/docs/guides/migrating-from-client-server-api-v-1#deprecated-endpoints).
##
## Parameters:
## - roomId: String - The room to get the data.
func room_initial_sync(roomId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/initialSync"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The current state of the room", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "You aren't a member of the room and weren't previously a member of the room. ", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#################################################
## Matrix Client-Server message event send API ##
#################################################

## Send a message event to the given room.
## This endpoint is used to send a message event to a room. Message events
##		allow access to historical events and pagination, making them suited
##		for "once-off" activity in a room.
##
##		The body of the request should be the content object of the event; the
##		fields in this object will vary depending on the type of event. See
##		[Room Events](/client-server-api/#room-events) for the m. event specification.
##
## Parameters:
## - roomId: String - The room to send the event to.
## - eventType: String - The type of event to send.
## - txnId: String - The [transaction ID](/client-server-api/#transaction-identifiers) for this event. Clients should generate an
##		ID unique across requests with the same access token; it will be
##		used by the server to ensure idempotency of requests.
## - data: Dictionary - {'msgtype': 'm.text', 'body': 'hello'}
func send_message(data: Dictionary, roomId: String, eventType: String, txnId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/send/" + eventType + "/" + txnId + ""
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_PUT, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "An ID for the sent event.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, "The request is invalid. A [standard error response](/client-server-api/#standard-error-response) will be returned. As well as the normal common error codes, other reasons for rejection include:  - `M_DUPLICATE_ANNOTATION`: The request is an attempt to send a [duplicate annotation](/client-server-api/#avoiding-duplicate-annotations).", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


###############################################
## Matrix Client-Server state event send API ##
###############################################

## Send a state event to the given room.
## State events can be sent using this endpoint.  These events will be
##		overwritten if `<room id>`, `<event type>` and `<state key>` all
##		match.
##
##		Requests to this endpoint **cannot use transaction IDs**
##		like other `PUT` paths because they cannot be differentiated from the
##		`state_key`. Furthermore, `POST` is unsupported on state paths.
##
##		The body of the request should be the content object of the event; the
##		fields in this object will vary depending on the type of event. See
##		[Room Events](/client-server-api/#room-events) for the `m.` event specification.
##
##		If the event type being sent is `m.room.canonical_alias` servers
##		SHOULD ensure that any new aliases being listed in the event are valid
##		per their grammar/syntax and that they point to the room ID where the
##		state event is to be sent. Servers do not validate aliases which are
##		being removed or are already present in the state event.
##
##
## Parameters:
## - roomId: String - The room to set the state in
## - eventType: String - The type of event to send.
## - stateKey: String - The state_key for the state to send. Defaults to the empty string. When
##		an empty string, the trailing slash on this endpoint is optional.
## - data: Dictionary - {'membership': 'join', 'avatar_url': 'mxc://localhost/SEsfnsuifSDFSSEF', 'displayname': 'Alice Margatroid'}
func set_room_state_with_key(data: Dictionary, roomId: String, eventType: String, stateKey: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/state/" + eventType + "/" + stateKey + ""
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_PUT, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "An ID for the sent event.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, "The sender's request is malformed.  Some example error codes include:  * `M_INVALID_PARAM`: One or more aliases within the `m.room.canonical_alias`   event have invalid syntax.  * `M_BAD_ALIAS`: One or more aliases within the `m.room.canonical_alias` event   do not point to the room ID for which the state event is to be sent to.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "The sender doesn't have permission to send the event into the room.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


############################################
## Matrix Client-Server Room Upgrades API ##
############################################

## Upgrades a room to a new room version.
## Upgrades the given room to a particular room version.
##
## Parameters:
## - roomId: String - The ID of the room to upgrade.
## - data: Dictionary - {'new_version': '2'}
func upgrade_room(data: Dictionary, roomId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/upgrade"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The room was successfully upgraded.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, "The request was invalid. One way this can happen is if the room version requested is not supported by the homeserver.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "The user is not permitted to upgrade the room.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#####################################
## Matrix Client-Server Search API ##
#####################################

## Perform a server-side search.
## Performs a full text search across different categories.
##
## Parameters:
## - next_batch: (Optional) String - The point to return events from. If given, this should be a
##		`next_batch` result from a previous call to this endpoint.
## - data: Dictionary - {'search_categories': {'room_events': {'keys': ['content.body'], 'search_term': 'martians and men', 'order_by': 'recent', 'groupings': {'group_by': [{'key': 'room_id'}]}}}}
func search(data: Dictionary, next_batch: String = "") -> MatrixClientServerResponse:
	var optional_url_params: String = ""
	optional_url_params = "" if str(next_batch) == "" else "next_batch=" + str(next_batch)
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/search" + "?" + optional_url_params
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "Results of the search.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, "Part of the request was invalid.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


##############################################
## Matrix Client-Server Space Hierarchy API ##
##############################################

## Retrieve a portion of a space tree.
## Paginates over the space tree in a depth-first manner to locate child rooms of a given space.
##
##		Where a child room is unknown to the local server, federation is used to fill in the details.
##		The servers listed in the `via` array should be contacted to attempt to fill in missing rooms.
##
##		Only [`m.space.child`](#mspacechild) state events of the room are considered. Invalid child
##		rooms and parent events are not covered by this endpoint.
##
## Parameters:
## - roomId: String - The room ID of the space to get a hierarchy for.
## - suggested_only: (Optional) bool | Must be provided as int (where 0 is `false`, 1 is `true`) - Optional (default `false`) flag to indicate whether or not the server should only consider
##		suggested rooms. Suggested rooms are annotated in their [`m.space.child`](#mspacechild) event
##		contents.
## - limit: (Optional) int - Optional limit for the maximum number of rooms to include per response. Must be an integer
##		greater than zero.
##
##		Servers should apply a default value, and impose a maximum value to avoid resource exhaustion.
## - max_depth: (Optional) int - Optional limit for how far to go into the space. Must be a non-negative integer.
##
##		When reached, no further child rooms will be returned.
##
##		Servers should apply a default value, and impose a maximum value to avoid resource exhaustion.
## - from: (Optional) String - A pagination token from a previous result. If specified, `max_depth` and `suggested_only` cannot
##		be changed from the first request.
func get_space_hierarchy(roomId: String, suggested_only: int = -9999, limit: int = -9999, max_depth: int = -9999, from: String = "") -> MatrixClientServerResponse:
	var optional_url_params: String = ""
	optional_url_params = "" if _int_to_bool_string(suggested_only) == "" else "suggested_only=" + _int_to_bool_string(suggested_only)
	optional_url_params = optional_url_params + ( "" if _int_to_string(limit) == "" else "&limit=" + _int_to_string(limit) )
	optional_url_params = optional_url_params + ( "" if _int_to_string(max_depth) == "" else "&max_depth=" + _int_to_string(max_depth) )
	optional_url_params = optional_url_params + ( "" if str(from) == "" else "&from=" + str(from) )
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v1" + "/rooms/" + roomId + "/hierarchy" + "?" + optional_url_params
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "A portion of the space tree, starting at the provided room ID.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, "The request was invalid in some way. A meaningful `errcode` and description error text will be returned. Example reasons for rejection are:  - The `from` token is unknown to the server. - `suggested_only` or `max_depth` changed during pagination.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "The user cannot view or peek on the room. A meaningful `errcode` and description error text will be returned. Example reasons for rejection are:  - The room is not set up for peeking. - The user has been banned from the room. - The room does not exist.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


########################################
## Matrix Client-Server SSO Login API ##
########################################

## Redirect the user's browser to the SSO interface.
## A web-based Matrix client should instruct the user's browser to
##		navigate to this endpoint in order to log in via SSO.
##
##		The server MUST respond with an HTTP redirect to the SSO interface,
##		or present a page which lets the user select an IdP to continue
##		with in the event multiple are supported by the server.
##
## Parameters:
## - redirectUrl: String - URI to which the user will be redirected after the homeserver has
##		authenticated the user with SSO.
func redirect_to_s_s_o(redirectUrl: String) -> MatrixClientServerResponse:
	var url_params: String = ""
	url_params = "?redirectUrl=" + str(redirectUrl)
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/login/sso/redirect" + "?" + url_params
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 302:
		return MatrixClientServerResponse.new(FAILED, "A redirect to the SSO interface.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Redirect the user's browser to the SSO interface for an IdP.
## This endpoint is the same as `/login/sso/redirect`, though with an
##		IdP ID from the original `identity_providers` array to inform the
##		server of which IdP the client/user would like to continue with.
##
##		The server MUST respond with an HTTP redirect to the SSO interface
##		for that IdP.
##
## Parameters:
## - idpId: String - The `id` of the IdP from the `m.login.sso` `identity_providers`
##		array denoting the user's selection.
## - redirectUrl: String - URI to which the user will be redirected after the homeserver has
##		authenticated the user with SSO.
func redirect_to_id_p(idpId: String, redirectUrl: String) -> MatrixClientServerResponse:
	var url_params: String = ""
	url_params = "?redirectUrl=" + str(redirectUrl)
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/login/sso/redirect/" + idpId + "" + "?" + url_params
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 302:
		return MatrixClientServerResponse.new(FAILED, "A redirect to the SSO interface.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The IdP ID was not recognized by the server. The server is encouraged to provide a user-friendly page explaining the error given the user will be navigated to it.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


################################################
## Matrix Client-Server Support Discovery API ##
################################################

## Gets homeserver contacts and support details.
## Gets server admin contact and support page of the domain.
##
##		Like the [well-known discovery URI](/client-server-api/#well-known-uri),
##		this should be accessed with the hostname of the homeserver by making a
##		GET request to `https://hostname/.well-known/matrix/support`.
##
##		Note that this endpoint is not necessarily handled by the homeserver.
##		It may be served by another webserver, used for discovering support
##		information for the homeserver.
func get_wellknown_support() -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/.well-known" + "/matrix/support"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "Server support information.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "No server support information available.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


###################################
## Matrix Client-Server sync API ##
###################################

## Synchronise the client's state and receive new messages.
## Synchronise the client's state with the latest state on the server.
##		Clients use this API when they first log in to get an initial snapshot
##		of the state on the server, and then continue to call this API to get
##		incremental deltas to the state, and to receive new messages.
##
##		*Note*: This endpoint supports lazy-loading. See [Filtering](/client-server-api/#filtering)
##		for more information. Lazy-loading members is only supported on a `StateFilter`
##		for this endpoint. When lazy-loading is enabled, servers MUST include the
##		syncing user's own membership event when they join a room, or when the
##		full state of rooms is requested, to aid discovering the user's avatar &
##		displayname.
##
##		Further, like other members, the user's own membership event is eligible
##		for being considered redundant by the server. When a sync is `limited`,
##		the server MUST return membership events for events in the gap
##		(between `since` and the start of the returned timeline), regardless
##		as to whether or not they are redundant. This ensures that joins/leaves
##		and profile changes which occur during the gap are not lost.
##
##		Note that the default behaviour of `state` is to include all membership
##		events, alongside other state, when lazy-loading is not enabled.
##
## Parameters:
## - filter: (Optional) String - The ID of a filter created using the filter API or a filter JSON
##		object encoded as a string. The server will detect whether it is
##		an ID or a JSON object by whether the first character is a `"{"`
##		open brace. Passing the JSON inline is best suited to one off
##		requests. Creating a filter using the filter API is recommended for
##		clients that reuse the same filter multiple times, for example in
##		long poll requests.
##
##		See [Filtering](/client-server-api/#filtering) for more information.
## - since: (Optional) String - A point in time to continue a sync from. This should be the
##		`next_batch` token returned by an earlier call to this endpoint.
## - full_state: (Optional) bool | Must be provided as int (where 0 is `false`, 1 is `true`) - Controls whether to include the full state for all rooms the user
##		is a member of.
##
##		If this is set to `true`, then all state events will be returned,
##		even if `since` is non-empty. The timeline will still be limited
##		by the `since` parameter. In this case, the `timeout` parameter
##		will be ignored and the query will return immediately, possibly with
##		an empty timeline.
##
##		If `false`, and `since` is non-empty, only state which has
##		changed since the point indicated by `since` will be returned.
##
##		By default, this is `false`.
## - set_presence: (Optional) String - Controls whether the client is automatically marked as online by
##		polling this API. If this parameter is omitted then the client is
##		automatically marked as online when it uses this API. Otherwise if
##		the parameter is set to "offline" then the client is not marked as
##		being online when it uses this API. When set to "unavailable", the
##		client is marked as being idle.
## - timeout: (Optional) int - The maximum time to wait, in milliseconds, before returning this
##		request. If no events (or other data) become available before this
##		time elapses, the server will return a response with empty fields.
##
##		By default, this is `0`, so the server will return immediately
##		even if the response is empty.
func sync(filter: String = "", since: String = "", full_state: int = -9999, set_presence: String = "", timeout: int = -9999) -> MatrixClientServerResponse:
	var optional_url_params: String = ""
	optional_url_params = "" if str(filter) == "" else "filter=" + str(filter)
	optional_url_params = optional_url_params + ( "" if str(since) == "" else "&since=" + str(since) )
	optional_url_params = optional_url_params + ( "" if _int_to_bool_string(full_state) == "" else "&full_state=" + _int_to_bool_string(full_state) )
	optional_url_params = optional_url_params + ( "" if str(set_presence) == "" else "&set_presence=" + str(set_presence) )
	optional_url_params = optional_url_params + ( "" if _int_to_string(timeout) == "" else "&timeout=" + _int_to_string(timeout) )
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/sync" + "?" + optional_url_params
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The initial snapshot or delta for the client to use to update their state.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#################################################
## Matrix Client-Server Third-party Lookup API ##
#################################################

## Retrieve metadata about all protocols that a homeserver supports.
## Fetches the overall metadata about protocols supported by the
##		homeserver. Includes both the available protocols and all fields
##		required for queries against each protocol.
func get_protocols() -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/thirdparty/protocols"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The protocols supported by the homeserver.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Retrieve metadata about a specific protocol that the homeserver supports.
## Fetches the metadata from the homeserver about a particular third-party protocol.
##
## Parameters:
## - protocol: String - The name of the protocol.
func get_protocol_metadata(protocol: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/thirdparty/protocol/" + protocol + ""
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The protocol was found and metadata returned.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The protocol is unknown.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Retrieve Matrix-side portals rooms leading to a third-party location.
## Requesting this endpoint with a valid protocol name results in a list
##		of successful mapping results in a JSON array. Each result contains
##		objects to represent the Matrix room or rooms that represent a portal
##		to this third-party network. Each has the Matrix room alias string,
##		an identifier for the particular third-party network protocol, and an
##		object containing the network-specific fields that comprise this
##		identifier. It should attempt to canonicalise the identifier as much
##		as reasonably possible given the network type.
##
## Parameters:
## - protocol: String - The protocol used to communicate to the third-party network.
## - searchFields: (Optional) String - One or more custom fields to help identify the third-party
##		location.
func query_location_by_protocol(protocol: String, searchFields: String = "") -> MatrixClientServerResponse:
	var optional_url_params: String = ""
	optional_url_params = "" if str(searchFields) == "" else "searchFields=" + str(searchFields)
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/thirdparty/location/" + protocol + "" + "?" + optional_url_params
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "At least one portal room was found.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "No portal rooms were found.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Retrieve the Matrix User ID of a corresponding third-party user.
## Retrieve a Matrix User ID linked to a user on the third-party service, given
##		a set of user parameters.
##
## Parameters:
## - protocol: String - The name of the protocol.
## - fields: (Optional) Dictionary - One or more custom fields that are passed to the AS to help identify the user.
func query_user_by_protocol(protocol: String, fields: Dictionary = {}) -> MatrixClientServerResponse:
	var optional_url_params: String = ""
	optional_url_params = "" if fields == {} else "fields=" + str(fields)
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/thirdparty/user/" + protocol + "" + "?" + optional_url_params
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The Matrix User IDs found with the given parameters.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The Matrix User ID was not found.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Reverse-lookup third-party locations given a Matrix room alias.
## Retrieve an array of third-party network locations from a Matrix room
##		alias.
##
## Parameters:
## - alias: String - The Matrix room alias to look up.
func query_location_by_alias(alias: String) -> MatrixClientServerResponse:
	var url_params: String = ""
	url_params = "?alias=" + str(alias)
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/thirdparty/location" + "?" + url_params
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "All found third-party locations.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The Matrix room alias was not found", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)

## Reverse-lookup third-party users given a Matrix User ID.
## Retrieve an array of third-party users from a Matrix User ID.
##
## Parameters:
## - userid: String - The Matrix User ID to look up.
func query_user_by_i_d(userid: String) -> MatrixClientServerResponse:
	var url_params: String = ""
	url_params = "?userid=" + str(userid)
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/thirdparty/user" + "?" + url_params
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "An array of third-party users.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "The Matrix User ID was not found.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


##########################################################################
## Matrix Client-Server Room Membership API for third-party identifiers ##
##########################################################################

## Invite a user to participate in a particular room.
## *Note that there are two forms of this API, which are documented separately.
##		This version of the API does not require that the inviter know the Matrix
##		identifier of the invitee, and instead relies on third-party identifiers.
##		The homeserver uses an identity server to perform the mapping from
##		third-party identifier to a Matrix identifier. The other is documented in the*
##		[joining rooms section](/client-server-api/#post_matrixclientv3roomsroomidinvite).
##
##		This API invites a user to participate in a particular room.
##		They do not start participating in the room until they actually join the
##		room.
##
##		Only users currently in a particular room can invite other users to
##		join that room.
##
##		If the identity server did know the Matrix user identifier for the
##		third-party identifier, the homeserver will append a `m.room.member`
##		event to the room.
##
##		If the identity server does not know a Matrix user identifier for the
##		passed third-party identifier, the homeserver will issue an invitation
##		which can be accepted upon providing proof of ownership of the third-
##		party identifier. This is achieved by the identity server generating a
##		token, which it gives to the inviting homeserver. The homeserver will
##		add an `m.room.third_party_invite` event into the graph for the room,
##		containing that token.
##
##		When the invitee binds the invited third-party identifier to a Matrix
##		user ID, the identity server will give the user a list of pending
##		invitations, each containing:
##
##		- The room ID to which they were invited
##
##		- The token given to the homeserver
##
##		- A signature of the token, signed with the identity server's private key
##
##		- The matrix user ID who invited them to the room
##
##		If a token is requested from the identity server, the homeserver will
##		append a `m.room.third_party_invite` event to the room.
##
## Parameters:
## - roomId: String - The room identifier (not alias) to which to invite the user.
## - data: Dictionary - {'id_server': 'matrix.org', 'id_access_token': 'abc123_OpaqueString', 'medium': 'email', 'address': 'cheeky@monkey.com'}
func invite_by3_p_i_d(data: Dictionary, roomId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/invite"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The user has been invited to join the room.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "You do not have permission to invite the user to the room. A meaningful `errcode` and description error text will be returned. Example reasons for rejections are:  - The invitee has been banned from the room. - The invitee is already a member of the room. - The inviter is not currently in the room. - The inviter's power level is insufficient to invite users to the room.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


###########################################
## Matrix Client-Server Threads List API ##
###########################################

## Fetches a list of the threads in a room.
## This API is used to paginate through the list of the thread roots in a given room.
##
##		Optionally, the returned list may be filtered according to whether the requesting
##		user has participated in the thread.
##
## Parameters:
## - roomId: String - The room ID where the thread roots are located.
## - include: (Optional) String - Optional (default `all`) flag to denote which thread roots are of interest to the caller.
##		When `all`, all thread roots found in the room are returned. When `participated`, only
##		thread roots for threads the user has [participated in](/client-server-api/#server-side-aggregation-of-mthread-relationships)
##		will be returned.
## - limit: (Optional) int - Optional limit for the maximum number of thread roots to include per response. Must be an integer
##		greater than zero.
##
##		Servers should apply a default value, and impose a maximum value to avoid resource exhaustion.
## - from: (Optional) String - A pagination token from a previous result. When not provided, the server starts paginating from
##		the most recent event visible to the user (as per history visibility rules; topologically).
func get_thread_roots(roomId: String, include: String = "", limit: int = -9999, from: String = "") -> MatrixClientServerResponse:
	var optional_url_params: String = ""
	optional_url_params = "" if str(include) == "" else "include=" + str(include)
	optional_url_params = optional_url_params + ( "" if _int_to_string(limit) == "" else "&limit=" + _int_to_string(limit) )
	optional_url_params = optional_url_params + ( "" if str(from) == "" else "&from=" + str(from) )
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v1" + "/rooms/" + roomId + "/threads" + "?" + optional_url_params
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "A portion of the available thread roots in the room, based on the filter criteria.", output)
	elif output.response_code == 400:
		return MatrixClientServerResponse.new(FAILED, "The request was invalid in some way. A meaningful `errcode` and description error text will be returned. Example reasons for rejection are:  - The `from` token is unknown to the server.", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "The user cannot view or peek on the room. A meaningful `errcode` and description error text will be returned. Example reasons for rejection are:  - The room is not set up for peeking. - The user has been banned from the room. - The room does not exist.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#####################################
## Matrix Client-Server Typing API ##
#####################################

## Informs the server that the user has started or stopped typing.
## This tells the server that the user is typing for the next N
##		milliseconds where N is the value specified in the `timeout` key.
##		Alternatively, if `typing` is `false`, it tells the server that the
##		user has stopped typing.
##
## Parameters:
## - userId: String - The user who has started to type.
## - roomId: String - The room in which the user is typing.
## - data: Dictionary - The current typing state. - {'typing': True, 'timeout': 30000}
func set_typing(data: Dictionary, userId: String, roomId: String) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/rooms/" + roomId + "/typing/" + userId + ""
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_PUT, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The new typing state was set.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#############################################
## Matrix Client-Server User Directory API ##
#############################################

## Searches the user directory.
## Performs a search for users. The homeserver may
##		determine which subset of users are searched, however the homeserver
##		MUST at a minimum consider the users the requesting user shares a
##		room with and those who reside in public rooms (known to the homeserver).
##		The search MUST consider local users to the homeserver, and SHOULD
##		query remote users as part of the search.
##
##		The search is performed case-insensitively on user IDs and display
##		names preferably using a collation determined based upon the
##		`Accept-Language` header provided in the request, if present.
func search_user_directory(data: Dictionary) -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/user_directory/search"
	var request_body: String = JSON.stringify(data)
	var request = http_request.request(url, headers, HTTPClient.METHOD_POST, request_body)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The results of the search.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#######################################
## Matrix Client-Server Versions API ##
#######################################

## Gets the versions of the specification supported by the server.
## Gets the versions of the specification supported by the server.
##
##		Values will take the form `vX.Y` or `rX.Y.Z` in historical cases. See
##		[the Specification Versioning](../#specification-versions) for more
##		information.
##
##		The server may additionally advertise experimental features it supports
##		through `unstable_features`. These features should be namespaced and
##		may optionally include version information within their name if desired.
##		Features listed here are not for optionally toggling parts of the Matrix
##		specification and should only be used to advertise support for a feature
##		which has not yet landed in the spec. For example, a feature currently
##		undergoing the proposal process may appear here and eventually be taken
##		off this list once the feature lands in the spec and the server deems it
##		reasonable to do so. Servers can choose to enable some features only for
##		some users, so clients should include authentication in the request to
##		get all the features available for the logged-in user. If no
##		authentication is provided, the server should only return the features
##		available to all users. Servers may wish to keep advertising features
##		here after they've been released into the spec to give clients a chance
##		to upgrade appropriately. Additionally, clients should avoid using
##		unstable features in their stable releases.
func get_versions() -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client" + "/versions"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The versions supported by the server.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


############################################
## Matrix Client-Server Voice over IP API ##
############################################

## Obtain TURN server credentials.
## This API provides credentials for the client to use when initiating
##		calls.
func get_turn_server() -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/voip/turnServer"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The TURN server credentials.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


###############################################
## Matrix Client-Server Server Discovery API ##
###############################################

## Gets Matrix server discovery information about the domain.
## Gets discovery information about the domain. The file may include
##		additional keys, which MUST follow the Java package naming convention,
##		e.g. `com.example.myapp.property`. This ensures property names are
##		suitably namespaced for each application and reduces the risk of
##		clashes.
##
##		Note that this endpoint is not necessarily handled by the homeserver,
##		but by another webserver, to be used for discovering the homeserver URL.
func get_wellknown() -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/.well-known" + "/matrix/client"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "Server discovery information.", output)
	elif output.response_code == 404:
		return MatrixClientServerResponse.new(FAILED, "No server discovery information available.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)


#####################################################
## Matrix Client-Server Account Identification API ##
#####################################################

## Gets information about the owner of an access token.
## Gets information about the owner of a given access token.
##
##		Note that, as with the rest of the Client-Server API,
##		Application Services may masquerade as users within their
##		namespace by giving a `user_id` query parameter. In this
##		situation, the server should verify that the given `user_id`
##		is registered by the appservice, and return it in the response
##		body.
func get_token_owner() -> MatrixClientServerResponse:
	var http_request: HTTPRequest = _request()
	var url = homeserver + "/_matrix/client/v3" + "/account/whoami"
	var request = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if request != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_QUERY_FAILED, "Error initiating HTTPRequest.")

	var http_response : Array = await http_request.request_completed
	var json: JSON = JSON.new()
	var json_parsed: int = json.parse(http_response[3].get_string_from_utf8())

	if json_parsed != OK:
		http_request.queue_free()
		return MatrixClientServerResponse.new(ERR_PARSE_ERROR, "Error parsing response body: " + http_response[3].get_string_from_utf8())

	var response_body: Dictionary = json.get_data()
	var output : Dictionary = {
		"response_status": http_response[0],
		"response_code": http_response[1],
		"headers": http_response[2],
		"body": response_body,
	}

	http_request.queue_free()

	if output.response_code == 401:
		return MatrixClientServerResponse.new(ERR_UNAUTHORIZED, "The homeserver requires additional authentication information. Errcode: `M_UNAUTHORIZED`.", output)
	elif output.response_code == 200:
		return MatrixClientServerResponse.new(OK, "The token belongs to a known user.", output)
	elif output.response_code == 401:
		return MatrixClientServerResponse.new(FAILED, "The token is not recognised", output)
	elif output.response_code == 403:
		return MatrixClientServerResponse.new(FAILED, "The appservice cannot masquerade as the user or has not registered them.", output)
	elif output.response_code == 429:
		return MatrixClientServerResponse.new(FAILED, "This request was rate-limited.", output)
	else:
		return MatrixClientServerResponse.new(ERR_DOES_NOT_EXIST, "Unknown response code returned. - " + str(output.response_code), output)
