<cfsetting showdebugoutput="false">
<cfscript>
	// Direct test of TestDiscovery
	writeOutput("Testing TestDiscovery manually" & chr(10));
	writeOutput("================================" & chr(10) & chr(10));

	try {
		// Create discovery instance
		discovery = new fuse.testing.TestDiscovery("/tests/testing/fixtures/discovery");
		writeOutput("Created TestDiscovery instance" & chr(10));

		// Run discover
		tests = discovery.discover();
		writeOutput("Discovered " & arrayLen(tests) & " test(s)" & chr(10) & chr(10));

		// Output test details
		for (test in tests) {
			writeOutput("Test: " & test.componentName & chr(10));
			writeOutput("  File: " & test.filePath & chr(10));
			writeOutput("  Methods: " & arrayLen(test.testMethods) & chr(10));
			for (method in test.testMethods) {
				writeOutput("    - " & method & chr(10));
			}
			writeOutput(chr(10));
		}

	} catch (any e) {
		writeOutput("ERROR: " & e.message & chr(10));
		writeOutput("Detail: " & e.detail & chr(10));
		writeOutput("Type: " & e.type & chr(10));
	}
</cfscript>
