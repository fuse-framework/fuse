<cfsetting enablecfoutputonly="true">
<cfscript>
	// Create TestBox instance
	testbox = new testbox.system.TestBox(
		directory = {
			mapping = "tests.core",
			recurse = true
		}
	);

	// Run tests and get results
	results = testbox.run();

	// Output results
	writeOutput(results);
</cfscript>
