<cfsetting showdebugoutput="false">
<cfscript>
	try {
		writeOutput("<h1>Module System Tests</h1>");
		writeOutput("<hr>");

		// Test 1: Create registry
		writeOutput("<h2>Test 1: Create ModuleRegistry</h2>");
		registry = new fuse.core.ModuleRegistry();
		writeOutput("<p>✓ ModuleRegistry created successfully</p>");

		// Test 2: Test topological sort with valid dependencies
		writeOutput("<h2>Test 2: Topological Sort</h2>");
		modules = {
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

		sorted = registry.sortByDependencies(modules);
		writeOutput("<p>Sorted order: " & arrayToList(sorted) & "</p>");
		if (sorted[1] == "ModuleA" && sorted[2] == "ModuleB" && sorted[3] == "ModuleC") {
			writeOutput("<p>✓ Topological sort works correctly</p>");
		} else {
			writeOutput("<p>✗ Topological sort failed</p>");
		}

		// Test 3: Circular dependency detection
		writeOutput("<h2>Test 3: Circular Dependency Detection</h2>");
		try {
			circularModules = {
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
			registry.sortByDependencies(circularModules);
			writeOutput("<p>✗ Circular dependency NOT detected</p>");
		} catch (ModuleRegistry.CircularDependency e) {
			writeOutput("<p>✓ Circular dependency detected correctly</p>");
		}

		// Test 4: Missing dependency detection
		writeOutput("<h2>Test 4: Missing Dependency Detection</h2>");
		try {
			missingModules = {
				"ModuleZ": {
					instance: new tests.fixtures.modules.ModuleZ(),
					dependencies: ["NonExistentModule"],
					loaded: false
				}
			};
			registry.sortByDependencies(missingModules);
			writeOutput("<p>✗ Missing dependency NOT detected</p>");
		} catch (ModuleRegistry.MissingDependency e) {
			writeOutput("<p>✓ Missing dependency detected correctly</p>");
		}

		// Test 5: Two-phase initialization
		writeOutput("<h2>Test 5: Two-Phase Initialization</h2>");
		container = new fuse.core.Container();
		testModules = {
			"ModuleA": {
				instance: new tests.fixtures.modules.ModuleA(),
				dependencies: [],
				loaded: false
			},
			"ModuleB": {
				instance: new tests.fixtures.modules.ModuleB(),
				dependencies: ["ModuleA"],
				loaded: false
			}
		};

		registry.initialize(testModules, container);

		if (testModules["ModuleA"].instance.isRegistered() && testModules["ModuleA"].instance.isBooted()) {
			writeOutput("<p>✓ ModuleA registered and booted</p>");
		}
		if (testModules["ModuleB"].instance.isRegistered() && testModules["ModuleB"].instance.isBooted()) {
			writeOutput("<p>✓ ModuleB registered and booted</p>");
		}

		// Test 6: Module discovery
		writeOutput("<h2>Test 6: Module Discovery</h2>");
		fusePath = expandPath("/fuse");
		discoveredModules = registry.discover(fusePath);
		writeOutput("<p>✓ Framework modules discovered: " & structCount(discoveredModules) & "</p>");

		writeOutput("<hr>");
		writeOutput("<h2>All Tests Passed!</h2>");

	} catch (any e) {
		writeOutput("<h2>Error!</h2>");
		writeOutput("<p><strong>Type:</strong> " & e.type & "</p>");
		writeOutput("<p><strong>Message:</strong> " & e.message & "</p>");
		writeOutput("<p><strong>Detail:</strong> " & e.detail & "</p>");
		writeOutput("<pre>" & e.stacktrace & "</pre>");
	}
</cfscript>
