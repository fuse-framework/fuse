/**
 * DatabaseConnectionTest - Tests for DatabaseConnection utility
 *
 * Validates datasource resolution and connection validation:
 * - resolve() checks flag > application > default order
 * - validate() tests connection with valid datasource
 * - validate() throws helpful error for invalid datasource
 */
component extends="fuse.testing.TestCase" {

	// TEST: resolve uses flag datasource when provided
	public function testResolveUsesFlagDatasourceWhenProvided() {
		var connection = new fuse.cli.support.DatabaseConnection();
		var args = {datasource: "custom_ds"};

		var result = connection.resolve(args);

		assertEqual("custom_ds", result);
	}

	// TEST: resolve falls back to application.datasource
	public function testResolveFallsBackToApplicationDatasource() {
		var connection = new fuse.cli.support.DatabaseConnection();
		var args = {};

		// Set application datasource
		application.datasource = "app_ds";

		try {
			var result = connection.resolve(args);
			assertEqual("app_ds", result);
		} finally {
			// Clean up
			structDelete(application, "datasource");
		}
	}

	// TEST: resolve uses default "fuse" when no others available
	public function testResolveUsesDefaultFuseWhenNoOthersAvailable() {
		var connection = new fuse.cli.support.DatabaseConnection();
		var args = {};

		// Ensure no application datasource
		if (structKeyExists(application, "datasource")) {
			structDelete(application, "datasource");
		}

		var result = connection.resolve(args);

		assertEqual("fuse", result);
	}

	// TEST: validate succeeds with valid datasource
	public function testValidateSucceedsWithValidDatasource() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		var connection = new fuse.cli.support.DatabaseConnection();
		var datasource = getDatasource();

		// Should not throw
		connection.validate(datasource);

		// If we get here, validation passed
		assertTrue(true);
	}

	// TEST: validate throws error for invalid datasource
	public function testValidateThrowsErrorForInvalidDatasource() {
		var connection = new fuse.cli.support.DatabaseConnection();

		assertThrows(function() {
			connection.validate("nonexistent_datasource_xyz");
		}, "Database.DatasourceNotFound");
	}

	// TEST: validate error message includes helpful guidance
	public function testValidateErrorMessageIncludesHelpfulGuidance() {
		var connection = new fuse.cli.support.DatabaseConnection();

		try {
			connection.validate("invalid_ds");
			assertTrue(false, "Should have thrown exception");
		} catch (any e) {
			assertEqual("Database.DatasourceNotFound", e.type);
			// Error message should be helpful
			assertTrue(len(e.message) > 0, "Should have error message");
			assertTrue(len(e.detail) > 0, "Should have error detail");
			// Should mention the datasource name
			assertTrue(findNoCase("invalid_ds", e.message) > 0 || findNoCase("invalid_ds", e.detail) > 0);
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
