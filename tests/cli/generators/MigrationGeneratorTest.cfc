component extends="testbox.system.BaseSpec" {

	function run() {
		describe("MigrationGenerator", function() {

			beforeEach(function() {
				variables.generator = new fuse.cli.generators.MigrationGenerator();
				variables.testDir = expandPath("/tests/tmp/migrations/");

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

			it("should detect CreateTable pattern", function() {
				var result = variables.generator.generate(
					name = "CreateUsers",
					attributes = ["name:string", "email:string"],
					options = {
						basePath: expandPath("/tests/tmp/")
					}
				);

				expect(result.success).toBeTrue();
				expect(result.migrationPath).toInclude("_CreateUsers.cfc");

				var content = fileRead(result.migrationPath);
				expect(content).toInclude('schema.create("users"');
				expect(content).toInclude('schema.drop("users")');
			});

			it("should detect AddColumnToTable pattern", function() {
				var result = variables.generator.generate(
					name = "AddEmailToUsers",
					attributes = ["email:string:unique"],
					options = {
						basePath: expandPath("/tests/tmp/")
					}
				);

				expect(result.success).toBeTrue();
				expect(result.migrationPath).toInclude("_AddEmailToUsers.cfc");

				var content = fileRead(result.migrationPath);
				expect(content).toInclude('schema.table("users"');
				expect(content).toInclude('table.string("email")');
			});

			it("should detect RemoveColumnFromTable pattern", function() {
				var result = variables.generator.generate(
					name = "RemovePhoneFromUsers",
					attributes = ["phone:string"],
					options = {
						basePath: expandPath("/tests/tmp/")
					}
				);

				expect(result.success).toBeTrue();

				var content = fileRead(result.migrationPath);
				expect(content).toInclude("Remove phone from users");
			});

			it("should generate timestamp in correct format", function() {
				var result = variables.generator.generate(
					name = "CreatePosts",
					attributes = [],
					options = {
						basePath: expandPath("/tests/tmp/")
					}
				);

				expect(result.success).toBeTrue();

				// Verify timestamp format: YYYYMMDDHHMMSS
				var filename = getFileFromPath(result.migrationPath);
				var timestamp = listFirst(filename, "_");
				expect(len(timestamp)).toBe(14);
				expect(isNumeric(timestamp)).toBeTrue();
			});

			it("should respect --table override flag", function() {
				var result = variables.generator.generate(
					name = "CreateCustomTable",
					attributes = ["name:string"],
					options = {
						basePath: expandPath("/tests/tmp/"),
						table: "my_custom_table"
					}
				);

				expect(result.success).toBeTrue();

				var content = fileRead(result.migrationPath);
				expect(content).toInclude('schema.create("my_custom_table"');
			});

			it("should exclude timestamps when --no-timestamps flag is set", function() {
				var result = variables.generator.generate(
					name = "CreateProducts",
					attributes = ["name:string"],
					options = {
						basePath: expandPath("/tests/tmp/"),
						noTimestamps: true
					}
				);

				expect(result.success).toBeTrue();

				var content = fileRead(result.migrationPath);
				expect(content).notToInclude("table.timestamps()");
			});

		});
	}

}
