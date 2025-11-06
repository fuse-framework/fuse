/**
 * MigrateCommandTest - Tests for MigrateCommand
 *
 * Validates migrate command functionality:
 * - Basic migrate operation calls Migrator.migrate()
 * - --status flag calls Migrator.status() and formats output
 * - --reset flag calls Migrator.reset()
 * - Datasource resolution via DatabaseConnection
 * - Error handling for missing migrations directory
 */
component extends="fuse.testing.TestCase" {

	// TEST: basic migrate operation calls Migrator.migrate()
	public function testBasicMigrateCallsMigratorMigrate() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		var command = new fuse.cli.commands.Migrate();
		var args = {datasource: getDatasource()};

		var result = command.main(args);

		assertTrue(result.success, "Command should succeed");
		assertTrue(structKeyExists(result, "migrationsRun"), "Should have migrationsRun count");
	}

	// TEST: status flag calls Migrator.status() and formats output
	public function testStatusFlagCallsMigratorStatus() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		var command = new fuse.cli.commands.Migrate();
		var args = {datasource: getDatasource(), status: true};

		var result = command.main(args);

		assertTrue(result.success, "Command should succeed");
		assertTrue(structKeyExists(result, "pending"), "Should have pending count");
		assertTrue(structKeyExists(result, "ran"), "Should have ran count");
	}

	// TEST: reset flag calls Migrator.reset()
	public function testResetFlagCallsMigratorReset() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		var command = new fuse.cli.commands.Migrate();
		var args = {datasource: getDatasource(), reset: true};

		var result = command.main(args);

		assertTrue(result.success, "Command should succeed");
		assertTrue(structKeyExists(result, "migrationsRolledBack"), "Should have migrationsRolledBack count");
	}

	// TEST: refresh flag calls Migrator.refresh()
	public function testRefreshFlagCallsMigratorRefresh() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		var command = new fuse.cli.commands.Migrate();
		var args = {datasource: getDatasource(), refresh: true};

		var result = command.main(args);

		assertTrue(result.success, "Command should succeed");
		assertTrue(structKeyExists(result, "message"), "Should have message");
	}

	// TEST: datasource resolution via DatabaseConnection
	public function testDatasourceResolutionViaDatabaseConnection() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		var command = new fuse.cli.commands.Migrate();
		// Don't pass datasource, let it resolve from defaults
		var args = {};

		// Should use DatabaseConnection to resolve datasource
		var result = command.main(args);

		assertTrue(result.success, "Command should succeed with resolved datasource");
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
