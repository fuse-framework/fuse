# Cache Providers

**Status:** Coming in v1.1

Implement custom cache backends and providers for flexible caching strategies across different storage mechanisms including memory, Redis, Memcached, and database.

## Overview

Cache abstraction enables pluggable storage backends (planned for v1.1):

```cfml
// Planned cache usage (v1.1)
// Get from cache or compute
var users = cache.remember("active_users", 3600, function() {
    return User::where({active: true}).get();
});

// Store in cache
cache.put("dashboard_stats", stats, 1800);

// Retrieve from cache
var stats = cache.get("dashboard_stats");

// Remove from cache
cache.forget("dashboard_stats");

// Check if exists
if (cache.has("user_#userId#")) {
    var user = cache.get("user_#userId#");
}
```

Cache providers abstract storage implementation for consistency across backends.

## Cache Abstraction

### Cache Interface

All cache providers implement common interface:

```cfml
// Planned interface (v1.1)
// fuse/cache/ICacheProvider.cfc
interface {

    /**
     * Retrieve item from cache
     * @param key Cache key
     * @return Cached value or null if not found
     */
    public any function get(required string key);

    /**
     * Store item in cache
     * @param key Cache key
     * @param value Value to cache
     * @param ttl Time to live in seconds
     */
    public void function put(required string key, required any value, numeric ttl = 3600);

    /**
     * Get or store item
     * @param key Cache key
     * @param ttl Time to live in seconds
     * @param callback Function to compute value if not cached
     * @return Cached or computed value
     */
    public any function remember(required string key, numeric ttl, required callback);

    /**
     * Check if item exists in cache
     * @param key Cache key
     * @return Boolean true if exists
     */
    public boolean function has(required string key);

    /**
     * Remove item from cache
     * @param key Cache key
     */
    public void function forget(required string key);

    /**
     * Clear all cached items
     */
    public void function flush();

    /**
     * Get multiple items
     * @param keys Array of cache keys
     * @return Struct with key-value pairs
     */
    public struct function many(required array keys);

    /**
     * Store multiple items
     * @param items Struct of key-value pairs
     * @param ttl Time to live in seconds
     */
    public void function putMany(required struct items, numeric ttl = 3600);
}
```

### Usage Patterns

Common cache operations:

```cfml
// Planned patterns (v1.1)

// Simple get/put
cache.put("user_1", user, 3600);
var user = cache.get("user_1");

// Get with default
var user = cache.get("user_1", new User());

// Remember pattern (get or compute)
var stats = cache.remember("dashboard_stats", 600, function() {
    return {
        userCount: User::count(),
        postCount: Post::count()
    };
});

// Forever (no expiration)
cache.forever("site_settings", settings);

// Increment/decrement
cache.increment("page_views");
cache.decrement("stock_#productId#");

// Tags (grouped caching)
cache.tags(["users", "profiles"]).put("user_1", user, 3600);
cache.tags(["users"]).flush();  // Clear all user-tagged items
```

## Custom Cache Provider Interface

### Implementing Provider

Create custom cache provider:

```cfml
// Planned pattern (v1.1)
// app/cache/providers/CustomCacheProvider.cfc
component implements="fuse.cache.ICacheProvider" {

    public function init(required struct config) {
        variables.config = arguments.config;
        variables.storage = {};  // Your storage mechanism
        return this;
    }

    public any function get(required string key) {
        if (structKeyExists(variables.storage, arguments.key)) {
            var item = variables.storage[arguments.key];

            // Check expiration
            if (!isNull(item.expires) && item.expires < now()) {
                structDelete(variables.storage, arguments.key);
                return null;
            }

            return item.value;
        }

        return null;
    }

    public void function put(required string key, required any value, numeric ttl = 3600) {
        variables.storage[arguments.key] = {
            value: arguments.value,
            expires: dateAdd("s", arguments.ttl, now())
        };
    }

    public any function remember(required string key, numeric ttl, required callback) {
        var value = this.get(arguments.key);

        if (!isNull(value)) {
            return value;
        }

        // Compute value
        value = arguments.callback();

        // Store in cache
        this.put(arguments.key, value, arguments.ttl);

        return value;
    }

    public boolean function has(required string key) {
        var value = this.get(arguments.key);
        return !isNull(value);
    }

    public void function forget(required string key) {
        structDelete(variables.storage, arguments.key);
    }

    public void function flush() {
        variables.storage = {};
    }

    public struct function many(required array keys) {
        var result = {};

        for (var key in arguments.keys) {
            result[key] = this.get(key);
        }

        return result;
    }

    public void function putMany(required struct items, numeric ttl = 3600) {
        for (var key in arguments.items) {
            this.put(key, arguments.items[key], arguments.ttl);
        }
    }
}
```

