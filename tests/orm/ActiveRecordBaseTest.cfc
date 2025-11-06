component extends="testbox.system.BaseSpec" {

	function run() {
		describe("ActiveRecord base class initialization", function() {

			beforeEach(function() {
				// Create mock datasource name
				variables.datasource = "testdb";
			});

			it("should store datasource reference from init", function() {
				var user = new tests.fixtures.User(variables.datasource);

				// Access private variables scope via getVariablesScope (TestBox utility)
				var scope = user.getVariablesScope();
				expect(scope).toHaveKey("datasource");
				expect(scope.datasource).toBe(variables.datasource);
			});

			it("should default table name to plural of component name", function() {
				var user = new tests.fixtures.User(variables.datasource);

				var scope = user.getVariablesScope();
				expect(scope).toHaveKey("tableName");
				expect(scope.tableName).toBe("users");
			});

			it("should respect this.tableName override", function() {
				var person = new tests.fixtures.Person(variables.datasource);

				var scope = person.getVariablesScope();
				expect(scope).toHaveKey("tableName");
				expect(scope.tableName).toBe("people");
			});

			it("should default primary key to id", function() {
				var user = new tests.fixtures.User(variables.datasource);

				var scope = user.getVariablesScope();
				expect(scope).toHaveKey("primaryKey");
				expect(scope.primaryKey).toBe("id");
			});

			it("should respect this.primaryKey override", function() {
				var legacy = new tests.fixtures.LegacyUser(variables.datasource);

				var scope = legacy.getVariablesScope();
				expect(scope).toHaveKey("primaryKey");
				expect(scope.primaryKey).toBe("user_id");
			});

			it("should initialize attribute storage structs", function() {
				var user = new tests.fixtures.User(variables.datasource);

				var scope = user.getVariablesScope();
				expect(scope).toHaveKey("attributes");
				expect(scope.attributes).toBeStruct();
				expect(scope).toHaveKey("original");
				expect(scope.original).toBeStruct();
				expect(scope).toHaveKey("isPersisted");
				expect(scope.isPersisted).toBeFalse();
			});

		});
	}

}
