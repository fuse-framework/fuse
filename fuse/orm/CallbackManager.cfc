/**
 * CallbackManager - ORM lifecycle callback management
 *
 * Manages registration and execution of lifecycle callbacks for ActiveRecord models.
 * Follows EventService.cfc pattern for callback storage and triggering.
 *
 * USAGE:
 *
 * Registration:
 *     var manager = new fuse.orm.CallbackManager();
 *     manager.registerCallback("beforeSave", "methodName");
 *
 * Execution:
 *     var shouldContinue = manager.executeCallbacks(model, "beforeSave");
 *     if (!shouldContinue) {
 *         // Callback returned false, halt operation
 *     }
 *
 * Callback execution:
 *     - Callbacks execute in registration order
 *     - Return false to short-circuit (halt execution)
 *     - Return true or void to continue
 */
component {

	/**
	 * Valid callback point names
	 */
	variables.validCallbacks = [
		"beforeSave",
		"afterSave",
		"beforeCreate",
		"afterCreate",
		"beforeDelete",
		"afterDelete"
	];

	/**
	 * Initialize CallbackManager
	 */
	public function init() {
		variables.callbacks = {};

		// Initialize empty arrays for each valid callback point
		for (var point in variables.validCallbacks) {
			variables.callbacks[point] = [];
		}

		return this;
	}

	/**
	 * Register a callback for a specific lifecycle point
	 *
	 * @point The callback point name (one of 6 valid points)
	 * @methodName String name of method on model to invoke
	 * @throws InvalidCallbackPointException if point name is invalid
	 */
	public void function registerCallback(
		required string point,
		required string methodName
	) {
		if (!arrayFindNoCase(variables.validCallbacks, arguments.point)) {
			throw(
				type = "InvalidCallbackPointException",
				message = "Invalid callback point: #arguments.point#",
				detail = "Valid points: #arrayToList(variables.validCallbacks)#"
			);
		}

		arrayAppend(variables.callbacks[arguments.point], arguments.methodName);
	}

	/**
	 * Execute all callbacks for a specific lifecycle point
	 *
	 * Executes callbacks in registration order. Short-circuits if callback returns false.
	 *
	 * @model The ActiveRecord model instance
	 * @point The callback point name
	 * @return Boolean true if all callbacks pass, false if halted by callback
	 */
	public boolean function executeCallbacks(
		required any model,
		required string point
	) {
		// Return true if no callbacks registered for this point
		if (!structKeyExists(variables.callbacks, arguments.point)) {
			return true;
		}

		var callbackMethods = variables.callbacks[arguments.point];

		for (var methodName in callbackMethods) {
			// Validate callback method exists on model
			if (!structKeyExists(arguments.model, methodName)) {
				continue;
			}

			// Invoke callback method on model using invoke() to preserve context
			var result = invoke(arguments.model, methodName);

			// Short-circuit if callback returns false explicitly
			if (isDefined("result") && isBoolean(result) && !result) {
				return false;
			}
		}

		return true;
	}

	/**
	 * Get all registered callbacks (for testing)
	 *
	 * @return Struct of callback arrays by point
	 */
	public struct function getCallbacks() {
		return variables.callbacks;
	}

}
