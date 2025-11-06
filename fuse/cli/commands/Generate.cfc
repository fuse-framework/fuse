/**
 * Generate Command - Dispatch to specific generators
 *
 * Main CLI command for generating models, handlers, and migrations.
 * Routes to appropriate generator based on type argument.
 */
component {

	/**
	 * Main command entry point
	 *
	 * @param args Arguments struct with __arguments array and flags
	 * @return Struct with success, message, and generator-specific data
	 */
	public struct function main(required struct args) {
		// Parse arguments
		var argumentsArray = structKeyExists(arguments.args, "__arguments") ? arguments.args.__arguments : [];

		// Show help if requested
		if (arrayLen(argumentsArray) == 0 || (arrayLen(argumentsArray) > 0 && argumentsArray[1] == "help")) {
			return _showHelp();
		}

		// Extract generator type
		if (arrayLen(argumentsArray) < 2) {
			throw(
				type = "InvalidArguments",
				message = "Missing generator type or name",
				detail = "Usage: generate <type> <name> [attributes] [flags]" & chr(10) & "Run 'generate help' for more information"
			);
		}

		var generatorType = lCase(argumentsArray[1]);
		var name = argumentsArray[2];
		var attributes = [];

		// Extract attributes (everything after name that doesn't start with --)
		for (var i = 3; i <= arrayLen(argumentsArray); i++) {
			if (!left(argumentsArray[i], 2) == "--") {
				arrayAppend(attributes, argumentsArray[i]);
			}
		}

		// Parse options from args struct
		var options = _parseOptions(arguments.args);

		// Validate generator type
		if (!_isValidGeneratorType(generatorType)) {
			throw(
				type = "UnknownGeneratorType",
				message = "Unknown generator type: '#generatorType#'",
				detail = "Supported types: model, handler, migration" & chr(10) & "Run 'generate help' for more information"
			);
		}

		// Validate name is valid CFML identifier
		var naming = new fuse.cli.support.NamingConventions();
		if (!naming.isValidIdentifier(name)) {
			throw(
				type = "InvalidName",
				message = "Invalid name: '#name#'",
				detail = "Names must start with letter, alphanumeric + underscore only"
			);
		}

		// Dispatch to appropriate generator
		return _dispatch(generatorType, name, attributes, options);
	}

	/**
	 * Parse options from args struct
	 *
	 * @param args Arguments struct
	 * @return Options struct
	 */
	private struct function _parseOptions(required struct args) {
		var options = {};

		// Extract common options
		if (structKeyExists(arguments.args, "basePath")) {
			options.basePath = arguments.args.basePath;
		}
		if (structKeyExists(arguments.args, "force")) {
			options.force = arguments.args.force;
		}
		if (structKeyExists(arguments.args, "noMigration")) {
			options.noMigration = arguments.args.noMigration;
		}
		if (structKeyExists(arguments.args, "noTimestamps")) {
			options.noTimestamps = arguments.args.noTimestamps;
		}
		if (structKeyExists(arguments.args, "api")) {
			options.api = arguments.args.api;
		}
		if (structKeyExists(arguments.args, "actions")) {
			options.actions = arguments.args.actions;
		}
		if (structKeyExists(arguments.args, "table")) {
			options.table = arguments.args.table;
		}

		return options;
	}

	/**
	 * Validate if generator type is supported
	 *
	 * @param type Generator type
	 * @return True if valid
	 */
	private boolean function _isValidGeneratorType(required string type) {
		var validTypes = ["model", "handler", "migration"];
		return arrayFind(validTypes, arguments.type) > 0;
	}

	/**
	 * Dispatch to appropriate generator
	 *
	 * @param type Generator type
	 * @param name Component name
	 * @param attributes Attributes array
	 * @param options Options struct
	 * @return Generator result
	 */
	private struct function _dispatch(
		required string type,
		required string name,
		required array attributes,
		required struct options
	) {
		var result = {};

		switch (arguments.type) {
			case "model":
				var generator = new fuse.cli.generators.ModelGenerator();
				result = generator.generate(arguments.name, arguments.attributes, arguments.options);
				break;

			case "handler":
				var generator = new fuse.cli.generators.HandlerGenerator();
				result = generator.generate(arguments.name, arguments.options);
				break;

			case "migration":
				var generator = new fuse.cli.generators.MigrationGenerator();
				result = generator.generate(arguments.name, arguments.attributes, arguments.options);
				break;
		}

		return result;
	}

	/**
	 * Show help text
	 *
	 * @return Struct with success and help message
	 */
	private struct function _showHelp() {
		var help = [];
		arrayAppend(help, "Usage: generate <type> <name> [attributes] [flags]");
		arrayAppend(help, "");
		arrayAppend(help, "Generator Types:");
		arrayAppend(help, "  model       Generate ActiveRecord model with optional migration");
		arrayAppend(help, "  handler     Generate RESTful handler");
		arrayAppend(help, "  migration   Generate database migration");
		arrayAppend(help, "");
		arrayAppend(help, "Common Flags:");
		arrayAppend(help, "  --force             Overwrite existing files");
		arrayAppend(help, "  --no-migration      Skip migration generation (model only)");
		arrayAppend(help, "  --no-timestamps     Skip timestamps in migration (model/migration)");
		arrayAppend(help, "  --api               Generate API-only handler (handler only)");
		arrayAppend(help, "  --actions=list      Generate specific actions (handler only)");
		arrayAppend(help, "  --table=name        Override table name (model/migration)");
		arrayAppend(help, "");
		arrayAppend(help, "Examples:");
		arrayAppend(help, "  generate model User name:string email:string:unique");
		arrayAppend(help, "  generate model Post title:string body:text user:references");
		arrayAppend(help, "  generate model Article title:string --no-migration");
		arrayAppend(help, "");
		arrayAppend(help, "  generate handler Users");
		arrayAppend(help, "  generate handler Posts --actions=index,show,create");
		arrayAppend(help, "  generate handler Api/V1/Users --api");
		arrayAppend(help, "");
		arrayAppend(help, "  generate migration CreatePosts title:string body:text");
		arrayAppend(help, "  generate migration AddEmailToUsers email:string:unique");
		arrayAppend(help, "  generate migration RemovePhoneFromUsers phone:string");

		return {
			success: true,
			message: arrayToList(help, chr(10))
		};
	}

}
