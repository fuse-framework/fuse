/**
 * NamingConventions - Utility for converting between naming conventions
 *
 * Provides simple pluralization, singularization, and case conversions
 * for CLI generators. Uses simple +s approach for Phase 1.
 */
component {

	/**
	 * Pluralize a word by appending 's'
	 *
	 * @param word The word to pluralize
	 * @return Pluralized word
	 */
	public string function pluralize(required string word) {
		return arguments.word & "s";
	}

	/**
	 * Singularize a word by removing trailing 's'
	 *
	 * @param word The word to singularize
	 * @return Singularized word
	 */
	public string function singularize(required string word) {
		if (right(arguments.word, 1) == "s") {
			return left(arguments.word, len(arguments.word) - 1);
		}
		return arguments.word;
	}

	/**
	 * Convert PascalCase to snake_case and pluralize
	 * Example: "BlogPost" -> "blog_posts"
	 *
	 * @param word The word to tableize
	 * @return Snake case plural form
	 */
	public string function tableize(required string word) {
		var snakeCase = _toSnakeCase(arguments.word);
		return pluralize(snakeCase);
	}

	/**
	 * Convert snake_case to PascalCase
	 * Example: "blog_post" -> "BlogPost"
	 *
	 * @param word The word to pascalize
	 * @return PascalCase form
	 */
	public string function pascalize(required string word) {
		var parts = listToArray(arguments.word, "_");
		var result = "";

		for (var part in parts) {
			result &= uCase(left(part, 1)) & lCase(right(part, len(part) - 1));
		}

		return result;
	}

	/**
	 * Validate if word is a valid CFML identifier
	 * Rules: Must start with letter, alphanumeric + underscore only
	 *
	 * @param word The word to validate
	 * @return True if valid identifier
	 */
	public boolean function isValidIdentifier(required string word) {
		// Must start with a letter
		if (!reFind("^[a-zA-Z]", arguments.word)) {
			return false;
		}

		// Must contain only alphanumeric and underscore
		if (reFind("[^a-zA-Z0-9_]", arguments.word)) {
			return false;
		}

		return true;
	}

	/**
	 * Convert PascalCase or camelCase to snake_case
	 *
	 * @param word The word to convert
	 * @return Snake case form
	 */
	private string function _toSnakeCase(required string word) {
		// Insert underscore before uppercase letters (except first character)
		var result = reReplace(arguments.word, "([A-Z])", "_\1", "all");

		// Remove leading underscore if present
		if (left(result, 1) == "_") {
			result = right(result, len(result) - 1);
		}

		return lCase(result);
	}

}
