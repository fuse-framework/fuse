/**
 * CLIDatabaseDevToolsIntegrationTest - Integration tests for CLI Database & Dev Tools
 *
 * Tests critical workflows and integration points between commands:
 * - Full migrate -> seed workflow
 * - Rollback after migration
 * - Routes command with various scenarios
 * - Test command discovery and filtering
 * - Error handling and edge cases
 */
component extends="fuse.testing.TestCase" {

	/**
	 * Setup test environment
	 */
	public function setup() {
		super.setup();

		// Store original application state
		variables.hadFuse = isDefined("application.fuse");
		if (variables.hadFuse) {
			variables.originalFuse = duplicate(application.fuse);
		}

		// Ensure test datasource is configured
		if (!isDatasourceConfigured()) {
			variables.skipTests = true;
		} else {
			variables.skipTests = false;
		}
	}

	/**
	 * Teardown test environment
	 */
	public function teardown() {
		// Restore application.fuse if it existed
		if (variables.hadFuse) {
			application.fuse = variables.originalFuse;
		} else if (isDefined("application.fuse")) {
			structDelete(application, "fuse");
		}

		super.teardown();
	}

	// INTEGRATION TEST 1: Full migrate -> seed workflow
	public function testFullMigrateThenSeedWorkflow() {
		if (variables.skipTests) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		// Setup: Create test seeder
		_createTestDatabaseSeeder();

		try {
			// Step 1: Run migrations
			var migrateCommand = new fuse.cli.commands.Migrate();
			var migrateArgs = {datasource: getDatasource(), silent: true};
			var migrateResult = migrateCommand.main(migrateArgs);

			assertTrue(migrateResult.success, "Migrate should succeed");

			// Step 2: Run seeds
			var seedCommand = new fuse.cli.commands.Seed();
			var seedArgs = {datasource: getDatasource(), silent: true};
			var seedResult = seedCommand.main(seedArgs);

			assertTrue(seedResult.success, "Seed should succeed");
			assertTrue(structKeyExists(seedResult, "message"), "Seed should have message");

		} finally {
			_cleanupTestSeeder("DatabaseSeeder");
		}
	}

	// INTEGRATION TEST 2: Migrate status then migrate workflow
	public function testMigrateStatusThenMigrate() {
		if (variables.skipTests) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		var command = new fuse.cli.commands.Migrate();
		var datasource = getDatasource();

		// Step 1: Check status
		var statusResult = command.main({
			datasource: datasource,
			status: true,
			silent: true
		});

		assertTrue(statusResult.success, "Status should succeed");
		assertTrue(structKeyExists(statusResult, "pending"), "Should have pending count");
		assertTrue(structKeyExists(statusResult, "ran"), "Should have ran count");

		// Step 2: Run migrations
		var migrateResult = command.main({
			datasource: datasource,
			silent: true
		});

		assertTrue(migrateResult.success, "Migrate should succeed");
	}

	// INTEGRATION TEST 3: Migrate then rollback workflow
	public function testMigrateThenRollbackWorkflow() {
		if (variables.skipTests) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		var datasource = getDatasource();

		// Step 1: Run migrations
		var migrateCommand = new fuse.cli.commands.Migrate();
		var migrateResult = migrateCommand.main({
			datasource: datasource,
			silent: true
		});

		assertTrue(migrateResult.success, "Migrate should succeed");

		// Step 2: Rollback one migration
		var rollbackCommand = new fuse.cli.commands.Rollback();
		var rollbackResult = rollbackCommand.main({
			datasource: datasource,
			steps: 1,
			silent: true
		});

		assertTrue(rollbackResult.success, "Rollback should succeed");
		assertTrue(structKeyExists(rollbackResult, "migrationsRolledBack"), "Should have rollback count");
	}

	// INTEGRATION TEST 4: Routes command with empty routes
	public function testRoutesCommandWithEmptyRoutes() {
		// Setup mock framework with empty router
		var router = new fuse.core.Router();
		application.fuse = {router: router};

		var command = new fuse.cli.commands.Routes();
		var result = command.main({silent: true});

		assertTrue(result.success, "Command should succeed with empty routes");
		assertEqual(0, result.routeCount, "Should have zero routes");
	}

	// INTEGRATION TEST 5: Routes command with filtering
	public function testRoutesCommandWithFiltering() {
		// Setup mock framework with routes
		var router = new fuse.core.Router();
		router.get("/users", "Users.index", {name: "users_index"});
		router.post("/users", "Users.create", {name: "users_create"});
		router.get("/posts", "Posts.index", {name: "posts_index"});

		application.fuse = {router: router};

		var command = new fuse.cli.commands.Routes();

		// Test method filter
		var result = command.main({method: "GET", silent: true});
		assertTrue(result.success, "Method filter should work");
		assertTrue(result.routeCount >= 2, "Should have at least 2 GET routes");

		// Test name filter
		result = command.main({name: "users", silent: true});
		assertTrue(result.success, "Name filter should work");
		assertTrue(result.routeCount >= 2, "Should have at least 2 users routes");

		// Test handler filter
		result = command.main({handler: "Posts", silent: true});
		assertTrue(result.success, "Handler filter should work");
		assertTrue(result.routeCount >= 1, "Should have at least 1 Posts route");
	}

	// INTEGRATION TEST 6: Test command with filter
	public function testTestCommandWithFilter() {
		var command = new fuse.cli.commands.Test();

		// Use specific filter to avoid recursion
		var result = command.main({
			filter: "ServeCommandTest",
			silent: true
		});

		assertTrue(structKeyExists(result, "success"), "Should have success key");
		assertTrue(structKeyExists(result, "totalTests"), "Should have totalTests count");
		assertTrue(result.totalTests > 0, "Should find at least one test");
	}

	// INTEGRATION TEST 7: Test command with type=unit
	public function testTestCommandWithTypeUnit() {
		var command = new fuse.cli.commands.Test();

		var result = command.main({
			type: "unit",
			filter: "DatabaseConnection",  // Focus on specific tests
			silent: true
		});

		assertTrue(structKeyExists(result, "success"), "Should have success key");
		assertTrue(structKeyExists(result, "totalTests"), "Should have totalTests count");
	}

	// INTEGRATION TEST 8: Seed with specific class
	public function testSeedWithSpecificClass() {
		if (variables.skipTests) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		// Create specific test seeder
		_createTestSeeder("UserSeeder");

		try {
			var command = new fuse.cli.commands.Seed();
			var result = command.main({
				class: "UserSeeder",
				datasource: getDatasource(),
				silent: true
			});

			assertTrue(result.success, "Specific seeder should succeed");
			assertTrue(structKeyExists(result, "message"), "Should have message");

		} finally {
			_cleanupTestSeeder("UserSeeder");
		}
	}

	// INTEGRATION TEST 9: Commands work with non-default datasource
	public function testCommandsWorkWithNonDefaultDatasource() {
		if (variables.skipTests) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		var datasource = getDatasource();

		// Test migrate with explicit datasource
		var migrateCommand = new fuse.cli.commands.Migrate();
		var migrateResult = migrateCommand.main({
			datasource: datasource,
			silent: true
		});

		assertTrue(migrateResult.success, "Migrate with datasource should work");

		// Test rollback with explicit datasource
		var rollbackCommand = new fuse.cli.commands.Rollback();
		var rollbackResult = rollbackCommand.main({
			datasource: datasource,
			steps: 1,
			silent: true
		});

		assertTrue(rollbackResult.success, "Rollback with datasource should work");
	}

	// INTEGRATION TEST 10: Error messages are user-friendly
	public function testErrorMessagesAreUserFriendly() {
		// Test missing seeder class
		var seedCommand = new fuse.cli.commands.Seed();

		try {
			seedCommand.main({
				class: "NonExistentSeederXYZ123",
				datasource: getDatasource(),
				silent: true
			});
			assertTrue(false, "Should have thrown exception");
		} catch (Seeder.NotFound e) {
			// Error should be clear
			assertTrue(len(e.message) > 0, "Should have error message");
			assertTrue(findNoCase("NonExistentSeederXYZ123", e.message) > 0, "Should mention seeder name");
		}

		// Test invalid datasource
		var connection = new fuse.cli.support.DatabaseConnection();

		try {
			connection.validate("invalid_datasource_xyz");
			assertTrue(false, "Should have thrown exception");
		} catch (Database.DatasourceNotFound e) {
			assertTrue(len(e.message) > 0, "Should have error message");
			assertTrue(len(e.detail) > 0, "Should have helpful detail");
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

}
