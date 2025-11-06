/**
 * AssertionsTest - Tests for Assertions component
 *
 * Validates core assertion behaviors:
 * - Equality assertions (assertEqual, assertNotEqual)
 * - Boolean assertions (assertTrue, assertFalse)
 * - Null assertions (assertNull, assertNotNull)
 * - Exception handling (assertThrows)
 * - Collection assertions (assertCount, assertContains)
 */
component extends="testbox.system.BaseSpec" {

	function run() {
		describe("Assertions", function() {

			beforeEach(function() {
				assertions = new fuse.testing.Assertions();
			});

			// EQUALITY ASSERTIONS
			describe("assertEqual and assertNotEqual", function() {

				it("passes when values are equal", function() {
					expect(function() {
						assertions.assertEqual(5, 5);
					}).notToThrow();

					expect(function() {
						assertions.assertEqual("test", "test");
					}).notToThrow();
				});

				it("throws AssertionFailedException when values are not equal", function() {
					expect(function() {
						assertions.assertEqual(5, 10);
					}).toThrow(type = "AssertionFailedException");
				});

				it("passes when values are not equal", function() {
					expect(function() {
						assertions.assertNotEqual(5, 10);
					}).notToThrow();
				});

				it("includes custom message in failure", function() {
					try {
						assertions.assertEqual(5, 10, "Custom error message");
						fail("Should have thrown AssertionFailedException");
					} catch (any e) {
						expect(e.type).toBe("AssertionFailedException");
						expect(e.detail).toContain("Custom error message");
						expect(e.detail).toContain("Expected: 5");
						expect(e.detail).toContain("Actual: 10");
					}
				});

			});

			// BOOLEAN ASSERTIONS
			describe("assertTrue and assertFalse", function() {

				it("passes when value is true/false", function() {
					expect(function() {
						assertions.assertTrue(true);
					}).notToThrow();

					expect(function() {
						assertions.assertFalse(false);
					}).notToThrow();
				});

				it("throws when boolean assertion fails", function() {
					expect(function() {
						assertions.assertTrue(false);
					}).toThrow(type = "AssertionFailedException");

					expect(function() {
						assertions.assertFalse(true);
					}).toThrow(type = "AssertionFailedException");
				});

			});

			// NULL ASSERTIONS
			describe("assertNull and assertNotNull", function() {

				it("passes when value is null", function() {
					expect(function() {
						assertions.assertNull(javaCast("null", ""));
					}).notToThrow();
				});

				it("throws when value is not null", function() {
					expect(function() {
						assertions.assertNull("not null");
					}).toThrow(type = "AssertionFailedException");
				});

				it("passes when value is not null", function() {
					expect(function() {
						assertions.assertNotNull("value");
					}).notToThrow();
				});

			});

			// EXCEPTION ASSERTIONS
			describe("assertThrows", function() {

				it("passes when callable throws exception", function() {
					expect(function() {
						assertions.assertThrows(function() {
							throw(type="TestException", message="Test error");
						});
					}).notToThrow();
				});

				it("throws when callable does not throw", function() {
					expect(function() {
						assertions.assertThrows(function() {
							// Does nothing
						});
					}).toThrow(type = "AssertionFailedException");
				});

				it("validates specific exception type", function() {
					expect(function() {
						assertions.assertThrows(function() {
							throw(type="ValidationException", message="Test");
						}, "ValidationException");
					}).notToThrow();

					expect(function() {
						assertions.assertThrows(function() {
							throw(type="WrongException", message="Test");
						}, "ValidationException");
					}).toThrow(type = "AssertionFailedException");
				});

			});

			// COLLECTION ASSERTIONS
			describe("assertCount and assertContains", function() {

				it("counts array elements correctly", function() {
					var arr = [1, 2, 3];
					expect(function() {
						assertions.assertCount(3, arr);
					}).notToThrow();

					expect(function() {
						assertions.assertCount(5, arr);
					}).toThrow(type = "AssertionFailedException");
				});

				it("checks array containment", function() {
					var arr = ["apple", "banana", "orange"];
					expect(function() {
						assertions.assertContains("banana", arr);
					}).notToThrow();

					expect(function() {
						assertions.assertContains("grape", arr);
					}).toThrow(type = "AssertionFailedException");
				});

				it("checks string containment", function() {
					var str = "hello world";
					expect(function() {
						assertions.assertContains("world", str);
					}).notToThrow();

					expect(function() {
						assertions.assertContains("xyz", str);
					}).toThrow(type = "AssertionFailedException");
				});

			});

		});
	}

}
