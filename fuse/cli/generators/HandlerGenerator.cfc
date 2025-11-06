/**
 * HandlerGenerator - Generate RESTful handler files
 *
 * Creates handler CFCs in app/handlers/ with configurable actions.
 * Supports full RESTful, API-only, and custom action sets.
 */
component {

	/**
	 * Generate a handler file
	 *
	 * @param name Handler name (e.g., "Users", "Api/V1/Users")
	 * @param options Generation options struct
	 * @return Struct with success, handlerPath
	 */
	public struct function generate(
		required string name,
		struct options = {}
	) {
		// Initialize utilities
		var naming = new fuse.cli.support.NamingConventions();
		var templateEngine = new fuse.cli.support.TemplateEngine();
		var fileGenerator = new fuse.cli.support.FileGenerator();

		// Set defaults
		var basePath = structKeyExists(arguments.options, "basePath") ? arguments.options.basePath : expandPath("/");
		var api = structKeyExists(arguments.options, "api") ? arguments.options.api : false;
		var actionsStr = structKeyExists(arguments.options, "actions") ? arguments.options.actions : "";
		var force = structKeyExists(arguments.options, "force") ? arguments.options.force : false;

		// Parse handler name and namespace
		var handlerInfo = _parseHandlerName(arguments.name, naming);
		var handlerName = handlerInfo.name;
		var namespace = handlerInfo.namespace;
		var fullPath = handlerInfo.fullPath;

		// Determine which actions to include
		var actions = _determineActions(api, actionsStr);

		// Determine which template to use
		var templatePath = "";
		if (api) {
			templatePath = expandPath("/fuse/cli/templates/app/handler_api.cfc.tmpl");
		} else {
			templatePath = expandPath("/fuse/cli/templates/app/handler.cfc.tmpl");
		}

		// Render handler template
		var handlerContent = templateEngine.render(
			templatePath,
			{
				handlerName: handlerName,
				namespace: lCase(replace(namespace, "/", "_", "all")),
				actions: arrayToList(actions, ",")
			}
		);

		// If specific actions were requested, filter the content
		if (len(actionsStr) > 0) {
			handlerContent = _filterActions(handlerContent, actions);
		}

		// Write handler file
		var handlerPath = basePath & "app/handlers/" & fullPath & ".cfc";
		var fileResult = fileGenerator.createFile(handlerPath, handlerContent, force);

		if (!fileResult.success) {
			return fileResult;
		}

		return {
			success: true,
			message: "Handler created: " & handlerPath,
			handlerPath: handlerPath
		};
	}

	/**
	 * Parse handler name into components
	 *
	 * @param name Handler name (may include namespace)
	 * @param naming NamingConventions instance
	 * @return Struct with name, namespace, fullPath
	 */
	private struct function _parseHandlerName(required string name, required any naming) {
		var parts = listToArray(arguments.name, "/");
		var handlerName = parts[arrayLen(parts)];

		// Pascalize the handler name
		handlerName = arguments.naming.pascalize(handlerName);

		// Build namespace path
		var namespace = "";
		var fullPath = "";

		if (arrayLen(parts) > 1) {
			// Extract namespace parts
			var namespaceParts = [];
			for (var i = 1; i < arrayLen(parts); i++) {
				arrayAppend(namespaceParts, arguments.naming.pascalize(parts[i]));
			}
			namespace = arrayToList(namespaceParts, "/");
			fullPath = namespace & "/" & handlerName;
		} else {
			fullPath = handlerName;
		}

		return {
			name: handlerName,
			namespace: namespace,
			fullPath: fullPath
		};
	}

	/**
	 * Determine which actions to include
	 *
	 * @param api Whether this is API-only
	 * @param actionsStr Comma-separated list of specific actions
	 * @return Array of action names
	 */
	private array function _determineActions(required boolean api, required string actionsStr) {
		// If specific actions requested
		if (len(arguments.actionsStr) > 0) {
			return listToArray(arguments.actionsStr, ",");
		}

		// API-only actions
		if (arguments.api) {
			return ["index", "show", "create", "update", "destroy"];
		}

		// Full RESTful actions
		return ["index", "show", "new", "create", "edit", "update", "destroy"];
	}

	/**
	 * Filter handler content to only include specified actions
	 *
	 * @param content Full handler content
	 * @param actions Array of actions to keep
	 * @return Filtered content
	 */
	private string function _filterActions(required string content, required array actions) {
		var lines = listToArray(arguments.content, chr(10));
		var filteredLines = [];
		var inFunction = false;
		var currentFunction = "";
		var functionBuffer = [];
		var keepFunction = false;

		for (var line in lines) {
			// Check if this is a function declaration
			if (reFind("function\s+(\w+)\s*\(", line)) {
				// If we were in a function, process the buffer
				if (inFunction && keepFunction) {
					filteredLines.append(functionBuffer, true);
				}

				// Start new function
				inFunction = true;
				functionBuffer = [];
				var match = reFind("function\s+(\w+)\s*\(", line, 1, true);
				if (match.pos[2] > 0) {
					currentFunction = mid(line, match.pos[2], match.len[2]);
				}
				keepFunction = arrayFind(arguments.actions, currentFunction) > 0;
				arrayAppend(functionBuffer, line);
			} else if (inFunction) {
				arrayAppend(functionBuffer, line);

				// Check for end of function (closing brace at start of line)
				if (trim(line) == "}" && arrayLen(functionBuffer) > 2) {
					// Function ended
					if (keepFunction) {
						filteredLines.append(functionBuffer, true);
					}
					inFunction = false;
					functionBuffer = [];
					keepFunction = false;
				}
			} else {
				// Not in a function, keep the line
				arrayAppend(filteredLines, line);
			}
		}

		// Handle last function if still in buffer
		if (inFunction && keepFunction) {
			filteredLines.append(functionBuffer, true);
		}

		return arrayToList(filteredLines, chr(10));
	}

}
