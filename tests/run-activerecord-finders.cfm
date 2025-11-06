<cfsetting enablecfoutputonly="true">
<cfscript>
	// Create TestBox instance
	testbox = new testbox.system.TestBox(
		bundles = "tests.orm.ActiveRecordFindersTest"
	);

	// Run tests and get results
	results = testbox.run();

	// Output results
	writeOutput(results);
</cfscript>
