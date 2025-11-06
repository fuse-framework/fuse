component extends="testbox.system.BaseSpec" {

	function run() {
		describe("NamingConventions utility", function() {

			beforeEach(function() {
				variables.naming = new fuse.cli.support.NamingConventions();
			});

			it("should pluralize words by appending s", function() {
				expect(variables.naming.pluralize("User")).toBe("Users");
				expect(variables.naming.pluralize("Post")).toBe("Posts");
				expect(variables.naming.pluralize("Article")).toBe("Articles");
			});

			it("should singularize words by removing trailing s", function() {
				expect(variables.naming.singularize("Users")).toBe("User");
				expect(variables.naming.singularize("Posts")).toBe("Post");
				expect(variables.naming.singularize("Articles")).toBe("Article");
			});

			it("should tableize PascalCase to snake_case plural", function() {
				expect(variables.naming.tableize("BlogPost")).toBe("blog_posts");
				expect(variables.naming.tableize("User")).toBe("users");
				expect(variables.naming.tableize("ApiKey")).toBe("api_keys");
			});

			it("should pascalize snake_case to PascalCase", function() {
				expect(variables.naming.pascalize("blog_post")).toBe("BlogPost");
				expect(variables.naming.pascalize("user_profile")).toBe("UserProfile");
				expect(variables.naming.pascalize("api_key")).toBe("ApiKey");
			});

			it("should validate CFML identifiers correctly", function() {
				expect(variables.naming.isValidIdentifier("User")).toBeTrue();
				expect(variables.naming.isValidIdentifier("blog_post")).toBeTrue();
				expect(variables.naming.isValidIdentifier("User123")).toBeTrue();
				expect(variables.naming.isValidIdentifier("123User")).toBeFalse();
				expect(variables.naming.isValidIdentifier("User-Name")).toBeFalse();
				expect(variables.naming.isValidIdentifier("User Name")).toBeFalse();
			});

		});
	}

}
