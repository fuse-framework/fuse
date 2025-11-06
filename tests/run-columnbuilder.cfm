<cfscript>
	// Initialize TestBox
	testbox = new testbox.system.TestBox();

	// Run tests and get results
	results = testbox.run(bundles="tests.orm.ColumnBuilderTest");

	// Output results
	echo(results);
</cfscript>
