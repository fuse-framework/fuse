/**
 * Routes Command - Display registered routes
 *
 * Shows all registered routes in ASCII table format with filtering options.
 */
component {

	/**
	 * Main command entry point
	 *
	 * @param args Arguments struct with flags
	 * @return Struct with success, message, and route data
	 */
	public struct function main(required struct args) {
		var silent = structKeyExists(arguments.args, "silent") ? arguments.args.silent : false;

		// Check framework initialization
		if (!isDefined("application.fuse")) {
			throw(
				type = "FrameworkNotInitialized",
				message = "Fuse framework not initialized",
				detail = "application.fuse not found. Ensure framework is loaded before running routes command."
			);
		}

		// Access router
		var router = application.fuse.router;
		var routes = router.getRoutes();

		// Filter routes
		var filteredRoutes = filterRoutes(routes, arguments.args);

		// Sort routes by URI then method
		var sortedRoutes = sortRoutes(filteredRoutes);

		// Display table
		if (!silent) {
			displayRoutesTable(sortedRoutes);
		}

		return {
			success: true,
			message: "Routes displayed",
			routeCount: arrayLen(sortedRoutes)
		};
	}

	/**
	 * Filter routes based on command flags
	 *
	 * @param routes Array of route structs
	 * @param args Arguments struct with filter flags
	 * @return Filtered array of routes
	 */
	private array function filterRoutes(required array routes, required struct args) {
		var filtered = [];

		for (var route in arguments.routes) {
			// Filter by method (case-insensitive)
			if (structKeyExists(arguments.args, "method") && len(arguments.args.method)) {
				if (uCase(route.method) != uCase(arguments.args.method)) {
					continue;
				}
			}

			// Filter by name (contains match)
			if (structKeyExists(arguments.args, "name") && len(arguments.args.name)) {
				var routeName = structKeyExists(route, "name") ? route.name : "";
				if (!findNoCase(arguments.args.name, routeName)) {
					continue;
				}
			}

			// Filter by handler (contains match)
			if (structKeyExists(arguments.args, "handler") && len(arguments.args.handler)) {
				if (!findNoCase(arguments.args.handler, route.handler)) {
					continue;
				}
			}

			arrayAppend(filtered, route);
		}

		return filtered;
	}

	/**
	 * Sort routes by URI alphabetically, then by method
	 *
	 * @param routes Array of route structs
	 * @return Sorted array of routes
	 */
	private array function sortRoutes(required array routes) {
		var sorted = duplicate(arguments.routes);

		// Simple bubble sort by URI then method
		for (var i = 1; i <= arrayLen(sorted); i++) {
			for (var j = i + 1; j <= arrayLen(sorted); j++) {
				var route1 = sorted[i];
				var route2 = sorted[j];

				// Compare URIs first
				var compareResult = compare(route1.pattern, route2.pattern);

				// If URIs equal, compare methods
				if (compareResult == 0) {
					compareResult = compare(route1.method, route2.method);
				}

				// Swap if route2 should come before route1
				if (compareResult > 0) {
					var temp = sorted[i];
					sorted[i] = sorted[j];
					sorted[j] = temp;
				}
			}
		}

		return sorted;
	}

	/**
	 * Display routes as ASCII table
	 *
	 * @param routes Array of route structs
	 */
	private void function displayRoutesTable(required array routes) {
		// Calculate column widths
		var widths = calculateColumnWidths(arguments.routes);

		// Draw top border
		drawBorder(widths);

		// Draw header
		drawRow(["Method", "URI", "Name", "Handler"], widths);

		// Draw separator
		drawBorder(widths);

		// Draw route rows
		for (var route in arguments.routes) {
			var name = structKeyExists(route, "name") ? route.name : "";
			drawRow([route.method, route.pattern, name, route.handler], widths);
		}

		// Draw bottom border
		drawBorder(widths);
	}

	/**
	 * Calculate column widths based on content
	 *
	 * @param routes Array of route structs
	 * @return Struct with width for each column
	 */
	private struct function calculateColumnWidths(required array routes) {
		var widths = {
			method: len("Method"),
			uri: len("URI"),
			name: len("Name"),
			handler: len("Handler")
		};

		for (var route in arguments.routes) {
			widths.method = max(widths.method, len(route.method));
			widths.uri = max(widths.uri, len(route.pattern));
			widths.handler = max(widths.handler, len(route.handler));

			if (structKeyExists(route, "name")) {
				widths.name = max(widths.name, len(route.name));
			}
		}

		return widths;
	}

	/**
	 * Draw table border
	 *
	 * @param widths Column widths struct
	 */
	private void function drawBorder(required struct widths) {
		var line = "+";
		line &= repeatString("-", arguments.widths.method + 2) & "+";
		line &= repeatString("-", arguments.widths.uri + 2) & "+";
		line &= repeatString("-", arguments.widths.name + 2) & "+";
		line &= repeatString("-", arguments.widths.handler + 2) & "+";

		writeOutput(line & chr(10));
	}

	/**
	 * Draw table row
	 *
	 * @param values Array of cell values
	 * @param widths Column widths struct
	 */
	private void function drawRow(required array values, required struct widths) {
		var row = "|";

		// Method column
		row &= " " & padRight(arguments.values[1], arguments.widths.method) & " |";

		// URI column
		row &= " " & padRight(arguments.values[2], arguments.widths.uri) & " |";

		// Name column
		row &= " " & padRight(arguments.values[3], arguments.widths.name) & " |";

		// Handler column
		row &= " " & padRight(arguments.values[4], arguments.widths.handler) & " |";

		writeOutput(row & chr(10));
	}

	/**
	 * Pad string to right with spaces
	 *
	 * @param str String to pad
	 * @param length Target length
	 * @return Padded string
	 */
	private string function padRight(required string str, required numeric length) {
		var padded = arguments.str;
		while (len(padded) < arguments.length) {
			padded &= " ";
		}
		return padded;
	}

	/**
	 * Repeat string N times
	 *
	 * @param str String to repeat
	 * @param count Number of times to repeat
	 * @return Repeated string
	 */
	private string function repeatString(required string str, required numeric count) {
		var result = "";
		for (var i = 1; i <= arguments.count; i++) {
			result &= arguments.str;
		}
		return result;
	}

}
