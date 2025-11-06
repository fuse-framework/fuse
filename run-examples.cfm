<cfscript>
	// Example test runner - demonstrates test framework with example tests
	// Run: http://localhost:8080/run-examples.cfm

	// Set up mappings
	this.mappings = {
		"/fuse": expandPath("./fuse"),
		"/tests": expandPath("./tests")
	};

	// Initialize components
	discovery = new fuse.testing.TestDiscovery(testPath = expandPath("/tests/examples"));
	runner = new fuse.testing.TestRunner();
	reporter = new fuse.testing.TestReporter();

	// Execute pipeline
	writeOutput("<pre>");
	writeOutput("Fuse Test Framework - Example Tests" & chr(10));
	writeOutput("====================================" & chr(10) & chr(10));

	// Discover tests
	tests = discovery.discover();

	if (arrayLen(tests) == 0) {
		writeOutput("No example tests found." & chr(10));
		writeOutput("</pre>");
		abort;
	}

	writeOutput("Running example tests..." & chr(10));
	writeOutput(chr(10));

	// Run tests with progress
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

			try {
				// Instantiate and run test
				testInstance = createObject("component", testDescriptor.componentName).init();
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
			}
		}
	}

	endTime = getTickCount();
	results.totalTime = (endTime - startTime) / 1000;

	// Report summary
	reporter.reportSummary(results);

	writeOutput("</pre>");
</cfscript>
