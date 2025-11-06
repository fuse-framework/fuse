component extends="testbox.system.BaseSpec" {

	function run() {
		describe("ActiveRecord integration workflows", function() {

			beforeEach(function() {
				variables.datasource = "testdb";
				application.datasource = variables.datasource;
			});

			it("should complete setAttribute -> getDirty workflow", function() {
				var user = new tests.fixtures.User(variables.datasource);
				user.populate({
					id: 1,
					name: "Original Name",
					email: "original@example.com"
				});

				// Verify clean state
				var dirty1 = user.getDirty();
				expect(structCount(dirty1)).toBe(0);

				// Modify attributes via setters
				user.setName("Updated Name");
				user.setEmail("updated@example.com");

				// Verify dirty tracking
				var dirty2 = user.getDirty();
				expect(dirty2).toHaveKey("name");
				expect(dirty2).toHaveKey("email");
				expect(dirty2.name).toBe("Updated Name");
				expect(dirty2.email).toBe("updated@example.com");
			});

			it("should return working model instances from all()", function() {
				var userClass = createObject("component", "tests.fixtures.User");

				// Verify all() returns ModelBuilder
				var builder = userClass.all();
				expect(builder).toBeInstanceOf("fuse.orm.ModelBuilder");
			});

			it("should handle attribute updates via update workflow", function() {
				var user = new tests.fixtures.User(variables.datasource);
				user.populate({
					id: 1,
					name: "Old Name",
					email: "old@example.com"
				});

				// Manually apply changes (simulating update without database)
				var changes = {
					name: "New Name",
					email: "new@example.com"
				};

				for (var key in changes) {
					user.getVariablesScope().attributes[key] = changes[key];
				}

				// Verify changes applied
				expect(user.getName()).toBe("New Name");
				expect(user.getEmail()).toBe("new@example.com");
			});

			it("should track dirty state across multiple changes", function() {
				var user = new tests.fixtures.User(variables.datasource);
				user.populate({
					id: 1,
					name: "Original",
					email: "original@example.com"
				});

				// Initially clean
				var dirty1 = user.getDirty();
				expect(structCount(dirty1)).toBe(0);

				// Make first change
				user.setName("Changed");
				var dirty2 = user.getDirty();
				expect(dirty2).toHaveKey("name");
				expect(dirty2.name).toBe("Changed");

				// Make second change
				user.setEmail("changed@example.com");
				var dirty3 = user.getDirty();
				expect(dirty3).toHaveKey("name");
				expect(dirty3).toHaveKey("email");
				expect(structCount(dirty3)).toBe(2);
			});

			it("should chain multiple setter calls", function() {
				var user = new tests.fixtures.User(variables.datasource);

				// Test method chaining
				var result = user
					.setName("John Doe")
					.setEmail("john@example.com");

				// Should return same instance
				expect(result).toBe(user);

				// Verify values were set
				expect(user.getName()).toBe("John Doe");
				expect(user.getEmail()).toBe("john@example.com");
			});

			it("should integrate static where() with builder", function() {
				var userClass = createObject("component", "tests.fixtures.User");

				// where() should return builder that can chain
				var builder = userClass.where({active: true});
				expect(builder).toBeInstanceOf("fuse.orm.ModelBuilder");

				// Builder should be chainable
				var builder2 = builder.where({role: "admin"});
				expect(builder2).toBeInstanceOf("fuse.orm.ModelBuilder");
			});

			it("should populate with various data types", function() {
				var user = new tests.fixtures.User(variables.datasource);

				// Populate with mixed data types
				user.populate({
					id: 1,
					name: "John Doe",
					age: 30,
					active: true,
					created_at: now()
				});

				// Verify all types stored correctly
				expect(user.getId()).toBe(1);
				expect(user.getName()).toBe("John Doe");
				expect(user.getAge()).toBe(30);
				expect(user.getActive()).toBeTrue();
				expect(user.getCreated_at()).toBeDate();

				// Verify isPersisted flag
				var scope = user.getVariablesScope();
				expect(scope.isPersisted).toBeTrue();
			});

			it("should handle getter/setter for various attribute names", function() {
				var user = new tests.fixtures.User(variables.datasource);

				// Test various attribute patterns
				user.setFirstName("John");
				user.setLastName("Doe");
				user.setEmailAddress("john.doe@example.com");

				expect(user.getFirstName()).toBe("John");
				expect(user.getLastName()).toBe("Doe");
				expect(user.getEmailAddress()).toBe("john.doe@example.com");
			});

		});
	}

}
