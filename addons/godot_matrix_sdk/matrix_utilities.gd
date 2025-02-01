@icon("res://addons/godot_matrix_sdk/matrix_icon.svg")
class_name MatrixUtils

class MXID:

	func validate_mxid(mxid: String) -> bool:
		# Group 1: MatrixID Localpart
		# Group 2: MatrixID Domain
		# Group 3: Port
		var mxid_regex = RegEx.new()
		mxid_regex.compile(r"^@([a-z0-9._=\-/+]+):([a-zA-Z0-9\-\.]+|\[[0-9a-fA-F:.]+\]|[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?::([0-9]{1,5}))?$")

		# Check if MXID matches the regex
		if not mxid_regex.match(mxid):
			return false

		# Ensure MXID length is within the limit
		if mxid.length() > 255:
			return false

		return true

	## Validate provided string is a MXID (`@exanple:matrix.org`)
	static func mxid_validate(matrix_id: String) -> bool:
		var validation: RegEx = RegEx.new()
		validation.compile(r"^@[a-zA-Z0-9._=-]+:[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
		if validation.search(matrix_id):
			return true
		else:
			return false

	## Split a MXID (`@exanple:matrix.org`) into localpart and homeserver
	## Used by `mxid_to_localpart` and `mxid_to_homeserver`
	static func _mxid_split(matrix_id: String, to: bool) -> MatrixClientServerResponse:
		if mxid_validate(matrix_id) == false:
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
	static func mxid_to_localpart(matrix_id: String) -> MatrixClientServerResponse:
		return _mxid_split(matrix_id, true)

	## Return homeserver of provided `matrix_id`
	## I.e. `@example:matrix.org` returns `matrix.org`
	static func mxid_to_homeserver(matrix_id: String) -> MatrixClientServerResponse:
		return _mxid_split(matrix_id, false)

static func email_validate(email: String) -> bool:
	var email_regex = RegEx.new()
	email_regex.compile(r"^[\w\.-]+@[\w\.-]+\.\w+$")
	return email_regex.search(email) != null

## Validate the provided `url` string is a valid URL
static func url_validate(url: String) -> bool:
	var validation: RegEx = RegEx.new()
	validation.compile(r"^((http|https):\/\/)?([a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,})(:([0-9]{1,5}))?(\/([^\s]*))?$")
	if validation.search(url):
		return true
	else:
		return false

## Format provided `url` string to confirm protocol (`http` / `https`) and no trailing `/`
## If provided `url` has no protocol, `https://` is added by default
static func url_formatter(url: String, trail: bool = false) -> MatrixClientServerResponse:
	if url_validate(url) == false:
		return MatrixClientServerResponse.new(FAILED, "URL validation failed. Use `url_validate()` for true/false validation of URL.")
	var formatter: RegEx = RegEx.new()
	# URL Pattern Matching Group Examples
	# Group 1: `http://` or `https://`
	# Group 2: `http` or `https`
	# Group 3: `sub.domain.com`
	# Group 4: `:1234`
	# Group 5: `1234`
	# Group 6: `/path`
	# Group 7: `path`
	formatter.compile(r"^((http|https):\/\/)?([a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,})(:([\d]{1,5}))?(\/([^\s:]*))?$")
	var formatter_result: RegExMatch = formatter.search(url)
	if formatter_result:
		var protocol: String = formatter_result.get_string(1)
		var domain: String = formatter_result.get_string(3)
		var port: String = formatter_result.get_string(5)
		var path: String = formatter_result.get_string(6)
		if not trail:
			if path.ends_with("/"):
				path = path.left(-1)
		if protocol == "":
			protocol = "https://"
		return MatrixClientServerResponse.new(OK, "", "{protocol}{domain}{port}{path}".format({"protocol":protocol,"domain":domain,"port":":" + port if port else "","path":path}))
	else:
		return MatrixClientServerResponse.new(FAILED, "Provided string is not a valid URL.")
