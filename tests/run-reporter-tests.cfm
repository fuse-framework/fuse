<cfsetting enablecfoutputonly="false">
<cfscript>
	// Simple test runner for TestReporter using our own framework
	try {
		writeOutput("<h1>Running TestReporter Tests</h1>");

		// Create test instance
		test = new tests.testing.TestReporterTest();

		// Get test methods
		testMethods = test.getTestMethods();

		writeOutput("<p>Found " & arrayLen(testMethods) & " tests</p>");

		// Run each test
		passed = 0;
		failed = 0;

		for (methodName in testMethods) {
			writeOutput("<h3>" & methodName & "</h3>");
			writeOutput("<pre>");

			try {
				// Setup
				test.setup();

				// Run test
				invoke(test, methodName);

				// Teardown
				test.teardown();

				writeOutput("PASS");
				passed++;
			} catch (any e) {
				writeOutput("FAIL: " & e.message);
				if (len(e.detail)) {
					writeOutput(chr(10) & "Detail: " & e.detail);
				}
				failed++;
			}

			writeOutput("</pre>");
		}

		// Summary
		writeOutput("<hr>");
		writeOutput("<h2>Summary</h2>");
		writeOutput("<p><strong>" & (passed + failed) & " tests, " & passed & " passed, " & failed & " failed</strong></p>");

		if (failed == 0) {
			writeOutput("<p style='color: green; font-weight: bold;'>All tests passed!</p>");
		}

	} catch (any e) {
		writeOutput("<h2>ERROR</h2>");
		writeOutput("<pre>");
		writeDump(e);
		writeOutput("</pre>");
	}
</cfscript>
