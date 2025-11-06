component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		variables.testAppScope = {};
	}

	function run() {
		describe("End-to-end bootstrap integration", function() {

			beforeEach(function() {
				variables.testAppScope = {};
			});

			it("should complete full bootstrap with module discovery and initialization", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);

				// Verify framework initialized
				expect(framework).toBeInstanceOf("fuse.core.Framework");

				// Verify container available
				var container = framework.getContainer();
				expect(container).toBeInstanceOf("fuse.core.Container");

				// Verify config bound
				expect(container.has("config")).toBeTrue();
			});

			it("should initialize modules with config injection", function() {
				// Create test module that uses config
				var testModule = new tests.fixtures.modules.ConfigAwareModule();

				var container = new fuse.core.Container();
				var config = new fuse.core.Config();

				var finalConfig = {
					"appName": "TestApp",
					"ConfigAwareModule": {
						"enabled": true,
						"value": 42
					}
				};

				config.bindToContainer(container, finalConfig);

				var modules = {
					"ConfigAwareModule": {
						instance: testModule,
						dependencies: [],
						loaded: false
					}
				};

				var registry = new fuse.core.ModuleRegistry();
				registry.initialize(modules, container);

				// Module should have received config during boot
				expect(testModule.isBooted()).toBeTrue();
				expect(testModule.getConfigValue()).toBe(42);
			});

			it("should resolve dependencies between modules during initialization", function() {
				// ModuleD provides a service, ModuleE depends on it
				var moduleD = new tests.fixtures.modules.ServiceProviderModule();
				var moduleE = new tests.fixtures.modules.ServiceConsumerModule();

				var container = new fuse.core.Container();

				var modules = {
					"ServiceProviderModule": {
						instance: moduleD,
						dependencies: [],
						loaded: false
					},
					"ServiceConsumerModule": {
						instance: moduleE,
						dependencies: ["ServiceProviderModule"],
						loaded: false
					}
				};

				var registry = new fuse.core.ModuleRegistry();
				registry.initialize(modules, container);

				// ServiceConsumerModule should have successfully resolved the service
				expect(moduleE.hasService()).toBeTrue();
			});

			it("should merge module configs before module initialization", function() {
				var moduleA = new tests.fixtures.modules.ModuleA();
				var moduleB = new tests.fixtures.modules.ModuleB();

				var container = new fuse.core.Container();
				var config = new fuse.core.Config();
				var baseConfig = {"appName": "TestApp"};

				var modules = {
					"ModuleA": {
						instance: moduleA,
						dependencies: [],
						loaded: false
					},
					"ModuleB": {
						instance: moduleB,
						dependencies: ["ModuleA"],
						loaded: false
					}
				};

				var registry = new fuse.core.ModuleRegistry();
				var finalConfig = registry.mergeConfigs(modules, baseConfig);

				expect(finalConfig.appName).toBe("TestApp");
				expect(finalConfig.ModuleA.setting1).toBe("value1");
			});

			it("should handle circular module dependencies through full bootstrap", function() {
				// Create modules with circular dependency
				var moduleX = new tests.fixtures.modules.ModuleX();
				var moduleY = new tests.fixtures.modules.ModuleY();

				var container = new fuse.core.Container();

				var modules = {
					"ModuleX": {
						instance: moduleX,
						dependencies: ["ModuleY"],
						loaded: false
					},
					"ModuleY": {
						instance: moduleY,
						dependencies: ["ModuleX"],
						loaded: false
					}
				};

				var registry = new fuse.core.ModuleRegistry();

				expect(function() {
					registry.initialize(modules, container);
				}).toThrow(type="ModuleRegistry.CircularDependency");
			});

			it("should propagate missing dependency errors through bootstrap", function() {
				var moduleZ = new tests.fixtures.modules.ModuleZ();

				var container = new fuse.core.Container();

				var modules = {
					"ModuleZ": {
						instance: moduleZ,
						dependencies: ["NonExistentModule"],
						loaded: false
					}
				};

				var registry = new fuse.core.ModuleRegistry();

				expect(function() {
					registry.initialize(modules, container);
				}).toThrow(type="ModuleRegistry.MissingDependency");
			});

			it("should inject config values into components resolved from container", function() {
				var container = new fuse.core.Container();

				// Bind config with database settings
				container.singleton("config", function(c) {
					return {
						"database": {
							"host": "db.example.com",
							"port": 5432
						}
					};
				});

				// Bind service that needs config
				container.singleton("dbService", "tests.fixtures.ConfigDrivenService");

				var service = container.resolve("dbService");

				expect(service.getHost()).toBe("db.example.com");
			});

			it("should support multi-level dependency resolution across modules", function() {
				// Chain: ModuleA -> ModuleB -> ModuleC
				var moduleA = new tests.fixtures.modules.ModuleA();
				var moduleB = new tests.fixtures.modules.ModuleB();
				var moduleC = new tests.fixtures.modules.ModuleC();

				var container = new fuse.core.Container();

				var modules = {
					"ModuleA": {
						instance: moduleA,
						dependencies: [],
						loaded: false
					},
					"ModuleB": {
						instance: moduleB,
						dependencies: ["ModuleA"],
						loaded: false
					},
					"ModuleC": {
						instance: moduleC,
						dependencies: ["ModuleA", "ModuleB"],
						loaded: false
					}
				};

				var registry = new fuse.core.ModuleRegistry();
				var sorted = registry.sortByDependencies(modules);

				// Verify correct ordering
				expect(sorted[1]).toBe("ModuleA");
				expect(sorted[2]).toBe("ModuleB");
				expect(sorted[3]).toBe("ModuleC");

				// Initialize and verify all booted
				registry.initialize(modules, container);

				expect(moduleA.isBooted()).toBeTrue();
				expect(moduleB.isBooted()).toBeTrue();
				expect(moduleC.isBooted()).toBeTrue();
			});

			it("should maintain singleton scope across module initialization", function() {
				var moduleA = new tests.fixtures.modules.SingletonTestModule();
				var moduleB = new tests.fixtures.modules.SingletonTestModule();

				var container = new fuse.core.Container();

				// Both modules register the same singleton service
				container.singleton("sharedService", "tests.fixtures.SimpleService");

				var instance1 = container.resolve("sharedService");
				var instance2 = container.resolve("sharedService");

				// Should be same instance
				expect(instance1).toBe(instance2);
			});

			it("should handle environment-specific config through full bootstrap", function() {
				var config = new fuse.core.Config();

				var baseConfig = {
					"appName": "TestApp",
					"debug": false
				};

				var devConfig = {
					"debug": true,
					"logLevel": "verbose"
				};

				var finalConfig = config.mergeEnvironment(baseConfig, devConfig);

				var container = new fuse.core.Container();
				config.bindToContainer(container, finalConfig);

				var resolved = container.resolve("config");

				expect(resolved.debug).toBeTrue();
				expect(resolved.logLevel).toBe("verbose");
				expect(resolved.appName).toBe("TestApp");
			});

		});
	}

}
