component extends="testbox.system.BaseSpec" {

	function run() {
		describe("ModelGenerator", function() {

			beforeEach(function() {
				variables.generator = new fuse.cli.generators.ModelGenerator();
				variables.testDir = expandPath("/tests/tmp/models/");

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

			it("should generate basic model file", function() {
				var result = variables.generator.generate(
					name = "User",
					attributes = ["name:string", "email:string"],
					options = {
						basePath: expandPath("/tests/tmp/"),
						noMigration: true
					}
				);

				expect(result.success).toBeTrue();
				expect(result.modelPath).toInclude("User.cfc");
				expect(fileExists(result.modelPath)).toBeTrue();

				var content = fileRead(result.modelPath);
				expect(content).toInclude("User Model");
				expect(content).toInclude('extends="fuse.orm.ActiveRecord"');
			});

			it("should auto-generate migration by default", function() {
				var result = variables.generator.generate(
					name = "Post",
					attributes = ["title:string", "body:text"],
					options = {
						basePath: expandPath("/tests/tmp/"),
						noMigration: false
					}
				);

				expect(result.success).toBeTrue();
				expect(result.migrationGenerated).toBeTrue();
				expect(result.migrationPath).toInclude("_CreatePosts.cfc");
			});

			it("should respect --no-migration flag", function() {
				var result = variables.generator.generate(
					name = "Article",
					attributes = ["title:string"],
					options = {
						basePath: expandPath("/tests/tmp/"),
						noMigration: true
					}
				);

				expect(result.success).toBeTrue();
				expect(result.migrationGenerated).toBeFalse();
				expect(structKeyExists(result, "migrationPath")).toBeFalse();
			});

			it("should handle references attributes", function() {
				var result = variables.generator.generate(
					name = "Comment",
					attributes = ["body:text", "user:references", "post:references"],
					options = {
						basePath: expandPath("/tests/tmp/"),
						noMigration: true
					}
				);

				expect(result.success).toBeTrue();

				var content = fileRead(result.modelPath);
				expect(content).toInclude("// belongsTo :user");
				expect(content).toInclude("// belongsTo :post");
			});

			it("should pass timestamps option to migration", function() {
				var result = variables.generator.generate(
					name = "Tag",
					attributes = ["name:string"],
					options = {
						basePath: expandPath("/tests/tmp/"),
						noMigration: false,
						noTimestamps: true
					}
				);

				expect(result.success).toBeTrue();
				expect(result.migrationGenerated).toBeTrue();

				// Verify migration was created without timestamps
				var migrationContent = fileRead(result.migrationPath);
				expect(migrationContent).notToInclude("table.timestamps()");
			});

		});
	}

}
