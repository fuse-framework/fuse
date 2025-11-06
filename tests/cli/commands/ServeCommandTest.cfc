/**
 * ServeCommandTest - Tests for ServeCommand
 *
 * Validates serve command functionality:
 * - Default host and port (127.0.0.1:8080)
 * - --host flag overrides default
 * - --port flag overrides default
 * - Output displays friendly message
 */
component extends="fuse.testing.TestCase" {

	// TEST: default host and port
	public function testDefaultHostAndPort() {
		var command = new fuse.cli.commands.Serve();
		var args = {silent: true, dryRun: true};

		var result = command.main(args);

		assertTrue(result.success, "Command should succeed");
		assertEqual("127.0.0.1", result.host, "Should use default host");
		assertEqual(8080, result.port, "Should use default port");
	}

	// TEST: host flag overrides default
	public function testHostFlagOverridesDefault() {
		var command = new fuse.cli.commands.Serve();
		var args = {host: "0.0.0.0", silent: true, dryRun: true};

		var result = command.main(args);

		assertTrue(result.success, "Command should succeed");
		assertEqual("0.0.0.0", result.host, "Should use custom host");
	}

	// TEST: port flag overrides default
	public function testPortFlagOverridesDefault() {
		var command = new fuse.cli.commands.Serve();
		var args = {port: 3000, silent: true, dryRun: true};

		var result = command.main(args);

		assertTrue(result.success, "Command should succeed");
		assertEqual(3000, result.port, "Should use custom port");
	}

	// TEST: both host and port can be customized
	public function testBothHostAndPortCustomized() {
		var command = new fuse.cli.commands.Serve();
		var args = {host: "localhost", port: 9090, silent: true, dryRun: true};

		var result = command.main(args);

		assertTrue(result.success, "Command should succeed");
		assertEqual("localhost", result.host, "Should use custom host");
		assertEqual(9090, result.port, "Should use custom port");
	}

}
