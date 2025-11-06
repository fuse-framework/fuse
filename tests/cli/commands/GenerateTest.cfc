component extends="testbox.system.BaseSpec" {

	function run() {
		describe("Generate Command", function() {

			beforeEach(function() {
				variables.generate = new fuse.cli.commands.Generate();
				variables.testDir = expandPath("/tests/tmp/generate/");

				// Clean up test directory
				if (directoryExists(variables.testDir)) {
					directoryDelete(variables.testDir, true);
				}
				directoryCreate(variables.testDir, true);
			});

			afterEach(function() {
				// Clean up
				if (directoryExists(variables.testDir)) {
					directoryDelete(variables.testDir, true);
				}
			});

			it("should dispatch to ModelGenerator for 'generate model'", function() {
				var result = variables.generate.main({
					__arguments: ["model", "User", "name:string", "email:string"],
					basePath: variables.testDir,
					noMigration: true
				});

				expect(result.success).toBeTrue();
				expect(result.message).toInclude("Model created");
				expect(fileExists(variables.testDir & "app/models/User.cfc")).toBeTrue();
			});

			it("should dispatch to HandlerGenerator for 'generate handler'", function() {
				var result = variables.generate.main({
					__arguments: ["handler", "Users"],
					basePath: variables.testDir
				});

				expect(result.success).toBeTrue();
				expect(result.message).toInclude("Handler created");
				expect(fileExists(variables.testDir & "app/handlers/Users.cfc")).toBeTrue();
			});

			it("should dispatch to MigrationGenerator for 'generate migration'", function() {
				var result = variables.generate.main({
					__arguments: ["migration", "CreatePosts", "title:string", "body:text"],
					basePath: variables.testDir
				});

				expect(result.success).toBeTrue();
				expect(result.message).toInclude("Migration created");

				// Migration file will have timestamp prefix
				var migrationFiles = directoryList(variables.testDir & "database/migrations/", false, "name", "*.cfc");
				expect(arrayLen(migrationFiles)).toBeGT(0);
			});

			it("should parse flags from __arguments array", function() {
				var result = variables.generate.main({
					__arguments: ["model", "Post", "title:string"],
					basePath: variables.testDir,
					noMigration: true,
					noTimestamps: true
				});

				expect(result.success).toBeTrue();
				expect(result.migrationGenerated).toBeFalse();
			});

			it("should handle error for unknown generator type", function() {
				expect(function() {
					variables.generate.main({
						__arguments: ["unknown", "Something"],
						basePath: variables.testDir
					});
				}).toThrow(type = "UnknownGeneratorType");
			});

			it("should validate generator type is supported", function() {
				expect(function() {
					variables.generate.main({
						__arguments: ["scaffold", "User"],
						basePath: variables.testDir
					});
				}).toThrow(type = "UnknownGeneratorType");
			});

		});
	}

}
