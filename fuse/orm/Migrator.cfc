/**
 * Migrator - Manages database migration execution
 *
 * Discovers, tracks, and executes migrations.
 */
component {

	/**
	 * Initialize Migrator
	 *
	 * @datasource Datasource name
	 * @return Migrator instance
	 */
	public function init(required string datasource) {
		variables.datasource = arguments.datasource;
		variables.migrationsDir = expandPath("/database/migrations/");

		ensureMigrationsTable();

		return this;
	}

	/**
	 * Run pending migrations
	 *
	 * @return Struct with success and messages
	 */
	public struct function migrate() {
		var result = {success: true, messages: []};
		var allMigrations = discoverMigrations();
		var ranMigrations = getRanMigrations();
		var pending = [];

		// Filter to pending migrations
		for (var migration in allMigrations) {
			if (!arrayFind(ranMigrations, migration.version)) {
				arrayAppend(pending, migration);
			}
		}

		// Execute pending migrations
		for (var migration in pending) {
			try {
				transaction {
					var instance = createObject("component", migration.componentPath).init(variables.datasource);
					instance.up();
					queryExecute(
						"INSERT INTO schema_migrations (version) VALUES (?)",
						[migration.version],
						{datasource: variables.datasource}
					);
					arrayAppend(result.messages, "Migrated: " & migration.filename);
					transaction action="commit";
				}
			} catch (any e) {
				transaction action="rollback";
				result.success = false;

				// Provide detailed error message
				var errorMsg = "Failed: " & migration.filename;
				if (structKeyExists(e, "detail") && len(e.detail) > 0) {
					errorMsg &= " - " & e.message & " (" & e.detail & ")";
				} else {
					errorMsg &= " - " & e.message;
				}

				arrayAppend(result.messages, errorMsg);

				// Re-throw as Migration.ExecutionError for better debugging
				throw(
					type = "Migration.ExecutionError",
					message = "Migration execution failed: " & migration.filename,
					detail = "Error: " & e.message & (structKeyExists(e, "detail") ? ". Details: " & e.detail : "")
				);
			}
		}

		return result;
	}

	/**
	 * Rollback last N migrations
	 *
	 * @steps Number of migrations to rollback
	 * @return Struct with success and messages
	 */
	public struct function rollback(numeric steps = 1) {
		var result = {success: true, messages: []};
		var ranVersions = getRanMigrations();
		var allMigrations = discoverMigrations();

		// Sort descending and take N steps
		arraySort(ranVersions, "numeric", "desc");
		var toRollback = [];
		for (var i = 1; i <= min(arguments.steps, arrayLen(ranVersions)); i++) {
			arrayAppend(toRollback, ranVersions[i]);
		}

		// Execute rollbacks
		for (var version in toRollback) {
			// Find migration file
			var migration = null;
			for (var m in allMigrations) {
				if (m.version == version) {
					migration = m;
					break;
				}
			}

			if (isNull(migration)) {
				result.success = false;
				arrayAppend(result.messages, "Migration file not found for version: " & version);
				continue;
			}

			try {
				transaction {
					var instance = createObject("component", migration.componentPath).init(variables.datasource);
					instance.down();
					queryExecute(
						"DELETE FROM schema_migrations WHERE version = ?",
						[version],
						{datasource: variables.datasource}
					);
					arrayAppend(result.messages, "Rolled back: " & migration.filename);
					transaction action="commit";
				}
			} catch (any e) {
				transaction action="rollback";
				result.success = false;

				// Provide detailed error message
				var errorMsg = "Failed rollback: " & migration.filename;
				if (structKeyExists(e, "detail") && len(e.detail) > 0) {
					errorMsg &= " - " & e.message & " (" & e.detail & ")";
				} else {
					errorMsg &= " - " & e.message;
				}

				arrayAppend(result.messages, errorMsg);

				// Re-throw as Migration.ExecutionError
				throw(
					type = "Migration.ExecutionError",
					message = "Migration rollback failed: " & migration.filename,
					detail = "Error: " & e.message & (structKeyExists(e, "detail") ? ". Details: " & e.detail : "")
				);
			}
		}

		return result;
	}

	/**
	 * Get migration status
	 *
	 * @return Struct with pending and ran arrays
	 */
	public struct function status() {
		var all = discoverMigrations();
		var ran = getRanMigrations();
		var pending = [];
		var ranList = [];

		for (var migration in all) {
			if (arrayFind(ran, migration.version)) {
				arrayAppend(ranList, migration);
			} else {
				arrayAppend(pending, migration);
			}
		}

		return {
			pending: pending,
			ran: ranList
		};
	}

	/**
	 * Rollback all migrations
	 *
	 * @return Struct with success and messages
	 */
	public struct function reset() {
		var ran = getRanMigrations();
		return rollback(arrayLen(ran));
	}

	/**
	 * Reset and re-run all migrations
	 *
	 * @return Struct with success and messages
	 */
	public struct function refresh() {
		var result = {success: true, messages: []};

		var resetResult = reset();
		arrayAppend(result.messages, resetResult.messages, true);

		if (!resetResult.success) {
			result.success = false;
			return result;
		}

		var migrateResult = migrate();
		arrayAppend(result.messages, migrateResult.messages, true);
		result.success = migrateResult.success;

		return result;
	}

	// Private methods

	/**
	 * Ensure schema_migrations table exists
	 */
	private function ensureMigrationsTable() {
		try {
			queryExecute(
				"CREATE TABLE IF NOT EXISTS schema_migrations (version BIGINT PRIMARY KEY)",
				{},
				{datasource: variables.datasource}
			);
		} catch (any e) {
			// Table may already exist
		}
	}

	/**
	 * Discover migration files
	 *
	 * @return Array of migration structs
	 */
	private array function discoverMigrations() {
		var migrations = [];

		if (!directoryExists(variables.migrationsDir)) {
			return migrations;
		}

		var files = directoryList(variables.migrationsDir, false, "query", "*.cfc");

		for (var row in files) {
			var filename = row.name;
			// Extract version from filename (first 14 digits)
			var version = left(filename, 14);

			if (isNumeric(version) && len(version) == 14) {
				arrayAppend(migrations, {
					version: version,
					filename: filename,
					path: variables.migrationsDir & filename,
					componentPath: "database.migrations." & listFirst(filename, ".")
				});
			}
		}

		// Sort by version ascending
		arraySort(migrations, function(a, b) {
			return compare(a.version, b.version);
		});

		return migrations;
	}

	/**
	 * Get ran migration versions
	 *
	 * @return Array of version numbers
	 */
	private array function getRanMigrations() {
		try {
			var result = queryExecute(
				"SELECT version FROM schema_migrations ORDER BY version",
				{},
				{datasource: variables.datasource}
			);

			var versions = [];
			for (var row in result) {
				arrayAppend(versions, row.version);
			}

			return versions;
		} catch (any e) {
			return [];
		}
	}

}
