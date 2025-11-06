<cfsetting enablecfoutputonly="true">
<cfscript>
	// Create TestBox instance for module tests
	testbox = new testbox.system.TestBox(
		bundles = ["tests.core.ModuleSystemTest"]
	);

	// Run tests and get results
	results = testbox.run(reporter="json");

	// Output results
	writeOutput(results);
</cfscript>
