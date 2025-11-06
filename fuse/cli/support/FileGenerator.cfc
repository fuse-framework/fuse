/**
 * FileGenerator - Utility for safely creating files with directory structure
 *
 * Handles file creation with overwrite protection, directory creation,
 * and consistent line endings.
 */
component {

	/**
	 * Create a file with content, optionally forcing overwrite
	 *
	 * @param path Full path to the file to create
	 * @param content Content to write to the file
	 * @param force Whether to overwrite existing file (default: false)
	 * @return Struct with success boolean and message string
	 * @throws FileAlreadyExists When file exists and force is false
	 */
	public struct function createFile(
		required string path,
		required string content,
		boolean force = false
	) {
		try {
			// Check if file already exists
			if (fileExists(arguments.path) && !arguments.force) {
				throw(
					type = "FileAlreadyExists",
					message = "File already exists: '#arguments.path#'",
					detail = "Use --force flag to overwrite existing files"
				);
			}

			// Create parent directories if they don't exist
			var directory = getDirectoryFromPath(arguments.path);
			if (!directoryExists(directory)) {
				directoryCreate(directory, true);
			}

			// Normalize line endings to LF
			var normalizedContent = _normalizeLineEndings(arguments.content);

			// Basic CFML parseability check
			_validateCFMLContent(normalizedContent, arguments.path);

			// Write file - delete first if exists to ensure clean overwrite
			if (fileExists(arguments.path)) {
				fileDelete(arguments.path);
			}
			fileWrite(arguments.path, normalizedContent);

			return {
				success: true,
				message: "File created successfully: #arguments.path#"
			};

		} catch (any e) {
			// If it's our own exception, rethrow it
			if (e.type == "FileAlreadyExists") {
				rethrow;
			}

			// Otherwise return error result
			return {
				success: false,
				message: "Error creating file: #e.message#",
				detail: e.detail ?: ""
			};
		}
	}

	/**
	 * Normalize line endings to LF (Unix-style)
	 *
	 * @param content The content to normalize
	 * @return Content with LF line endings
	 */
	private string function _normalizeLineEndings(required string content) {
		var result = arguments.content;

		// Replace CRLF with LF
		result = replace(result, chr(13) & chr(10), chr(10), "all");

		// Replace any remaining CR with LF
		result = replace(result, chr(13), chr(10), "all");

		return result;
	}

	/**
	 * Basic validation that content is parseable CFML
	 * Only checks if it's a .cfc or .cfm file and has basic structure
	 *
	 * @param content The content to validate
	 * @param path The file path (to check extension)
	 */
	private void function _validateCFMLContent(required string content, required string path) {
		var extension = listLast(arguments.path, ".");

		// Only validate CFML files
		if (!listFindNoCase("cfc,cfm", extension)) {
			return;
		}

		// Basic check: CFC files should contain "component" keyword
		if (extension == "cfc" && !findNoCase("component", arguments.content)) {
			throw(
				type = "InvalidCFMLContent",
				message = "Invalid CFC content: missing 'component' keyword",
				detail = "Generated .cfc files must contain the 'component' keyword"
			);
		}
	}

}
