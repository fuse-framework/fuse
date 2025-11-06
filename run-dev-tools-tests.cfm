<cfscript>
	// Test runner for Task Group 3: Development Tool Commands
	// Run: http://localhost:8080/run-dev-tools-tests.cfm

	// Set up mappings
	this.mappings = {
		"/fuse": expandPath("./fuse"),
		"/tests": expandPath("./tests"),
		"/database": expandPath("./database")
	};

	// Initialize components
	discovery = new fuse.testing.TestDiscovery(testPath = expandPath("/tests"));
	runner = new fuse.testing.TestRunner();
	reporter = new fuse.testing.TestReporter();

	// Execute pipeline
	writeOutput("<pre>");
	writeOutput("Running Development Tool Command Tests" & chr(10));
	writeOutput("=======================================" & chr(10) & chr(10));

	// Discover all tests
	allTests = discovery.discover();

	// Filter to only dev tool command tests
	devToolTests = [];
	targetTests = ["RoutesCommandTest", "ServeCommandTest", "TestCommandTest"];

	for (testDescriptor in allTests) {
		componentName = testDescriptor.componentName;
		for (targetTest in targetTests) {
			if (findNoCase(targetTest, componentName) > 0) {
				arrayAppend(devToolTests, testDescriptor);
				break;
			}
		}
	}

	writeOutput("Discovered " & arrayLen(devToolTests) & " dev tool test file(s)" & chr(10));
	writeOutput(chr(10));

	// Run tests with progress
	results = {
		passes: [],
		failures: [],
		errors: [],
		totalTime: 0
	};

	startTime = getTickCount();

	for (testDescriptor in devToolTests) {
		writeOutput("Running " & testDescriptor.componentName & chr(10));

		for (methodName in testDescriptor.testMethods) {
			testName = testDescriptor.componentName & "::" & methodName;
			testStartTime = getTickCount();
			testInstance = "";

			try {
				// Instantiate and run test
				testInstance = createObject("component", testDescriptor.componentName).init();
				testInstance.setup();
				invoke(testInstance, methodName);
				testInstance.teardown();

				// Test passed
				testTime = (getTickCount() - testStartTime) / 1000;
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
	writeOutput(chr(10) & chr(10));
	reporter.reportSummary(results);

	writeOutput("</pre>");
</cfscript>
