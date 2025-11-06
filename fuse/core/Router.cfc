component {

	function init() {
		variables.routes = [];
		variables.namedRoutes = {};

		return this;
	}

	/**
	 * Register GET route
	 *
	 * @pattern URL pattern (e.g., "/users/:id")
	 * @handler Handler string (e.g., "Users.show")
	 * @options Options struct with optional "name" key
	 */
	public void function get(required string pattern, required string handler, struct options = {}) {
		addRoute("GET", arguments.pattern, arguments.handler, arguments.options);
	}

	/**
	 * Register POST route
	 */
	public void function post(required string pattern, required string handler, struct options = {}) {
		addRoute("POST", arguments.pattern, arguments.handler, arguments.options);
	}

	/**
	 * Register PUT route
	 */
	public void function put(required string pattern, required string handler, struct options = {}) {
		addRoute("PUT", arguments.pattern, arguments.handler, arguments.options);
	}

	/**
	 * Register PATCH route
	 */
	public void function patch(required string pattern, required string handler, struct options = {}) {
		addRoute("PATCH", arguments.pattern, arguments.handler, arguments.options);
	}

	/**
	 * Register DELETE route
	 */
	public void function delete(required string pattern, required string handler, struct options = {}) {
		addRoute("DELETE", arguments.pattern, arguments.handler, arguments.options);
	}

	/**
	 * Generate RESTful resource routes
	 *
	 * @name Resource name (e.g., "users", "blog_posts")
	 * @options Options struct with optional "only" and "except" arrays
	 */
	public void function resource(required string name, struct options = {}) {
		// Define all 7 standard RESTful actions
		var allActions = ["index", "new", "create", "show", "edit", "update", "destroy"];
		var actions = allActions;

		// Filter actions based on only/except options
		if (structKeyExists(arguments.options, "only") && isArray(arguments.options.only)) {
			actions = arguments.options.only;
			validateActions(actions);
		} else if (structKeyExists(arguments.options, "except") && isArray(arguments.options.except)) {
			validateActions(arguments.options.except);
			actions = [];
			for (var action in allActions) {
				if (!arrayContains(arguments.options.except, action)) {
					arrayAppend(actions, action);
				}
			}
		}

		// Derive handler name from resource name
		var handlerName = deriveHandlerName(arguments.name);

		// Generate routes in correct precedence order
		// Static routes must come before parameterized routes
		var routeDefinitions = [
			{action: "index", method: "get", pattern: "/{name}", handler: "index"},
			{action: "new", method: "get", pattern: "/{name}/new", handler: "new"},
			{action: "create", method: "post", pattern: "/{name}", handler: "create"},
			{action: "show", method: "get", pattern: "/{name}/:id", handler: "show"},
			{action: "edit", method: "get", pattern: "/{name}/:id/edit", handler: "edit"},
			{action: "update", method: "put", pattern: "/{name}/:id", handler: "update"},
			{action: "update_patch", method: "patch", pattern: "/{name}/:id", handler: "update"},
			{action: "destroy", method: "delete", pattern: "/{name}/:id", handler: "destroy"}
		];

		for (var routeDef in routeDefinitions) {
			var action = routeDef.action;

			// Skip update_patch special case in filtering
			if (action == "update_patch") {
				action = "update";
			}

			// Skip if action not in filtered list
			if (!arrayContains(actions, action)) {
				continue;
			}

			var routeName = arguments.name & "_" & action;
			var pattern = replace(routeDef.pattern, "{name}", arguments.name, "all");
			var handlerMethod = handlerName & "." & routeDef.handler;

			// For update_patch, don't assign a route name (already assigned to PUT)
			if (routeDef.action == "update_patch") {
				this[routeDef.method](pattern, handlerMethod, {});
			} else {
				this[routeDef.method](pattern, handlerMethod, {name: routeName});
			}
		}
	}

	/**
	 * Find matching route for path and HTTP method
	 *
	 * @path URL path to match
	 * @method HTTP method (GET, POST, etc.)
	 * @return Struct with route and params on match, struct with matched=false if no match
	 */
	public struct function findRoute(required string path, required string method) {
		// Iterate routes in registration order
		for (var route in variables.routes) {
			// Match HTTP method
			if (route.method != uCase(arguments.method)) {
				continue;
			}

			// Try to match pattern
			var matchResult = route.patternObj.match(arguments.path);

			if (matchResult.matched) {
				return {
					matched: true,
					route: route,
					params: matchResult
				};
			}
		}

		// No match found
		return {matched: false};
	}

	/**
	 * Get named route by name
	 *
	 * @name Route name
	 * @return Route struct or null if not found
	 */
	public any function getNamedRoute(required string name) {
		if (structKeyExists(variables.namedRoutes, arguments.name)) {
			return variables.namedRoutes[arguments.name];
		}

		return null;
	}

	/**
	 * Generate URL from named route with parameter replacement
	 *
	 * @name Route name
	 * @params Parameters to replace in pattern
	 * @return Generated URL string
	 */
	public string function urlFor(required string name, struct params = {}) {
		// Lookup route from namedRoutes
		if (!structKeyExists(variables.namedRoutes, arguments.name)) {
			throw(
				type = "RouteNotFoundException",
				message = "Named route not found: #arguments.name#",
				detail = "No route registered with name '#arguments.name#'. Check route definitions in routes.cfm."
			);
		}

		var route = variables.namedRoutes[arguments.name];
		var pattern = route.pattern;
		var generatedUrl = pattern;

		// Find all parameter placeholders in pattern
		var paramMatches = reMatch(":[a-zA-Z_][a-zA-Z0-9_]*", pattern);

		// Replace each parameter placeholder with value from params
		for (var paramMatch in paramMatches) {
			// Extract param name (remove leading colon)
			var paramName = right(paramMatch, len(paramMatch) - 1);

			// Check if param value provided
			if (!structKeyExists(arguments.params, paramName)) {
				throw(
					type = "MissingParameterException",
					message = "Missing required parameter: #paramName#",
					detail = "Route '#arguments.name#' requires parameter '#paramName#' but it was not provided."
				);
			}

			// Replace :param with value
			generatedUrl = replace(generatedUrl, paramMatch, arguments.params[paramName], "all");
		}

		return generatedUrl;
	}

	// Private methods

	private void function addRoute(
		required string method,
		required string pattern,
		required string handler,
		struct options = {}
	) {
		// Create RoutePattern instance
		var patternObj = new fuse.core.RoutePattern(arguments.pattern);

		// Build route struct
		var route = {
			pattern: arguments.pattern,
			method: uCase(arguments.method),
			handler: arguments.handler,
			patternObj: patternObj
		};

		// Add name if provided
		if (structKeyExists(arguments.options, "name")) {
			route.name = arguments.options.name;
			variables.namedRoutes[arguments.options.name] = route;
		}

		// Store in routes array maintaining order
		arrayAppend(variables.routes, route);
	}

	/**
	 * Derive handler name from resource name with proper casing
	 * Examples: "users" -> "Users", "blog_posts" -> "BlogPosts"
	 */
	private string function deriveHandlerName(required string name) {
		var parts = listToArray(arguments.name, "_");
		var result = "";

		for (var part in parts) {
			result &= uCase(left(part, 1)) & right(part, len(part) - 1);
		}

		return result;
	}

	/**
	 * Validate action names are valid RESTful actions
	 */
	private void function validateActions(required array actions) {
		var validActions = ["index", "new", "create", "show", "edit", "update", "destroy"];

		for (var action in arguments.actions) {
			if (!arrayContains(validActions, action)) {
				throw(
					type = "InvalidActionException",
					message = "Invalid resource action: #action#",
					detail = "Valid actions are: #arrayToList(validActions, ', ')#"
				);
			}
		}
	}

	/**
	 * Check if array contains a value
	 */
	private boolean function arrayContains(required array arr, required string value) {
		for (var item in arguments.arr) {
			if (item == arguments.value) {
				return true;
			}
		}
		return false;
	}

}
