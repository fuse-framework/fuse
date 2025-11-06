component {

	function init(required string pattern) {
		variables.pattern = arguments.pattern;
		variables.paramNames = [];
		variables.regex = compilePattern(arguments.pattern);

		return this;
	}

	/**
	 * Match a path against this pattern
	 *
	 * @path URL path to match
	 * @return Struct with matched flag and params, or struct with matched=false if no match
	 */
	public struct function match(required string path) {
		// Normalize paths: remove trailing slash for comparison
		var normalizedPath = normalizeSlash(arguments.path);
		var normalizedPattern = normalizeSlash(variables.pattern);

		// Check if path matches compiled regex
		var matches = reMatch(variables.regex, normalizedPath);

		if (arrayLen(matches) == 0) {
			return {matched: false};
		}

		// Extract parameters from path
		var params = extractParams(normalizedPath);
		params.matched = true;

		return params;
	}

	/**
	 * Get the original pattern string
	 *
	 * @return Original pattern
	 */
	public string function getPattern() {
		return variables.pattern;
	}

	// Private methods

	private string function compilePattern(required string pattern) {
		var normalized = normalizeSlash(arguments.pattern);
		var regexPattern = "^";
		var segments = listToArray(normalized, "/");

		for (var segment in segments) {
			if (len(segment) == 0) {
				continue;
			}

			regexPattern &= "\/";

			if (left(segment, 1) == ":") {
				// Named parameter: capture alphanumeric and underscore
				var paramName = right(segment, len(segment) - 1);
				arrayAppend(variables.paramNames, paramName);
				regexPattern &= "([^\/]+)";
			} else if (left(segment, 1) == "*") {
				// Wildcard: capture everything remaining
				var paramName = right(segment, len(segment) - 1);
				arrayAppend(variables.paramNames, paramName);
				regexPattern &= "(.+)";
			} else {
				// Static segment: exact match
				regexPattern &= reEscape(segment);
			}
		}

		regexPattern &= "$";

		return regexPattern;
	}

	private struct function extractParams(required string path) {
		var params = {};
		var normalized = normalizeSlash(arguments.path);
		var patternNormalized = normalizeSlash(variables.pattern);

		// Build regex with capture groups to extract values
		var regexPattern = "^";
		var patternSegments = listToArray(patternNormalized, "/");
		var pathSegments = listToArray(normalized, "/");

		var paramIndex = 1;

		for (var i = 1; i <= arrayLen(patternSegments); i++) {
			var segment = patternSegments[i];

			if (len(segment) == 0) {
				continue;
			}

			if (left(segment, 1) == ":") {
				// Named parameter
				var paramName = right(segment, len(segment) - 1);
				if (arrayLen(pathSegments) >= i) {
					params[paramName] = pathSegments[i];
				}
			} else if (left(segment, 1) == "*") {
				// Wildcard: capture remaining path segments
				var paramName = right(segment, len(segment) - 1);
				var remainingPath = "";

				for (var j = i; j <= arrayLen(pathSegments); j++) {
					if (len(remainingPath) > 0) {
						remainingPath &= "/";
					}
					remainingPath &= pathSegments[j];
				}

				params[paramName] = remainingPath;
				break; // Wildcard captures rest, stop processing
			}
		}

		return params;
	}

	private string function normalizeSlash(required string path) {
		var result = trim(arguments.path);

		// Remove trailing slash unless it's the root path
		if (len(result) > 1 && right(result, 1) == "/") {
			result = left(result, len(result) - 1);
		}

		// Ensure leading slash
		if (len(result) == 0 || left(result, 1) != "/") {
			result = "/" & result;
		}

		return result;
	}

	private string function reEscape(required string str) {
		// Escape regex special characters for literal matching
		var escaped = arguments.str;
		var specialChars = ["\", ".", "^", "$", "*", "+", "?", "(", ")", "[", "]", "{", "}", "|"];

		for (var char in specialChars) {
			escaped = replace(escaped, char, "\" & char, "all");
		}

		return escaped;
	}

}
