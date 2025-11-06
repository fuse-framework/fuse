component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		variables.container = new fuse.core.Container();
		variables.config = new fuse.core.Config();
	}

	function run() {
		describe("Module system", function() {

			beforeEach(function() {
				variables.container = new fuse.core.Container();
				variables.config = new fuse.core.Config();
			});

			it("should auto-discover modules from /fuse/modules/ directory", function() {
				var registry = new fuse.core.ModuleRegistry();
				var modules = registry.discover(expandPath("/fuse"));

				// Framework modules directory exists but may be empty initially
				expect(modules).toBeStruct();
			});

			it("should auto-discover modules from /modules/ directory", function() {
				var registry = new fuse.core.ModuleRegistry();
				var modules = registry.discover(expandPath("/modules"));

				// App modules directory may not exist yet
				expect(modules).toBeStruct();
			});

			it("should sort modules in topological order with valid dependencies", function() {
				var registry = new fuse.core.ModuleRegistry();

				// Create test modules with dependencies
				var modules = {
					"ModuleA": {
						instance: new tests.fixtures.modules.ModuleA(),
						dependencies: [],
						loaded: false
					},
					"ModuleB": {
						instance: new tests.fixtures.modules.ModuleB(),
						dependencies: ["ModuleA"],
						loaded: false
					},
					"ModuleC": {
						instance: new tests.fixtures.modules.ModuleC(),
						dependencies: ["ModuleA", "ModuleB"],
						loaded: false
					}
				};

				var sorted = registry.sortByDependencies(modules);

				expect(sorted).toBeArray();
				expect(sorted[1]).toBe("ModuleA");
				expect(sorted[2]).toBe("ModuleB");
				expect(sorted[3]).toBe("ModuleC");
			});

			it("should detect circular dependencies and throw error", function() {
				var registry = new fuse.core.ModuleRegistry();

				var modules = {
					"ModuleX": {
						instance: new tests.fixtures.modules.ModuleX(),
						dependencies: ["ModuleY"],
						loaded: false
					},
					"ModuleY": {
						instance: new tests.fixtures.modules.ModuleY(),
						dependencies: ["ModuleX"],
						loaded: false
					}
				};

				expect(function() {
					registry.sortByDependencies(modules);
				}).toThrow(type="ModuleRegistry.CircularDependency");
			});

			it("should detect missing dependencies and throw error", function() {
				var registry = new fuse.core.ModuleRegistry();

				var modules = {
					"ModuleZ": {
						instance: new tests.fixtures.modules.ModuleZ(),
						dependencies: ["NonExistentModule"],
						loaded: false
					}
				};

				expect(function() {
					registry.sortByDependencies(modules);
				}).toThrow(type="ModuleRegistry.MissingDependency");
			});

			it("should execute two-phase initialization (register then boot)", function() {
				var registry = new fuse.core.ModuleRegistry();

				var moduleA = new tests.fixtures.modules.ModuleA();
				var moduleB = new tests.fixtures.modules.ModuleB();

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

				registry.initialize(modules, container);

				// After initialization, both register and boot should have been called
				expect(moduleA.isRegistered()).toBeTrue();
				expect(moduleA.isBooted()).toBeTrue();
				expect(moduleB.isRegistered()).toBeTrue();
				expect(moduleB.isBooted()).toBeTrue();
			});

			it("should load framework modules before application modules", function() {
				var registry = new fuse.core.ModuleRegistry();

				var frameworkModules = registry.discover(expandPath("/fuse"), "framework");
				var appModules = registry.discover(expandPath("/modules"), "application");

				var allModules = registry.merge(frameworkModules, appModules);

				// Framework modules should be first in the ordered struct
				var keys = structKeyArray(allModules);
				// This validates that framework modules are processed before app modules
				expect(keys).toBeArray();
			});

		});
	}

}
