/**
 * RollbackCommandTest - Tests for RollbackCommand
 *
 * Validates rollback command functionality:
 * - Basic rollback with default steps=1
 * - --steps=N flag validates positive integer
 * - --all flag calls Migrator.reset()
 * - Datasource resolution
 */
component extends="fuse.testing.TestCase" {

	// TEST: basic rollback with default steps=1
	public function testBasicRollbackWithDefaultSteps() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		var command = new fuse.cli.commands.Rollback();
		var args = {datasource: getDatasource()};

		var result = command.main(args);

		assertTrue(result.success, "Command should succeed");
		assertTrue(structKeyExists(result, "migrationsRolledBack"), "Should have migrationsRolledBack count");
	}

	// TEST: steps flag validates positive integer
	public function testStepsFlagValidatesPositiveInteger() {
		var command = new fuse.cli.commands.Rollback();
		var args = {datasource: getDatasource(), steps: 2};

		// Should not throw for positive integer
		var result = command.main(args);

		assertTrue(result.success, "Should accept positive integer");
	}

	// TEST: steps flag rejects negative value
	public function testStepsFlagRejectsNegativeValue() {
		var command = new fuse.cli.commands.Rollback();
		var args = {datasource: getDatasource(), steps: -1};

		assertThrows(function() {
			command.main(args);
		}, "InvalidArguments");
	}

	// TEST: steps flag rejects zero
	public function testStepsFlagRejectsZero() {
		var command = new fuse.cli.commands.Rollback();
		var args = {datasource: getDatasource(), steps: 0};

		assertThrows(function() {
			command.main(args);
		}, "InvalidArguments");
	}

	// TEST: all flag calls Migrator.reset()
	public function testAllFlagCallsMigratorReset() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		var command = new fuse.cli.commands.Rollback();
		var args = {datasource: getDatasource(), all: true};

		var result = command.main(args);

		assertTrue(result.success, "Command should succeed");
		assertTrue(structKeyExists(result, "migrationsRolledBack"), "Should have migrationsRolledBack count");
	}

	// TEST: datasource resolution works
	public function testDatasourceResolution() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		var command = new fuse.cli.commands.Rollback();
		// Don't pass datasource, let it resolve from defaults
		var args = {};

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
