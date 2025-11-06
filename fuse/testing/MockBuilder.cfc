/**
 * MockBuilder - Lightweight mock system for test isolation
 *
 * Creates mock instances with method call tracking and stubbing.
 * Supports verification of call counts and arguments.
 *
 * USAGE EXAMPLES:
 *
 * Create mock instance:
 *     var mockBuilder = new MockBuilder();
 *     var mockService = mockBuilder.mock("app.services.EmailService");
 *
 * Stub method with return value:
 *     mockBuilder.stub(mockService, "send", true);
 *     var result = mockService.send(); // returns true
 *
 * Verify exact call count:
 *     mockBuilder.verify(mockService, "send", 2);
 *
 * Verify call count range:
 *     mockBuilder.verify(mockService, "send", {min: 1, max: 3});
 *
 * Features:
 * - Method-level mocking only (no property mocking)
 * - Call tracking with timestamp and arguments
 * - Simple stub configuration for return values
 * - Verification with exact or min/max ranges
 * - Descriptive errors for unstubbed methods and verification failures
 */
component {

	/**
	 * Create mock instance of component
	 *
	 * Creates a proxy component that tracks method calls and allows stubbing.
	 * All public methods are intercepted. Unstubbed methods throw error.
	 *
	 * @componentPath Dot-notation path to component (e.g., "app.models.User")
	 * @return Mock instance with call tracking
	 */
	public any function mock(required string componentPath) {
		// Get component metadata to introspect methods
		var targetComponent = createObject("component", arguments.componentPath);
		var metadata = getMetadata(targetComponent);

		// Create mock proxy object
		var mockInstance = {
			_componentPath: arguments.componentPath,
			_callHistory: [],
			_stubs: {},
			_metadata: metadata,

			// Expose call history for verification
			getCallHistory: function() {
				return this._callHistory;
			},

			// Expose stubs for debugging
			getStubs: function() {
				return this._stubs;
			}
		};

		// Override each public method to intercept calls
		if (structKeyExists(metadata, "functions")) {
			for (var funcMeta in metadata.functions) {
				if (structKeyExists(funcMeta, "name") &&
					(!structKeyExists(funcMeta, "access") || funcMeta.access == "public")) {

					var methodName = funcMeta.name;

					// Create interceptor closure for this method
					mockInstance[methodName] = createInterceptor(mockInstance, methodName);
				}
			}
		}

		return mockInstance;
	}

	/**
	 * Stub method to return static value
	 *
	 * Configures a mock method to return the specified value without
	 * calling the original implementation.
	 *
	 * @mockInstance Mock instance created by mock()
	 * @methodName Name of method to stub
	 * @returnValue Value to return when method is called
	 */
	public void function stub(
		required any mockInstance,
		required string methodName,
		any returnValue
	) {
		// Store stub configuration in mock's stubs struct
		arguments.mockInstance._stubs[arguments.methodName] = {
			returnValue: arguments.returnValue,
			hasReturnValue: structKeyExists(arguments, "returnValue")
		};
	}

	/**
	 * Verify method was called expected number of times
	 *
	 * Checks call history and throws descriptive error if verification fails.
	 * Supports exact count or min/max range.
	 *
	 * @mockInstance Mock instance created by mock()
	 * @methodName Name of method to verify
	 * @times Expected call count (numeric) or struct with min/max keys
	 */
	public void function verify(
		required any mockInstance,
		required string methodName,
		required any times
	) {
		// Count calls for this method
		var actualCount = 0;
		for (var call in arguments.mockInstance._callHistory) {
			if (call.method == arguments.methodName) {
				actualCount++;
			}
		}

		// Determine expected count or range
		var isValid = false;
		var expectedDescription = "";

		if (isNumeric(arguments.times)) {
			// Exact count verification
			isValid = (actualCount == arguments.times);
			expectedDescription = "Expected: " & arguments.times;
		} else if (isStruct(arguments.times)) {
			// Min/max range verification
			var hasMin = structKeyExists(arguments.times, "min");
			var hasMax = structKeyExists(arguments.times, "max");

			if (hasMin && hasMax) {
				isValid = (actualCount >= arguments.times.min && actualCount <= arguments.times.max);
				expectedDescription = "Expected: between " & arguments.times.min & " and " & arguments.times.max;
			} else if (hasMin) {
				isValid = (actualCount >= arguments.times.min);
				expectedDescription = "Expected: at least " & arguments.times.min;
			} else if (hasMax) {
				isValid = (actualCount <= arguments.times.max);
				expectedDescription = "Expected: at most " & arguments.times.max;
			}
		}

		// Throw descriptive error if verification fails
		if (!isValid) {
			throw(
				type = "VerificationFailedException",
				message = "Method call verification failed for #arguments.methodName#()",
				detail = "#expectedDescription#, Actual: #actualCount#"
			);
		}
	}

	// PRIVATE METHODS

	/**
	 * Create interceptor function for mock method
	 *
	 * Returns a function that tracks calls and checks for stubs.
	 * This creates a closure that captures the mock instance and method name.
	 *
	 * @mockInstance Mock instance
	 * @methodName Method name to intercept
	 * @return Interceptor function
	 */
	private function createInterceptor(required any mockInstance, required string methodName) {
		return function() {
			var mock = mockInstance;
			var method = methodName;

			// Track this call
			arrayAppend(mock._callHistory, {
				method: method,
				args: arguments,
				timestamp: now()
			});

			// Check if method is stubbed
			if (structKeyExists(mock._stubs, method)) {
				var stub = mock._stubs[method];

				// Return stubbed value if configured
				if (stub.hasReturnValue) {
					return stub.returnValue;
				} else {
					return;
				}
			}

			// Method not stubbed - throw descriptive error
			throw(
				type = "MethodNotStubbedException",
				message = "Method not stubbed: #method#()",
				detail = "Mock methods must be stubbed before calling. Use stub(mockInstance, '#method#', returnValue) to configure."
			);
		};
	}

}
