<!---
	Test Runner Entry Point

	Executes full test pipeline: discover → run → report

	USAGE:

	Run all tests:
		http://localhost:8080/fuse/testing/run.cfm

	Run tests from specific path:
		http://localhost:8080/fuse/testing/run.cfm?path=/tests/orm

	Run example tests only:
		http://localhost:8080/fuse/testing/run.cfm?path=/tests/examples

	With custom datasource:
		http://localhost:8080/fuse/testing/run.cfm?datasource=test_db
--->
<cfscript>
	// Get parameters
	param name="url.path" default="/tests";
	param name="url.datasource" default="";

	// Resolve absolute test path
	testPath = expandPath("../../" & url.path);

	// Initialize test framework components
	discovery = new fuse.testing.TestDiscovery(testPath = testPath);
	runner = new fuse.testing.TestRunner(datasource = url.datasource);
	reporter = new fuse.testing.TestReporter();

	// Execute full pipeline
	writeOutput("<pre>");

	// 1. Discover tests
	tests = discovery.discover();

	writeOutput("Running tests from: " & testPath & chr(10));
	writeOutput(chr(10));

	// 2. Run tests with real-time progress reporting
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
				if (len(url.datasource)) {
					transaction action="begin" isolation="read_committed" {
						// Transaction started
					}
					transactionStarted = true;
				}

				// Instantiate and run test
				if (len(url.datasource)) {
					testInstance = createObject("component", testDescriptor.componentName).init(url.datasource);
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

				// Report progress: green dot
				reporter.reportProgress("pass");

			} catch (AssertionFailedException e) {
				// Assertion failure
				arrayAppend(results.failures, {
					testName: testName,
					message: e.message,
					detail: e.detail,
					stackTrace: e.stackTrace
				});

				// Report progress: red F
				reporter.reportProgress("fail");

			} catch (any e) {
				// Unexpected error
				arrayAppend(results.errors, {
					testName: testName,
					message: e.message,
					detail: e.detail ?: "",
					stackTrace: e.stackTrace
				});

				// Report progress: yellow E
				reporter.reportProgress("error");

			} finally {
				// Rollback transaction
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

	writeOutput("</pre>");
</cfscript>