### Provider Configuration

Configure provider with options:

```cfml
// Planned config (v1.1)
// config/cache.cfc
component {

    public struct function getCacheConfig() {
        return {
            default: "redis",  // Default provider

            providers: {
                // Memory cache provider
                memory: {
                    driver: "memory",
                    maxSize: 1000
                },

                // Redis cache provider
                redis: {
                    driver: "redis",
                    host: "localhost",
                    port: 6379,
                    password: "",
                    database: 0
                },

                // Database cache provider
                database: {
                    driver: "database",
                    table: "cache",
                    connection: "default"
                },

                // Custom provider
                custom: {
                    driver: "app.cache.providers.CustomCacheProvider",
                    customOption: "value"
                }
            }
        };
    }
}
```

## Provider Registration

### Registering in Module

Register cache provider in module:

```cfml
// Planned pattern (v1.1)
// app/modules/CacheModule.cfc
component implements="fuse.core.IModule" {

    public void function register(required container) {
        // Register cache manager
        arguments.container.singleton("cache", function(c) {
            var config = c.resolve("config").cache;
            return new fuse.cache.CacheManager(config);
        });

        // Register custom providers
        arguments.container.bind("cache.providers.custom", function(c) {
            var config = c.resolve("config").cache.providers.custom;
            return new app.cache.providers.CustomCacheProvider(config);
        });
    }

    public void function boot(required container) {
        var cacheManager = arguments.container.resolve("cache");

        // Register custom driver
        cacheManager.extend("custom", function(config) {
            return new app.cache.providers.CustomCacheProvider(config);
        });
    }

    public array function getDependencies() {
        return [];
    }

    public struct function getConfig() {
        return {
            cache: {
                default: "memory",
                providers: {
                    memory: {
                        driver: "memory"
                    }
                }
            }
        };
    }
}
```

### Using Registered Provider

Access cache through container:

```cfml
// Handler with injected cache
component {

    public function init(required cache) {
        variables.cache = arguments.cache;
        return this;
    }

    public struct function index() {
        var posts = variables.cache.remember("posts", 600, function() {
            return Post::where({published: true})
                .orderBy("created_at DESC")
                .get();
        });

        return {posts: posts};
    }
}
```

## Built-in Providers

### Memory Cache Provider

In-memory caching (application scope):

```cfml
// Planned implementation (v1.1)
// fuse/cache/providers/MemoryCacheProvider.cfc
component implements="fuse.cache.ICacheProvider" {

    public function init(required struct config) {
        if (!structKeyExists(application, "cache")) {
            application.cache = {};
        }
        variables.storage = application.cache;
        return this;
    }

    // ... implement interface methods
}
```

**Pros:**
- Fast access
- No external dependencies
- Simple configuration

**Cons:**
- Not distributed (single server only)
- Limited by server memory
- Cleared on app restart

### Redis Cache Provider

Redis-backed caching:

```cfml
// Planned implementation (v1.1)
// fuse/cache/providers/RedisCacheProvider.cfc
component implements="fuse.cache.ICacheProvider" {

    public function init(required struct config) {
        variables.redis = new fuse.redis.RedisClient(
            arguments.config.host,
            arguments.config.port,
            arguments.config.password
        );
        return this;
    }

    public any function get(required string key) {
        var value = variables.redis.get(arguments.key);
        return isNull(value) ? null : deserializeJSON(value);
    }

    public void function put(required string key, required any value, numeric ttl = 3600) {
        variables.redis.setex(
            arguments.key,
            arguments.ttl,
            serializeJSON(arguments.value)
        );
    }

    // ... implement other interface methods
}
```

**Pros:**
- Distributed caching
- Persistent across restarts
- Advanced features (sets, lists, etc.)

**Cons:**
- Requires Redis server
- Network overhead
- Additional infrastructure

### Database Cache Provider

Database table caching:

```cfml
// Planned implementation (v1.1)
// fuse/cache/providers/DatabaseCacheProvider.cfc
component implements="fuse.cache.ICacheProvider" {

    public function init(required struct config) {
        variables.table = arguments.config.table;
        variables.datasource = arguments.config.connection;
        return this;
    }

    public any function get(required string key) {
        var sql = "
            SELECT value, expires_at
            FROM #variables.table#
            WHERE key = ?
            AND (expires_at IS NULL OR expires_at > ?)
        ";

        var result = queryExecute(sql, [arguments.key, now()], {
            datasource: variables.datasource
        });

        if (result.recordCount > 0) {
            return deserializeJSON(result.value);
        }

        return null;
    }

    public void function put(required string key, required any value, numeric ttl = 3600) {
        var expiresAt = dateAdd("s", arguments.ttl, now());

        var sql = "
            REPLACE INTO #variables.table# (key, value, expires_at)
            VALUES (?, ?, ?)
        ";

        queryExecute(sql, [
            arguments.key,
            serializeJSON(arguments.value),
            expiresAt
        ], {
            datasource: variables.datasource
        });
    }

    // ... implement other interface methods
}
```

