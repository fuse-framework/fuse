<cfsetting enablecfoutputonly="true">
<cfscript>
	// Create TestBox instance for TestCase tests
	testbox = new testbox.system.TestBox(
		bundles = ["tests.testing.TestCaseTest"]
	);

	// Run tests and get results
	results = testbox.run(reporter="simple");

	// Output results
	writeOutput(results);
</cfscript>
