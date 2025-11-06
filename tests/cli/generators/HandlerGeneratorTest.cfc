component extends="testbox.system.BaseSpec" {

	function run() {
		describe("HandlerGenerator", function() {

			beforeEach(function() {
				variables.generator = new fuse.cli.generators.HandlerGenerator();
				variables.testDir = expandPath("/tests/tmp/handlers/");

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

			it("should generate full RESTful handler by default", function() {
				var result = variables.generator.generate(
					name = "Users",
					options = {
						basePath: expandPath("/tests/tmp/")
					}
				);

				expect(result.success).toBeTrue();
				expect(result.handlerPath).toInclude("Users.cfc");
				expect(fileExists(result.handlerPath)).toBeTrue();

				var content = fileRead(result.handlerPath);
				expect(content).toInclude("function index()");
				expect(content).toInclude("function show(");
				expect(content).toInclude("function new()");
				expect(content).toInclude("function create()");
				expect(content).toInclude("function edit(");
				expect(content).toInclude("function update(");
				expect(content).toInclude("function destroy(");
			});

			it("should generate API-only handler with --api flag", function() {
				var result = variables.generator.generate(
					name = "Posts",
					options = {
						basePath: expandPath("/tests/tmp/"),
						api: true
					}
				);

				expect(result.success).toBeTrue();

				var content = fileRead(result.handlerPath);
				expect(content).toInclude("function index()");
				expect(content).toInclude("function show(");
				expect(content).toInclude("function create()");
				expect(content).toInclude("function update(");
				expect(content).toInclude("function destroy(");

				// Should NOT include form actions
				expect(content).notToInclude("function new()");
				expect(content).notToInclude("function edit(");
			});

			it("should generate specific actions with --actions flag", function() {
				var result = variables.generator.generate(
					name = "Articles",
					options = {
						basePath: expandPath("/tests/tmp/"),
						actions: "index,show,create"
					}
				);

				expect(result.success).toBeTrue();

				var content = fileRead(result.handlerPath);
				expect(content).toInclude("function index()");
				expect(content).toInclude("function show(");
				expect(content).toInclude("function create()");

				// Should NOT include other actions
				expect(content).notToInclude("function new()");
				expect(content).notToInclude("function edit(");
				expect(content).notToInclude("function update(");
				expect(content).notToInclude("function destroy(");
			});

			it("should support namespace syntax with nested directories", function() {
				var result = variables.generator.generate(
					name = "Api/V1/Users",
					options = {
						basePath: expandPath("/tests/tmp/")
					}
				);

				expect(result.success).toBeTrue();
				expect(result.handlerPath).toInclude("Api/V1/Users.cfc");
				expect(fileExists(result.handlerPath)).toBeTrue();

				// Verify nested directory was created
				var apiV1Dir = expandPath("/tests/tmp/app/handlers/Api/V1/");
				expect(directoryExists(apiV1Dir)).toBeTrue();
			});

			it("should include JSDoc comments for actions", function() {
				var result = variables.generator.generate(
					name = "Comments",
					options = {
						basePath: expandPath("/tests/tmp/")
					}
				);

				expect(result.success).toBeTrue();

				var content = fileRead(result.handlerPath);
				// Check for JSDoc-style comments
				expect(content).toInclude("/**");
				expect(content).toInclude("* List all");
				expect(content).toInclude("@return");
			});

		});
	}

}
