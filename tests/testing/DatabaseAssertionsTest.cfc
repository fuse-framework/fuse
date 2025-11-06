/**
 * DatabaseAssertionsTest - Tests for database assertion methods
 *
 * Validates database assertion behaviors:
 * - assertDatabaseHas finds matching records
 * - assertDatabaseMissing verifies no match
 * - assertDatabaseCount verifies exact count
 * - Failure messages include table and attributes
 */
component extends="fuse.testing.TestCase" {

	public function setup() {
		// Skip if no datasource configured
		if (!isDatasourceConfigured()) {
			return;
		}

		// Create test table for assertions
		queryExecute("
			CREATE TABLE IF NOT EXISTS test_assertions (
				id INTEGER PRIMARY KEY AUTO_INCREMENT,
				name VARCHAR(100),
				email VARCHAR(100),
				active BOOLEAN DEFAULT 1
			)
		", [], {datasource: getDatasource()});

		// Clear any existing data
		queryExecute("DELETE FROM test_assertions", [], {datasource: getDatasource()});

		// Insert test data
		queryExecute("
			INSERT INTO test_assertions (name, email, active) VALUES
			('John Doe', 'john@test.com', 1),
			('Jane Smith', 'jane@test.com', 1),
			('Bob Johnson', 'bob@test.com', 0)
		", [], {datasource: getDatasource()});
	}

	public function teardown() {
		// Skip if no datasource configured
		if (!isDatasourceConfigured()) {
			return;
		}

		// Clean up test table
		queryExecute("DROP TABLE IF EXISTS test_assertions", [], {datasource: getDatasource()});
	}

	// TEST: assertDatabaseHas finds matching record
	public function testAssertDatabaseHasFindsMatchingRecord() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		// Should pass - record exists
		assertDatabaseHas("test_assertions", {name: "John Doe", email: "john@test.com"});
	}

	// TEST: assertDatabaseHas with single attribute
	public function testAssertDatabaseHasWithSingleAttribute() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		// Should pass - record with this email exists
		assertDatabaseHas("test_assertions", {email: "jane@test.com"});
	}

	// TEST: assertDatabaseHas throws when no match
	public function testAssertDatabaseHasThrowsWhenNoMatch() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		assertThrows(function() {
			assertDatabaseHas("test_assertions", {name: "Nonexistent User"});
		}, "AssertionFailedException");
	}

	// TEST: assertDatabaseMissing verifies no match
	public function testAssertDatabaseMissingVerifiesNoMatch() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		// Should pass - no record with this name
		assertDatabaseMissing("test_assertions", {name: "Nonexistent User"});
	}

	// TEST: assertDatabaseMissing throws when record exists
	public function testAssertDatabaseMissingThrowsWhenRecordExists() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		assertThrows(function() {
			assertDatabaseMissing("test_assertions", {email: "john@test.com"});
		}, "AssertionFailedException");
	}

	// TEST: assertDatabaseCount verifies exact count
	public function testAssertDatabaseCountVerifiesExactCount() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		// Should pass - exactly 3 records
		assertDatabaseCount("test_assertions", 3);
	}

	// TEST: assertDatabaseCount throws when count doesn't match
	public function testAssertDatabaseCountThrowsWhenCountDoesNotMatch() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		assertThrows(function() {
			assertDatabaseCount("test_assertions", 10);
		}, "AssertionFailedException");
	}

	// TEST: assertion failure messages include table and attributes
	public function testFailureMessagesIncludeTableAndAttributes() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		try {
			assertDatabaseHas("test_assertions", {name: "Missing", email: "missing@test.com"});
			// Should not reach here
			assertTrue(false, "Should have thrown AssertionFailedException");
		} catch (any e) {
			assertEqual("AssertionFailedException", e.type);
			// Verify message includes table name
			assertTrue(findNoCase("test_assertions", e.detail) > 0, "Error should mention table name");
			// Verify message includes expected attributes
			assertTrue(findNoCase("Missing", e.detail) > 0, "Error should mention expected name");
		}
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
			queryExecute("SELECT 1 as test", [], {datasource: ds});

			return true;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Get configured datasource name
	 */
	private string function getDatasource() {
		if (structKeyExists(variables, "datasource") && len(variables.datasource)) {
			return variables.datasource;
		}
		if (isDefined("application.datasource") && len(application.datasource)) {
			return application.datasource;
		}
		return "fuse";
	}

}
