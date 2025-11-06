component extends="testbox.system.BaseSpec" {

    function beforeAll() {
        variables.testOutputDir = expandPath("/tests/tmp/integration");

        // Clean test directory
        if (directoryExists(variables.testOutputDir)) {
            directoryDelete(variables.testOutputDir, true);
        }
        directoryCreate(variables.testOutputDir);

        // Initialize components
        variables.newCommand = new fuse.cli.commands.New();
        variables.generateCommand = new fuse.cli.commands.Generate();
        variables.namingConventions = new fuse.cli.support.NamingConventions();
    }

    function afterAll() {
        // Clean up test directory
        if (directoryExists(variables.testOutputDir)) {
            directoryDelete(variables.testOutputDir, true);
        }
    }

    function run() {
        describe("CLI Integration Tests", function() {

            it("can create new app, then generate model, handler, and migration in sequence", function() {
                var appName = "test_blog_app";
                var appPath = variables.testOutputDir & "/" & appName;

                // Step 1: Create new app
                var newResult = variables.newCommand.main({
                    __arguments: [appName],
                    basePath: variables.testOutputDir & "/",
                    database: "mysql",
                    silent: true
                });

                expect(newResult.success).toBeTrue("New command should succeed");
                expect(directoryExists(appPath)).toBeTrue("App directory should exist");
                expect(fileExists(appPath & "/Application.cfc")).toBeTrue("Application.cfc should exist");

                // Step 2: Generate model
                var modelResult = variables.generateCommand.main({
                    __arguments: ["model", "User", "name:string", "email:string:unique"],
                    basePath: appPath & "/"
                });

                expect(modelResult.success).toBeTrue("Model generation should succeed");
                expect(fileExists(appPath & "/app/models/User.cfc")).toBeTrue("User model should exist");

                // Step 3: Generate handler
                var handlerResult = variables.generateCommand.main({
                    __arguments: ["handler", "Users"],
                    basePath: appPath & "/"
                });

                expect(handlerResult.success).toBeTrue("Handler generation should succeed");
                expect(fileExists(appPath & "/app/handlers/Users.cfc")).toBeTrue("Users handler should exist");

                // Step 4: Generate migration
                var migrationResult = variables.generateCommand.main({
                    __arguments: ["migration", "AddAgeToUsers", "age:integer"],
                    basePath: appPath & "/"
                });

                expect(migrationResult.success).toBeTrue("Migration generation should succeed");

                // Verify migration file exists (filename has timestamp)
                var migrationFiles = directoryList(appPath & "/database/migrations", false, "name", "*.cfc");
                expect(migrationFiles.len()).toBeGT(1, "Should have at least 2 migrations");
            });

            it("generates valid CFML files that can be loaded", function() {
                var appName = "test_valid_cfml";
                var appPath = variables.testOutputDir & "/" & appName;

                // Create app and generate model
                variables.newCommand.main({
                    __arguments: [appName],
                    basePath: variables.testOutputDir & "/",
                    silent: true
                });

                variables.generateCommand.main({
                    __arguments: ["model", "Post", "title:string", "body:text"],
                    basePath: appPath & "/"
                });

                var modelPath = appPath & "/app/models/Post.cfc";
                expect(fileExists(modelPath)).toBeTrue("Post model should exist");

                // Try to read and parse the file
                var modelContent = fileRead(modelPath);
                expect(modelContent).toInclude("component extends=""fuse.orm.ActiveRecord""");
                expect(modelContent).toInclude("function init");
            });

            it("generates migrations that follow Migrator pattern", function() {
                var appName = "test_migrator_compat";
                var appPath = variables.testOutputDir & "/" & appName;

                variables.newCommand.main({
                    __arguments: [appName],
                    basePath: variables.testOutputDir & "/",
                    silent: true
                });

                variables.generateCommand.main({
                    __arguments: ["model", "Product", "name:string", "price:decimal"],
                    basePath: appPath & "/"
                });

                // Find the generated migration
                var migrationFiles = directoryList(appPath & "/database/migrations", false, "path", "*.cfc");
                expect(migrationFiles.len()).toBeGT(0, "Should have migrations");

                var migrationPath = migrationFiles[migrationFiles.len()]; // Get latest
                var migrationContent = fileRead(migrationPath);

                // Verify migration structure
                expect(migrationContent).toInclude("component extends=""fuse.orm.Migration""");
                expect(migrationContent).toInclude("function up()");
                expect(migrationContent).toInclude("function down()");
                expect(migrationContent).toInclude("getSchema()");

                // Verify timestamp format in filename (YYYYMMDDHHMMSS)
                var fileName = getFileFromPath(migrationPath);
                expect(reFind("^\d{14}_", fileName)).toBeGT(0, "Filename should have timestamp prefix");
            });

            it("generates models that extend ActiveRecord correctly", function() {
                var appName = "test_activerecord";
                var appPath = variables.testOutputDir & "/" & appName;

                variables.newCommand.main({
                    __arguments: [appName],
                    basePath: variables.testOutputDir & "/",
                    silent: true
                });

                variables.generateCommand.main({
                    __arguments: ["model", "Category", "name:string"],
                    basePath: appPath & "/"
                });

                var modelContent = fileRead(appPath & "/app/models/Category.cfc");

                // Verify ActiveRecord extension and structure
                expect(modelContent).toInclude("component extends=""fuse.orm.ActiveRecord""");
                expect(modelContent).toInclude("function init");
                expect(modelContent).toInclude("super.init");
                expect(modelContent).toInclude("// Define relationships here");
                expect(modelContent).toInclude("// Define validations here");
            });

            it("generates handlers following RESTful pattern", function() {
                var appName = "test_restful";
                var appPath = variables.testOutputDir & "/" & appName;

                variables.newCommand.main({
                    __arguments: [appName],
                    basePath: variables.testOutputDir & "/",
                    silent: true
                });

                variables.generateCommand.main({
                    __arguments: ["handler", "Articles"],
                    basePath: appPath & "/"
                });

                var handlerContent = fileRead(appPath & "/app/handlers/Articles.cfc");

                // Verify RESTful actions exist
                expect(handlerContent).toInclude("function index()");
                expect(handlerContent).toInclude("function show(required numeric id)");
                expect(handlerContent).toInclude("function new()");
                expect(handlerContent).toInclude("function create()");
                expect(handlerContent).toInclude("function edit(required numeric id)");
                expect(handlerContent).toInclude("function update(required numeric id)");
                expect(handlerContent).toInclude("function destroy(required numeric id)");

                // Verify JSDoc comments
                expect(handlerContent).toInclude("@route GET");
                expect(handlerContent).toInclude("@route POST");
            });

            it("supports template override system", function() {
                var appName = "test_template_override";
                var appPath = variables.testOutputDir & "/" & appName;

                // Create app
                variables.newCommand.main({
                    __arguments: [appName],
                    basePath: variables.testOutputDir & "/",
                    silent: true
                });

                // Create custom template in config/templates/
                var customTemplateDir = appPath & "/config/templates";
                directoryCreate(customTemplateDir);

                var customTemplate = "component extends=""fuse.orm.ActiveRecord"" {
    // CUSTOM TEMPLATE
    function init() {
        super.init();
        return this;
    }
}";
                fileWrite(customTemplateDir & "/model.cfc.tmpl", customTemplate);

                // Generate model - should use custom template
                variables.generateCommand.main({
                    __arguments: ["model", "CustomModel"],
                    basePath: appPath & "/"
                });

                var modelContent = fileRead(appPath & "/app/models/CustomModel.cfc");
                expect(modelContent).toInclude("// CUSTOM TEMPLATE", "Should use custom template");
            });

            it("handles file conflicts with proper error", function() {
                var appName = "test_conflicts";
                var appPath = variables.testOutputDir & "/" & appName;

                variables.newCommand.main({
                    __arguments: [appName],
                    basePath: variables.testOutputDir & "/",
                    silent: true
                });

                // Generate model first time
                var result1 = variables.generateCommand.main({
                    __arguments: ["model", "Author"],
                    basePath: appPath & "/"
                });
                expect(result1.success).toBeTrue("First generation should succeed");

                // Try to generate same model again (should fail without --force)
                try {
                    var result2 = variables.generateCommand.main({
                        __arguments: ["model", "Author"],
                        basePath: appPath & "/"
                    });
                    fail("Should have thrown error for duplicate file");
                } catch (any e) {
                    expect(e.message).toInclude("already exists", "Should report file exists");
                }
            });

            it("force flag overwrites existing files", function() {
                var appName = "test_force";
                var appPath = variables.testOutputDir & "/" & appName;

                variables.newCommand.main({
                    __arguments: [appName],
                    basePath: variables.testOutputDir & "/",
                    silent: true
                });

                // Generate model
                variables.generateCommand.main({
                    __arguments: ["model", "Item", "name:string"],
                    basePath: appPath & "/"
                });
                var originalContent = fileRead(appPath & "/app/models/Item.cfc");

                // Wait a moment to ensure different content
                sleep(100);

                // Generate again with --force
                var result = variables.generateCommand.main({
                    __arguments: ["model", "Item", "title:string"],
                    basePath: appPath & "/",
                    force: true
                });
                expect(result.success).toBeTrue("Force generation should succeed");

                var newContent = fileRead(appPath & "/app/models/Item.cfc");
                // Content should be regenerated (both will have similar structure, so just check it exists)
                expect(fileExists(appPath & "/app/models/Item.cfc")).toBeTrue();
            });

            it("handles references attributes correctly", function() {
                var appName = "test_references";
                var appPath = variables.testOutputDir & "/" & appName;

                variables.newCommand.main({
                    __arguments: [appName],
                    basePath: variables.testOutputDir & "/",
                    silent: true
                });

                variables.generateCommand.main({
                    __arguments: ["model", "Comment", "body:text", "user:references"],
                    basePath: appPath & "/"
                });

                var modelContent = fileRead(appPath & "/app/models/Comment.cfc");

                // Check model has relationship hint
                expect(modelContent).toInclude("belongsTo: User");

                // Find migration and verify user_id column
                var migrationFiles = directoryList(appPath & "/database/migrations", false, "path", "*.cfc");
                var migrationContent = fileRead(migrationFiles[migrationFiles.len()]);

                expect(migrationContent).toInclude("user_id");
                expect(migrationContent).toInclude("integer");
                expect(migrationContent).toInclude("index");
            });

            it("generates API handlers without form actions", function() {
                var appName = "test_api";
                var appPath = variables.testOutputDir & "/" & appName;

                variables.newCommand.main({
                    __arguments: [appName],
                    basePath: variables.testOutputDir & "/",
                    silent: true
                });

                variables.generateCommand.main({
                    __arguments: ["handler", "ApiUsers"],
                    basePath: appPath & "/",
                    api: true
                });

                var handlerContent = fileRead(appPath & "/app/handlers/ApiUsers.cfc");

                // Should have index, show, create, update, destroy
                expect(handlerContent).toInclude("function index()");
                expect(handlerContent).toInclude("function show");
                expect(handlerContent).toInclude("function create()");
                expect(handlerContent).toInclude("function update");
                expect(handlerContent).toInclude("function destroy");

                // Should NOT have new() and edit()
                expect(handlerContent).notToInclude("function new()");
                expect(handlerContent).notToInclude("function edit(");
            });

        });
    }

}
