<cfsetting enablecfoutputonly="true">
<cfscript>
	// Create TestBox instance for handler conventions test only
	testbox = new testbox.system.TestBox(
		bundles = ["tests.core.HandlerConventionsTest"],
		reporter = "json"
	);

	// Run tests and get results
	results = testbox.run();

	// Output results
	writeOutput(results);
</cfscript>
