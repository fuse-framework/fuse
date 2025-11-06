interface {

	/**
	 * Get cached value by key
	 * Returns null if key not found or expired
	 *
	 * @key Cache key
	 * @return Cached value or null
	 */
	public any function get(required string key);

	/**
	 * Set cache value with optional TTL
	 * TTL of 0 means no expiration
	 *
	 * @key Cache key
	 * @value Value to cache
	 * @ttl Time to live in seconds (0 = no expiration)
	 */
	public void function set(required string key, required any value, numeric ttl = 0);

	/**
	 * Check if key exists in cache
	 * Does not return value, only checks existence
	 *
	 * @key Cache key
	 * @return True if key exists and not expired
	 */
	public boolean function has(required string key);

	/**
	 * Delete single cache entry by key
	 *
	 * @key Cache key
	 */
	public void function delete(required string key);

	/**
	 * Clear all cache entries
	 */
	public void function clear();

}
