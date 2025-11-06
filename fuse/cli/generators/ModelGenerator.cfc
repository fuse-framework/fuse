/**
 * ModelGenerator - Generate ActiveRecord model files with optional migrations
 *
 * Creates model CFCs in app/models/ and optionally generates corresponding
 * create table migrations.
 */
component {

	/**
	 * Generate a model file and optional migration
	 *
	 * @param name Model name (e.g., "User", "BlogPost")
	 * @param attributes Array of attribute strings (e.g., ["name:string", "email:string:unique"])
	 * @param options Generation options struct
	 * @return Struct with success, modelPath, and optional migrationPath
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
		var noMigration = structKeyExists(arguments.options, "noMigration") ? arguments.options.noMigration : false;
		var noTimestamps = structKeyExists(arguments.options, "noTimestamps") ? arguments.options.noTimestamps : false;
		var force = structKeyExists(arguments.options, "force") ? arguments.options.force : false;

		// Validate model name
		if (!naming.isValidIdentifier(arguments.name)) {
			throw(
				type = "InvalidModelName",
				message = "Invalid model name: '#arguments.name#'",
				detail = "Model names must start with letter, alphanumeric + underscore only"
			);
		}

		// Pascalize model name and determine table name
		var componentName = naming.pascalize(arguments.name);
		var tableName = naming.tableize(componentName);

		// Parse attributes and detect relationships
		var parsedAttributes = [];
		var relationships = [];

		for (var attr in arguments.attributes) {
			var parsed = parser.parse(attr);
			arrayAppend(parsedAttributes, parsed);

			if (parsed.isReference) {
				arrayAppend(relationships, "// belongsTo :" & parsed.referenceName);
			}
		}

		// Build relationship comments
		var relationshipsStr = "";
		if (arrayLen(relationships) > 0) {
			relationshipsStr = arrayToList(relationships, chr(10) & "		");
		}

		// Build validation placeholders
		var validationsStr = "// Add validations here";

		// Render model template using absolute path
		var templatePath = expandPath("/fuse/cli/templates/app/model.cfc.tmpl");
		var modelContent = templateEngine.render(
			templatePath,
			{
				componentName: componentName,
				tableName: tableName,
				relationships: relationshipsStr,
				validations: validationsStr
			}
		);

		// Write model file
		var modelPath = basePath & "app/models/" & componentName & ".cfc";
		var fileResult = fileGenerator.createFile(modelPath, modelContent, force);

		if (!fileResult.success) {
			return fileResult;
		}

		var result = {
			success: true,
			message: "Model created: " & modelPath,
			modelPath: modelPath,
			migrationGenerated: false
		};

		// Generate migration if requested
		if (!noMigration) {
			var migrationGenerator = new fuse.cli.generators.MigrationGenerator();

			var migrationOptions = {
				basePath: basePath,
				force: force,
				noTimestamps: noTimestamps
			};

			var migrationResult = migrationGenerator.generate(
				name = "Create" & naming.pluralize(componentName),
				attributes = arguments.attributes,
				options = migrationOptions
			);

			if (migrationResult.success) {
				result.migrationGenerated = true;
				result.migrationPath = migrationResult.migrationPath;
				result.message &= chr(10) & migrationResult.message;
			}
		}

		return result;
	}

}
