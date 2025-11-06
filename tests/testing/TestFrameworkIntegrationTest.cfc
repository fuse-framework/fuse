/**
 * TestFrameworkIntegrationTest - End-to-end integration tests for test framework
 *
 * Tests full pipeline: discovery → run → report
 * Validates cross-component interactions and complete workflows
 */
component extends="fuse.testing.TestCase" {

	variables.testPath = "";
	variables.discovery = "";
	variables.runner = "";
	variables.reporter = "";

	/**
	 * Setup - initialize test framework components
	 */
	public void function setup() {
		// Use fixtures directory for testing
		variables.testPath = expandPath("/tests/testing/fixtures");
		variables.discovery = new fuse.testing.TestDiscovery(testPath = variables.testPath);
		variables.runner = new fuse.testing.TestRunner();
		variables.reporter = new fuse.testing.TestReporter();
	}

	/**
	 * Test full pipeline: discover -> run -> report
	 */
	public void function testFullPipelineExecution() {
		// 1. Discover tests
		var tests = variables.discovery.discover();
		assertNotEmpty(tests, "Should discover test files");

		// 2. Run tests
		var results = variables.runner.run(tests);
		assertNotNull(results, "Should return results");
		assertTrue(structKeyExists(results, "passes"), "Results should have passes");
		assertTrue(structKeyExists(results, "failures"), "Results should have failures");
		assertTrue(structKeyExists(results, "errors"), "Results should have errors");
		assertTrue(structKeyExists(results, "totalTime"), "Results should have totalTime");

		// 3. Report results (verify it doesn't throw)
		try {
			variables.reporter.reportSummary(results);
			assertTrue(true, "Reporter should handle results without error");
		} catch (any e) {
			assertTrue(false, "Reporter threw unexpected exception: " & e.message);
		}
	}

	/**
	 * Test discovery finds all fixture test files
	 */
	public void function testDiscoveryFindsFixtures() {
		var tests = variables.discovery.discover();

		// Should find multiple test files in fixtures
		assertGreaterThan(0, arrayLen(tests), "Should discover fixture tests");

		// Verify structure of discovered tests
		for (var test in tests) {
			assertTrue(structKeyExists(test, "filePath"), "Test should have filePath");
			assertTrue(structKeyExists(test, "componentName"), "Test should have componentName");
			assertTrue(structKeyExists(test, "testMethods"), "Test should have testMethods");
			assertInstanceOf("array", test.testMethods);
		}
	}

	/**
	 * Test runner executes mixed pass/fail/error tests
	 */
	public void function testRunnerHandlesMixedResults() {
		// Create registry with passing, failing, and error tests
		var tests = [
			{
				componentName: "tests.testing.fixtures.PassingTestCase",
				testMethods: ["testPass1", "testPass2"]
			},
			{
				componentName: "tests.testing.fixtures.FailingTestCase",
				testMethods: ["testFailure"]
			},
			{
				componentName: "tests.testing.fixtures.ErrorTestCase",
				testMethods: ["testError"]
			}
		];

		var results = variables.runner.run(tests);

		// Verify mixed results
		assertEqual(2, arrayLen(results.passes), "Should have 2 passes");
		assertEqual(1, arrayLen(results.failures), "Should have 1 failure");
		assertEqual(1, arrayLen(results.errors), "Should have 1 error");
	}

	/**
	 * Test runner continues after failures
	 */
	public void function testContinuesAfterFailure() {
		var tests = [
			{
				componentName: "tests.testing.fixtures.FailingTestCase",
				testMethods: ["testFailure"]
			},
			{
				componentName: "tests.testing.fixtures.PassingTestCase",
				testMethods: ["testPass1"]
			}
		];

		var results = variables.runner.run(tests);

		// Second test should still execute
		assertEqual(1, arrayLen(results.passes), "Should execute test after failure");
		assertEqual(1, arrayLen(results.failures), "Should record failure");
	}

	/**
	 * Test runner continues after errors
	 */
	public void function testContinuesAfterError() {
		var tests = [
			{
				componentName: "tests.testing.fixtures.ErrorTestCase",
				testMethods: ["testError"]
			},
			{
				componentName: "tests.testing.fixtures.PassingTestCase",
				testMethods: ["testPass1"]
			}
		];

		var results = variables.runner.run(tests);

		// Second test should still execute
		assertEqual(1, arrayLen(results.passes), "Should execute test after error");
		assertEqual(1, arrayLen(results.errors), "Should record error");
	}

	/**
	 * Test reporter handles empty results
	 */
	public void function testReporterHandlesEmptyResults() {
		var emptyResults = {
			passes: [],
			failures: [],
			errors: [],
			totalTime: 0
		};

		try {
			variables.reporter.reportSummary(emptyResults);
			assertTrue(true, "Reporter should handle empty results");
		} catch (any e) {
			assertTrue(false, "Reporter should not throw on empty results");
		}
	}

	/**
	 * Test reporter handles results with only passes
	 */
	public void function testReporterHandlesOnlyPasses() {
		var results = {
			passes: [
				{testName: "TestOne::testMethod", time: 0.01},
				{testName: "TestTwo::testMethod", time: 0.02}
			],
			failures: [],
			errors: [],
			totalTime: 0.03
		};

		try {
			variables.reporter.reportSummary(results);
			assertTrue(true, "Reporter should handle only passes");
		} catch (any e) {
			assertTrue(false, "Reporter should not throw on all-pass results");
		}
	}

	/**
	 * Test error propagation through layers
	 */
	public void function testErrorPropagation() {
		var tests = [{
			componentName: "tests.testing.fixtures.ErrorTestCase",
			testMethods: ["testError"]
		}];

		var results = variables.runner.run(tests);

		// Verify error details propagated correctly
		assertEqual(1, arrayLen(results.errors), "Should have error");
		assertTrue(structKeyExists(results.errors[1], "testName"), "Error should have testName");
		assertTrue(structKeyExists(results.errors[1], "message"), "Error should have message");
		assertTrue(structKeyExists(results.errors[1], "stackTrace"), "Error should have stackTrace");
	}

	/**
	 * Test failure propagation through layers
	 */
	public void function testFailurePropagation() {
		var tests = [{
			componentName: "tests.testing.fixtures.FailingTestCase",
			testMethods: ["testFailure"]
		}];

		var results = variables.runner.run(tests);

		// Verify failure details propagated correctly
		assertEqual(1, arrayLen(results.failures), "Should have failure");
		assertTrue(structKeyExists(results.failures[1], "testName"), "Failure should have testName");
		assertTrue(structKeyExists(results.failures[1], "message"), "Failure should have message");
		assertTrue(structKeyExists(results.failures[1], "detail"), "Failure should have detail");
		assertTrue(find("Expected", results.failures[1].detail) > 0, "Detail should contain Expected");
	}

	/**
	 * Test timing is tracked correctly
	 */
	public void function testTimingTracking() {
		var tests = [{
			componentName: "tests.testing.fixtures.PassingTestCase",
			testMethods: ["testPass1", "testPass2"]
		}];

		var results = variables.runner.run(tests);

		// Verify timing tracked
		assertGreaterThan(0, results.totalTime, "Should track total time");

		for (var pass in results.passes) {
			assertGreaterThan(-1, pass.time, "Should track individual test time");
		}
	}

}
