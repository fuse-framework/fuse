/**
 * Dispatcher
 *
 * Orchestrates the request lifecycle from routing through handler execution.
 * Triggers interceptor points and manages event context throughout the request.
 */
component {

	/**
	 * Initialize Dispatcher with dependencies
	 *
	 * @router Router instance for route matching
	 * @container Container instance for handler resolution
	 * @eventService EventService instance for interceptor execution
	 */
	public function init(
		required router,
		required container,
		required eventService
	) {
		variables.router = arguments.router;
		variables.container = arguments.container;
		variables.eventService = arguments.eventService;

		return this;
	}

	/**
	 * Dispatch a request through the full lifecycle
	 *
	 * @path Request path (e.g., "/users/123")
	 * @method HTTP method (e.g., "GET", "POST")
	 * @return Handler result or error struct
	 */
	public any function dispatch(
		required string path,
		required string method
	) {
		// Build initial event context
		var event = buildEventContext(arguments.path, arguments.method);

		// Phase 1: onBeforeRequest
		event = variables.eventService.trigger("onBeforeRequest", event);
		if (event.abort) {
			return buildAbortResponse(event);
		}

		// Phase 2: Route matching
		var routeMatch = variables.router.findRoute(arguments.path, arguments.method);

		if (!routeMatch.matched) {
			return build404Response(arguments.path, arguments.method);
		}

		// Add route and params to event context
		event.route = routeMatch.route;
		event.params = routeMatch.params;

		// Phase 3: onAfterRouting
		event = variables.eventService.trigger("onAfterRouting", event);
		if (event.abort) {
			return buildAbortResponse(event);
		}

		// Phase 4: Resolve and instantiate handler
		var handler = resolveHandler(event.route.handler);
		event.handler = handler;

		// Phase 5: onBeforeHandler
		event = variables.eventService.trigger("onBeforeHandler", event);
		if (event.abort) {
			return buildAbortResponse(event);
		}

		// Phase 6: Invoke handler action
		var result = invokeHandlerAction(handler, event.route.handler, event.params);

		// Phase 7: Process handler return value
		event.result = normalizeHandlerResult(result, event.route, event.request.method, event.params);

		// Phase 8: onAfterHandler
		event = variables.eventService.trigger("onAfterHandler", event);
		if (event.abort) {
			return buildAbortResponse(event);
		}

		// Phase 9: onBeforeRender
		event = variables.eventService.trigger("onBeforeRender", event);
		if (event.abort) {
			return buildAbortResponse(event);
		}

		// Phase 10: onAfterRender
		event = variables.eventService.trigger("onAfterRender", event);
		if (event.abort) {
			return buildAbortResponse(event);
		}

		// Return response with rendered body
		return event.response;
	}

	// Private methods

	/**
	 * Build initial event context struct
	 */
	private struct function buildEventContext(
		required string path,
		required string method
	) {
		return {
			request: {
				path: arguments.path,
				method: arguments.method,
				cgi: duplicate(cgi),
				form: duplicate(form),
				url: duplicate(url)
			},
			response: {
				status: 200,
				headers: {},
				body: ""
			},
			route: {},
			params: {},
			handler: {},
			result: {},
			abort: false
		};
	}

	/**
	 * Resolve handler from container
	 *
	 * @handlerString Handler string like "Users.show"
	 * @return Handler instance
	 */
	private any function resolveHandler(required string handlerString) {
		// Parse handler string to extract handler name
		var parts = listToArray(arguments.handlerString, ".");
		var handlerName = parts[1];

		// Try to resolve from container
		try {
			return variables.container.resolve(handlerName);
		} catch (Container.BindingNotFound e) {
			throw(
				type = "Dispatcher.HandlerNotFound",
				message = "Handler '#handlerName#' not found",
				detail = "Handler '#handlerName#' is not registered in the container. Check that the handler exists at /app/handlers/#handlerName#.cfc and is registered in the container."
			);
		} catch (any e) {
			// Pass through container errors with additional context
			throw(
				type = "Dispatcher.HandlerResolutionError",
				message = "Failed to resolve handler '#handlerName#'",
				detail = "Error resolving handler: #e.message#"
			);
		}
	}

	/**
	 * Invoke handler action method with route params
	 *
	 * @handler Handler instance
	 * @handlerString Handler string like "Users.show"
	 * @params Route parameters struct
	 * @return Handler action result
	 */
	private any function invokeHandlerAction(
		required handler,
		required string handlerString,
		required struct params
	) {
		// Parse handler string to extract action name
		var parts = listToArray(arguments.handlerString, ".");
		if (arrayLen(parts) < 2) {
			throw(
				type = "Dispatcher.InvalidHandlerString",
				message = "Invalid handler string format: #arguments.handlerString#",
				detail = "Handler string must be in format 'HandlerName.actionMethod'"
			);
		}

		var handlerName = parts[1];
		var actionName = parts[2];

		// Check if action method exists on handler
		if (!structKeyExists(arguments.handler, actionName)) {
			var availableActions = getAvailableActions(arguments.handler);
			throw(
				type = "Dispatcher.ActionNotFound",
				message = "Action '#actionName#' not found on handler '#handlerName#'",
				detail = "Available actions on '#handlerName#': #arrayToList(availableActions, ', ')#"
			);
		}

		// Invoke action method with route params as arguments
		// Use invoke() to maintain handler's scope context
		try {
			return invoke(arguments.handler, actionName, arguments.params);
		} catch (any e) {
			throw(
				type = "Dispatcher.ActionInvocationError",
				message = "Error invoking action '#handlerName#.#actionName#'",
				detail = "Error: #e.message#"
			);
		}
	}

	/**
	 * Get list of available public methods on handler
	 */
	private array function getAvailableActions(required handler) {
		var actions = [];
		var metadata = getMetadata(arguments.handler);

		if (structKeyExists(metadata, "functions")) {
			for (var func in metadata.functions) {
				if (func.access == "public" && func.name != "init") {
					arrayAppend(actions, func.name);
				}
			}
		}

		// If struct/anonymous object, get keys
		if (isStruct(arguments.handler)) {
			for (var key in arguments.handler) {
				if (isCustomFunction(arguments.handler[key]) || isClosure(arguments.handler[key])) {
					if (key != "init") {
						arrayAppend(actions, key);
					}
				}
			}
		}

		return actions;
	}

	/**
	 * Build 404 response struct
	 */
	private struct function build404Response(
		required string path,
		required string method
	) {
		return {
			status: 404,
			message: "Route not found: #arguments.method# #arguments.path#",
			detail: "No route registered matching this path and HTTP method"
		};
	}

	/**
	 * Build response for aborted request
	 */
	private any function buildAbortResponse(required struct event) {
		// Return response struct from event if available
		if (structKeyExists(arguments.event, "response") && !structIsEmpty(arguments.event.response)) {
			return arguments.event.response;
		}

		// Default abort response
		return {
			status: 200,
			message: "Request aborted by interceptor"
		};
	}

	/**
	 * Normalize handler return value to standard result struct
	 *
	 * @result Handler return value (string, struct, or null)
	 * @route Route struct with pattern and handler info
	 * @method HTTP method
	 * @return Normalized struct with view, locals, and layout keys
	 */
	private struct function normalizeHandlerResult(
		any result,
		required struct route,
		required string method,
		required struct params
	) {
		// String return: convert to {view: "path"} with params as locals
		if (isSimpleValue(arguments.result) && len(trim(arguments.result))) {
			return {
				view: arguments.result,
				locals: duplicate(arguments.params),
				layout: "application"
			};
		}

		// Struct return: use as-is with defaults
		if (isStruct(arguments.result)) {
			var normalized = duplicate(arguments.result);

			// Set defaults if not provided
			if (!structKeyExists(normalized, "locals")) {
				normalized.locals = duplicate(arguments.params);
			} else {
				// Merge params into existing locals (locals take precedence)
				for (var key in arguments.params) {
					if (!structKeyExists(normalized.locals, key)) {
						normalized.locals[key] = arguments.params[key];
					}
				}
			}
			if (!structKeyExists(normalized, "layout")) {
				normalized.layout = "application";
			}

			// Derive view from route if not provided
			if (!structKeyExists(normalized, "view")) {
				normalized.view = deriveViewFromRoute(arguments.route);
			}

			return normalized;
		}

		// Null/void return: derive view from route with params as locals
		return {
			view: deriveViewFromRoute(arguments.route),
			locals: duplicate(arguments.params),
			layout: "application"
		};
	}

	/**
	 * Derive view path from route handler string
	 * Example: "Users.show" -> "users/show"
	 */
	private string function deriveViewFromRoute(required struct route) {
		var handler = arguments.route.handler;
		var parts = listToArray(handler, ".");

		if (arrayLen(parts) < 2) {
			return "";
		}

		var handlerName = parts[1];
		var actionName = parts[2];

		// Convert handler name to snake_case path
		// "BlogPosts" -> "blog_posts"
		var viewPath = convertPascalToSnake(handlerName);

		return viewPath & "/" & actionName;
	}

	/**
	 * Convert PascalCase to snake_case
	 * Example: "BlogPosts" -> "blog_posts"
	 */
	private string function convertPascalToSnake(required string str) {
		var result = "";
		var len = len(arguments.str);

		for (var i = 1; i <= len; i++) {
			var char = mid(arguments.str, i, 1);

			// Add underscore before uppercase letters (except first)
			if (i > 1 && reFind("[A-Z]", char)) {
				result &= "_";
			}

			result &= lCase(char);
		}

		return result;
	}

}
