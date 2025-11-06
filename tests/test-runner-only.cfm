<cfsetting enablecfoutputonly="true">
<cfscript>
	// Create TestBox instance for TestRunner tests only
	testbox = new testbox.system.TestBox(
		bundles = ["tests.testing.TestRunnerTest"],
		reporter = "simple"
	);

	// Run tests and get results
	results = testbox.run();

	// Output results
	writeOutput(results);
</cfscript>
