component extends="testbox.system.BaseSpec" {

	function run() {
		describe("ActiveRecord instance methods", function() {

			beforeEach(function() {
				variables.datasource = "testdb";
				application.datasource = variables.datasource;
			});

			it("should populate instance from struct data", function() {
				var user = new tests.fixtures.User(variables.datasource);
				var data = {
					id: 1,
					name: "John Doe",
					email: "john@example.com"
				};

				user.populate(data);

				var scope = user.getVariablesScope();
				expect(scope.attributes).toBe(data);
				expect(scope.original).toBeStruct();
				expect(scope.isPersisted).toBeTrue();
			});

			it("should get dirty attributes after changes", function() {
				var user = new tests.fixtures.User(variables.datasource);
				user.populate({
					id: 1,
					name: "John Doe",
					email: "john@example.com"
				});

				// Make changes via explicit setter methods
				user.setName("Jane Doe");
				user.setEmail("jane@example.com");

				var dirty = user.getDirty();
				expect(dirty).toHaveKey("name");
				expect(dirty.name).toBe("Jane Doe");
				expect(dirty).toHaveKey("email");
				expect(dirty.email).toBe("jane@example.com");
				expect(dirty).notToHaveKey("id");
			});

			it("should access attributes via onMissingMethod getter", function() {
				var user = new tests.fixtures.User(variables.datasource);
				user.populate({
					id: 1,
					name: "John Doe",
					email: "john@example.com"
				});

				expect(user.getName()).toBe("John Doe");
				expect(user.getEmail()).toBe("john@example.com");
				expect(user.getId()).toBe(1);
			});

			it("should set attributes via onMissingMethod setter", function() {
				var user = new tests.fixtures.User(variables.datasource);
				user.populate({id: 1, name: "Old Name"});

				user.setName("New Name");
				user.setEmail("new@example.com");

				var scope = user.getVariablesScope();
				expect(scope.attributes.name).toBe("New Name");
				expect(scope.attributes.email).toBe("new@example.com");
			});

			it("should return empty struct when no attributes are dirty", function() {
				var user = new tests.fixtures.User(variables.datasource);
				user.populate({
					id: 1,
					name: "John Doe",
					email: "john@example.com"
				});

				var dirty = user.getDirty();
				expect(dirty).toBeStruct();
				expect(structCount(dirty)).toBe(0);
			});

			it("should support method chaining for setters", function() {
				var user = new tests.fixtures.User(variables.datasource);

				var result = user.setName("John");

				// Setter should return this for chaining
				expect(result).toBe(user);
			});

		});
	}

}
