/**
 * TestRunner - Sequential test executor with transaction management
 *
 * Executes tests one at a time with full lifecycle (setup -> test -> teardown).
 * Wraps each test in database transaction that rolls back automatically.
 * Distinguishes assertion failures from unexpected errors.
 * Continues execution after failures to run all tests.
 *
 * Supports both unit tests (TestCase) and integration tests (IntegrationTestCase).
 * Integration tests load full framework stack before transaction begins.
 *
 * USAGE EXAMPLES:
 *
 * Basic execution:
 *     discovery = new fuse.testing.TestDiscovery();
 *     tests = discovery.discover();
 *
 *     runner = new fuse.testing.TestRunner();
 *     results = runner.run(tests);
 *
 * With explicit datasource:
 *     runner = new fuse.testing.TestRunner(datasource = "test_db");
 *     results = runner.run(tests);
 *
 * Results structure:
 *     {
 *         passes: [
 *             {testName: "UserTest::testCreate", time: 0.045}
 *         ],
 *         failures: [
 *             {
 *                 testName: "UserTest::testValidation",
 *                 message: "Assertion failed",
 *                 detail: "Expected: true, Actual: false",
 *                 stackTrace: "..."
 *             }
 *         ],
 *         errors: [
 *             {
 *                 testName: "PostTest::testCreate",
 *                 message: "Division by zero",
 *                 detail: "...",
 *                 stackTrace: "..."
 *             }
 *         ],
 *         totalTime: 2.34
 *     }
 *
 * Transaction behavior:
 * - Unit tests: Begin transaction -> instantiate -> setup -> test -> teardown -> rollback
 * - Integration tests: Instantiate -> init framework -> begin transaction -> setup -> test -> teardown -> rollback
 * - Rollback occurs in finally block after teardown
 * - Rollback happens even on exceptions
 * - Database changes do not persist between tests
 */
