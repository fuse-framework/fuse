/**
 * Seed Command - Database seeder execution
 *
 * Invokes database seeders to populate database with test/default data.
 */
component {

	/**
	 * Main command entry point
	 *
	 * @param args Arguments struct with flags
	 * @return Struct with success, message, and seed data
	 */
	public struct function main(required struct args) {
		var silent = structKeyExists(arguments.args, "silent") ? arguments.args.silent : false;

		// Resolve datasource
		var dbConnection = new fuse.cli.support.DatabaseConnection();
		var datasource = dbConnection.resolve(arguments.args);

		// Validate datasource
		dbConnection.validate(datasource);

		// Determine which seeder to run
		var seederName = "DatabaseSeeder";
		if (structKeyExists(arguments.args, "class") && len(arguments.args.class)) {
			seederName = arguments.args.class;

			// Convert snake_case to PascalCase using NamingConventions
			var naming = new fuse.cli.support.NamingConventions();
			seederName = naming.pascalize(seederName);
		}

		// Run seeder
		return _runSeeder(seederName, datasource, silent);
	}

	/**
	 * Run specified seeder
	 *
	 * @param seederName Name of seeder class
	 * @param datasource Datasource name
	 * @param silent Whether to suppress output
	 * @return Result struct
	 */
	private struct function _runSeeder(
		required string seederName,
		required string datasource,
		boolean silent = false
	) {
		if (!arguments.silent) {
			writeOutput("Seeding database..." & chr(10) & chr(10));
		}

		try {
			// Load seeder from database.seeds package
			var seederPath = "database.seeds." & arguments.seederName;
			var seeder = createObject("component", seederPath).init(arguments.datasource);

			// Output seeder name
			if (!arguments.silent) {
				writeOutput("  Running " & arguments.seederName & "..." & chr(10));
			}

			// Run seeder
			seeder.run();

			// Output success
			if (!arguments.silent) {
				writeOutput(chr(10) & "Database seeded successfully!" & chr(10));
			}

			return {
				success: true,
				message: "Database seeded successfully",
				seederName: arguments.seederName
			};

		} catch (any e) {
			// Handle missing seeder class
			if (findNoCase("component", e.type) > 0 || findNoCase("not found", e.message) > 0) {
				throw(
					type = "Seeder.NotFound",
					message = "Seeder not found: '#arguments.seederName#'",
					detail = "Create seeder at /database/seeds/#arguments.seederName#.cfc or use --class flag to specify a different seeder."
				);
			}

			// Re-throw other errors
			rethrow;
		}
	}

}
