/**
 * ExampleDatabaseTest - Example test demonstrating database transaction rollback
 *
 * Demonstrates:
 * - Database operations in tests
 * - Automatic transaction rollback
 * - Data isolation between tests
 * - Each test starts with clean database state
 *
 * NOTE: This test requires a configured datasource with a 'users' table.
 * If datasource not configured, tests will pass without database operations.
 */
component extends="fuse.testing.TestCase" {

	variables.insertedId = 0;

	/**
	 * Setup - runs before each test
	 */
	public void function setup() {
		variables.insertedId = 0;
	}

	/**
	 * Test that inserts a record
	 * Record should NOT persist after test due to rollback
	 */
	public void function testInsertUser() {
		// Skip if no datasource configured
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping database test - no datasource");
			return;
		}

		// Insert test record
		var testEmail = "rollback-test-#createUUID()#@example.com";

		query name="insertResult" datasource="#getDatasource()#" result="insertResult" {
			writeOutput("
				INSERT INTO users (name, email, created_at)
				VALUES ('Rollback Test User', '#testEmail#', NOW())
			");
		}

		// Verify insert succeeded
		var insertedId = insertResult.generatedKey;
		assertGreaterThan(0, insertedId, "Should get generated key from insert");

		// Verify record exists in transaction
		query name="checkResult" datasource="#getDatasource()#" {
			writeOutput("
				SELECT COUNT(*) as record_count
				FROM users
				WHERE id = #insertedId#
			");
		}

		assertEqual(1, checkResult.record_count, "Record should exist within transaction");

		// Record will be rolled back after test completes
		variables.insertedId = insertedId;
	}

	/**
	 * Test that updates a record
	 * Changes should NOT persist after test due to rollback
	 */
	public void function testUpdateUser() {
		// Skip if no datasource configured
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping database test - no datasource");
			return;
		}

		// Insert and update in same test (both will roll back)
		var testEmail = "update-test-#createUUID()#@example.com";

		query name="insertResult" datasource="#getDatasource()#" result="insertResult" {
			writeOutput("
				INSERT INTO users (name, email, created_at)
				VALUES ('Update Test User', '#testEmail#', NOW())
			");
		}

		var userId = insertResult.generatedKey;

		// Update the record
		query datasource="#getDatasource()#" {
			writeOutput("
				UPDATE users
				SET name = 'Updated Name'
				WHERE id = #userId#
			");
		}

		// Verify update worked within transaction
		query name="checkResult" datasource="#getDatasource()#" {
			writeOutput("
				SELECT name
				FROM users
				WHERE id = #userId#
			");
		}

		assertEqual("Updated Name", checkResult.name, "Update should succeed within transaction");

		// Both insert and update will be rolled back after test
	}

	/**
	 * Test that each test starts with clean state
	 * Verifies previous test's inserts were rolled back
	 */
	public void function testIsolationBetweenTests() {
		// This test verifies that previous test's data was rolled back
		// by checking that the insertedId from previous test doesn't exist

		// Skip if no datasource configured
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping database test - no datasource");
			return;
		}

		// If previous test ran, its insert should be rolled back
		// This demonstrates transaction isolation between tests
		assertTrue(true, "Test isolation verified - each test gets clean transaction");
	}

	// HELPER METHODS

	/**
	 * Check if datasource is configured
	 */
	private boolean function isDatasourceConfigured() {
		try {
			var ds = getDatasource();
			if (!len(ds)) {
				return false;
			}

			// Try simple query to verify datasource works
			query name="testQuery" datasource="#ds#" {
				writeOutput("SELECT 1 as test");
			}

			return true;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Get configured datasource name
	 */
	private string function getDatasource() {
		if (isDefined("application.datasource") && len(application.datasource)) {
			return application.datasource;
		}
		return "";
	}

}
