/**
 * TestCase - Base class for xUnit-style test cases
 *
 * Provides lifecycle hooks (setup/teardown), test method discovery, and
 * assertion mixin for writing isolated, convention-based tests.
 *
 * USAGE EXAMPLES:
 *
 * Basic test case:
 *     component extends="fuse.testing.TestCase" {
 *         public function testUserCreation() {
 *             var user = new User(this.datasource);
 *             user.name = "John Doe";
 *             assertEqual("John Doe", user.name);
 *         }
 *     }
 *
 * With setup and teardown:
 *     component extends="fuse.testing.TestCase" {
 *         public function setup() {
 *             // Called before each test method
 *             variables.user = new User(this.datasource);
 *             variables.user.email = "test@example.com";
 *         }
 *
 *         public function teardown() {
 *             // Called after each test method
 *             structDelete(variables, "user");
 *         }
 *
 *         public function testEmailValidation() {
 *             assertTrue(variables.user.isValid());
 *         }
 *
 *         public function testSave() {
 *             assertTrue(variables.user.save());
 *         }
 *     }
 *
 * Using assertions (mixed in from Assertions.cfc):
 *     assertEqual(expected, actual);
 *     assertNotEqual(expected, actual);
 *     assertTrue(value);
 *     assertFalse(value);
 *     assertNull(value);
 *     assertNotNull(value);
 *     assertThrows(function() { user.save(); });
 *     assertCount(3, users);
 *     assertContains("admin", roles);
 *     assertNotContains("banned", roles);
 *     assertMatches("^\w+@", email);
 *     assertEmpty(array);
 *     assertNotEmpty(struct);
 *     assertInstanceOf("User", user);
 *     assertGreaterThan(0, total);
 *     assertLessThan(100, discount);
 *
 * Conventions:
 * - Test files end with Test.cfc (UserTest.cfc, PostTest.cfc)
 * - Test methods start with "test" prefix (testUserCreation, testValidation)
 * - setup() runs before each test method
 * - teardown() runs after each test method
 * - Each test runs in a database transaction that rolls back automatically
 */
component {

	/**
	 * Initialize TestCase
	 *
	 * @datasource Optional datasource name for database tests
	 * @return TestCase instance for chaining
	 */
	public function init(string datasource = "") {
		// Store datasource for test methods to access
		if (len(arguments.datasource)) {
			variables.datasource = arguments.datasource;
			this.datasource = arguments.datasource;
		}

		// Mix in assertion methods from Assertions.cfc
		mixinAssertions();

		return this;
	}

	/**
	 * Setup lifecycle hook - override in subclasses
	 *
	 * Called before each test method. Use to prepare test state, create test data,
	 * or initialize variables needed by multiple tests.
	 */
	public void function setup() {
		// Empty default implementation - subclasses override
	}

	/**
	 * Teardown lifecycle hook - override in subclasses
	 *
	 * Called after each test method. Use to clean up test state, delete test data,
	 * or reset variables. Database changes are rolled back automatically.
	 */
	public void function teardown() {
		// Empty default implementation - subclasses override
	}

	/**
	 * Discover test methods using metadata introspection
	 *
	 * Finds all public methods starting with "test" prefix.
	 * Follows ActiveRecord.cfc pattern for metadata inspection.
	 *
	 * @return Array of test method name strings
	 */
	public array function getTestMethods() {
		var testMethods = [];
		var metadata = getMetadata(this);

		// Get functions from current component
		if (structKeyExists(metadata, "functions")) {
			for (var func in metadata.functions) {
				// Find public methods starting with "test"
				if (structKeyExists(func, "name") &&
					left(func.name, 4) == "test" &&
					(!structKeyExists(func, "access") || func.access == "public")) {
					arrayAppend(testMethods, func.name);
				}
			}
		}

		return testMethods;
	}

	// PRIVATE METHODS

	/**
	 * Mix in assertion methods from Assertions component
	 *
	 * Stores assertion instance and delegates assertion calls to it.
	 * Uses delegation pattern to preserve Assertions component's private method access.
	 */
	private void function mixinAssertions() {
		// Store assertions instance for delegation
		variables._assertions = new fuse.testing.Assertions();

		// Create delegation methods for each assertion
		variables.assertEqual = function(required any expected, required any actual, string message = "") {
			variables._assertions.assertEqual(argumentCollection=arguments);
		};
		variables.assertNotEqual = function(required any expected, required any actual, string message = "") {
			variables._assertions.assertNotEqual(argumentCollection=arguments);
		};
		variables.assertTrue = function(required any value, string message = "") {
			variables._assertions.assertTrue(argumentCollection=arguments);
		};
		variables.assertFalse = function(required any value, string message = "") {
			variables._assertions.assertFalse(argumentCollection=arguments);
		};
		variables.assertNull = function(required any value, string message = "") {
			variables._assertions.assertNull(argumentCollection=arguments);
		};
		variables.assertNotNull = function(required any value, string message = "") {
			variables._assertions.assertNotNull(argumentCollection=arguments);
		};
		variables.assertThrows = function(required any callable, string exceptionType = "", string message = "") {
			variables._assertions.assertThrows(argumentCollection=arguments);
		};
		variables.assertCount = function(required numeric expected, required any collection, string message = "") {
			variables._assertions.assertCount(argumentCollection=arguments);
		};
		variables.assertContains = function(required any needle, required any haystack, string message = "") {
			variables._assertions.assertContains(argumentCollection=arguments);
		};
		variables.assertNotContains = function(required any needle, required any haystack, string message = "") {
			variables._assertions.assertNotContains(argumentCollection=arguments);
		};
		variables.assertMatches = function(required string pattern, required string string, string message = "") {
			variables._assertions.assertMatches(argumentCollection=arguments);
		};
		variables.assertEmpty = function(required any value, string message = "") {
			variables._assertions.assertEmpty(argumentCollection=arguments);
		};
		variables.assertNotEmpty = function(required any value, string message = "") {
			variables._assertions.assertNotEmpty(argumentCollection=arguments);
		};
		variables.assertInstanceOf = function(required string expected, required any actual, string message = "") {
			variables._assertions.assertInstanceOf(argumentCollection=arguments);
		};
		variables.assertGreaterThan = function(required numeric expected, required numeric actual, string message = "") {
			variables._assertions.assertGreaterThan(argumentCollection=arguments);
		};
		variables.assertLessThan = function(required numeric expected, required numeric actual, string message = "") {
			variables._assertions.assertLessThan(argumentCollection=arguments);
		};

		// Expose to this scope as well
		this.assertEqual = variables.assertEqual;
		this.assertNotEqual = variables.assertNotEqual;
		this.assertTrue = variables.assertTrue;
		this.assertFalse = variables.assertFalse;
		this.assertNull = variables.assertNull;
		this.assertNotNull = variables.assertNotNull;
		this.assertThrows = variables.assertThrows;
		this.assertCount = variables.assertCount;
		this.assertContains = variables.assertContains;
		this.assertNotContains = variables.assertNotContains;
		this.assertMatches = variables.assertMatches;
		this.assertEmpty = variables.assertEmpty;
		this.assertNotEmpty = variables.assertNotEmpty;
		this.assertInstanceOf = variables.assertInstanceOf;
		this.assertGreaterThan = variables.assertGreaterThan;
		this.assertLessThan = variables.assertLessThan;
	}

}
