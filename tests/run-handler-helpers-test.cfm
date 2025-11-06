<cfscript>
// Run handler helper tests only
discovery = new fuse.testing.TestDiscovery();
tests = discovery.discover("tests.testing.HandlerHelpersTest");

runner = new fuse.testing.TestRunner();
results = runner.run(tests);

// Simple text output
writeOutput("Handler Helper Tests" & chr(10));
writeOutput("===================" & chr(10) & chr(10));

writeOutput("Passes: " & arrayLen(results.passes) & chr(10));
if (arrayLen(results.passes) > 0) {
	for (i = 1; i <= arrayLen(results.passes); i++) {
		writeOutput("  PASS: " & results.passes[i].testName & " (" & results.passes[i].time & "s)" & chr(10));
	}
}

writeOutput(chr(10) & "Failures: " & arrayLen(results.failures) & chr(10));
if (arrayLen(results.failures) > 0) {
	for (i = 1; i <= arrayLen(results.failures); i++) {
		writeOutput("  FAIL: " & results.failures[i].testName & chr(10));
		writeOutput("    " & results.failures[i].message & chr(10));
		writeOutput("    " & results.failures[i].detail & chr(10));
	}
}

writeOutput(chr(10) & "Errors: " & arrayLen(results.errors) & chr(10));
if (arrayLen(results.errors) > 0) {
	for (i = 1; i <= arrayLen(results.errors); i++) {
		writeOutput("  ERROR: " & results.errors[i].testName & chr(10));
		writeOutput("    " & results.errors[i].message & chr(10));
		writeOutput("    " & results.errors[i].detail & chr(10));
	}
}

writeOutput(chr(10) & "Total Time: " & results.totalTime & "s" & chr(10));
</cfscript>
