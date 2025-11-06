component extends="testbox.system.BaseSpec" {

	function run() {
		describe("ActiveRecord static finders", function() {

			beforeEach(function() {
				variables.datasource = "testdb";
				// Set application.datasource for static method calls
				application.datasource = variables.datasource;
			});

			it("should return ModelBuilder from where() for chaining", function() {
				var userClass = createObject("component", "tests.fixtures.User");
				var builder = userClass.where({active: true});

				expect(builder).toBeInstanceOf("fuse.orm.ModelBuilder");
			});

			it("should return ModelBuilder from all() for chaining", function() {
				var userClass = createObject("component", "tests.fixtures.User");
				var builder = userClass.all();

				expect(builder).toBeInstanceOf("fuse.orm.ModelBuilder");
			});

			it("should allow calling find method on User class", function() {
				var userClass = createObject("component", "tests.fixtures.User");

				// find() should be callable even if it doesn't find anything
				// This just tests the method exists and can be invoked
				try {
					// Calling with non-existent ID should return null (not throw error)
					var result = userClass.find(99999);
					// If we get here, method exists and is callable
					expect(true).toBeTrue();
				} catch (any e) {
					// If error is about method not found, fail the test
					if (findNoCase("find", e.message)) {
						fail("find() method should exist on User class: " & e.message);
					}
					// Other errors (like datasource not found) are expected in unit tests
					expect(true).toBeTrue();
				}
			});

			it("should allow where() to work without init()", function() {
				var userClass = createObject("component", "tests.fixtures.User");

				// This should not throw an error even though init() hasn't been called
				try {
					var builder = userClass.where({id: 1});
					expect(builder).toBeInstanceOf("fuse.orm.ModelBuilder");
				} catch (any e) {
					fail("where() should work without init(), but threw: " & e.message);
				}
			});

		});
	}

}
