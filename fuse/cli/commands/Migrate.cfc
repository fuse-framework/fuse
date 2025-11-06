/**
 * Migrate Command - Database migration execution
 *
 * Wraps Migrator to execute pending migrations, display status,
 * and manage migration state.
 */
component {

	/**
	 * Main command entry point
	 *
	 * @param args Arguments struct with flags
	 * @return Struct with success, message, and migration data
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

		// Handle --status flag
		if (structKeyExists(arguments.args, "status") && arguments.args.status) {
			return _handleStatus(migrator, silent);
		}

		// Handle --reset flag
		if (structKeyExists(arguments.args, "reset") && arguments.args.reset) {
			return _handleReset(migrator, silent);
		}

		// Handle --refresh flag
		if (structKeyExists(arguments.args, "refresh") && arguments.args.refresh) {
			return _handleRefresh(migrator, silent);
		}

		// Default: run pending migrations
		return _handleMigrate(migrator, silent);
	}

	/**
	 * Handle default migrate operation
	 *
	 * @param migrator Migrator instance
	 * @param silent Whether to suppress output
	 * @return Result struct
	 */
	private struct function _handleMigrate(required any migrator, boolean silent = false) {
		if (!arguments.silent) {
			writeOutput("Running pending migrations..." & chr(10) & chr(10));
		}

		var result = arguments.migrator.migrate();

		// Output each migration
		if (!arguments.silent) {
			for (var message in result.messages) {
				writeOutput("  " & message & chr(10));
			}
		}

		// Count migrations run
		var migrationsRun = arrayLen(result.messages);

		// Output summary
		if (!arguments.silent) {
			if (migrationsRun > 0) {
				writeOutput(chr(10) & "Migrations complete! (" & migrationsRun & " migration" & (migrationsRun == 1 ? "" : "s") & ")" & chr(10));
			} else {
				writeOutput("No pending migrations." & chr(10));
			}
		}

		return {
			success: result.success,
			message: migrationsRun > 0 ? "Migrations complete" : "No pending migrations",
			migrationsRun: migrationsRun
		};
	}

	/**
	 * Handle --status flag
	 *
	 * @param migrator Migrator instance
	 * @param silent Whether to suppress output
	 * @return Result struct
	 */
	private struct function _handleStatus(required any migrator, boolean silent = false) {
		var status = arguments.migrator.status();

		if (!arguments.silent) {
			writeOutput("Migration Status:" & chr(10) & chr(10));

			// Show ran migrations first
			for (var migration in status.ran) {
				writeOutput("  [" & chr(10003) & "] " & migration.filename & chr(10));
			}

			// Then show pending migrations
			for (var migration in status.pending) {
				writeOutput("  [ ] " & migration.filename & chr(10));
			}

			// Summary
			var ranCount = arrayLen(status.ran);
			var pendingCount = arrayLen(status.pending);
			writeOutput(chr(10) & ranCount & " migration" & (ranCount == 1 ? "" : "s") & " run, " & pendingCount & " pending" & chr(10));
		}

		return {
			success: true,
			message: "Migration status displayed",
			ran: arrayLen(status.ran),
			pending: arrayLen(status.pending)
		};
	}

	/**
	 * Handle --reset flag
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

	/**
	 * Handle --refresh flag
	 *
	 * @param migrator Migrator instance
	 * @param silent Whether to suppress output
	 * @return Result struct
	 */
	private struct function _handleRefresh(required any migrator, boolean silent = false) {
		if (!arguments.silent) {
			writeOutput("Refreshing migrations (reset + migrate)..." & chr(10) & chr(10));
		}

		var result = arguments.migrator.refresh();

		// Output each message
		if (!arguments.silent) {
			for (var message in result.messages) {
				writeOutput("  " & message & chr(10));
			}
		}

		// Output summary
		if (!arguments.silent) {
			writeOutput(chr(10) & "Refresh complete!" & chr(10));
		}

		return {
			success: result.success,
			message: "Refresh complete"
		};
	}

}
