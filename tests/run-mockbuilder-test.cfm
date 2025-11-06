<!---
	MockBuilder Test Runner

	Runs ONLY the MockBuilder tests for Task Group 4

	USAGE:
		Run with default datasource:
			lucee run-mockbuilder-test.cfm

		Run with specific datasource:
			lucee run-mockbuilder-test.cfm datasource=test_db
--->
<cfscript>
	// Get datasource from command line or use default
	param name="url.datasource" default="fuse";

	// Initialize test framework
	discovery = new fuse.testing.TestDiscovery(testPath = expandPath("./testing"));
	runner = new fuse.testing.TestRunner(datasource = url.datasource);
	reporter = new fuse.testing.TestReporter();

	// Discover tests (only in testing directory)
	tests = discovery.discover();

	// Debug: show what was discovered
	writeOutput("<pre>");
	writeOutput("Discovered " & arrayLen(tests) & " test classes" & chr(10));
	for (test in tests) {
		writeOutput("  - " & test.componentName & " (" & arrayLen(test.testMethods) & " methods)" & chr(10));
	}
	writeOutput(chr(10));

	// Filter to only MockBuilderTest
	filteredTests = [];
	for (test in tests) {
		if (findNoCase("MockBuilderTest", test.componentName)) {
			arrayAppend(filteredTests, test);
		}
	}

	writeOutput("Running MockBuilder Tests (" & arrayLen(filteredTests) & " classes)" & chr(10));
	writeOutput("Datasource: " & url.datasource & chr(10));
	writeOutput(chr(10));

	// Run tests
	results = runner.run(filteredTests);

	// Report results
	reporter.reportSummary(results);

	writeOutput("</pre>");
</cfscript>
