<cfsetting enablecfoutputonly="true">
<cfscript>
	// Create TestBox instance for TestDiscovery tests
	testbox = new testbox.system.TestBox(
		bundles = ["tests.testing.TestDiscoveryTest"]
	);

	// Run tests and get results
	results = testbox.run(reporter="simple");

	// Output results
	writeOutput(results);
</cfscript>
