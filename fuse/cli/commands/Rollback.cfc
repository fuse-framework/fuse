/**
 * Rollback Command - Migration rollback control
 *
 * Wraps Migrator to rollback migrations with step control.
 */
component {

	/**
	 * Main command entry point
	 *
	 * @param args Arguments struct with flags
	 * @return Struct with success, message, and rollback data
	 */
	public struct function main(required struct args) {
		var silent = structKeyExists(arguments.args, "silent") ? arguments.args.silent : false;

		// Resolve datasource
		var dbConnection = new fuse.cli.support.DatabaseConnection();
		var datasource = dbConnection.resolve(arguments.args);

		// Validate datasource
		dbConnection.validate(datasource);

		// Create Migrator instance
		var migrator = new fuse.orm.Migrator(datasource);

		// Handle --all flag
		if (structKeyExists(arguments.args, "all") && arguments.args.all) {
			return _handleReset(migrator, silent);
		}

		// Get steps (default to 1)
		var steps = 1;
		if (structKeyExists(arguments.args, "steps")) {
			steps = arguments.args.steps;

			// Validate steps is positive integer
			if (!isNumeric(steps) || steps <= 0 || int(steps) != steps) {
				throw(
					type = "InvalidArguments",
					message = "Invalid steps value: '#steps#'",
					detail = "Steps must be a positive integer (e.g., --steps=1, --steps=5)"
				);
			}

			steps = int(steps);
		}

		// Handle rollback
		return _handleRollback(migrator, steps, silent);
	}

	/**
	 * Handle rollback operation
	 *
	 * @param migrator Migrator instance
	 * @param steps Number of migrations to rollback
	 * @param silent Whether to suppress output
	 * @return Result struct
	 */
	private struct function _handleRollback(required any migrator, required numeric steps, boolean silent = false) {
		if (!arguments.silent) {
			writeOutput("Rolling back " & arguments.steps & " migration" & (arguments.steps == 1 ? "" : "s") & "..." & chr(10) & chr(10));
		}

		var result = arguments.migrator.rollback(arguments.steps);

		// Output each rollback
		if (!arguments.silent) {
			for (var message in result.messages) {
				writeOutput("  " & message & chr(10));
			}
		}

		// Count migrations rolled back
		var migrationsRolledBack = arrayLen(result.messages);

		// Output summary
		if (!arguments.silent) {
			if (migrationsRolledBack > 0) {
				writeOutput(chr(10) & "Rollback complete! (" & migrationsRolledBack & " migration" & (migrationsRolledBack == 1 ? "" : "s") & ")" & chr(10));
			} else {
				writeOutput("No migrations to rollback." & chr(10));
			}
		}

		return {
			success: result.success,
			message: migrationsRolledBack > 0 ? "Rollback complete" : "No migrations to rollback",
			migrationsRolledBack: migrationsRolledBack
		};
	}

	/**
	 * Handle --all flag (reset all migrations)
	 *
	 * @param migrator Migrator instance
	 * @param silent Whether to suppress output
	 * @return Result struct
	 */
	private struct function _handleReset(required any migrator, boolean silent = false) {
		if (!arguments.silent) {
			writeOutput("Rolling back all migrations..." & chr(10) & chr(10));
		}

		var result = arguments.migrator.reset();

		// Output each rollback
		if (!arguments.silent) {
			for (var message in result.messages) {
				writeOutput("  " & message & chr(10));
			}
		}

		// Count migrations rolled back
		var migrationsRolledBack = arrayLen(result.messages);

		// Output summary
		if (!arguments.silent) {
			if (migrationsRolledBack > 0) {
				writeOutput(chr(10) & "Reset complete! (" & migrationsRolledBack & " migration" & (migrationsRolledBack == 1 ? "" : "s") & " rolled back)" & chr(10));
			} else {
				writeOutput("No migrations to reset." & chr(10));
			}
		}

		return {
			success: result.success,
			message: migrationsRolledBack > 0 ? "Reset complete" : "No migrations to reset",
			migrationsRolledBack: migrationsRolledBack
		};
	}

}
