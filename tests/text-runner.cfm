<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<cfscript>
	// Create TestBox instance
	testbox = new testbox.system.TestBox(
		directory = {
			mapping = "tests.core",
			recurse = true
		},
		reporter = "text"
	);

	// Run tests and get results
	results = testbox.run();

	// Output results
	writeOutput(results);
</cfscript>
