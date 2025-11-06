/**
 * TestReporter - Colorized console reporter with Minitest-style output
 *
 * Displays real-time progress dots during test execution and formatted
 * summary with failure/error details. Supports ANSI color codes with
 * graceful fallback for non-ANSI terminals.
 *
 * USAGE EXAMPLES:
 *
 * Basic usage with TestRunner:
 *     discovery = new fuse.testing.TestDiscovery();
 *     tests = discovery.discover();
 *
 *     runner = new fuse.testing.TestRunner();
 *     reporter = new fuse.testing.TestReporter();
 *
 *     // Show progress during execution
 *     for (test in tests) {
 *         result = runner.runTest(test);
 *         reporter.reportProgress(result.status);
 *     }
 *
 *     // Show summary after completion
 *     results = runner.run(tests);
 *     reporter.reportSummary(results);
 *
 * Disable colors for non-ANSI terminals:
 *     reporter = new fuse.testing.TestReporter(useColors = false);
 *
 * Output format (Minitest style):
 *     Running tests...
 *     .....F.....E...
 *
 *     Failures:
 *     1) UserTest::testValidation
 *        Expected: false
 *        Actual: true
 *        at /tests/UserTest.cfc:23
 *
 *     Errors:
 *     1) PostTest::testCreate
 *        Division by zero
 *        at /tests/PostTest.cfc:45
 *        at cfTestRunner2ecfc123456789$funcRUNTESTMETHOD.runTest(/fuse/testing/TestRunner.cfc:141)
 *        ...
 *
 *     15 tests, 13 passed, 1 failure, 1 error
 *     Finished in 2.34 seconds
 *
 * Progress indicators:
 * - Green "." for passing test
 * - Red "F" for assertion failure
 * - Yellow "E" for unexpected error
 */
