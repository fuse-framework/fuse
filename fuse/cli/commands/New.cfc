/**
 * New Command - Scaffold new Fuse applications
 *
 * Creates complete application structure with all directories,
 * configuration files, and initial setup.
 */
component {

	/**
	 * Main command entry point
	 *
	 * @param args Arguments struct with __arguments array and flags
	 * @return Struct with success, message, and generation data
	 */
	public struct function main(required struct args) {
		// Parse arguments
		var argumentsArray = structKeyExists(arguments.args, "__arguments") ? arguments.args.__arguments : [];

		// Validate we have an app name
		if (arrayLen(argumentsArray) == 0) {
			throw(
				type = "InvalidArguments",
				message = "Missing application name",
				detail = "Usage: new <app-name> [flags]" & chr(10) & "Example: new my-blog-app"
			);
		}

		var appName = argumentsArray[1];
		var basePath = structKeyExists(arguments.args, "basePath") ? arguments.args.basePath : expandPath("./");
		var database = structKeyExists(arguments.args, "database") ? arguments.args.database : "mysql";
		var noGit = structKeyExists(arguments.args, "noGit") ? arguments.args.noGit : false;
		var silent = structKeyExists(arguments.args, "silent") ? arguments.args.silent : false;

		// Validate app name using NamingConventions
		var naming = new fuse.cli.support.NamingConventions();
		if (!naming.isValidIdentifier(appName)) {
			throw(
				type = "InvalidName",
				message = "Invalid application name: '#appName#'",
				detail = "Application names must start with letter, alphanumeric + underscore only"
			);
		}

		// Validate database type
		if (!_isValidDatabaseType(database)) {
			throw(
				type = "InvalidDatabase",
				message = "Invalid database type: '#database#'",
				detail = "Supported types: mysql, postgresql, sqlserver, h2"
			);
		}

		// Create app root directory
		var appPath = basePath & appName & "/";
		if (directoryExists(appPath)) {
			throw(
				type = "DirectoryExists",
				message = "Directory already exists: '#appPath#'",
				detail = "Please choose a different application name or remove the existing directory"
			);
		}

		// Track created items for output
		var created = [];

		try {
			// Display header
			if (!silent) {
				writeOutput("Creating new Fuse application: " & appName & chr(10) & chr(10));
			}

			// Create directory structure
			_createDirectoryStructure(appPath, created, silent);

			// Generate core files
			_generateCoreFiles(appPath, appName, database, created, silent);

			// Initialize git if not disabled
			var gitInitialized = false;
			if (!noGit) {
				gitInitialized = _initializeGit(appPath, created);
			}

			// Display success message with next steps
			if (!silent) {
				_displaySuccessMessage(appName, created);
			}

			return {
				success: true,
				message: "Application created successfully",
				appName: appName,
				appPath: appPath,
				database: database,
				gitInitialized: gitInitialized,
				filesCreated: arrayLen(created)
			};

		} catch (any e) {
			// Clean up on failure
			if (directoryExists(appPath)) {
				directoryDelete(appPath, true);
			}
			rethrow;
		}
	}

	/**
	 * Create complete directory structure
	 *
	 * @param appPath Root application path
	 * @param created Array to track created items
	 * @param silent Whether to suppress output
	 */
	private void function _createDirectoryStructure(
		required string appPath,
		required array created,
		boolean silent = false
	) {
		var directories = [
			"app/models/",
			"app/handlers/",
			"app/views/",
			"app/views/layouts/",
			"database/migrations/",
			"database/seeds/",
			"config/",
			"config/templates/",
			"modules/",
			"tests/fixtures/",
			"tests/integration/",
			"tests/unit/",
			"public/css/",
			"public/js/"
		];

		// Create root directory
		directoryCreate(arguments.appPath, true);
		arrayAppend(arguments.created, arguments.appPath);
		if (!arguments.silent) {
			_outputCreate(arguments.appPath);
		}

		// Create all subdirectories
		for (var dir in directories) {
			var fullPath = arguments.appPath & dir;
			directoryCreate(fullPath, true);
			arrayAppend(arguments.created, fullPath);
			if (!arguments.silent) {
				_outputCreate(fullPath);
			}

			// Add .gitkeep to empty directories
			_createGitkeep(fullPath, arguments.created);
		}
	}

	/**
	 * Generate core configuration and setup files
	 *
	 * @param appPath Root application path
	 * @param appName Application name
	 * @param database Database type
	 * @param created Array to track created items
	 * @param silent Whether to suppress output
	 */
	private void function _generateCoreFiles(
		required string appPath,
		required string appName,
		required string database,
		required array created,
		boolean silent = false
	) {
		var templateEngine = new fuse.cli.support.TemplateEngine();
		var fileGenerator = new fuse.cli.support.FileGenerator();

		// Prepare template variables
		var year = year(now());
		var variables = {
			appName: arguments.appName,
			datasourceName: arguments.appName,
			databaseType: arguments.database,
			year: year
		};

		// Generate Application.cfc
		var applicationContent = templateEngine.render("Application.cfc.tmpl", variables);
		fileGenerator.createFile(
			arguments.appPath & "Application.cfc",
			applicationContent,
			false
		);
		arrayAppend(arguments.created, arguments.appPath & "Application.cfc");
		if (!arguments.silent) {
			_outputCreate(arguments.appPath & "Application.cfc");
		}

		// Generate config/routes.cfc
		var routesContent = templateEngine.render("routes.cfc.tmpl", variables);
		fileGenerator.createFile(
			arguments.appPath & "config/routes.cfc",
			routesContent,
			false
		);
		arrayAppend(arguments.created, arguments.appPath & "config/routes.cfc");
		if (!arguments.silent) {
			_outputCreate(arguments.appPath & "config/routes.cfc");
		}

		// Generate config/database.cfc
		var databaseContent = templateEngine.render("database.cfc.tmpl", variables);
		fileGenerator.createFile(
			arguments.appPath & "config/database.cfc",
			databaseContent,
			false
		);
		arrayAppend(arguments.created, arguments.appPath & "config/database.cfc");
		if (!arguments.silent) {
			_outputCreate(arguments.appPath & "config/database.cfc");
		}

		// Generate README.md
		var readmeContent = templateEngine.render("README.md.tmpl", variables);
		fileGenerator.createFile(
			arguments.appPath & "README.md",
			readmeContent,
			false
		);
		arrayAppend(arguments.created, arguments.appPath & "README.md");
		if (!arguments.silent) {
			_outputCreate(arguments.appPath & "README.md");
		}

		// Generate .gitignore
		var gitignoreContent = templateEngine.render(".gitignore.tmpl", variables);
		fileGenerator.createFile(
			arguments.appPath & ".gitignore",
			gitignoreContent,
			false
		);
		arrayAppend(arguments.created, arguments.appPath & ".gitignore");
		if (!arguments.silent) {
			_outputCreate(arguments.appPath & ".gitignore");
		}

		// Generate box.json
		var boxJsonContent = templateEngine.render("box.json.tmpl", variables);
		fileGenerator.createFile(
			arguments.appPath & "box.json",
			boxJsonContent,
			false
		);
		arrayAppend(arguments.created, arguments.appPath & "box.json");
		if (!arguments.silent) {
			_outputCreate(arguments.appPath & "box.json");
		}
	}

	/**
	 * Create .gitkeep file in directory
	 *
	 * @param directoryPath Path to directory
	 * @param created Array to track created items
	 */
	private void function _createGitkeep(required string directoryPath, required array created) {
		var gitkeepPath = arguments.directoryPath & ".gitkeep";
		fileWrite(gitkeepPath, "");
		arrayAppend(arguments.created, gitkeepPath);
	}

	/**
	 * Initialize git repository
	 *
	 * @param appPath Root application path
	 * @param created Array to track created items
	 * @return True if git initialized successfully
	 */
	private boolean function _initializeGit(required string appPath, required array created) {
		try {
			// Run git init
			execute(
				name = "git",
				arguments = ["init"],
				directory = arguments.appPath,
				timeout = 10,
				variable = "gitInitOutput"
			);

			// Create initial commit
			execute(
				name = "git",
				arguments = ["add", "."],
				directory = arguments.appPath,
				timeout = 10,
				variable = "gitAddOutput"
			);

			execute(
				name = "git",
				arguments = ["commit", "-m", "Initial commit"],
				directory = arguments.appPath,
				timeout = 10,
				variable = "gitCommitOutput"
			);

			arrayAppend(arguments.created, "git initialized");
			return true;

		} catch (any e) {
			// Git initialization is optional, don't fail if it doesn't work
			return false;
		}
	}

	/**
	 * Display success message with next steps
	 *
	 * @param appName Application name
	 * @param created Array of created items
	 */
	private void function _displaySuccessMessage(required string appName, required array created) {
		writeOutput(chr(10) & "Application created successfully!" & chr(10) & chr(10));
		writeOutput("Next steps:" & chr(10));
		writeOutput("  cd " & arguments.appName & chr(10));
		writeOutput("  lucli server start" & chr(10));
		writeOutput("  lucli migrate" & chr(10));
	}

	/**
	 * Output create message for file/directory
	 *
	 * @param path Path that was created
	 */
	private void function _outputCreate(required string path) {
		// Get just the filename or directory name for display
		var displayPath = arguments.path;

		// Simple output format
		writeOutput("   create  " & displayPath & chr(10));
	}

	/**
	 * Validate if database type is supported
	 *
	 * @param type Database type
	 * @return True if valid
	 */
	private boolean function _isValidDatabaseType(required string type) {
		var validTypes = ["mysql", "postgresql", "sqlserver", "h2"];
		return arrayFind(validTypes, lCase(arguments.type)) > 0;
	}

}
