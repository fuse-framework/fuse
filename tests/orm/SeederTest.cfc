/**
 * SeederTest - Tests for Seeder base class
 *
 * Validates seeder base class functionality:
 * - init() sets datasource in variables scope
 * - run() is overridable (abstract method pattern)
 * - call() loads and invokes another seeder
 * - call() passes datasource to child seeder
 */
component extends="fuse.testing.TestCase" {

	// TEST: init sets datasource in variables scope
	public function testInitSetsDatasourceInVariablesScope() {
		seeder = new fuse.orm.Seeder("test_datasource");

		// Access datasource via public method to verify it's set
		assertEqual("test_datasource", seeder.getDatasource());
	}

	// TEST: run method is overridable
	public function testRunMethodIsOverridable() {
		// Create a test seeder that overrides run()
		testSeeder = new database.seeds.TestSeeder("test_ds");

		// Call run() - should not throw
		testSeeder.run();

		// Verify it was called (TestSeeder sets a flag)
		assertTrue(testSeeder.wasRunCalled());
	}

	// TEST: call loads and invokes another seeder
	public function testCallLoadsAndInvokesAnotherSeeder() {
		// Create main seeder
		mainSeeder = new database.seeds.MainSeeder("test_ds");

		// Call TestSeeder from MainSeeder
		mainSeeder.run();

		// Verify TestSeeder was invoked
		assertTrue(mainSeeder.wasChildSeederCalled());
	}

	// TEST: call passes datasource to child seeder
	public function testCallPassesDatasourceToChildSeeder() {
		// Create main seeder with specific datasource
		mainSeeder = new database.seeds.MainSeeder("custom_datasource");

		// Call child seeder
		mainSeeder.run();

		// Verify child received correct datasource
		assertEqual("custom_datasource", mainSeeder.getChildDatasource());
	}

}
