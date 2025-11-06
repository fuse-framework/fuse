component extends="testbox.system.BaseSpec" {

	function run() {
		describe("FileGenerator utility", function() {

			beforeEach(function() {
				variables.generator = new fuse.cli.support.FileGenerator();
				variables.tempDir = getTempDirectory() & "filegen_test_" & createUUID() & "/";
				directoryCreate(variables.tempDir);
			});

			afterEach(function() {
				if (directoryExists(variables.tempDir)) {
					directoryDelete(variables.tempDir, true);
				}
			});

			it("should create file with content", function() {
				var filePath = variables.tempDir & "test.cfc";
				var content = "component { }";

				var result = variables.generator.createFile(filePath, content);

				expect(fileExists(filePath)).toBeTrue();
				expect(fileRead(filePath)).toBe(content);
				expect(result.success).toBeTrue();
			});

			it("should create parent directories if they dont exist", function() {
				var filePath = variables.tempDir & "app/models/User.cfc";
				var content = "component extends='fuse.orm.ActiveRecord' { }";

				var result = variables.generator.createFile(filePath, content);

				expect(fileExists(filePath)).toBeTrue();
				expect(directoryExists(variables.tempDir & "app/models/")).toBeTrue();
			});

			it("should throw error if file exists without force flag", function() {
				var filePath = variables.tempDir & "existing.cfc";
				fileWrite(filePath, "component { }");

				expect(function() {
					variables.generator.createFile(filePath, "component extends='base' { }", false);
				}).toThrow();

				// Original content should be unchanged
				expect(fileRead(filePath)).toBe("component { }");
			});

			it("should overwrite file when force flag is true", function() {
				var filePath = variables.tempDir & "existing.cfc";
				fileWrite(filePath, "component { }");

				var result = variables.generator.createFile(filePath, "component extends='updated' { }", true);

				expect(result.success).toBeTrue();
				expect(fileRead(filePath)).toBe("component extends='updated' { }");
			});

			it("should use LF line endings consistently", function() {
				var filePath = variables.tempDir & "test.cfc";
				var content = "component {" & chr(13) & chr(10) & "function init() {}" & chr(13) & "}";

				variables.generator.createFile(filePath, content);

				var fileContent = fileRead(filePath);
				// Should not contain CR (chr(13))
				expect(find(chr(13), fileContent)).toBe(0);
				// Should contain LF (chr(10))
				expect(find(chr(10), fileContent)).toBeGT(0);
			});

			it("should return error result for invalid paths", function() {
				// Try to write to a directory path instead of file
				var result = variables.generator.createFile("/dev/null/invalid/path.txt", "content");

				expect(result.success).toBeFalse();
				expect(result.message).toInclude("error");
			});

		});
	}

}
