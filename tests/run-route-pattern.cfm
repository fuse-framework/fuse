<cfsetting enablecfoutputonly="true">
<cfscript>
	// Create TestBox instance for specific bundle
	testbox = new testbox.system.TestBox(
		bundles = "tests.core.RoutePatternTest"
	);

	// Run tests and get results
	results = testbox.run();

	// Output results
	writeOutput(results);
</cfscript>
