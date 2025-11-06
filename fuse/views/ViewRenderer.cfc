/**
 * View Renderer
 *
 * Renders .cfm view templates with layout wrapping and helper injection.
 * Supports convention-based view path resolution and isolated execution context.
 */
component {

	property name="config" inject="config";

	/**
	 * Initialize ViewRenderer
	 *
	 * @config Configuration struct with views settings
	 */
	function init(struct config = {}) {
		variables.config = arguments.config;
		variables.helpers = {};
		return this;
	}

	/**
	 * Render view template with optional layout wrapping
	 *
	 * @view View path (e.g., "users/index" -> "/views/users/index.cfm")
	 * @locals Struct of local variables to inject into view scope
	 * @layout Layout name (default "application"), or false to skip layout
	 * @return Rendered HTML string
	 * @throws MissingTemplateException if view template not found
	 */
	public string function render(
		required string view,
		struct locals = {},
		any layout = "application"
	) {
		// Resolve view path using convention
		var paths = resolveViewPath(arguments.view);

		// Check if view exists
		if (!fileExists(paths.absolute)) {
			throw(
				type = "MissingTemplateException",
				message = "View template not found: #arguments.view#",
				detail = "Attempted path: #paths.absolute#"
			);
		}

		// Render the view in isolated context
		var viewHtml = executeView(paths.absolute, paths.relative, arguments.locals);

		// Wrap with layout if requested
		if (arguments.layout !== false && !isBoolean(arguments.layout)) {
			return wrapWithLayout(viewHtml, arguments.layout);
		} else if (isBoolean(arguments.layout) && arguments.layout) {
			// layout = true means use default layout
			var defaultLayout = getConfigValue("views.defaultLayout", "application");
			return wrapWithLayout(viewHtml, defaultLayout);
		}

		// No layout wrapping
		return viewHtml;
	}

	/**
	 * Register a helper function
	 *
	 * @name Helper function name
	 * @func Helper function/closure
	 */
	public void function addHelper(required string name, required any func) {
		variables.helpers[arguments.name] = arguments.func;
	}

	/**
	 * Check if a helper is registered
	 *
	 * @name Helper function name
	 * @return True if helper exists
	 */
	public boolean function hasHelper(required string name) {
		return structKeyExists(variables.helpers, arguments.name);
	}

	/**
	 * Resolve view path using convention
	 *
	 * @view View name (e.g., "users/index")
	 * @return Struct with absolute path and relative path
	 */
	private struct function resolveViewPath(required string view) {
		var viewsPath = getConfigValue("views.path", "/views");
		var viewFile = arguments.view & ".cfm";

		// Build paths
		var relativePath = viewsPath & "/" & viewFile;
		var absolutePath = expandPath(relativePath);

		return {
			absolute: absolutePath,
			relative: relativePath
		};
	}

	/**
	 * Execute view template in isolated context
	 *
	 * @viewPath Absolute path to view template
	 * @viewRelativePath Relative path for cfinclude
	 * @locals Local variables to inject
	 * @return Rendered HTML string
	 */
	private string function executeView(required string viewPath, required string viewRelativePath, required struct locals) {
		// Merge locals with helpers for the execution scope
		var executionScope = duplicate(arguments.locals);

		// Inject helpers as callable functions
		for (var helperName in variables.helpers) {
			executionScope[helperName] = variables.helpers[helperName];
		}

		// Capture view output with variables available in scope
		var output = "";
		savecontent variable="output" {
			// Make all executionScope variables available in the include context
			for (var key in executionScope) {
				variables[key] = executionScope[key];
			}

			// Execute view template using cfinclude
			include "#arguments.viewRelativePath#";

			// Clean up variables to avoid pollution
			for (var key in executionScope) {
				structDelete(variables, key);
			}
		}

		return output;
	}

	/**
	 * Wrap view HTML with layout template
	 *
	 * @viewHtml Rendered view HTML
	 * @layout Layout name
	 * @return HTML wrapped in layout, or unwrapped if layout not found
	 */
	private string function wrapWithLayout(required string viewHtml, required string layout) {
		var layoutPaths = resolveLayoutPath(arguments.layout);

		// Fallback to no-layout if layout doesn't exist
		if (!fileExists(layoutPaths.absolute)) {
			return arguments.viewHtml;
		}

		// Execute layout with content variable
		var content = arguments.viewHtml;
		var layoutOutput = "";

		savecontent variable="layoutOutput" {
			include "#layoutPaths.relative#";
		}

		return layoutOutput;
	}

	/**
	 * Resolve layout path using convention
	 *
	 * @layout Layout name (e.g., "application")
	 * @return Struct with absolute and relative paths
	 */
	private struct function resolveLayoutPath(required string layout) {
		var layoutPath = getConfigValue("views.layoutPath", "/views/layouts");
		var layoutFile = arguments.layout & ".cfm";
		var relativePath = layoutPath & "/" & layoutFile;
		var absolutePath = expandPath(relativePath);

		return {
			absolute: absolutePath,
			relative: relativePath
		};
	}

	/**
	 * Get config value with dot notation and default fallback
	 *
	 * @key Config key with dot notation (e.g., "views.path")
	 * @defaultValue Default value if key not found
	 * @return Config value or default
	 */
	private any function getConfigValue(required string key, any defaultValue = "") {
		var keys = listToArray(arguments.key, ".");
		var value = variables.config;

		for (var k in keys) {
			if (isStruct(value) && structKeyExists(value, k)) {
				value = value[k];
			} else {
				return arguments.defaultValue;
			}
		}

		return value;
	}

	// Setter for property injection
	public void function setConfig(required struct config) {
		variables.config = arguments.config;
	}

}
