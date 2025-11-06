component extends="testbox.system.BaseSpec" {

	function run() {
		describe("AttributeParser utility", function() {

			beforeEach(function() {
				variables.parser = new fuse.cli.support.AttributeParser();
			});

			it("should parse basic attribute with name and type", function() {
				var result = variables.parser.parse("name:string");

				expect(result.name).toBe("name");
				expect(result.type).toBe("string");
				expect(result.modifiers).toBeArray();
				expect(arrayLen(result.modifiers)).toBe(0);
			});

			it("should parse attribute with multiple modifiers", function() {
				var result = variables.parser.parse("email:string:unique:notnull");

				expect(result.name).toBe("email");
				expect(result.type).toBe("string");
				expect(arrayLen(result.modifiers)).toBe(2);
				expect(result.modifiers[1]).toBe("unique");
				expect(result.modifiers[2]).toBe("notnull");
			});

			it("should convert references type to integer with index", function() {
				var result = variables.parser.parse("user:references");

				expect(result.name).toBe("user_id");
				expect(result.type).toBe("integer");
				expect(arrayLen(result.modifiers)).toBe(1);
				expect(result.modifiers[1]).toBe("index");
				expect(result.isReference).toBeTrue();
				expect(result.referenceName).toBe("user");
			});

			it("should throw error for invalid attribute format", function() {
				expect(function() {
					variables.parser.parse("invalid");
				}).toThrow();

				expect(function() {
					variables.parser.parse("name:");
				}).toThrow();
			});

			it("should throw error for unknown type", function() {
				expect(function() {
					variables.parser.parse("field:invalidtype");
				}).toThrow();
			});

			it("should support all valid column types", function() {
				var types = ["string", "text", "integer", "boolean", "date", "datetime", "decimal"];

				for (var type in types) {
					var result = variables.parser.parse("field:#type#");
					expect(result.type).toBe(type);
				}
			});

		});
	}

}
