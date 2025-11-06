<!---
	Database Commands Test Runner

	Runs ONLY the database command tests for Task Group 2:
	- MigrateCommandTest
	- RollbackCommandTest
	- SeedCommandTest

	USAGE:
		Run with default datasource:
			lucee run-database-commands-tests.cfm

		Run with specific datasource:
			lucee run-database-commands-tests.cfm datasource=test_db
--->
<cfscript>
	// Get datasource from command line or use default
	param name="url.datasource" default="fuse";

	// Initialize test framework
	discovery = new fuse.testing.TestDiscovery(testPath = expandPath("./cli/commands"));
	runner = new fuse.testing.TestRunner(datasource = url.datasource);
	reporter = new fuse.testing.TestReporter();

	// Discover tests (only in cli/commands directory)
	tests = discovery.discover();

	// Filter to only database command tests
	filteredTests = [];
	for (test in tests) {
		if (findNoCase("MigrateCommandTest", test.componentName) ||
		    findNoCase("RollbackCommandTest", test.componentName) ||
		    findNoCase("SeedCommandTest", test.componentName)) {
			arrayAppend(filteredTests, test);
		}
	}

	writeOutput("<pre>");
	writeOutput("Running Database Command Tests (Task Group 2)" & chr(10));
	writeOutput("Datasource: " & url.datasource & chr(10));
	writeOutput(chr(10));

	// Run tests
	results = runner.run(filteredTests);

	// Report results
	reporter.reportSummary(results);

	// List test names for verification
	writeOutput(chr(10) & "Tests run:" & chr(10));
	for (test in filteredTests) {
		writeOutput("  - " & test.componentName & " (" & arrayLen(test.testMethods) & " test methods)" & chr(10));
	}

	writeOutput("</pre>");
</cfscript>
