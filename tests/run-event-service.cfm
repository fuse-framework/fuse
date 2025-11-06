<cfsetting enablecfoutputonly="true">
<cfscript>
	// Create TestBox instance for specific bundle
	testbox = new testbox.system.TestBox(
		bundles = "tests.core.EventServiceTest"
	);

	// Run tests and get results
	results = testbox.run();

	// Output results
	writeOutput(results);
</cfscript>
