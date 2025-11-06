/**
 * Assertions - Mixin component providing assertion methods for test cases
 *
 * Provides 15 core assertion methods for validating test conditions.
 * All assertions throw AssertionFailedException on failure with expected/actual details.
 * Each assertion accepts optional message parameter for custom failure context.
 *
 * USAGE EXAMPLES:
 *
 * Equality assertions:
 *     assertEqual(5, user.age);
 *     assertEqual("active", user.status, "User should be active");
 *     assertNotEqual(0, cart.total);
 *
 * Boolean assertions:
 *     assertTrue(user.isValid());
 *     assertFalse(user.isLocked());
 *
 * Null assertions:
 *     assertNull(user.deletedAt);
 *     assertNotNull(user.createdAt);
 *
 * Exception assertions:
 *     assertThrows(function() { user.save(); });
 *     assertThrows(function() { user.delete(); }, "ValidationException");
 *
 * Collection assertions:
 *     assertCount(3, users);
 *     assertContains("admin", user.roles);
 *     assertNotContains("banned", user.roles);
 *
 * Pattern matching:
 *     assertMatches("^\w+@\w+\.\w+$", user.email);
 *
 * Empty checks:
 *     assertEmpty([]);
 *     assertNotEmpty(cart.items);
 *
 * Type assertions:
 *     assertInstanceOf("User", user);
 *
 * Numeric comparisons:
 *     assertGreaterThan(0, cart.total);
 *     assertLessThan(100, discount);
 */
