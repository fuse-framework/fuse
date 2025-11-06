component extends="testbox.system.BaseSpec" {

	function run() {
		describe("TemplateEngine utility", function() {

			beforeEach(function() {
				variables.engine = new fuse.cli.support.TemplateEngine();
				variables.tempDir = getTempDirectory() & "template_test_" & createUUID() & "/";
				directoryCreate(variables.tempDir);
			});

			afterEach(function() {
				if (directoryExists(variables.tempDir)) {
					directoryDelete(variables.tempDir, true);
				}
			});

			it("should replace single variable in template", function() {
				var template = "Hello {{name}}!";
				var result = variables.engine.renderString(template, {name: "World"});

				expect(result).toBe("Hello World!");
			});

			it("should replace multiple variables in template", function() {
				var template = "{{greeting}} {{name}}, welcome to {{place}}!";
				var result = variables.engine.renderString(template, {
					greeting: "Hello",
					name: "John",
					place: "Fuse"
				});

				expect(result).toBe("Hello John, welcome to Fuse!");
			});

			it("should leave missing variables unchanged", function() {
				var template = "Hello {{name}}, {{missing}} variable";
				var result = variables.engine.renderString(template, {name: "World"});

				expect(result).toBe("Hello World, {{missing}} variable");
			});

			it("should load and render template from file", function() {
				var templatePath = variables.tempDir & "test.tmpl";
				fileWrite(templatePath, "Component: {{componentName}}");

				var result = variables.engine.render(templatePath, {componentName: "User"});

				expect(result).toBe("Component: User");
			});

			it("should handle template with CFML-like syntax", function() {
				var template = "component name='{{name}}' {##LF##	function init() {##LF##		return this;##LF##	}##LF##}";
				var result = variables.engine.renderString(template, {name: "TestComponent"});

				expect(result).toInclude("component name='TestComponent'");
			});

			it("should support template override from config directory", function() {
				// Create framework template
				var frameworkTemplateDir = variables.tempDir & "fuse/cli/templates/";
				directoryCreate(frameworkTemplateDir, true);
				fileWrite(frameworkTemplateDir & "test.tmpl", "Framework: {{value}}");

				// Create override template
				var configTemplateDir = variables.tempDir & "config/templates/";
				directoryCreate(configTemplateDir, true);
				fileWrite(configTemplateDir & "test.tmpl", "Custom: {{value}}");

				// Set base path for testing
				variables.engine.setBasePath(variables.tempDir);

				var result = variables.engine.render("test.tmpl", {value: "Override"});

				expect(result).toBe("Custom: Override");
			});

		});
	}

}
