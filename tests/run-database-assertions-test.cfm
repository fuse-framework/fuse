<!---
	Database Assertions Test Runner

	Runs ONLY the database assertion tests for Task Group 2

	USAGE:
		Run with default datasource:
			lucee run-database-assertions-test.cfm

		Run with specific datasource:
			lucee run-database-assertions-test.cfm datasource=test_db
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

	// Filter to only DatabaseAssertionsTest
	filteredTests = [];
	for (test in tests) {
		if (findNoCase("DatabaseAssertionsTest", test.componentName)) {
			arrayAppend(filteredTests, test);
		}
	}

	writeOutput("<pre>");
	writeOutput("Running Database Assertions Tests" & chr(10));
	writeOutput("Datasource: " & url.datasource & chr(10));
	writeOutput(chr(10));

	// Run tests
	results = runner.run(filteredTests);

	// Report results
	reporter.reportSummary(results);

	writeOutput("</pre>");
</cfscript>
