/**
 * Test Command - Run test suite
 *
 * Discovers and executes tests with filtering and output options.
 */
component {

	/**
	 * Main command entry point
	 *
	 * @param args Arguments struct with flags
	 * @return Struct with success, message, test results, and exit code
	 */
	public struct function main(required struct args) {
		var silent = structKeyExists(arguments.args, "silent") ? arguments.args.silent : false;
		var verbose = structKeyExists(arguments.args, "verbose") ? arguments.args.verbose : false;

		// Resolve datasource
		var dbConnection = new fuse.cli.support.DatabaseConnection();
		var datasource = dbConnection.resolve(arguments.args);

		// Determine test path based on type flag
		var testPath = determineTestPath(arguments.args);

		// Discover tests
		var discovery = new fuse.testing.TestDiscovery(testPath);
		var tests = discovery.discover();

		// Apply filter if provided
		if (structKeyExists(arguments.args, "filter") && len(arguments.args.filter)) {
			tests = filterTests(tests, arguments.args.filter);
		}

		// Count total test methods
		var totalTestMethods = countTestMethods(tests);

		if (!silent) {
			writeOutput("Running tests..." & chr(10) & chr(10));
		}

		// Run tests
		var runner = new fuse.testing.TestRunner(datasource);
		var results = runner.run(tests);

		// Display results
		if (!silent) {
			if (verbose) {
				displayVerboseResults(results);
			} else {
				displayDefaultResults(results);
			}

			displaySummary(results);
			displayFailuresAndErrors(results);
		}

		// Determine exit code
		var exitCode = (arrayLen(results.failures) + arrayLen(results.errors)) > 0 ? 1 : 0;

		return {
			success: exitCode == 0,
			message: exitCode == 0 ? "All tests passed" : "Some tests failed",
			totalTests: totalTestMethods,
			passes: arrayLen(results.passes),
			failures: arrayLen(results.failures),
			errors: arrayLen(results.errors),
			exitCode: exitCode
		};
	}

	/**
	 * Determine test path based on type flag
	 *
	 * @param args Arguments struct
	 * @return Test path string
	 */
	private string function determineTestPath(required struct args) {
		if (structKeyExists(arguments.args, "type") && len(arguments.args.type)) {
			var type = arguments.args.type;

			if (type == "unit") {
				return "/tests/unit";
			} else if (type == "integration") {
				return "/tests/integration";
			}
		}

		return "/tests";
	}

	/**
	 * Filter tests by component name pattern
	 *
	 * @param tests Array of test descriptors
	 * @param pattern Filter pattern (case-insensitive)
	 * @return Filtered array of test descriptors
	 */
	private array function filterTests(required array tests, required string pattern) {
		var filtered = [];

		for (var test in arguments.tests) {
			// Case-insensitive contains match on component name
			if (findNoCase(arguments.pattern, test.componentName)) {
				arrayAppend(filtered, test);
			}
		}

		return filtered;
	}

	/**
	 * Count total test methods across all test files
	 *
	 * @param tests Array of test descriptors
	 * @return Total count of test methods
	 */
	private numeric function countTestMethods(required array tests) {
		var count = 0;

		for (var test in arguments.tests) {
			count += arrayLen(test.testMethods);
		}

		return count;
	}

	/**
	 * Display verbose results (test-by-test output)
	 *
	 * @param results Results struct from TestRunner
	 */
	private void function displayVerboseResults(required struct results) {
		// Display passes
		for (var pass in arguments.results.passes) {
			var time = numberFormat(pass.time, "0.000");
			writeOutput("  " & pass.testName & " ... PASS (" & time & "s)" & chr(10));
		}

		// Display failures
		for (var failure in arguments.results.failures) {
			writeOutput("  " & failure.testName & " ... FAIL" & chr(10));
		}

		// Display errors
		for (var error in arguments.results.errors) {
			writeOutput("  " & error.testName & " ... ERROR" & chr(10));
		}

		writeOutput(chr(10));
	}

	/**
	 * Display default results (dots output)
	 *
	 * @param results Results struct from TestRunner
	 */
	private void function displayDefaultResults(required struct results) {
		// Combine all results in order
		var allResults = [];

		// Add passes
		for (var pass in arguments.results.passes) {
			arrayAppend(allResults, {type: "pass", data: pass});
		}

		// Add failures
		for (var failure in arguments.results.failures) {
			arrayAppend(allResults, {type: "failure", data: failure});
		}

		// Add errors
		for (var error in arguments.results.errors) {
			arrayAppend(allResults, {type: "error", data: error});
		}

		// Display dots/F/E
		for (var result in allResults) {
			if (result.type == "pass") {
				writeOutput(".");
			} else if (result.type == "failure") {
				writeOutput("F");
			} else if (result.type == "error") {
				writeOutput("E");
			}
		}

		writeOutput(chr(10) & chr(10));
	}

	/**
	 * Display summary line
	 *
	 * @param results Results struct from TestRunner
	 */
	private void function displaySummary(required struct results) {
		var total = arrayLen(arguments.results.passes) + arrayLen(arguments.results.failures) + arrayLen(arguments.results.errors);
		var passes = arrayLen(arguments.results.passes);
		var failures = arrayLen(arguments.results.failures);
		var errors = arrayLen(arguments.results.errors);
		var time = numberFormat(arguments.results.totalTime, "0.00");

		var summary = total & " test" & (total == 1 ? "" : "s") & ", ";
		summary &= passes & " passed, ";
		summary &= failures & " failure" & (failures == 1 ? "" : "s") & ", ";
		summary &= errors & " error" & (errors == 1 ? "" : "s");
		summary &= " (" & time & "s)";

		writeOutput(summary & chr(10) & chr(10));
	}

	/**
	 * Display failure and error details
	 *
	 * @param results Results struct from TestRunner
	 */
	private void function displayFailuresAndErrors(required struct results) {
		// Display failures
		if (arrayLen(arguments.results.failures) > 0) {
			writeOutput("FAILURES:" & chr(10) & chr(10));

			for (var failure in arguments.results.failures) {
				writeOutput("  " & failure.testName & chr(10));
				writeOutput("    " & failure.detail & chr(10));
				writeOutput(chr(10));
			}
		}

		// Display errors
		if (arrayLen(arguments.results.errors) > 0) {
			writeOutput("ERRORS:" & chr(10) & chr(10));

			for (var error in arguments.results.errors) {
				writeOutput("  " & error.testName & chr(10));
				writeOutput("    " & error.message & chr(10));

				// Try to extract file location from stack trace
				if (structKeyExists(error, "stackTrace") && len(error.stackTrace)) {
					var location = extractLocation(error.stackTrace);
					if (len(location)) {
						writeOutput("    " & location & chr(10));
					}
				}

				writeOutput(chr(10));
			}
		}
	}

	/**
	 * Extract file location from stack trace
	 *
	 * @param stackTrace Stack trace string
	 * @return Location string or empty
	 */
	private string function extractLocation(required string stackTrace) {
		// Try to find first line with file path and line number
		var lines = listToArray(arguments.stackTrace, chr(10));

		for (var line in lines) {
			// Look for pattern like: /path/to/file.cfc:123
			if (find(".cfc:", line) > 0) {
				return trim(line);
			}
		}

		return "";
	}

}
