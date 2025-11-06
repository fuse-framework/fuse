component extends="testbox.system.BaseSpec" {

	function run() {
		describe("Configuration system", function() {

			beforeEach(function() {
				variables.config = new fuse.core.Config();
			});

			it("should load base config from application.cfc", function() {
				var baseConfig = {
					"appName": "FuseApp",
					"database": {
						"host": "localhost",
						"port": 3306
					}
				};

				var result = config.loadBase(baseConfig);

				expect(result.appName).toBe("FuseApp");
				expect(result.database.host).toBe("localhost");
				expect(result.database.port).toBe(3306);
			});

			it("should deep-merge environment overrides", function() {
				var baseConfig = {
					"appName": "FuseApp",
					"debug": false,
					"database": {
						"host": "localhost",
						"port": 3306,
						"username": "root"
					}
				};

				var envConfig = {
					"debug": true,
					"database": {
						"host": "dev.example.com",
						"password": "secret"
					}
				};

				var result = config.mergeEnvironment(baseConfig, envConfig);

				expect(result.appName).toBe("FuseApp");
				expect(result.debug).toBe(true);
				expect(result.database.host).toBe("dev.example.com");
				expect(result.database.port).toBe(3306);
				expect(result.database.username).toBe("root");
				expect(result.database.password).toBe("secret");
			});

			it("should merge module configs under module key", function() {
				var baseConfig = {
					"appName": "FuseApp"
				};

				var moduleConfigs = {
					"RoutingModule": {
						"basePath": "/app",
						"routes": []
					},
					"CacheModule": {
						"enabled": true,
						"ttl": 3600
					}
				};

				var result = config.mergeModules(baseConfig, moduleConfigs);

				expect(result.appName).toBe("FuseApp");
				expect(result.RoutingModule.basePath).toBe("/app");
				expect(result.CacheModule.enabled).toBe(true);
				expect(result.CacheModule.ttl).toBe(3600);
			});

			it("should detect environment from APPLICATION scope", function() {
				application.environment = "development";

				var detected = config.detectEnvironment();

				expect(detected).toBe("development");
			});

			it("should detect environment from ENV.FUSE_ENV", function() {
				if (structKeyExists(application, "environment")) {
					structDelete(application, "environment");
				}

				var mockEnv = {"FUSE_ENV": "production"};
				var detected = config.detectEnvironment(mockEnv);

				expect(detected).toBe("production");
			});

			it("should default to production if no environment set", function() {
				if (structKeyExists(application, "environment")) {
					structDelete(application, "environment");
				}

				var detected = config.detectEnvironment({});

				expect(detected).toBe("production");
			});

			it("should bind final config to DI container as singleton", function() {
				var container = new fuse.core.Container();
				var finalConfig = {
					"appName": "FuseApp",
					"debug": true
				};

				config.bindToContainer(container, finalConfig);

				expect(container.has("config")).toBe(true);
				var resolved = container.resolve("config");
				expect(resolved.appName).toBe("FuseApp");
				expect(resolved.debug).toBe(true);

				// Verify singleton behavior
				var resolved2 = container.resolve("config");
				expect(resolved).toBe(resolved2);
			});

			it("should support complete config loading workflow", function() {
				var baseConfig = {
					"appName": "FuseApp",
					"database": {
						"host": "localhost"
					}
				};

				var envConfig = {
					"database": {
						"host": "dev.example.com"
					}
				};

				var moduleConfigs = {
					"RoutingModule": {
						"enabled": true
					}
				};

				var result = config.loadBase(baseConfig);
				result = config.mergeEnvironment(result, envConfig);
				result = config.mergeModules(result, moduleConfigs);

				expect(result.appName).toBe("FuseApp");
				expect(result.database.host).toBe("dev.example.com");
				expect(result.RoutingModule.enabled).toBe(true);
			});

		});
	}

}
