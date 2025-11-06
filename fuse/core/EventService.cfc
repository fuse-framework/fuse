/**
 * Event Service
 *
 * Manages interceptor registration and execution for the request lifecycle.
 * Supports 6 interceptor points with observer pattern implementation.
 */
component singleton {

	/**
	 * Valid interceptor point names
	 */
	variables.validPoints = [
		"onBeforeRequest",
		"onAfterRouting",
		"onBeforeHandler",
		"onAfterHandler",
		"onBeforeRender",
		"onAfterRender"
	];

	/**
	 * Initialize EventService
	 */
	public function init() {
		variables.interceptors = {};

		// Initialize empty arrays for each valid point
		for (var point in variables.validPoints) {
			variables.interceptors[point] = [];
		}

		return this;
	}

	/**
	 * Register an interceptor listener for a specific point
	 *
	 * @point The interceptor point name (one of 6 valid points)
	 * @listener Function/closure that receives event struct
	 * @throws InvalidInterceptorPointException if point name is invalid
	 */
	public void function registerInterceptor(
		required string point,
		required any listener
	) {
		if (!arrayFindNoCase(variables.validPoints, arguments.point)) {
			throw(
				type = "InvalidInterceptorPointException",
				message = "Invalid interceptor point: #arguments.point#",
				detail = "Valid points: #arrayToList(variables.validPoints)#"
			);
		}

		arrayAppend(variables.interceptors[arguments.point], arguments.listener);
	}

	/**
	 * Trigger all listeners for a specific interceptor point
	 *
	 * Executes listeners in registration order. Short-circuits if event.abort is set to true.
	 *
	 * @point The interceptor point name
	 * @event Event struct containing request context
	 * @return Modified event struct
	 */
	public struct function trigger(
		required string point,
		required struct event
	) {
		// Return early if no listeners registered for this point
		if (!structKeyExists(variables.interceptors, arguments.point)) {
			return arguments.event;
		}

		var listeners = variables.interceptors[arguments.point];

		for (var listener in listeners) {
			// Execute listener with event struct
			listener(arguments.event);

			// Short-circuit if abort flag set
			if (structKeyExists(arguments.event, "abort") && arguments.event.abort) {
				break;
			}
		}

		return arguments.event;
	}

}
