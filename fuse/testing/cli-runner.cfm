#!/usr/bin/env lucee
<!---
	CLI Test Runner

	Command-line test execution script for Fuse test framework.
	Executes full test pipeline with colorized console output.

	USAGE:

	Run all tests:
		lucee fuse/testing/cli-runner.cfm

	Run tests from specific path:
		lucee fuse/testing/cli-runner.cfm path=/tests/orm

	Run example tests only:
		lucee fuse/testing/cli-runner.cfm path=/tests/examples

	With custom datasource:
		lucee fuse/testing/cli-runner.cfm datasource=test_db

	Multiple parameters:
		lucee fuse/testing/cli-runner.cfm path=/tests/examples datasource=test_db
--->
<cfscript>
	// Parse command-line arguments
	args = {
		path: "/tests",
		datasource: ""
	};

	// Parse arguments from URL scope (Lucee CLI puts them there)
	if (isDefined("url.path")) {
		args.path = url.path;
	}
	if (isDefined("url.datasource")) {
		args.datasource = url.datasource;
	}

	// Resolve absolute test path
	testPath = expandPath("../../" & args.path);

	// Initialize test framework components
	discovery = new fuse.testing.TestDiscovery(testPath = testPath);
	runner = new fuse.testing.TestRunner(datasource = args.datasource);
	reporter = new fuse.testing.TestReporter();

	// Execute full pipeline
	writeOutput("Running tests from: " & testPath & chr(10));
	writeOutput(chr(10));

	// 1. Discover tests
	tests = discovery.discover();

	if (arrayLen(tests) == 0) {
		writeOutput("No tests found." & chr(10));
		abort;
	}

	// 2. Run tests with progress reporting
	results = {
		passes: [],
		failures: [],
		errors: [],
		totalTime: 0
	};

	startTime = getTickCount();

	for (testDescriptor in tests) {
		for (methodName in testDescriptor.testMethods) {
			var testName = testDescriptor.componentName & "::" & methodName;
			var testStartTime = getTickCount();
			var testInstance = "";
			var transactionStarted = false;

			try {
				// Begin transaction
				if (len(args.datasource)) {
					transaction action="begin" isolation="read_committed" {
						// Transaction started
					}
					transactionStarted = true;
				}

				// Instantiate and run test
				if (len(args.datasource)) {
					testInstance = createObject("component", testDescriptor.componentName).init(args.datasource);
				} else {
					testInstance = createObject("component", testDescriptor.componentName).init();
				}

				testInstance.setup();
				invoke(testInstance, methodName);
				testInstance.teardown();

				// Test passed
				var testTime = (getTickCount() - testStartTime) / 1000;
				arrayAppend(results.passes, {
					testName: testName,
					time: testTime
				});

				reporter.reportProgress("pass");

			} catch (AssertionFailedException e) {
				arrayAppend(results.failures, {
					testName: testName,
					message: e.message,
					detail: e.detail,
					stackTrace: e.stackTrace
				});

				reporter.reportProgress("fail");

			} catch (any e) {
				arrayAppend(results.errors, {
					testName: testName,
					message: e.message,
					detail: e.detail ?: "",
					stackTrace: e.stackTrace
				});

				reporter.reportProgress("error");

			} finally {
				if (transactionStarted) {
					transaction action="rollback" {
						// Transaction rolled back
					}
				}
			}
		}
	}

	endTime = getTickCount();
	results.totalTime = (endTime - startTime) / 1000;

	// 3. Report summary
	reporter.reportSummary(results);

	// Exit with appropriate code
	exitCode = (arrayLen(results.failures) + arrayLen(results.errors)) > 0 ? 1 : 0;
	// Note: Lucee CLI exit code handling may vary by version
</cfscript>
