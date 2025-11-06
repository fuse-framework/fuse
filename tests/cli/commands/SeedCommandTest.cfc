/**
 * SeedCommandTest - Tests for SeedCommand
 *
 * Validates seed command functionality:
 * - Default invokes DatabaseSeeder
 * - --class flag runs specific seeder
 * - Error handling for missing seeder class
 * - Datasource resolution
 */
component extends="fuse.testing.TestCase" {

	// TEST: default invokes DatabaseSeeder
	public function testDefaultInvokesDatabaseSeeder() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		// Create a minimal DatabaseSeeder for testing
		_createTestDatabaseSeeder();

		try {
			var command = new fuse.cli.commands.Seed();
			var args = {datasource: getDatasource()};

			var result = command.main(args);

			assertTrue(result.success, "Command should succeed");
			assertTrue(structKeyExists(result, "message"), "Should have message");

		} finally {
			_cleanupTestSeeder("DatabaseSeeder");
		}
	}

	// TEST: class flag runs specific seeder
	public function testClassFlagRunsSpecificSeeder() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		// Create a specific test seeder
		_createTestSeeder("UserSeeder");

		try {
			var command = new fuse.cli.commands.Seed();
			var args = {datasource: getDatasource(), class: "UserSeeder"};

			var result = command.main(args);

			assertTrue(result.success, "Command should succeed");
			assertTrue(structKeyExists(result, "message"), "Should have message");

		} finally {
			_cleanupTestSeeder("UserSeeder");
		}
	}

	// TEST: class flag handles snake_case conversion
	public function testClassFlagHandlesSnakeCaseConversion() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		// Create a test seeder with PascalCase name
		_createTestSeeder("PostSeeder");

		try {
			var command = new fuse.cli.commands.Seed();
			// Pass snake_case, should be converted to PascalCase
			var args = {datasource: getDatasource(), class: "post_seeder"};

			var result = command.main(args);

			assertTrue(result.success, "Command should succeed with snake_case conversion");

		} finally {
			_cleanupTestSeeder("PostSeeder");
		}
	}

	// TEST: error handling for missing seeder class
	public function testErrorHandlingForMissingSeederClass() {
		var command = new fuse.cli.commands.Seed();
		var args = {datasource: getDatasource(), class: "NonExistentSeeder"};

		assertThrows(function() {
			command.main(args);
		}, "Seeder.NotFound");
	}

	// TEST: datasource resolution works
	public function testDatasourceResolution() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		// Create DatabaseSeeder for default behavior
		_createTestDatabaseSeeder();

		try {
			var command = new fuse.cli.commands.Seed();
			// Don't pass datasource, let it resolve from defaults
			var args = {};

			var result = command.main(args);

			assertTrue(result.success, "Command should succeed with resolved datasource");

		} finally {
			_cleanupTestSeeder("DatabaseSeeder");
		}
	}

	// HELPER METHODS

	/**
	 * Create test DatabaseSeeder
	 */
	private void function _createTestDatabaseSeeder() {
		_createTestSeeder("DatabaseSeeder");
	}

	/**
	 * Create a test seeder component
	 */
	private void function _createTestSeeder(required string seederName) {
		var seederDir = expandPath("/database/seeds/");

		// Create directory if needed
		if (!directoryExists(seederDir)) {
			directoryCreate(seederDir, true);
		}

		// Create seeder file
		var seederPath = seederDir & arguments.seederName & ".cfc";
		var content = '/**
 * Test Seeder - #arguments.seederName#
 */
component extends="fuse.orm.Seeder" {
	public function run() {
		// Test seeder - does nothing
	}
}';

		fileWrite(seederPath, content);
	}

	/**
	 * Clean up test seeder
	 */
	private void function _cleanupTestSeeder(required string seederName) {
		var seederPath = expandPath("/database/seeds/" & arguments.seederName & ".cfc");

		if (fileExists(seederPath)) {
			fileDelete(seederPath);
		}
	}

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
