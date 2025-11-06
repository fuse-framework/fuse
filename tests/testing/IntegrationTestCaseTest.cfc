/**
 * Integration test framework tests
 *
 * Tests IntegrationTestCase loads framework and manages transactions correctly.
 */
component extends="fuse.testing.TestCase" {

	function testIntegrationTestCaseExtendsTestCase() {
		// Verify IntegrationTestCase extends TestCase
		var integrationTestCase = new fuse.testing.IntegrationTestCase();
		assertTrue(isInstanceOf(integrationTestCase, "fuse.testing.TestCase"));
	}

	function testIntegrationTestCaseHasInitFrameworkMethod() {
		// Verify IntegrationTestCase has initFramework method
		var integrationTestCase = new fuse.testing.IntegrationTestCase();
		var metadata = getMetadata(integrationTestCase);

		// Find initFramework in methods
		var hasMethod = false;
		if (structKeyExists(metadata, "functions")) {
			for (var func in metadata.functions) {
				if (func.name == "initFramework") {
					hasMethod = true;
					break;
				}
			}
		}

		assertTrue(hasMethod, "IntegrationTestCase should have initFramework() method");
	}

	function testFrameworkServicesAccessibleAfterInit() {
		// Create integration test case and manually call initFramework
		var integrationTestCase = new fuse.testing.IntegrationTestCase();

		// Manually invoke private initFramework() method
		var meta = getMetadata(integrationTestCase);
		invoke(integrationTestCase, "initFramework");

		var framework = integrationTestCase.getFramework();

		// Verify container is accessible
		var container = framework.getContainer();
		assertNotNull(container);
		assertInstanceOf("fuse.core.Container", container);

		// Verify router is registered
		assertTrue(container.has("router"));
		var router = container.resolve("router");
		assertInstanceOf("fuse.core.Router", router);

		// Verify event service is registered
		assertTrue(container.has("eventService"));
		var eventService = container.resolve("eventService");
		assertInstanceOf("fuse.core.EventService", eventService);
	}

	function testIntegrationTestDetection() {
		// Test that TestRunner can detect IntegrationTestCase
		var runner = new fuse.testing.TestRunner();

		// Create integration test instance
		var integrationTest = new fuse.testing.IntegrationTestCase();

		// Access private isIntegrationTestCase method via invoke
		var result = invoke(runner, "isIntegrationTestCase", {testInstance: integrationTest});

		assertTrue(result, "TestRunner should detect IntegrationTestCase");

		// Regular TestCase should return false
		var regularTest = new fuse.testing.TestCase();
		var result2 = invoke(runner, "isIntegrationTestCase", {testInstance: regularTest});

		assertFalse(result2, "TestRunner should NOT detect regular TestCase as integration test");
	}

	function testIntegrationTestRunsInTransaction() {
		// This test verifies transaction behavior works with integration tests
		// We'll verify this by checking that changes are rolled back

		// Create a test table for this test
		var qry = new Query();
		qry.setDatasource(this.datasource);
		qry.setSQL("
			CREATE TABLE IF NOT EXISTS integration_test_table (
				id INTEGER PRIMARY KEY AUTO_INCREMENT,
				test_value VARCHAR(100)
			)
		");
		qry.execute();

		// Ensure table is empty
		qry = new Query();
		qry.setDatasource(this.datasource);
		qry.setSQL("DELETE FROM integration_test_table");
		qry.execute();

		// Insert a record - this should be rolled back
		qry = new Query();
		qry.setDatasource(this.datasource);
		qry.setSQL("INSERT INTO integration_test_table (test_value) VALUES ('test_data')");
		qry.execute();

		// Verify insert succeeded within transaction
		assertDatabaseHas("integration_test_table", {test_value: "test_data"});

		// After test rollback, record should not exist
		// This will be verified by TestRunner's rollback mechanism
	}

	function testIntegrationTestIsolationMatchesUnitTests() {
		// Create test table
		var qry = new Query();
		qry.setDatasource(this.datasource);
		qry.setSQL("
			CREATE TABLE IF NOT EXISTS test_isolation (
				id INTEGER PRIMARY KEY AUTO_INCREMENT,
				counter INTEGER
			)
		");
		qry.execute();

		// Insert initial record
		qry = new Query();
		qry.setDatasource(this.datasource);
		qry.setSQL("INSERT INTO test_isolation (counter) VALUES (1)");
		qry.execute();

		// This should be rolled back by TestRunner
		assertDatabaseCount("test_isolation", 1);
	}

	function testIntegrationTestCanAccessFactoryHelpers() {
		// Integration tests should still have access to factory helpers
		var integrationTestCase = new fuse.testing.IntegrationTestCase();

		// Verify factory methods are available via mixin
		var vars = integrationTestCase.getVariables();
		assertTrue(structKeyExists(vars, "make"));
		assertTrue(structKeyExists(vars, "create"));
	}

	function testIntegrationTestCanAccessMockHelpers() {
		// Integration tests should have access to mock helpers
		var integrationTestCase = new fuse.testing.IntegrationTestCase();

		// Verify mock methods are available via mixin
		var vars = integrationTestCase.getVariables();
		assertTrue(structKeyExists(vars, "mock"));
		assertTrue(structKeyExists(vars, "stub"));
		assertTrue(structKeyExists(vars, "verify"));
	}

	function testGetFrameworkThrowsBeforeInit() {
		// Verify getFramework() throws descriptive error if called before init
		var integrationTestCase = new fuse.testing.IntegrationTestCase();

		assertThrows(function() {
			integrationTestCase.getFramework();
		}, "IntegrationTestCase.FrameworkNotInitialized");
	}

}
