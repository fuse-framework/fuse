<cfsetting enablecfoutputonly="true">
<cfscript>
	// Create TestBox instance for specific test
	testbox = new testbox.system.TestBox(
		bundles = "tests.core.BootstrapCacheViewIntegrationTest"
	);

	// Run tests and get results
	results = testbox.run();

	// Output results
	writeOutput(results);
</cfscript>
