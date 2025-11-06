component implements="fuse.cache.ICacheProvider" {

	property name="config" inject="config";

	function init(struct config = {}) {
		variables.cache = {};
		variables.config = arguments.config;
		return this;
	}

	/**
	 * Get cached value by key
	 * Returns null if key not found or expired
	 * Performs lazy expiration cleanup
	 */
	public any function get(required string key) {
		// Check with readonly lock first
		var isExpired = false;
		var hasKey = false;
		var value = javaCast("null", "");

		lock name="fuse_cache_#arguments.key#" timeout="5" type="readonly" {
			if (!structKeyExists(variables.cache, arguments.key)) {
				return;
			}

			hasKey = true;
			var entry = variables.cache[arguments.key];

			// Check if expired
			if (!isNull(entry.expiresAt) && entry.expiresAt < now()) {
				isExpired = true;
			} else {
				value = entry.value;
			}
		}

		// If expired, delete with exclusive lock
		if (isExpired) {
			lock name="fuse_cache_#arguments.key#" timeout="5" type="exclusive" {
				structDelete(variables.cache, arguments.key);
			}
			return;
		}

		return value;
	}

	/**
	 * Set cache value with optional TTL
	 * TTL of 0 means no expiration
	 */
	public void function set(required string key, required any value, numeric ttl = 0) {
		var defaultTTL = structKeyExists(variables.config, "cache") && structKeyExists(variables.config.cache, "defaultTTL")
			? variables.config.cache.defaultTTL
			: 0;

		var effectiveTTL = arguments.ttl > 0 ? arguments.ttl : defaultTTL;

		lock name="fuse_cache_#arguments.key#" timeout="5" type="exclusive" {
			variables.cache[arguments.key] = {
				value: arguments.value,
				expiresAt: effectiveTTL > 0 ? dateAdd("s", effectiveTTL, now()) : javaCast("null", "")
			};
		}
	}

	/**
	 * Check if key exists in cache
	 * Does not return value, only checks existence
	 */
	public boolean function has(required string key) {
		lock name="fuse_cache_#arguments.key#" timeout="5" type="readonly" {
			if (!structKeyExists(variables.cache, arguments.key)) {
				return false;
			}

			var entry = variables.cache[arguments.key];

			// Check if expired
			if (!isNull(entry.expiresAt) && entry.expiresAt < now()) {
				return false;
			}

			return true;
		}
	}

	/**
	 * Delete single cache entry by key
	 */
	public void function delete(required string key) {
		lock name="fuse_cache_#arguments.key#" timeout="5" type="exclusive" {
			structDelete(variables.cache, arguments.key);
		}
	}

	/**
	 * Clear all cache entries
	 */
	public void function clear() {
		// Use global lock for clearing entire cache
		lock name="fuse_cache_clear" timeout="5" type="exclusive" {
			variables.cache = {};
		}
	}

	// Setter for property injection
	public void function setConfig(required struct config) {
		variables.config = arguments.config;
	}

}
