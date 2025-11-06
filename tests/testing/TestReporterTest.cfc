/**
 * TestReporterTest - Tests for TestReporter colorized console output
 *
 * Validates progress output, summary formatting, and failure/error details.
 * Tests verify output structure without checking exact formatting.
 */
component extends="fuse.testing.TestCase" {

	public function setup() {
		variables.reporter = new fuse.testing.TestReporter(useColors = false);
	}

	public function teardown() {
		structDelete(variables, "reporter");
	}

	/**
	 * Test progress output generates correct symbols
	 */
	public function testReportProgressOutputsCorrectSymbols() {
		// Capture output by buffering
		savecontent variable="local.output" {
			variables.reporter.reportProgress("pass");
			variables.reporter.reportProgress("fail");
			variables.reporter.reportProgress("error");
		}

		// Verify symbols present (without colors since useColors=false)
		assertTrue(find(".", local.output) > 0, "Should output dot for pass");
		assertTrue(find("F", local.output) > 0, "Should output F for fail");
		assertTrue(find("E", local.output) > 0, "Should output E for error");
	}

	/**
	 * Test summary includes all result sections
	 */
	public function testReportSummaryIncludesAllSections() {
		var results = {
			passes: [
				{testName: "Test1::testPass", time: 0.01}
			],
			failures: [
				{
					testName: "Test2::testFail",
					message: "Assertion failed",
					detail: "Expected: true, Actual: false",
					stackTrace: "at /tests/Test2.cfc:10"
				}
			],
			errors: [
				{
					testName: "Test3::testError",
					message: "Division by zero",
					detail: "",
					stackTrace: "at /tests/Test3.cfc:20" & chr(10) & "at cfTestRunner.runTest()"
				}
			],
			totalTime: 1.23
		};

		savecontent variable="local.output" {
			variables.reporter.reportSummary(results);
		}

		// Verify all sections present
		assertTrue(findNoCase("Failures:", local.output) > 0, "Should show Failures section");
		assertTrue(findNoCase("Errors:", local.output) > 0, "Should show Errors section");
		assertTrue(findNoCase("3 tests", local.output) > 0, "Should show total test count");
		assertTrue(findNoCase("1 passed", local.output) > 0, "Should show pass count");
		assertTrue(findNoCase("1 failure", local.output) > 0, "Should show failure count");
		assertTrue(findNoCase("1 error", local.output) > 0, "Should show error count");
		assertTrue(findNoCase("Finished in", local.output) > 0, "Should show execution time");
	}

	/**
	 * Test failure formatting shows expected vs actual
	 */
	public function testFailureFormattingShowsExpectedVsActual() {
		var results = {
			passes: [],
			failures: [
				{
					testName: "UserTest::testValidation",
					message: "Assertion failed",
					detail: "Expected: false, Actual: true",
					stackTrace: "at /tests/UserTest.cfc:23"
				}
			],
			errors: [],
			totalTime: 0.5
		};

		savecontent variable="local.output" {
			variables.reporter.reportSummary(results);
		}

		// Verify failure details
		assertTrue(findNoCase("UserTest::testValidation", local.output) > 0, "Should show test name");
		assertTrue(findNoCase("Expected: false", local.output) > 0, "Should show expected value");
		assertTrue(findNoCase("Actual: true", local.output) > 0, "Should show actual value");
	}

	/**
	 * Test error formatting shows exception message
	 */
	public function testErrorFormattingShowsExceptionMessage() {
		var results = {
			passes: [],
			failures: [],
			errors: [
				{
					testName: "PostTest::testCreate",
					message: "Division by zero",
					detail: "Cannot divide by zero",
					stackTrace: "at /tests/PostTest.cfc:45" & chr(10) & "at cfTestRunner.run()" & chr(10) & "at cfApplication.onRequest()"
				}
			],
			totalTime: 0.3
		};

		savecontent variable="local.output" {
			variables.reporter.reportSummary(results);
		}

		// Verify error details
		assertTrue(findNoCase("PostTest::testCreate", local.output) > 0, "Should show test name");
		assertTrue(findNoCase("Division by zero", local.output) > 0, "Should show error message");
		assertTrue(findNoCase("at /tests/PostTest.cfc", local.output) > 0, "Should show stack trace");
	}

	/**
	 * Test statistics formatting with pluralization
	 */
	public function testStatisticsFormattingWithPluralization() {
		// Test singular forms
		var results1 = {
			passes: [{testName: "Test1::test1", time: 0.01}],
			failures: [],
			errors: [],
			totalTime: 0.05
		};

		savecontent variable="local.output1" {
			variables.reporter.reportSummary(results1);
		}

		assertTrue(findNoCase("1 test,", local.output1) > 0, "Should use singular 'test'");

		// Test plural forms
		var results2 = {
			passes: [
				{testName: "Test1::test1", time: 0.01},
				{testName: "Test2::test2", time: 0.02}
			],
			failures: [
				{testName: "Test3::test3", message: "fail", detail: "", stackTrace: ""}
			],
			errors: [
				{testName: "Test4::test4", message: "error", detail: "", stackTrace: ""}
			],
			totalTime: 0.1
		};

		savecontent variable="local.output2" {
			variables.reporter.reportSummary(results2);
		}

		assertTrue(findNoCase("4 tests", local.output2) > 0, "Should use plural 'tests'");
		assertTrue(findNoCase("1 failure", local.output2) > 0, "Should use singular 'failure'");
		assertTrue(findNoCase("1 error", local.output2) > 0, "Should use singular 'error'");
	}

}
