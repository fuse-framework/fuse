<cfsetting enablecfoutputonly="true">
<cfscript>
	try {
		// Create TestBox instance
		testbox = new testbox.system.TestBox(
			bundles = "tests.orm.CallbackManagerTest",
			reporter = "text"
		);

		// Run tests and get results
		results = testbox.run();

		// Output results
		writeOutput(results);
	} catch (any e) {
		writeOutput("Error: " & e.message & chr(10));
		writeOutput("Detail: " & e.detail & chr(10));
		writeOutput("Type: " & e.type & chr(10));
		if (structKeyExists(e, "tagContext")) {
			writeOutput("Stack trace:" & chr(10));
			for (var frame in e.tagContext) {
				writeOutput("  " & frame.template & ":" & frame.line & chr(10));
			}
		}
	}
</cfscript>
