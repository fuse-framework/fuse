/**
 * DatabaseConnection - Utility for datasource resolution and validation
 *
 * Provides consistent datasource resolution across all CLI commands:
 * - Resolve datasource from flag > application > default
 * - Validate datasource connection before use
 * - Throw helpful errors when datasource not found
 *
 * USAGE EXAMPLES:
 *
 * Basic datasource resolution:
 *     connection = new fuse.cli.support.DatabaseConnection();
 *     datasource = connection.resolve(args);
 *
 * With validation:
 *     connection = new fuse.cli.support.DatabaseConnection();
 *     datasource = connection.resolve(args);
 *     connection.validate(datasource);
 *
 * Resolution order:
 * 1. args.datasource (command flag)
 * 2. application.datasource (application config)
 * 3. "fuse" (default)
 */
component {

	/**
	 * Resolve datasource name from arguments or fallbacks
	 *
	 * Resolution order:
	 * 1. args.datasource (command flag: --datasource=name)
	 * 2. application.datasource (application config)
	 * 3. "fuse" (default datasource name)
	 *
	 * @args Arguments struct from command (may contain datasource key)
	 * @return Datasource name string
	 */
	public string function resolve(required struct args) {
		// Check flag datasource first
		if (structKeyExists(arguments.args, "datasource") && len(arguments.args.datasource)) {
			return arguments.args.datasource;
		}

		// Check application datasource
		if (isDefined("application.datasource") && len(application.datasource)) {
			return application.datasource;
		}

		// Default to "fuse"
		return "fuse";
	}

	/**
	 * Validate datasource connection
	 *
	 * Tests connection with simple SELECT 1 query.
	 * Throws Database.DatasourceNotFound on failure.
	 *
	 * @datasource Datasource name to validate
	 * @throws Database.DatasourceNotFound if connection fails
	 */
	public void function validate(required string datasource) {
		try {
			// Test connection with simple query
			queryExecute("SELECT 1 as test", [], {datasource: arguments.datasource});

		} catch (any e) {
			// Throw helpful error message
			throw(
				type = "Database.DatasourceNotFound",
				message = "Datasource not found or inaccessible: '#arguments.datasource#'",
				detail = "Verify datasource '#arguments.datasource#' is configured in Lucee Admin or use --datasource flag to specify a different datasource."
			);
		}
	}

}