component {

	variables.useColors = true;
	variables.colorGreen = "";
	variables.colorRed = "";
	variables.colorYellow = "";
	variables.colorReset = "";

	/**
	 * Initialize TestReporter
	 *
	 * Detects ANSI color support and configures color codes.
	 * Colors disabled if terminal doesn't support ANSI codes.
	 *
	 * @useColors Optional boolean to force enable/disable colors (default auto-detect)
	 * @return TestReporter instance for chaining
	 */
	public function init(boolean useColors) {
		// Auto-detect or use explicit setting
		if (structKeyExists(arguments, "useColors")) {
			variables.useColors = arguments.useColors;
		} else {
			variables.useColors = detectColorSupport();
		}

		// Configure ANSI color codes
		if (variables.useColors) {
			variables.colorGreen = chr(27) & "[32m";
			variables.colorRed = chr(27) & "[31m";
			variables.colorYellow = chr(27) & "[33m";
			variables.colorReset = chr(27) & "[0m";
		}

		return this;
	}

	/**
	 * Report real-time progress for single test
	 *
	 * Outputs progress indicator without newline for inline display.
	 * Uses color-coded symbols: green dot (pass), red F (fail), yellow E (error).
	 *
	 * @status Test status: "pass", "fail", or "error"
	 */
	public void function reportProgress(required string status) {
		var symbol = "";

		switch (arguments.status) {
			case "pass":
				symbol = variables.colorGreen & "." & variables.colorReset;
				break;
			case "fail":
				symbol = variables.colorRed & "F" & variables.colorReset;
				break;
			case "error":
				symbol = variables.colorYellow & "E" & variables.colorReset;
				break;
			default:
				symbol = ".";
		}

		writeOutput(symbol);
	}

	/**
	 * Report summary with failure and error details
	 *
	 * Displays Minitest-style summary after all tests complete.
	 * Shows failure details with expected/actual values, error details
	 * with exception messages, and overall statistics.
	 *
	 * @results Results struct from TestRunner.run() with passes, failures, errors, totalTime
	 */
	public void function reportSummary(required struct results) {
		writeOutput(chr(10) & chr(10)); // Two newlines after progress dots

		// Report failures
		if (arrayLen(arguments.results.failures) > 0) {
			reportFailures(arguments.results.failures);
			writeOutput(chr(10));
		}

		// Report errors
		if (arrayLen(arguments.results.errors) > 0) {
			reportErrors(arguments.results.errors);
			writeOutput(chr(10));
		}

		// Report statistics
		reportStatistics(arguments.results);
	}

	// PRIVATE METHODS

	/**
	 * Detect if terminal supports ANSI color codes
	 *
	 * Checks environment variables and terminal type to determine
	 * if ANSI escape sequences are supported.
	 *
	 * @return Boolean indicating color support
	 */
	private boolean function detectColorSupport() {
		// Check if TERM environment variable indicates color support
		try {
			var termVar = createObject("java", "java.lang.System").getenv("TERM");
			if (!isNull(termVar) && len(termVar) > 0) {
				// Common terminal types that support colors
				if (findNoCase("color", termVar) || findNoCase("xterm", termVar) || findNoCase("screen", termVar)) {
					return true;
				}
			}

			// Check if running in CI environment (usually supports colors)
			var ciVar = createObject("java", "java.lang.System").getenv("CI");
			if (!isNull(ciVar) && len(ciVar) > 0) {
				return true;
			}
		} catch (any e) {
			// If detection fails, default to no colors
			return false;
		}

		// Default to no colors if unable to detect
		return false;
	}

	/**
	 * Report failure details with expected/actual values
	 *
	 * Shows each failure with test name, expected vs actual values,
	 * and file location. Applies red color to failure section.
	 *
	 * @failures Array of failure structs from TestRunner
	 */
	private void function reportFailures(required array failures) {
		writeOutput(variables.colorRed & "Failures:" & variables.colorReset & chr(10));

		var index = 1;
		for (var failure in arguments.failures) {
			// Format: 1) TestName::methodName
			writeOutput(index & ") " & failure.testName & chr(10));

			// Show expected/actual if available in detail
			if (len(failure.detail)) {
				writeOutput("   " & failure.detail & chr(10));
			} else if (len(failure.message)) {
				writeOutput("   " & failure.message & chr(10));
			}

			// Extract file path and line number from stack trace
			var location = extractLocation(failure.stackTrace);
			if (len(location)) {
				writeOutput("   at " & location & chr(10));
			}

			writeOutput(chr(10));
			index++;
		}
	}

	/**
	 * Report error details with exception message and stack trace
	 *
	 * Shows each error with test name, exception message, and abbreviated
	 * stack trace (top 5 frames). Applies yellow color to error section.
	 *
	 * @errors Array of error structs from TestRunner
	 */
	private void function reportErrors(required array errors) {
		writeOutput(variables.colorYellow & "Errors:" & variables.colorReset & chr(10));

		var index = 1;
		for (var error in arguments.errors) {
			// Format: 1) TestName::methodName
			writeOutput(index & ") " & error.testName & chr(10));

			// Show exception message
			if (len(error.message)) {
				writeOutput("   " & error.message & chr(10));
			}

			// Show abbreviated stack trace (top 5 frames)
			var stackFrames = extractStackFrames(error.stackTrace, 5);
			for (var frame in stackFrames) {
				// Only prepend "at" if frame doesn't already start with it
				var prefix = left(trim(frame), 2) == "at" ? "   " : "   at ";
				writeOutput(prefix & frame & chr(10));
			}

			writeOutput(chr(10));
			index++;
		}
	}

	/**
	 * Report overall test statistics
	 *
	 * Shows total tests, passes, failures, errors, and execution time
	 * in Minitest format.
	 *
	 * @results Results struct from TestRunner
	 */
	private void function reportStatistics(required struct results) {
		var totalTests = arrayLen(arguments.results.passes) +
						 arrayLen(arguments.results.failures) +
						 arrayLen(arguments.results.errors);
		var passCount = arrayLen(arguments.results.passes);
		var failCount = arrayLen(arguments.results.failures);
		var errorCount = arrayLen(arguments.results.errors);

		// Format: 15 tests, 13 passed, 1 failure, 1 error
		var summary = totalTests & " test" & (totalTests != 1 ? "s" : "") & ", " &
					  passCount & " passed";

		if (failCount > 0) {
			summary &= ", " & failCount & " failure" & (failCount != 1 ? "s" : "");
		}

		if (errorCount > 0) {
			summary &= ", " & errorCount & " error" & (errorCount != 1 ? "s" : "");
		}

		writeOutput(summary & chr(10));

		// Format: Finished in 2.34 seconds
		writeOutput("Finished in " & numberFormat(arguments.results.totalTime, "0.00") & " seconds" & chr(10));
	}

	/**
	 * Extract file location from stack trace
	 *
	 * Parses stack trace to find first relevant file path and line number.
	 * Looks for test file references in stack trace.
	 *
	 * @stackTrace Stack trace string from exception
	 * @return Formatted location string (file:line) or empty string
	 */
	private string function extractLocation(required string stackTrace) {
		if (!len(arguments.stackTrace)) {
			return "";
		}

		// Split stack trace into lines
		var lines = listToArray(arguments.stackTrace, chr(10) & chr(13));

		// Look for test file references
		for (var line in lines) {
			// Match pattern: at /path/to/file.cfc:123
			// or: cfTestFile2ecfc123.method(/path/to/file.cfc:123)
			if (findNoCase(".cfc", line) && findNoCase("test", line)) {
				// Extract file path and line number
				var matches = reMatchNoCase("([\/\\][^\(\)]+\.cfc):(\d+)", line);
				if (arrayLen(matches) > 0) {
					return matches[1];
				}
			}
		}

		// Fallback: return first line if no test file found
		if (arrayLen(lines) > 0) {
			return trim(lines[1]);
		}

		return "";
	}

	/**
	 * Extract top N frames from stack trace
	 *
	 * Returns abbreviated stack trace with specified number of frames.
	 * Useful for showing relevant error context without overwhelming output.
	 *
	 * @stackTrace Stack trace string from exception
	 * @limit Maximum number of frames to return
	 * @return Array of stack frame strings
	 */
	private array function extractStackFrames(required string stackTrace, numeric limit = 5) {
		var frames = [];

		if (!len(arguments.stackTrace)) {
			return frames;
		}

		// Split stack trace into lines
		var lines = listToArray(arguments.stackTrace, chr(10) & chr(13));

		// Take first N non-empty lines
		for (var line in lines) {
			var trimmed = trim(line);
			if (len(trimmed) > 0) {
				arrayAppend(frames, trimmed);

				if (arrayLen(frames) >= arguments.limit) {
					break;
				}
			}
		}

		return frames;
	}

}
