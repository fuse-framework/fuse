component extends="testbox.system.BaseSpec" {

	function run() {
		describe("New Command", function() {

			beforeEach(function() {
				variables.newCmd = new fuse.cli.commands.New();
				variables.testDir = expandPath("/tests/tmp/new/");

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

			it("should create complete directory structure", function() {
				var appName = "my-blog-app";
				var result = variables.newCmd.main({
					__arguments: [appName],
					basePath: variables.testDir,
					noGit: true,
					silent: true
				});

				expect(result.success).toBeTrue();

				// Check root directories
				var appPath = variables.testDir & appName & "/";
				expect(directoryExists(appPath & "app/models/")).toBeTrue();
				expect(directoryExists(appPath & "app/handlers/")).toBeTrue();
				expect(directoryExists(appPath & "app/views/")).toBeTrue();
				expect(directoryExists(appPath & "app/views/layouts/")).toBeTrue();
				expect(directoryExists(appPath & "database/migrations/")).toBeTrue();
				expect(directoryExists(appPath & "database/seeds/")).toBeTrue();
				expect(directoryExists(appPath & "config/")).toBeTrue();
				expect(directoryExists(appPath & "config/templates/")).toBeTrue();
				expect(directoryExists(appPath & "modules/")).toBeTrue();
				expect(directoryExists(appPath & "tests/fixtures/")).toBeTrue();
				expect(directoryExists(appPath & "tests/integration/")).toBeTrue();
				expect(directoryExists(appPath & "tests/unit/")).toBeTrue();
				expect(directoryExists(appPath & "public/css/")).toBeTrue();
				expect(directoryExists(appPath & "public/js/")).toBeTrue();
			});

			it("should generate Application.cfc with datasource config", function() {
				var appName = "testapp";
				var result = variables.newCmd.main({
					__arguments: [appName],
					basePath: variables.testDir,
					noGit: true,
					silent: true
				});

				var appPath = variables.testDir & appName & "/";
				expect(fileExists(appPath & "Application.cfc")).toBeTrue();

				var content = fileRead(appPath & "Application.cfc");
				expect(content).toInclude('this.name = "testapp"');
				expect(content).toInclude('this.datasource = "testapp"');
			});

			it("should support --database flag for mysql", function() {
				var appName = "mysqlapp";
				var result = variables.newCmd.main({
					__arguments: [appName],
					basePath: variables.testDir,
					database: "mysql",
					noGit: true,
					silent: true
				});

				var appPath = variables.testDir & appName & "/";
				var dbConfig = fileRead(appPath & "config/database.cfc");
				expect(dbConfig).toInclude('"type": "mysql"');
				expect(dbConfig).toInclude('3306');
			});

			it("should support --database flag for postgresql", function() {
				var appName = "pgapp";
				var result = variables.newCmd.main({
					__arguments: [appName],
					database: "postgresql",
					basePath: variables.testDir,
					noGit: true,
					silent: true
				});

				var appPath = variables.testDir & appName & "/";
				var dbConfig = fileRead(appPath & "config/database.cfc");
				expect(dbConfig).toInclude('"type": "postgresql"');
				expect(dbConfig).toInclude('5432');
			});

			it("should skip git initialization with --no-git flag", function() {
				var appName = "nogitapp";
				var result = variables.newCmd.main({
					__arguments: [appName],
					basePath: variables.testDir,
					noGit: true,
					silent: true
				});

				expect(result.success).toBeTrue();
				expect(result.gitInitialized).toBeFalse();
			});

			it("should validate invalid app names", function() {
				expect(function() {
					variables.newCmd.main({
						__arguments: ["123invalid"],
						basePath: variables.testDir,
						silent: true
					});
				}).toThrow(type = "InvalidName");

				expect(function() {
					variables.newCmd.main({
						__arguments: ["app-with-dashes"],
						basePath: variables.testDir,
						silent: true
					});
				}).toThrow(type = "InvalidName");
			});

		});
	}

}
