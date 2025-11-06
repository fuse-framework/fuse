/**
 * TestCaseTest - Tests for TestCase base class
 *
 * Validates critical TestCase behaviors:
 * - Test method discovery
 * - Setup/teardown execution order
 * - Assertion access in tests
 * - Metadata introspection
 */
component extends="testbox.system.BaseSpec" {

	function run() {
		describe("TestCase", function() {

			beforeEach(function() {
				testCase = new fuse.testing.TestCase();
			});

			// TEST METHOD DISCOVERY
			describe("getTestMethods", function() {

				it("discovers methods starting with test prefix", function() {
					// Create fixture test class
					var fixture = createObject("component", "tests.testing.fixtures.SampleTestCase").init();
					var methods = fixture.getTestMethods();

					expect(methods).toBeArray();
					expect(arrayLen(methods)).toBeGTE(2);
					expect(methods).toContain("testExample");
					expect(methods).toContain("testAnother");
				});

				it("excludes non-test methods", function() {
					var fixture = createObject("component", "tests.testing.fixtures.SampleTestCase").init();
					var methods = fixture.getTestMethods();

					// Should not include setup, teardown, or helper methods
					expect(methods).notToContain("setup");
					expect(methods).notToContain("teardown");
					expect(methods).notToContain("helperMethod");
				});

			});

			// SETUP/TEARDOWN EXECUTION
			describe("setup and teardown hooks", function() {

				it("executes setup before test and teardown after", function() {
					var fixture = createObject("component", "tests.testing.fixtures.LifecycleTestCase").init();

					// Reset execution log
					fixture.resetLog();

					// Manually simulate test runner execution pattern
					fixture.setup();
					fixture.testLifecycleOrder();
					fixture.teardown();

					var log = fixture.getLog();
					expect(arrayLen(log)).toBe(3);
					expect(log[1]).toBe("setup");
					expect(log[2]).toBe("test");
					expect(log[3]).toBe("teardown");
				});

				it("provides default empty implementations", function() {
					// Base TestCase should have empty setup/teardown that don't throw
					expect(function() {
						testCase.setup();
					}).notToThrow();

					expect(function() {
						testCase.teardown();
					}).notToThrow();
				});

			});

			// ASSERTION ACCESS
			describe("assertion mixin", function() {

				it("makes assertions available in test methods", function() {
					// Verify key assertion methods are mixed in
					expect(testCase).toHaveKey("assertEqual");
					expect(testCase).toHaveKey("assertTrue");
					expect(testCase).toHaveKey("assertFalse");
					expect(testCase).toHaveKey("assertNull");
					expect(testCase).toHaveKey("assertThrows");
				});

				it("allows calling assertions directly", function() {
					// Should not throw when calling assertion methods
					expect(function() {
						testCase.assertEqual(5, 5);
					}).notToThrow();

					expect(function() {
						testCase.assertTrue(true);
					}).notToThrow();

					// Should throw AssertionFailedException on failure
					expect(function() {
						testCase.assertEqual(5, 10);
					}).toThrow(type = "AssertionFailedException");
				});

			});

			// METADATA INTROSPECTION
			describe("metadata introspection", function() {

				it("uses getMetadata for method discovery", function() {
					var fixture = createObject("component", "tests.testing.fixtures.SampleTestCase").init();

					// Verify metadata approach works (indirectly via getTestMethods)
					var methods = fixture.getTestMethods();
					expect(methods).toBeArray();

					// All discovered methods should actually exist on component
					for (var methodName in methods) {
						expect(fixture).toHaveKey(methodName);
					}
				});

			});

		});
	}

}
