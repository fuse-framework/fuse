<cfscript>
	// Test runner for CLI Database & Dev Tools feature (Roadmap ##13)
	// Run: http://localhost:8080/run-cli-db-devtools-tests.cfm
	//
	// Tests all components from the CLI Database & Dev Tools spec:
	// - Foundation: DatabaseConnection, Seeder
	// - Database Commands: Migrate, Rollback, Seed
	// - Dev Tools: Routes, Serve, Test
	// - Integration: End-to-end workflows

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
	writeOutput("CLI Database & Dev Tools Feature Tests (Roadmap ##13)" & chr(10));
	writeOutput("====================================================" & chr(10) & chr(10));

	// Discover all tests
	allTests = discovery.discover();

	// Filter to only CLI Database & Dev Tools tests
	featureTests = [];
	targetTests = [
		// Foundation (Task Group 1)
		"DatabaseConnectionTest",
		"SeederTest",
		// Database Commands (Task Group 2)
		"MigrateCommandTest",
		"RollbackCommandTest",
		"SeedCommandTest",
		// Dev Tools (Task Group 3)
		"RoutesCommandTest",
		"ServeCommandTest",
		"TestCommandTest",
		// Integration (Task Group 4)
		"CLIDatabaseDevToolsIntegrationTest"
	];

	for (testDescriptor in allTests) {
		componentName = testDescriptor.componentName;
		for (targetTest in targetTests) {
			if (findNoCase(targetTest, componentName) > 0) {
				arrayAppend(featureTests, testDescriptor);
				break;
			}
		}
	}

	writeOutput("Discovered " & arrayLen(featureTests) & " test file(s) for this feature" & chr(10));
	writeOutput(chr(10));

	// Run tests with progress
	results = {
		passes: [],
		failures: [],
		errors: [],
		totalTime: 0
	};

	startTime = getTickCount();

	for (testDescriptor in featureTests) {
		writeOutput("Running " & testDescriptor.componentName & " (" & arrayLen(testDescriptor.testMethods) & " tests)" & chr(10));

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

		writeOutput(chr(10));
	}

	endTime = getTickCount();
	results.totalTime = (endTime - startTime) / 1000;

	// Report summary
	writeOutput(chr(10));
	reporter.reportSummary(results);

	// Show breakdown by task group
	writeOutput(chr(10) & chr(10));
	writeOutput("Test Breakdown by Task Group:" & chr(10));
	writeOutput("------------------------------" & chr(10));
	writeOutput("Task Group 1 (Foundation): DatabaseConnection, Seeder" & chr(10));
	writeOutput("Task Group 2 (Database Commands): Migrate, Rollback, Seed" & chr(10));
	writeOutput("Task Group 3 (Dev Tools): Routes, Serve, Test" & chr(10));
	writeOutput("Task Group 4 (Integration): End-to-end workflows" & chr(10));

	writeOutput("</pre>");
</cfscript>
