/**
 * TemplateEngine - Simple template rendering with variable interpolation
 *
 * Renders templates with {{variable}} interpolation syntax.
 * Supports template override: searches config/templates/ first,
 * then falls back to fuse/cli/templates/.
 */
component {

	variables.basePath = "";

	/**
	 * Initialize template engine
	 */
	public function init() {
		variables.basePath = expandPath("/");
		return this;
	}

	/**
	 * Set base path for template resolution (used in testing)
	 *
	 * @param basePath The base path to use
	 */
	public void function setBasePath(required string basePath) {
		variables.basePath = arguments.basePath;
	}

	/**
	 * Render template from file with variable interpolation
	 *
	 * @param templatePath Path to template file (can be absolute or relative)
	 * @param variables Struct of variables to interpolate
	 * @return Rendered template string
	 * @throws TemplateNotFound When template file doesn't exist
	 */
	public string function render(required string templatePath, struct variables = {}) {
		var resolvedPath = "";

		// If path is absolute (starts with / or drive letter), use it directly
		if (left(arguments.templatePath, 1) == "/" || reFind("^[a-zA-Z]:", arguments.templatePath)) {
			resolvedPath = arguments.templatePath;
		} else {
			// Otherwise resolve relative to template directories
			resolvedPath = _resolveTemplatePath(arguments.templatePath);
		}

		if (!fileExists(resolvedPath)) {
			throw(
				type = "TemplateNotFound",
				message = "Template file not found: '#resolvedPath#'",
				detail = "Searched in: config/templates/ and fuse/cli/templates/"
			);
		}

		var templateContent = fileRead(resolvedPath);
		return renderString(templateContent, arguments.variables);
	}

	/**
	 * Render template string with variable interpolation
	 *
	 * @param templateString The template string to render
	 * @param variables Struct of variables to interpolate
	 * @return Rendered string
	 */
	public string function renderString(required string templateString, struct variables = {}) {
		var result = arguments.templateString;

		// Replace each {{variable}} with its value
		// Note: CFML struct keys are case-insensitive, so we need to match case-insensitively
		for (var key in arguments.variables) {
			// Try both the original key and lowercase version
			var pattern = "{{" & key & "}}";
			var value = arguments.variables[key];

			// Use regex replace for case-insensitive matching
			result = reReplaceNoCase(result, "\{\{" & key & "\}\}", value, "all");
		}

		return result;
	}

	/**
	 * Resolve template path with override support
	 * Searches config/templates/ first, then fuse/cli/templates/
	 *
	 * @param templatePath Template filename or relative path
	 * @return Full path to template file
	 */
	private string function _resolveTemplatePath(required string templatePath) {
		// Check for override in config/templates/
		var configPath = variables.basePath & "config/templates/" & arguments.templatePath;
		if (fileExists(configPath)) {
			return configPath;
		}

		// Fallback to framework templates
		var frameworkPath = variables.basePath & "fuse/cli/templates/" & arguments.templatePath;
		return frameworkPath;
	}

}