**Migration for cache table:**

```cfml
// migrations/2025-11-06-create-cache-table.cfc
public void function up() {
    schema.createTable("cache", function(table) {
        table.string("key", 255).primary();
        table.text("value");
        table.datetime("expires_at").nullable();
        table.timestamps();

        table.index("expires_at");
    });
}

public void function down() {
    schema.dropTable("cache");
}
```

**Pros:**
- No additional services required
- Persistent across restarts
- Can query cache contents

**Cons:**
- Slower than memory/Redis
- Database load
- Requires maintenance (cleanup)

## Example: Multi-tier Caching

Implement multi-tier caching strategy:

```cfml
// Planned pattern (v1.1)
// app/cache/providers/MultiTierCacheProvider.cfc
component implements="fuse.cache.ICacheProvider" {

    public function init(required struct config) {
        // L1: Fast memory cache
        variables.l1Cache = new fuse.cache.providers.MemoryCacheProvider(config);

        // L2: Distributed Redis cache
        variables.l2Cache = new fuse.cache.providers.RedisCacheProvider(config);

        return this;
    }

    public any function get(required string key) {
        // Try L1 first
        var value = variables.l1Cache.get(arguments.key);

        if (!isNull(value)) {
            return value;
        }

        // Try L2
        value = variables.l2Cache.get(arguments.key);

        if (!isNull(value)) {
            // Populate L1 for next time
            variables.l1Cache.put(arguments.key, value, 300);
            return value;
        }

        return null;
    }

    public void function put(required string key, required any value, numeric ttl = 3600) {
        // Write to both tiers
        variables.l1Cache.put(arguments.key, arguments.value, min(arguments.ttl, 300));
        variables.l2Cache.put(arguments.key, arguments.value, arguments.ttl);
    }

    public void function forget(required string key) {
        variables.l1Cache.forget(arguments.key);
        variables.l2Cache.forget(arguments.key);
    }

    public void function flush() {
        variables.l1Cache.flush();
        variables.l2Cache.flush();
    }

    // ... implement other interface methods
}
```

## Current Workarounds

Until cache system implemented:

### Application Scope Caching

```cfml
// Manual application scope caching
if (!structKeyExists(application, "userCache")) {
    application.userCache = {};
}

var cacheKey = "user_#userId#";

if (structKeyExists(application.userCache, cacheKey)) {
    var cached = application.userCache[cacheKey];

    // Check expiration
    if (dateDiff("s", cached.time, now()) < 3600) {
        return cached.value;
    }
}

// Cache miss - fetch and store
var user = User::find(userId);
application.userCache[cacheKey] = {
    value: user,
    time: now()
};
```

### Custom Cache Service

```cfml
// app/services/CacheService.cfc
component {

    public function init() {
        variables.storage = {};
        return this;
    }

    public any function get(required string key) {
        if (structKeyExists(variables.storage, arguments.key)) {
            var item = variables.storage[arguments.key];

            if (item.expires > now()) {
                return item.value;
            }

            structDelete(variables.storage, arguments.key);
        }

        return null;
    }

    public void function put(required string key, required any value, numeric ttl = 3600) {
        variables.storage[arguments.key] = {
            value: arguments.value,
            expires: dateAdd("s", arguments.ttl, now())
        };
    }

    public any function remember(required string key, numeric ttl, required callback) {
        var value = this.get(arguments.key);

        if (!isNull(value)) {
            return value;
        }

        value = arguments.callback();
        this.put(arguments.key, value, arguments.ttl);

        return value;
    }
}
```

## Implementation Timeline

Cache system planned for v1.1:

**Phase 1:**
- Cache interface definition
- Memory cache provider
- Basic operations (get, put, forget)

**Phase 2:**
- Redis cache provider
- Database cache provider
- Advanced operations (tags, increment)

**Phase 3:**
- Custom provider registration
- Multi-tier caching
- Cache warming and preloading

## Design Goals

Cache system will prioritize:

1. **Flexibility** - Support multiple backends
2. **Performance** - Minimal overhead
3. **Simplicity** - Easy to use API
4. **Extensibility** - Custom providers
5. **Reliability** - Graceful degradation

## Related Topics

- [Performance](performance.md) - Query caching strategies
- [Modules](modules.md) - Cache module implementation
- [Views](views.md) - View fragment caching
- [Models & ORM](../guides/models-orm.md) - Model caching patterns
