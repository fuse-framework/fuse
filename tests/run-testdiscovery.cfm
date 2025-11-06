<cfsetting showdebugoutput="false">
<cfscript>
	// Create TestBox instance for TestDiscovery tests
	testbox = new testbox.system.TestBox(
		bundles = ["tests.testing.TestDiscoveryTest"],
		reporter = "json"
	);

	// Run tests and get results
	results = testbox.run();

	// Parse JSON and output summary
	data = deserializeJSON(results);

	writeOutput("TestDiscovery Tests" & chr(10));
	writeOutput("==================" & chr(10));
	writeOutput("Total Specs: " & data.totalSpecs & chr(10));
	writeOutput("Total Pass: " & data.totalPass & chr(10));
	writeOutput("Total Fail: " & data.totalFail & chr(10));
	writeOutput("Total Error: " & data.totalError & chr(10));
	writeOutput(chr(10));

	// Show errors if any
	if (data.totalError > 0 || data.totalFail > 0) {
		for (var bundle in data.bundleStats) {
			for (var suite in bundle.suiteStats) {
				for (var spec in suite.specStats) {
					if (spec.status == "Error" || spec.status == "Failed") {
						writeOutput("FAIL/ERROR: " & spec.name & chr(10));
						writeOutput("  Status: " & spec.status & chr(10));
						if (structKeyExists(spec, "failMessage") && len(spec.failMessage)) {
							writeOutput("  Message: " & spec.failMessage & chr(10));
						}
						if (structKeyExists(spec, "error") && structKeyExists(spec.error, "message")) {
							writeOutput("  Error: " & spec.error.message & chr(10));
						}
						if (structKeyExists(spec, "error") && structKeyExists(spec.error, "detail")) {
							writeOutput("  Detail: " & left(spec.error.detail, 500) & chr(10));
						}
						writeOutput(chr(10));
					}
				}
			}
		}
	}
</cfscript>
