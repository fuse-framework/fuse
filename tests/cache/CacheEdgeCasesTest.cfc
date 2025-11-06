component extends="testbox.system.BaseSpec" {

	function run() {
		describe("Cache edge cases and boundary conditions", function() {

			beforeEach(function() {
				variables.container = new fuse.core.Container();

				// Bind config
				container.singleton("config", function(c) {
					return {
						cache: {
							defaultTTL: 0,
							enabled: true
						}
					};
				});

				// Register cache module
				var cacheModule = new fuse.modules.CacheModule();
				cacheModule.register(container);
				cacheModule.boot(container);
				variables.cache = container.resolve("ICacheProvider");
			});

			it("should handle TTL of exactly 1 second correctly", function() {
				cache.set("oneSecondKey", "value", 1);

				// Should exist immediately
				expect(cache.get("oneSecondKey")).toBe("value");

				// Wait exactly 1.1 seconds
				sleep(1100);

				// Should be expired
				var result = cache.get("oneSecondKey");
				expect(isNull(result)).toBeTrue();
			});

			it("should handle immediate expiration with very short TTL", function() {
				// TTL of 0.1 seconds (100ms)
				cache.set("shortLivedKey", "value", 0.1);

				// Wait 200ms
				sleep(200);

				// Should be expired
				var result = cache.get("shortLivedKey");
				expect(isNull(result)).toBeTrue();
			});

			it("should handle overwriting existing cache keys", function() {
				cache.set("overwriteKey", "originalValue", 0);
				expect(cache.get("overwriteKey")).toBe("originalValue");

				// Overwrite with new value
				cache.set("overwriteKey", "newValue", 0);
				expect(cache.get("overwriteKey")).toBe("newValue");
			});

			it("should handle concurrent reads from multiple threads safely", function() {
				cache.set("sharedReadKey", "sharedValue", 0);

				var results = [];

				// Spawn 10 threads that all read the same key
				for (var i = 1; i <= 10; i++) {
					thread action="run" name="readThread#i#" cache="#cache#" {
						var val = attributes.cache.get("sharedReadKey");
						// Store result for later verification
					}
				}

				// Wait for all threads
				var threadNames = [];
				for (var j = 1; j <= 10; j++) {
					arrayAppend(threadNames, "readThread#j#");
				}
				thread action="join" name="#arrayToList(threadNames)#";

				// No exception means thread-safe reads worked
				expect(cache.get("sharedReadKey")).toBe("sharedValue");
			});

			it("should delete expired items lazily on get()", function() {
				cache.set("lazyExpireKey", "value", 1);

				// Wait for expiration
				sleep(1500);

				// First get() should trigger lazy deletion
				var result1 = cache.get("lazyExpireKey");
				expect(isNull(result1)).toBeTrue();

				// Second get() should also return null (item already deleted)
				var result2 = cache.get("lazyExpireKey");
				expect(isNull(result2)).toBeTrue();

				// has() should also return false
				expect(cache.has("lazyExpireKey")).toBeFalse();
			});

			it("should handle complex struct and array values", function() {
				var complexData = {
					nested: {
						array: [1, 2, 3],
						struct: {key: "value"}
					},
					list: ["a", "b", "c"]
				};

				cache.set("complexKey", complexData, 0);
				var retrieved = cache.get("complexKey");

				expect(retrieved).toBeStruct();
				expect(retrieved.nested.array).toHaveLength(3);
				expect(retrieved.nested.struct.key).toBe("value");
				expect(retrieved.list).toHaveLength(3);
			});

		});
	}

}
