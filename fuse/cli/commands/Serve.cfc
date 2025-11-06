/**
 * Serve Command - Start development server
 *
 * Wrapper around lucli server start command for convenient local development.
 */
component {

	/**
	 * Main command entry point
	 *
	 * @param args Arguments struct with flags
	 * @return Struct with success, message, and server data
	 */
	public struct function main(required struct args) {
		var silent = structKeyExists(arguments.args, "silent") ? arguments.args.silent : false;
		var dryRun = structKeyExists(arguments.args, "dryRun") ? arguments.args.dryRun : false;

		// Get host and port with defaults
		var host = structKeyExists(arguments.args, "host") ? arguments.args.host : "127.0.0.1";
		var port = structKeyExists(arguments.args, "port") ? arguments.args.port : 8080;

		// Display friendly message
		if (!silent) {
			writeOutput("Starting Fuse development server..." & chr(10));
			writeOutput("Server running at http://" & host & ":" & port & chr(10));
			writeOutput("Press Ctrl+C to stop" & chr(10));
		}

		// If dry run (for testing), don't actually start server
		if (dryRun) {
			return {
				success: true,
				message: "Server started (dry run)",
				host: host,
				port: port
			};
		}

		// Execute lucli server start command
		try {
			var result = execute(
				name = "lucli",
				arguments = [
					"server",
					"start",
					"--host=" & host,
					"--port=" & port,
					"--openbrowser=false"
				],
				timeout = 0
			);

			return {
				success: true,
				message: "Server started",
				host: host,
				port: port
			};

		} catch (any e) {
			throw(
				type = "ServerStartFailed",
				message = "Failed to start development server",
				detail = "Error: " & e.message & ". Ensure lucli is installed and accessible."
			);
		}
	}

}