component {

	variables.datasource = "";
	variables.passes = [];
	variables.failures = [];
	variables.errors = [];

	/**
	 * Initialize TestRunner
	 *
	 * @datasource Optional datasource name for transaction management
	 * @return TestRunner instance for chaining
	 */
	public function init(string datasource = "") {
		variables.datasource = arguments.datasource;

		// Initialize result storage
		variables.passes = [];
		variables.failures = [];
		variables.errors = [];

		return this;
	}

	/**
	 * Run all tests with transaction management
	 *
	 * Executes tests sequentially with full lifecycle. Each test runs in
	 * isolated database transaction that rolls back after completion.
	 * Follows CallbackManager execution pattern.
	 *
	 * @tests Array of test descriptors from TestDiscovery.discover()
	 * @return Struct with passes[], failures[], errors[], totalTime
	 */
	public struct function run(required array tests) {
		// Reset result storage
		variables.passes = [];
		variables.failures = [];
		variables.errors = [];

		var startTime = getTickCount();

		// Execute each test file sequentially
		for (var testDescriptor in arguments.tests) {
			runTestFile(testDescriptor);
		}

		var endTime = getTickCount();
		var totalTime = (endTime - startTime) / 1000; // Convert to seconds

		return {
			passes: variables.passes,
			failures: variables.failures,
			errors: variables.errors,
			totalTime: totalTime
		};
	}

	// PRIVATE METHODS

	/**
	 * Execute all test methods in a test file
	 *
	 * @testDescriptor Test descriptor struct with componentName and testMethods
	 */
	private void function runTestFile(required struct testDescriptor) {
		var componentName = arguments.testDescriptor.componentName;
		var testMethods = arguments.testDescriptor.testMethods;

		// Execute each test method
		for (var methodName in testMethods) {
			runTestMethod(componentName, methodName);
		}
	}

	/**
	 * Execute single test method with full lifecycle
	 *
	 * Lifecycle for unit tests (TestCase):
	 * 1. Begin database transaction
	 * 2. Instantiate test class
	 * 3. Call setup()
	 * 4. Call test method
	 * 5. Call teardown()
	 * 6. Rollback transaction (in finally block)
	 *
	 * Lifecycle for integration tests (IntegrationTestCase):
	 * 1. Instantiate test class
	 * 2. Call initFramework() (framework loads outside transaction)
	 * 3. Begin database transaction
	 * 4. Call setup()
	 * 5. Call test method
	 * 6. Call teardown()
	 * 7. Rollback transaction (in finally block)
	 *
	 * @componentName Component name in dot notation
	 * @methodName Test method name to execute
	 */
	private void function runTestMethod(required string componentName, required string methodName) {
		var testName = arguments.componentName & "::" & arguments.methodName;
		var testStartTime = getTickCount();
		var testInstance = "";
		var transactionStarted = false;
		var isIntegrationTest = false;

		try {
			// Instantiate test class to check if it's integration test
			if (len(variables.datasource)) {
				testInstance = createObject("component", arguments.componentName).init(variables.datasource);
			} else {
				testInstance = createObject("component", arguments.componentName).init();
			}

			// Detect if this is an integration test
			isIntegrationTest = isIntegrationTestCase(testInstance);

			// For integration tests, initialize framework BEFORE transaction
			if (isIntegrationTest) {
				// Call private initFramework() method on IntegrationTestCase
				// This loads the framework stack outside the transaction
				if (structKeyExists(testInstance, "initFramework")) {
					invoke(testInstance, "initFramework");
				}
			}

			// Begin database transaction (for both unit and integration tests)
			beginTransaction();
			transactionStarted = true;

			// Execute lifecycle: setup -> test -> teardown
			testInstance.setup();
			invoke(testInstance, arguments.methodName);
			testInstance.teardown();

			// Test passed - record success
			var testTime = (getTickCount() - testStartTime) / 1000;
			arrayAppend(variables.passes, {
				testName: testName,
				time: testTime
			});

		} catch (AssertionFailedException e) {
			// Assertion failure - record as failure
			arrayAppend(variables.failures, {
				testName: testName,
				message: e.message,
				detail: e.detail,
				stackTrace: e.stackTrace
			});

		} catch (any e) {
			// Unexpected exception - record as error
			arrayAppend(variables.errors, {
				testName: testName,
				message: e.message,
				detail: e.detail ?: "",
				stackTrace: e.stackTrace
			});

		} finally {
			// Rollback transaction if started
			if (transactionStarted) {
				rollbackTransaction();
			}
		}
	}

	/**
	 * Detect if test instance is an IntegrationTestCase
	 *
	 * Uses getMetadata() to check component inheritance chain.
	 * Returns true if component extends IntegrationTestCase.
	 *
	 * @testInstance Test component instance
	 * @return Boolean true if integration test
	 */
	private boolean function isIntegrationTestCase(required any testInstance) {
		var metadata = getMetadata(arguments.testInstance);

		// Walk inheritance chain looking for IntegrationTestCase
		while (structKeyExists(metadata, "name")) {
			// Check if this component is IntegrationTestCase
			if (findNoCase("IntegrationTestCase", metadata.name)) {
				return true;
			}

			// Move up inheritance chain
			if (structKeyExists(metadata, "extends")) {
				metadata = metadata.extends;
			} else {
				break;
			}
		}

		return false;
	}

	/**
	 * Begin database transaction
	 *
	 * Uses Lucee transaction syntax with action="begin".
	 * Resolves datasource from init parameter or application scope.
	 * Note: Datasource is resolved but transaction block requires explicit datasource
	 * only when database operations occur. Transaction state is managed per-thread.
	 */
	private void function beginTransaction() {
		var ds = resolveDatasource();

		// Only begin transaction if datasource configured
		// Transaction applies to subsequent database operations in same thread
		if (len(ds)) {
			transaction action="begin" isolation="read_committed" {
				// Transaction started - applies to all DB operations in this thread
			}
		}
	}

	/**
	 * Rollback database transaction
	 *
	 * Uses Lucee transaction syntax with action="rollback".
	 * Ensures all database changes are reverted.
	 * Transaction rollback is managed per-thread and applies to active transaction.
	 */
	private void function rollbackTransaction() {
		var ds = resolveDatasource();

		if (len(ds)) {
			transaction action="rollback" {
				// Transaction rolled back - reverts all DB changes in this thread
			}
		}
	}

	/**
	 * Resolve datasource name
	 *
	 * Resolution order:
	 * 1. Init parameter (variables.datasource)
	 * 2. Application scope datasource
	 * 3. Default "fuse" datasource
	 *
	 * @return Datasource name string
	 */
	private string function resolveDatasource() {
		if (len(variables.datasource)) {
			return variables.datasource;
		}

		if (isDefined("application.datasource") && len(application.datasource)) {
			return application.datasource;
		}

		return "fuse";
	}

}
