<cfscript>
// Run integration test framework tests only
discovery = new fuse.testing.TestDiscovery();
runner = new fuse.testing.TestRunner(datasource = "fuse");
reporter = new fuse.testing.TestReporter();

// Discover only IntegrationTestCaseTest
tests = [];
testDescriptor = {
	componentName: "tests.testing.IntegrationTestCaseTest",
	testMethods: []
};

// Get test methods from the test component
testInstance = new tests.testing.IntegrationTestCaseTest();
testDescriptor.testMethods = testInstance.getTestMethods();
arrayAppend(tests, testDescriptor);

// Run tests
results = runner.run(tests);

// Report results
reporter.report(results, "text");
</cfscript>
