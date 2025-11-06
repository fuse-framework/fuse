/**
 * TestRunnerTest - Tests for TestRunner component
 *
 * Validates critical TestRunner behaviors:
 * - Sequential execution
 * - Transaction rollback
 * - Exception handling (failures vs errors)
 * - Result collection
 */
component extends="testbox.system.BaseSpec" {

	function run() {
		describe("TestRunner", function() {

			beforeEach(function() {
				runner = new fuse.testing.TestRunner();
			});

			// SEQUENTIAL EXECUTION
			describe("run", function() {

				it("executes tests sequentially", function() {
					// Create test registry with passing tests
					var tests = [{
						filePath: expandPath("/tests/testing/fixtures/PassingTestCase.cfc"),
						componentName: "tests.testing.fixtures.PassingTestCase",
						testMethods: ["testPass1", "testPass2"]
					}];

					var results = runner.run(tests);

					// Should execute all tests
					expect(results).toHaveKey("passes");
					expect(results).toHaveKey("failures");
					expect(results).toHaveKey("errors");
					expect(results).toHaveKey("totalTime");

					// All tests should pass
					expect(arrayLen(results.passes)).toBe(2);
					expect(arrayLen(results.failures)).toBe(0);
					expect(arrayLen(results.errors)).toBe(0);
				});

				it("continues execution after failures", function() {
					// Create test registry with failing and passing tests
					var tests = [
						{
							filePath: expandPath("/tests/testing/fixtures/FailingTestCase.cfc"),
							componentName: "tests.testing.fixtures.FailingTestCase",
							testMethods: ["testFailure"]
						},
						{
							filePath: expandPath("/tests/testing/fixtures/PassingTestCase.cfc"),
							componentName: "tests.testing.fixtures.PassingTestCase",
							testMethods: ["testPass1"]
						}
					];

					var results = runner.run(tests);

					// Should execute all tests despite failure
					expect(arrayLen(results.passes)).toBe(1);
					expect(arrayLen(results.failures)).toBe(1);
					expect(arrayLen(results.errors)).toBe(0);
				});

			});

			// EXCEPTION HANDLING
			describe("exception handling", function() {

				it("distinguishes assertion failures from errors", function() {
					// Create test registry with failure and error
					var tests = [
						{
							componentName: "tests.testing.fixtures.FailingTestCase",
							testMethods: ["testFailure"]
						},
						{
							componentName: "tests.testing.fixtures.ErrorTestCase",
							testMethods: ["testError"]
						}
					];

					var results = runner.run(tests);

					// Should categorize correctly
					expect(arrayLen(results.failures)).toBe(1);
					expect(arrayLen(results.errors)).toBe(1);

					// Verify failure structure
					expect(results.failures[1]).toHaveKey("testName");
					expect(results.failures[1]).toHaveKey("message");
					expect(results.failures[1]).toHaveKey("detail");

					// Verify error structure
					expect(results.errors[1]).toHaveKey("testName");
					expect(results.errors[1]).toHaveKey("message");
				});

				it("records assertion failure details", function() {
					var tests = [{
						componentName: "tests.testing.fixtures.FailingTestCase",
						testMethods: ["testFailure"]
					}];

					var results = runner.run(tests);

					// Should record failure with expected/actual in detail
					expect(results.failures[1].detail).toInclude("Expected");
					expect(results.failures[1].detail).toInclude("Actual");
				});

			});

			// RESULT COLLECTION
			describe("result collection", function() {

				it("collects pass results with test names and timing", function() {
					var tests = [{
						componentName: "tests.testing.fixtures.PassingTestCase",
						testMethods: ["testPass1"]
					}];

					var results = runner.run(tests);

					expect(arrayLen(results.passes)).toBe(1);

					var pass = results.passes[1];
					expect(pass).toHaveKey("testName");
					expect(pass).toHaveKey("time");
					expect(pass.testName).toInclude("::");
					expect(pass.time).toBeGTE(0);
				});

				it("tracks total execution time", function() {
					var tests = [{
						componentName: "tests.testing.fixtures.PassingTestCase",
						testMethods: ["testPass1", "testPass2"]
					}];

					var results = runner.run(tests);

					expect(results.totalTime).toBeGTE(0);
					expect(results.totalTime).toBeNumeric();
				});

				it("includes stack trace for errors", function() {
					var tests = [{
						componentName: "tests.testing.fixtures.ErrorTestCase",
						testMethods: ["testError"]
					}];

					var results = runner.run(tests);

					expect(arrayLen(results.errors)).toBe(1);
					expect(results.errors[1]).toHaveKey("stackTrace");
				});

			});

			// TRANSACTION ROLLBACK
			describe("transaction management", function() {

				it("executes full lifecycle with setup and teardown", function() {
					// This test verifies lifecycle hooks are called
					// Transaction rollback tested with actual database in integration tests
					var tests = [{
						componentName: "tests.testing.fixtures.TransactionTestCase",
						testMethods: ["testTransaction"]
					}];

					var results = runner.run(tests);

					// Test should pass, verifying setup was called
					expect(arrayLen(results.passes)).toBe(1);
					expect(arrayLen(results.failures)).toBe(0);
				});

				it("accepts datasource parameter", function() {
					// Verify runner accepts datasource configuration
					var runnerWithDs = new fuse.testing.TestRunner(datasource = "test_db");

					var tests = [{
						componentName: "tests.testing.fixtures.PassingTestCase",
						testMethods: ["testPass1"]
					}];

					// Should not throw
					expect(function() {
						runnerWithDs.run(tests);
					}).notToThrow();
				});

			});

		});
	}

}
