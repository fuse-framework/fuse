/**
 * MigrationGenerator - Generate database migration files
 *
 * Creates migration CFCs in database/migrations/ with automatic
 * pattern detection for Create/Add/Remove operations.
 */
component {

	/**
	 * Generate a migration file
	 *
	 * @param name Migration name (e.g., "CreateUsers", "AddEmailToUsers")
	 * @param attributes Array of attribute strings
	 * @param options Generation options struct
	 * @return Struct with success, migrationPath
	 */
	public struct function generate(
		required string name,
		array attributes = [],
		struct options = {}
	) {
		// Initialize utilities
		var naming = new fuse.cli.support.NamingConventions();
		var parser = new fuse.cli.support.AttributeParser();
		var templateEngine = new fuse.cli.support.TemplateEngine();
		var fileGenerator = new fuse.cli.support.FileGenerator();

		// Set defaults
		var basePath = structKeyExists(arguments.options, "basePath") ? arguments.options.basePath : expandPath("/");
		var noTimestamps = structKeyExists(arguments.options, "noTimestamps") ? arguments.options.noTimestamps : false;
		var force = structKeyExists(arguments.options, "force") ? arguments.options.force : false;
		var tableOverride = structKeyExists(arguments.options, "table") ? arguments.options.table : "";

		// Generate timestamp
		var timestamp = dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss");

		// Detect migration type and extract table name
		var migrationType = _detectMigrationType(arguments.name);
		var tableName = _extractTableName(arguments.name, migrationType, naming);

		// Override table name if provided
		if (len(tableOverride) > 0) {
			tableName = tableOverride;
		}

		// Parse attributes and build column definitions
		var columns = _buildColumnDefinitions(arguments.attributes, parser);

		// Determine which template to use
		var templatePath = "";
		var timestampsStr = "";

		if (migrationType == "create") {
			templatePath = expandPath("/fuse/cli/templates/app/create_migration.cfc.tmpl");
			// Add timestamps unless --no-timestamps
			timestampsStr = noTimestamps ? "" : "table.timestamps();";
		} else {
			templatePath = expandPath("/fuse/cli/templates/app/alter_migration.cfc.tmpl");
		}

		// Render migration template
		var migrationContent = templateEngine.render(
			templatePath,
			{
				migrationName: arguments.name,
				tableName: tableName,
				columns: columns,
				timestamps: timestampsStr
			}
		);

		// Write migration file
		var migrationPath = basePath & "database/migrations/" & timestamp & "_" & arguments.name & ".cfc";
		var fileResult = fileGenerator.createFile(migrationPath, migrationContent, force);

		if (!fileResult.success) {
			return fileResult;
		}

		return {
			success: true,
			message: "Migration created: " & migrationPath,
			migrationPath: migrationPath
		};
	}

	/**
	 * Detect migration type from name pattern
	 *
	 * @param name Migration name
	 * @return Migration type: "create", "add", or "remove"
	 */
	private string function _detectMigrationType(required string name) {
		if (reFind("^Create", arguments.name)) {
			return "create";
		} else if (reFind("^Add\w+To", arguments.name)) {
			return "add";
		} else if (reFind("^Remove\w+From", arguments.name)) {
			return "remove";
		}

		// Default to alter
		return "add";
	}

	/**
	 * Extract table name from migration name
	 * Migration names should already contain plural table names (e.g., CreateUsers, not CreateUser)
	 *
	 * @param name Migration name
	 * @param type Migration type
	 * @param naming NamingConventions instance
	 * @return Table name in snake_case
	 */
	private string function _extractTableName(required string name, required string type, required any naming) {
		if (arguments.type == "create") {
			// CreateUsers -> Users -> users (just snake_case, don't pluralize)
			var tableName = reReplace(arguments.name, "^Create", "");
			return lCase(_toSnakeCase(tableName));
		} else if (arguments.type == "add") {
			// AddEmailToUsers -> Users -> users
			var parts = reFind("To(\w+)$", arguments.name, 1, true);
			if (parts.pos[2] > 0) {
				var tableName = mid(arguments.name, parts.pos[2], parts.len[2]);
				return lCase(_toSnakeCase(tableName));
			}
		} else if (arguments.type == "remove") {
			// RemovePhoneFromUsers -> Users -> users
			var parts = reFind("From(\w+)$", arguments.name, 1, true);
			if (parts.pos[2] > 0) {
				var tableName = mid(arguments.name, parts.pos[2], parts.len[2]);
				return lCase(_toSnakeCase(tableName));
			}
		}

		return "unknown";
	}

	/**
	 * Convert PascalCase to snake_case (without pluralizing)
	 *
	 * @param word The word to convert
	 * @return Snake case form
	 */
	private string function _toSnakeCase(required string word) {
		// Insert underscore before uppercase letters (except first character)
		var result = reReplace(arguments.word, "([A-Z])", "_\1", "all");

		// Remove leading underscore if present
		if (left(result, 1) == "_") {
			result = right(result, len(result) - 1);
		}

		return lCase(result);
	}

	/**
	 * Build column definition strings for migration
	 *
	 * @param attributes Array of attribute strings
	 * @param parser AttributeParser instance
	 * @return String of column definitions
	 */
	private string function _buildColumnDefinitions(required array attributes, required any parser) {
		var columnDefs = [];

		for (var attr in arguments.attributes) {
			var parsed = arguments.parser.parse(attr);
			var columnDef = _buildSingleColumnDef(parsed);
			arrayAppend(columnDefs, columnDef);
		}

		if (arrayLen(columnDefs) == 0) {
			return "";
		}

		return arrayToList(columnDefs, chr(10) & "			");
	}

	/**
	 * Build a single column definition string
	 *
	 * @param parsed Parsed attribute struct
	 * @return Column definition string
	 */
	private string function _buildSingleColumnDef(required struct parsed) {
		var def = 'table.' & arguments.parsed.type & '("' & arguments.parsed.name & '")';

		// Add modifiers
		for (var modifier in arguments.parsed.modifiers) {
			if (modifier == "unique") {
				def &= ".unique()";
			} else if (modifier == "index") {
				def &= ".index()";
			} else if (modifier == "notnull") {
				def &= ".notNull()";
			} else if (left(modifier, 8) == "default:") {
				var defaultValue = right(modifier, len(modifier) - 8);
				// Quote string defaults
				if (arguments.parsed.type == "string" || arguments.parsed.type == "text") {
					def &= '.default("' & defaultValue & '")';
				} else {
					def &= '.default(' & defaultValue & ')';
				}
			}
		}

		def &= ";";
		return def;
	}

}
