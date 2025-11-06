<cfsetting enablecfoutputonly="true">
<cfscript>
	// Create TestBox instance with text reporter
	testbox = new testbox.system.TestBox(
		bundles = [
			"tests.cli.support.NamingConventionsTest",
			"tests.cli.support.AttributeParserTest",
			"tests.cli.support.TemplateEngineTest",
			"tests.cli.support.FileGeneratorTest"
		],
		reporter = "text"
	);

	// Run tests and get results
	results = testbox.run();

	// Output results
	writeOutput(results);
</cfscript>
