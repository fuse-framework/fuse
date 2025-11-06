/**
 * AttributeParser - Parse attribute syntax for CLI generators
 *
 * Parses "name:type:modifier:modifier" format into structured data
 * for generating migrations and models.
 *
 * Supported types: string, text, integer, boolean, date, datetime, decimal, references
 * Supported modifiers: unique, index, notnull, default:value
 */
component {

	/**
	 * Parse attribute string into structured format
	 *
	 * @param attributeString The attribute string to parse (e.g., "name:string:unique")
	 * @return Struct with name, type, modifiers array, and optional reference info
	 * @throws InvalidAttributeFormat When format is invalid
	 * @throws UnknownColumnType When type is not supported
	 */
	public struct function parse(required string attributeString) {
		var parts = listToArray(arguments.attributeString, ":");

		// Validate format: must have at least name:type
		if (arrayLen(parts) < 2) {
			throw(
				type = "InvalidAttributeFormat",
				message = "Invalid attribute format: '#arguments.attributeString#'",
				detail = "Expected format: name:type or name:type:modifier. Example: email:string:unique"
			);
		}

		var name = parts[1];
		var type = parts[2];
		var modifiers = [];

		// Validate type is supported
		if (!_isValidType(type)) {
			throw(
				type = "UnknownColumnType",
				message = "Unknown column type: '#type#'",
				detail = "Supported types: string, text, integer, boolean, date, datetime, decimal, references"
			);
		}

		// Extract modifiers (everything after type)
		for (var i = 3; i <= arrayLen(parts); i++) {
			arrayAppend(modifiers, parts[i]);
		}

		var result = {
			name: name,
			type: type,
			modifiers: modifiers,
			isReference: false
		};

		// Handle special "references" type
		if (type == "references") {
			result.isReference = true;
			result.referenceName = name;
			result.name = name & "_id";
			result.type = "integer";

			// Add index modifier for foreign keys
			if (!arrayFind(modifiers, "index")) {
				arrayAppend(result.modifiers, "index");
			}
		}

		return result;
	}

	/**
	 * Validate if type is supported
	 *
	 * @param type The column type to validate
	 * @return True if valid type
	 */
	private boolean function _isValidType(required string type) {
		var validTypes = [
			"string",
			"text",
			"integer",
			"boolean",
			"date",
			"datetime",
			"decimal",
			"references"
		];

		return arrayFind(validTypes, arguments.type) > 0;
	}

}
