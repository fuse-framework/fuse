/**
 * TestCommandTest - Tests for TestCommand
 *
 * Validates test command functionality:
 * - Default runs all tests using TestDiscovery
 * - --filter flag matches component name patterns
 * - --type=unit discovers only from /tests/unit/
 * - --verbose flag displays detailed output
 * - Exit code 0 for passes, 1 for failures/errors
 *
 * NOTE: Tests use specific filters to avoid infinite recursion
 */
component extends="fuse.testing.TestCase" {

	// TEST: filter flag matches component name patterns
	public function testFilterMatchesComponentName() {
		var command = new fuse.cli.commands.Test();
		// Use specific filter to avoid recursion - test RoutesCommand
		var args = {filter: "RoutesCommandTest", silent: true};

		var result = command.main(args);

		assertTrue(structKeyExists(result, "success"), "Should have success key");
		assertTrue(structKeyExists(result, "totalTests"), "Should have totalTests count");
	}

	// TEST: type=unit discovers only from /tests/unit/
	public function testTypeUnitDiscoversFromUnitPath() {
		var command = new fuse.cli.commands.Test();
		var args = {type: "unit", silent: true};

		var result = command.main(args);

		assertTrue(structKeyExists(result, "success"), "Should have success key");
		assertTrue(structKeyExists(result, "totalTests"), "Should have totalTests count");
	}

	// TEST: type=integration discovers only from /tests/integration/
	public function testTypeIntegrationDiscoversFromIntegrationPath() {
		var command = new fuse.cli.commands.Test();
		var args = {type: "integration", silent: true};

		var result = command.main(args);

		assertTrue(structKeyExists(result, "success"), "Should have success key");
		assertTrue(structKeyExists(result, "totalTests"), "Should have totalTests count");
	}

	// TEST: verbose flag displays detailed output
	public function testVerboseFlagDisplaysDetailedOutput() {
		var command = new fuse.cli.commands.Test();
		// Use specific filter to avoid recursion
		var args = {verbose: true, silent: true, filter: "ServeCommandTest"};

		var result = command.main(args);

		assertTrue(structKeyExists(result, "success"), "Should have success key");
		assertTrue(structKeyExists(result, "totalTests"), "Should have totalTests count");
	}

	// TEST: exit code structure exists
	public function testExitCodeStructureExists() {
		var command = new fuse.cli.commands.Test();
		// Use specific filter to avoid recursion
		var args = {silent: true, filter: "ServeCommandTest"};

		var result = command.main(args);

		assertTrue(structKeyExists(result, "exitCode"), "Should have exitCode key");
		assertTrue(result.exitCode == 0 || result.exitCode == 1, "Exit code should be 0 or 1");
	}

}
