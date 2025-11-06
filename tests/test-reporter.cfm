<cfsetting enablecfoutputonly="true">
<cfscript>
	// Create TestBox instance for TestReporter tests only
	testbox = new testbox.system.TestBox(
		bundles = ["tests.testing.TestReporterTest"],
		reporter = "simple"
	);

	// Run tests and get results
	results = testbox.run();

	// Output results
	writeOutput(results);
</cfscript>