component {

	public function init() {
		return this;
	}

	/**
	 * Assert two values are equal
	 *
	 * @expected The expected value
	 * @actual The actual value
	 * @message Optional custom failure message
	 */
	public void function assertEqual(required any expected, required any actual, string message = "") {
		if (arguments.expected != arguments.actual) {
			throwAssertionFailure(arguments.expected, arguments.actual, arguments.message);
		}
	}

	/**
	 * Assert two values are not equal
	 *
	 * @expected The expected different value
	 * @actual The actual value
	 * @message Optional custom failure message
	 */
	public void function assertNotEqual(required any expected, required any actual, string message = "") {
		if (arguments.expected == arguments.actual) {
			throwAssertionFailure("not " & arguments.expected, arguments.actual, arguments.message);
		}
	}

	/**
	 * Assert value is true
	 *
	 * @value The value to check
	 * @message Optional custom failure message
	 */
	public void function assertTrue(required any value, string message = "") {
		if (arguments.value != true) {
			throwAssertionFailure(true, arguments.value, arguments.message);
		}
	}

	/**
	 * Assert value is false
	 *
	 * @value The value to check
	 * @message Optional custom failure message
	 */
	public void function assertFalse(required any value, string message = "") {
		if (arguments.value != false) {
			throwAssertionFailure(false, arguments.value, arguments.message);
		}
	}

	/**
	 * Assert value is null
	 *
	 * @value The value to check
	 * @message Optional custom failure message
	 */
	public void function assertNull(required any value, string message = "") {
		if (!isNull(arguments.value)) {
			throwAssertionFailure("null", arguments.value, arguments.message);
		}
	}

	/**
	 * Assert value is not null
	 *
	 * @value The value to check
	 * @message Optional custom failure message
	 */
	public void function assertNotNull(required any value, string message = "") {
		if (isNull(arguments.value)) {
			throwAssertionFailure("not null", "null", arguments.message);
		}
	}

	/**
	 * Assert callable throws exception
	 *
	 * @callable Function to execute that should throw
	 * @exceptionType Optional expected exception type
	 * @message Optional custom failure message
	 */
	public void function assertThrows(required any callable, string exceptionType = "", string message = "") {
		var thrown = false;
		var actualType = "";

		try {
			arguments.callable();
		} catch (any e) {
			thrown = true;
			actualType = e.type;

			// If specific exception type expected, verify it matches
			if (len(arguments.exceptionType) && e.type != arguments.exceptionType) {
				throwAssertionFailure(arguments.exceptionType, e.type, arguments.message);
			}
		}

		if (!thrown) {
			var expected = len(arguments.exceptionType) ? arguments.exceptionType : "any exception";
			throwAssertionFailure(expected, "no exception thrown", arguments.message);
		}
	}

	/**
	 * Assert collection has expected count
	 *
	 * @expected Expected count
	 * @collection Array or query to count
	 * @message Optional custom failure message
	 */
	public void function assertCount(required numeric expected, required any collection, string message = "") {
		var actual = 0;

		if (isArray(arguments.collection)) {
			actual = arrayLen(arguments.collection);
		} else if (isQuery(arguments.collection)) {
			actual = arguments.collection.recordCount;
		} else {
			throw(type="InvalidArgumentException", message="Collection must be array or query");
		}

		if (actual != arguments.expected) {
			throwAssertionFailure(arguments.expected, actual, arguments.message);
		}
	}

	/**
	 * Assert haystack contains needle
	 *
	 * @needle Value to find
	 * @haystack Array, string, or query to search
	 * @message Optional custom failure message
	 */
	public void function assertContains(required any needle, required any haystack, string message = "") {
		var found = false;

		if (isArray(arguments.haystack)) {
			found = arrayContains(arguments.haystack, arguments.needle);
		} else if (isSimpleValue(arguments.haystack)) {
			found = findNoCase(arguments.needle, arguments.haystack) > 0;
		} else if (isQuery(arguments.haystack)) {
			// Check if query contains value in any column
			for (var row = 1; row <= arguments.haystack.recordCount; row++) {
				for (var col in listToArray(arguments.haystack.columnList)) {
					if (arguments.haystack[col][row] == arguments.needle) {
						found = true;
						break;
					}
				}
				if (found) break;
			}
		}

		if (!found) {
			throwAssertionFailure("contains " & arguments.needle, "not found", arguments.message);
		}
	}

	/**
	 * Assert haystack does not contain needle
	 *
	 * @needle Value to find
	 * @haystack Array or string to search
	 * @message Optional custom failure message
	 */
	public void function assertNotContains(required any needle, required any haystack, string message = "") {
		var found = false;

		if (isArray(arguments.haystack)) {
			found = arrayContains(arguments.haystack, arguments.needle);
		} else if (isSimpleValue(arguments.haystack)) {
			found = findNoCase(arguments.needle, arguments.haystack) > 0;
		} else if (isQuery(arguments.haystack)) {
			// Check if query contains value in any column
			for (var row = 1; row <= arguments.haystack.recordCount; row++) {
				for (var col in listToArray(arguments.haystack.columnList)) {
					if (arguments.haystack[col][row] == arguments.needle) {
						found = true;
						break;
					}
				}
				if (found) break;
			}
		}

		if (found) {
			throwAssertionFailure("not contains " & arguments.needle, "found", arguments.message);
		}
	}

	/**
	 * Assert string matches regex pattern
	 *
	 * @pattern Regex pattern
	 * @string String to test
	 * @message Optional custom failure message
	 */
	public void function assertMatches(required string pattern, required string string, string message = "") {
		if (!reFind(arguments.pattern, arguments.string)) {
			throwAssertionFailure("matches " & arguments.pattern, arguments.string, arguments.message);
		}
	}

	/**
	 * Assert value is empty
	 *
	 * @value Value to check (string, array, struct, query)
	 * @message Optional custom failure message
	 */
	public void function assertEmpty(required any value, string message = "") {
		var isEmpty = false;

		if (isSimpleValue(arguments.value)) {
			isEmpty = len(arguments.value) == 0;
		} else if (isArray(arguments.value)) {
			isEmpty = arrayLen(arguments.value) == 0;
		} else if (isStruct(arguments.value)) {
			isEmpty = structCount(arguments.value) == 0;
		} else if (isQuery(arguments.value)) {
			isEmpty = arguments.value.recordCount == 0;
		}

		if (!isEmpty) {
			throwAssertionFailure("empty", "not empty", arguments.message);
		}
	}

	/**
	 * Assert value is not empty
	 *
	 * @value Value to check (string, array, struct, query)
	 * @message Optional custom failure message
	 */
	public void function assertNotEmpty(required any value, string message = "") {
		var isEmpty = false;

		if (isSimpleValue(arguments.value)) {
			isEmpty = len(arguments.value) == 0;
		} else if (isArray(arguments.value)) {
			isEmpty = arrayLen(arguments.value) == 0;
		} else if (isStruct(arguments.value)) {
			isEmpty = structCount(arguments.value) == 0;
		} else if (isQuery(arguments.value)) {
			isEmpty = arguments.value.recordCount == 0;
		}

		if (isEmpty) {
			throwAssertionFailure("not empty", "empty", arguments.message);
		}
	}

	/**
	 * Assert object is instance of expected type
	 *
	 * @expected Expected component name
	 * @actual Object to check
	 * @message Optional custom failure message
	 */
	public void function assertInstanceOf(required string expected, required any actual, string message = "") {
		if (!isObject(arguments.actual)) {
			throwAssertionFailure(arguments.expected, "not an object", arguments.message);
		}

		var metadata = getMetadata(arguments.actual);
		var actualType = metadata.name ?: "";

		// Check exact match or inheritance chain
		var isInstance = false;
		if (actualType == arguments.expected) {
			isInstance = true;
		} else if (structKeyExists(metadata, "extends")) {
			var current = metadata.extends;
			while (structKeyExists(current, "name")) {
				if (current.name == arguments.expected) {
					isInstance = true;
					break;
				}
				if (structKeyExists(current, "extends")) {
					current = current.extends;
				} else {
					break;
				}
			}
		}

		if (!isInstance) {
			throwAssertionFailure(arguments.expected, actualType, arguments.message);
		}
	}

	/**
	 * Assert actual is greater than expected
	 *
	 * @expected Minimum value (exclusive)
	 * @actual Value to check
	 * @message Optional custom failure message
	 */
	public void function assertGreaterThan(required numeric expected, required numeric actual, string message = "") {
		if (arguments.actual <= arguments.expected) {
			throwAssertionFailure("> " & arguments.expected, arguments.actual, arguments.message);
		}
	}

	/**
	 * Assert actual is less than expected
	 *
	 * @expected Maximum value (exclusive)
	 * @actual Value to check
	 * @message Optional custom failure message
	 */
	public void function assertLessThan(required numeric expected, required numeric actual, string message = "") {
		if (arguments.actual >= arguments.expected) {
			throwAssertionFailure("< " & arguments.expected, arguments.actual, arguments.message);
		}
	}

	// PRIVATE METHODS

	/**
	 * Throw AssertionFailedException with formatted message
	 *
	 * @expected Expected value
	 * @actual Actual value
	 * @message Optional custom message
	 */
	private void function throwAssertionFailure(required any expected, required any actual, string message = "") {
		var detail = "Expected: " & serializeValue(arguments.expected) & ", Actual: " & serializeValue(arguments.actual);

		if (len(arguments.message)) {
			detail &= " - " & arguments.message;
		}

		throw(
			type = "AssertionFailedException",
			message = "Assertion failed",
			detail = detail
		);
	}

	/**
	 * Serialize value for display in error messages
	 *
	 * @value Value to serialize
	 * @return String representation
	 */
	private string function serializeValue(required any value) {
		if (isNull(arguments.value)) {
			return "null";
		} else if (isSimpleValue(arguments.value)) {
			return arguments.value;
		} else if (isArray(arguments.value)) {
			return "[Array with " & arrayLen(arguments.value) & " elements]";
		} else if (isStruct(arguments.value)) {
			return "[Struct with " & structCount(arguments.value) & " keys]";
		} else if (isQuery(arguments.value)) {
			return "[Query with " & arguments.value.recordCount & " rows]";
		} else if (isObject(arguments.value)) {
			var metadata = getMetadata(arguments.value);
			return "[Object: " & (metadata.name ?: "unknown") & "]";
		} else {
			return "[" & getMetadata(arguments.value).name & "]";
		}
	}

}
