component extends="testbox.system.BaseSpec" {

	function run() {
		describe("Validator component validation execution", function() {

			beforeEach(function() {
				variables.datasource = "testdb";
				validator = new fuse.orm.Validator();
			});

			it("should validate required field and return error", function() {
				var model = new tests.fixtures.User(variables.datasource);
				model.setVariablesScope("validations", {
					name: [{type: "required", options: {}}]
				});

				var errors = validator.validate(model);

				expect(errors).toHaveKey("name");
				expect(errors.name).toBeArray();
				expect(errors.name[1]).toBe("is required");
			});

			it("should validate email format and return error for invalid", function() {
				var model = new tests.fixtures.User(variables.datasource);
				model.setVariablesScope("validations", {
					email: [{type: "email", options: {}}]
				});
				model.email = "invalid-email";

				var errors = validator.validate(model);

				expect(errors).toHaveKey("email");
				expect(errors.email[1]).toBe("is not a valid email");
			});

			it("should pass validation for valid email", function() {
				var model = new tests.fixtures.User(variables.datasource);
				model.setVariablesScope("validations", {
					email: [{type: "email", options: {}}]
				});
				model.email = "test@example.com";

				var errors = validator.validate(model);

				// Check struct is empty (case-insensitive)
				expect(structCount(errors)).toBe(0);
			});

			it("should execute custom validator method and return error on false", function() {
				var model = new tests.fixtures.User(variables.datasource);
				model.setVariablesScope("validations", {
					password: [{type: "custom", options: {validator: "validatePasswordStrength"}}]
				});
				model.password = "weak";

				// Add custom validator method to model
				model.validatePasswordStrength = function(value, model) {
					return len(value) >= 8;
				};

				var errors = validator.validate(model);

				expect(errors).toHaveKey("password");
				expect(errors.password[1]).toBe("is invalid");
			});

			it("should execute custom validator closure and pass on true", function() {
				var model = new tests.fixtures.User(variables.datasource);
				var customValidator = function(value, model) {
					return len(value) >= 8;
				};
				model.setVariablesScope("validations", {
					password: [{type: "custom", options: {validator: customValidator}}]
				});
				model.password = "strongpassword123";

				var errors = validator.validate(model);

				expect(structCount(errors)).toBe(0);
			});

			it("should collect multiple errors for multiple validators on same field", function() {
				var model = new tests.fixtures.User(variables.datasource);
				model.setVariablesScope("validations", {
					email: [
						{type: "required", options: {}},
						{type: "email", options: {}}
					]
				});
				// Leave email empty - triggers both validators

				var errors = validator.validate(model);

				expect(errors).toHaveKey("email");
				expect(errors.email).toBeArray();
				expect(arrayLen(errors.email)).toBe(2);
				expect(errors.email[1]).toBe("is required");
				expect(errors.email[2]).toBe("is not a valid email");
			});

			it("should validate length constraints", function() {
				var model = new tests.fixtures.User(variables.datasource);
				model.setVariablesScope("validations", {
					name: [{type: "length", options: {min: 5, max: 20}}]
				});
				model.name = "Joe";

				var errors = validator.validate(model);

				expect(errors).toHaveKey("name");
				expect(errors.name[1]).toInclude("too short");
			});

			it("should validate numeric field", function() {
				var model = new tests.fixtures.User(variables.datasource);
				model.setVariablesScope("validations", {
					age: [{type: "numeric", options: {}}]
				});
				model.age = "not a number";

				var errors = validator.validate(model);

				expect(errors).toHaveKey("age");
				expect(errors.age[1]).toBe("must be a number");
			});

		});
	}

}
