<cfsetting enablecfoutputonly="false">
<cfscript>
	// Simple standalone test for TestReporter
	try {
		// Create reporter with no colors for testing
		reporter = new fuse.testing.TestReporter(useColors = false);

		writeOutput("<h1>TestReporter Manual Tests</h1>");

		// Test 1: Progress output
		writeOutput("<h2>Test 1: Progress Output</h2>");
		writeOutput("<pre>");
		reporter.reportProgress("pass");
		reporter.reportProgress("fail");
		reporter.reportProgress("error");
		reporter.reportProgress("pass");
		writeOutput("</pre>");

		// Test 2: Summary with all result types
		writeOutput("<h2>Test 2: Summary with All Result Types</h2>");
		results = {
			passes: [
				{testName: "UserTest::testCreate", time: 0.01},
				{testName: "UserTest::testValidate", time: 0.02}
			],
			failures: [
				{
					testName: "PostTest::testValidation",
					message: "Assertion failed",
					detail: "Expected: false, Actual: true",
					stackTrace: "at /Users/peter/tests/PostTest.cfc:23"
				}
			],
			errors: [
				{
					testName: "CommentTest::testCreate",
					message: "Division by zero",
					detail: "Cannot divide by zero",
					stackTrace: "at /Users/peter/tests/CommentTest.cfc:45" & chr(10) & "at cfTestRunner2ecfc.runTest()" & chr(10) & "at cfApplication.onRequest()"
				}
			],
			totalTime: 1.23
		};

		writeOutput("<pre>");
		reporter.reportSummary(results);
		writeOutput("</pre>");

		// Test 3: Summary with only passes
		writeOutput("<h2>Test 3: Summary with Only Passes</h2>");
		results2 = {
			passes: [
				{testName: "Test1::testPass", time: 0.01}
			],
			failures: [],
			errors: [],
			totalTime: 0.05
		};

		writeOutput("<pre>");
		reporter.reportSummary(results2);
		writeOutput("</pre>");

		writeOutput("<p><strong>All manual tests completed!</strong></p>");

	} catch (any e) {
		writeOutput("<h2>ERROR</h2>");
		writeOutput("<pre>");
		writeDump(e);
		writeOutput("</pre>");
	}
</cfscript>
