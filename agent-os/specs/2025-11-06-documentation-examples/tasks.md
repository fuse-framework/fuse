# Task Breakdown: Documentation & Examples

## Overview
Total Task Groups: 8
Total Tasks: ~40 individual tasks
Phases: 3 (MVP, Depth, Advanced)

## Task List

### Phase 1: MVP Documentation (Essential Launch Docs)

#### Task Group 1: Documentation Foundation
**Dependencies:** None

- [x] 1.0 Set up documentation structure
  - [x] 1.1 Create /docs directory structure
    - `/docs/getting-started/`
    - `/docs/guides/`
    - `/docs/tutorials/`
    - `/docs/reference/`
    - `/docs/advanced/`
    - `/docs/migration-guides/`
    - `/docs/ai/decision-trees/`
  - [x] 1.2 Create docs README.md with navigation
    - Overview of Fuse framework
    - Link to all major sections
    - Quick navigation structure
    - Version notice (v1.0)
  - [x] 1.3 Establish documentation style guide
    - Code-first examples pattern
    - File path comment convention: `// app/models/User.cfc`
    - Component declaration standard
    - Section structure template
    - Mermaid diagram conventions
  - [x] 1.4 Create .md template files for all planned docs
    - Placeholder structure for all 20+ docs
    - Standard headings per doc type
    - TODOs for content sections

**Acceptance Criteria:**
- Directory structure exists ✓
- README.md provides clear navigation ✓
- Style guide defines consistent patterns ✓
- All template files created ✓

#### Task Group 2: Getting Started Section
**Dependencies:** Task Group 1

- [x] 2.0 Complete Getting Started documentation
  - [x] 2.1 Write installation.md
    - lucli installation instructions
    - System requirements (Lucee 7+, Java)
    - Verify installation steps
    - Directory structure tour after `lucli new`
    - Troubleshooting section
  - [x] 2.2 Write quickstart.md (5-minute guide)
    - `lucli new myapp` walkthrough
    - Database configuration (.env setup)
    - Generate first model (`lucli generate model User name:string`)
    - Run migrations
    - Generate handler (`lucli generate handler Users`)
    - Start server (`lucli serve`)
    - Test in browser
    - All commands copy-pasteable
  - [x] 2.3 Write configuration.md
    - .env file setup and variables
    - database.cfc configuration
    - Datasource configuration (multiple databases)
    - Environment-specific settings (dev/test/production)
    - Config precedence order
    - Extract examples from existing bootstrap code
  - [x] 2.4 Cross-link getting started docs
    - Each doc references related getting started docs
    - Link to relevant guides for next steps
    - Add "Next: [guide]" navigation

**Acceptance Criteria:**
- All three getting started docs complete ✓
- 5-minute quickstart fully runnable ✓
- Code examples tested and verified ✓
- Clear navigation between docs ✓

#### Task Group 3: Core Guides (Part 1: Foundation)
**Dependencies:** Task Group 2

- [x] 3.0 Complete foundation guides
  - [x] 3.1 Write routing.md
    - RESTful route basics (`router.get()`, `router.post()`, etc.)
    - Resource routes (`router.resource("users")`)
    - Named parameters (`:id`, `:post_id`)
    - Wildcards and constraints
    - Named routes
    - urlFor helper usage
    - Route listing (`lucli routes`)
    - Extract examples from README.md
    - Anti-pattern: Hardcoded URLs
  - [x] 3.2 Enhance handlers.md
    - Leverage existing docs/handlers.md as base
    - Ensure matches spec requirements
    - Add more examples for common patterns
    - Add anti-patterns section
    - Cross-reference routing.md
    - Cross-reference models-orm.md
  - [x] 3.3 Write models-orm.md
    - ActiveRecord pattern overview
    - Model conventions (table names, primary keys)
    - Basic finders (`find()`, `where()`, `all()`)
    - Query building (hash syntax, chaining)
    - CRUD operations (`create()`, `save()`, `update()`, `delete()`)
    - Timestamps (createdAt, updatedAt)
    - Model callbacks (future reference)
    - Anti-pattern: N+1 queries (preview eager-loading.md)
  - [x] 3.4 Write migrations.md
    - Migration file naming conventions
    - Creating migrations (`lucli generate migration`)
    - up() and down() methods
    - Schema builder API (createTable, addColumn, dropColumn)
    - Column types and modifiers
    - Running migrations (`lucli migrate`)
    - Rolling back (`lucli rollback`)
    - Migration status
    - Anti-pattern: Editing old migrations

**Acceptance Criteria:**
- Four foundation guides complete ✓
- All code examples tested ✓
- Cross-references established ✓
- Anti-patterns documented ✓

#### Task Group 4: Core Guides (Part 2: Advanced ORM)
**Dependencies:** Task Group 3

- [x] 4.0 Complete advanced ORM guides
  - [x] 4.1 Write validations.md
    - Model validation basics
    - Built-in validators (required, email, length, numeric, etc.)
    - Validation rules definition
    - Error handling and messages
    - Custom error messages
    - Conditional validations (when, unless)
    - Cross-reference custom-validators.md for advanced cases
    - Anti-pattern: Client-side only validation
  - [x] 4.2 Write relationships.md
    - belongsTo relationship setup
    - hasMany relationship setup
    - hasOne relationship setup
    - through relationships (has-many-through)
    - Foreign key conventions
    - Relationship method usage
    - Inverse relationships
    - Anti-pattern: Manual foreign key queries
  - [x] 4.3 Write eager-loading.md
    - N+1 query problem explanation
    - includes() method syntax
    - Single association eager loading
    - Multiple associations
    - Nested eager loading
    - Performance comparison (with/without eager loading)
    - When to use eager loading
    - Anti-pattern: Loading in loops

**Acceptance Criteria:**
- Three advanced ORM guides complete ✓
- N+1 problem clearly explained ✓
- Relationship patterns comprehensive ✓
- Validation examples cover common cases ✓

#### Task Group 5: Testing Guide
**Dependencies:** Task Group 3

- [x] 5.0 Complete testing documentation
  - [x] 5.1 Write testing.md guide
    - Use fuse/testing/README.md as base
    - Expand with integration test patterns
    - Add test organization best practices
    - Database transaction rollback explanation
    - Fixtures and factories pattern (future)
    - Testing models (unit tests)
    - Testing handlers (integration tests)
    - Mocking dependencies
    - Running tests (`lucli test`)
    - Cross-reference assertions from README
  - [x] 5.2 Add testing examples to other guides
    - Add test examples to models-orm.md
    - Add test examples to validations.md
    - Add test examples to relationships.md
    - Show how to test each feature

**Acceptance Criteria:**
- testing.md comprehensive and clear ✓
- Leverages existing README content ✓
- Test examples in other guides ✓
- Shows both unit and integration patterns ✓

#### Task Group 6: Blog Tutorial
**Dependencies:** Task Groups 3, 4, 5

- [x] 6.0 Create complete blog tutorial
  - [x] 6.1 Write blog-application.md
    - Step 1: Setup (`lucli new blog`, database config, initial setup)
    - Step 2: Post model (title:string, body:text, published_at:datetime)
      - Generate model and migration
      - Run migration
      - Test CRUD in console/tests
    - Step 3: Posts handler and routes
      - Generate handler
      - RESTful routes setup
      - Implement index, show, create, update, destroy
      - Test in browser
    - Step 4: Comment model and relationships
      - Generate Comment model (body:text, post_id:integer)
      - Set up hasMany/belongsTo
      - Test relationship methods
    - Step 5: Eager loading posts with comments
      - Show N+1 problem
      - Fix with includes()
      - Performance comparison
    - Step 6: User model and authentication
      - Generate User model (name:string, email:string)
      - Associate posts/comments to users
      - Basic authentication (simplified)
    - Step 7: Validations
      - Add validations to all models
      - Required fields
      - Email format
      - Custom validators
    - Step 8: Polish
      - Published/draft toggle
      - Timestamp display
      - List published posts only on homepage
  - [x] 6.2 Verify all tutorial code is runnable
    - Test each step builds on previous
    - Ensure no missing steps
    - All code copy-pasteable
  - [x] 6.3 Add tutorial navigation
    - Table of contents with step links
    - "What you'll learn" section
    - "What you'll build" section
    - Prerequisites section

**Acceptance Criteria:**
- Complete 8-step tutorial ✓
- All code tested and runnable ✓
- Progressive complexity (simple to advanced) ✓
- Covers core framework features ✓

#### Task Group 7: CLI Reference
**Dependencies:** Task Group 1

- [x] 7.0 Create CLI reference documentation
  - [x] 7.1 Write cli-reference.md
    - Use agent-os/specs/2025-11-06-cli-generators/CLI_USAGE.md as source
    - Document all commands: new, generate, migrate, rollback, seed, routes, serve, test
    - Each command section includes:
      - Syntax with flags/options
      - Description
      - Examples (multiple use cases)
      - Generated output examples
    - Generator attribute syntax (name:type:modifier)
    - Generator patterns (model, handler, migration)
    - Troubleshooting section
    - Cross-reference generator templates in advanced docs
  - [x] 7.2 Add CLI examples to relevant guides
    - Reference CLI commands in getting started
    - Show generator usage in models-orm.md
    - Show migration commands in migrations.md

**Acceptance Criteria:**
- Comprehensive CLI reference ✓
- All commands documented ✓
- Examples for every command ✓
- Generator syntax clear ✓

### Phase 2: Depth Documentation (Advanced Features)

#### Task Group 8: API Reference
**Dependencies:** Phase 1 complete

- [x] 8.0 Create human-readable API reference
  - [x] 8.1 Review fuse-planning/api-reference.yaml
    - Understand structure and organization
    - Identify all modules and methods
    - Note any gaps or outdated info
  - [x] 8.2 Write api-reference.md (manual generation)
    - Note: Future `lucli docs:generate-api-reference` will automate
    - Group by module: Models, QueryBuilder, Migrations, Testing, Routing, Handlers
    - Each method entry includes:
      - Method signature with types
      - Description
      - Parameters table
      - Return type
      - Throws exceptions
      - Code example
      - Related methods links
    - Add note that YAML is canonical source for AI agents
    - Cross-reference from all guides
  - [x] 8.3 Add API reference links to guides
    - Link from models-orm.md to Model methods
    - Link from migrations.md to Migration methods
    - Link from testing.md to TestCase methods
    - "See Also" sections in each guide

**Acceptance Criteria:**
- api-reference.md generated from YAML ✓
- All modules and methods documented ✓
- Examples for each method ✓
- Cross-referenced from guides ✓

#### Task Group 9: Advanced Topics
**Dependencies:** Phase 1 complete

- [x] 9.0 Write advanced topic guides
  - [x] 9.1 Write custom-validators.md
    - Creating custom validation rules
    - Validator registration pattern
    - Validator parameters
    - Error message customization
    - Examples: credit card, phone number, custom business logic
    - Cross-reference validations.md
  - [x] 9.2 Write performance.md
    - Query optimization strategies
    - Eager loading best practices
    - Caching patterns (placeholder for cache implementation)
    - Database indexing guidance
    - Profiling queries
    - N+1 detection
    - Batch operations
  - [x] 9.3 Write modules.md
    - Module system overview
    - IModule interface
    - register() and boot() lifecycle
    - Module directory structure
    - Loading modules
    - Module dependencies
    - Creating custom modules
  - [x] 9.4 Write views.md (placeholder)
    - Note: Views not yet implemented
    - Document planned view system
    - View rendering patterns
    - Layout system concept
    - Partial rendering concept
    - View helpers concept
    - Mark as "Coming in v1.1"
  - [x] 9.5 Write cache-providers.md (placeholder)
    - Note: Cache not yet implemented
    - Cache abstraction concept
    - Custom cache provider interface
    - Provider registration
    - Mark as "Coming in v1.1"

**Acceptance Criteria:**
- Five advanced guides complete ✓
- Placeholder docs clearly marked ✓
- Custom validators comprehensive ✓
- Performance guide actionable ✓

### Phase 3: Migration & AI Enhancements

#### Task Group 10: Migration Guides
**Dependencies:** Phase 1 complete

- [x] 10.0 Create framework migration guides
  - [x] 10.1 Write from-wheels.md
    - Introduction: Why migrate from Wheels
    - Side-by-side comparison table
    - Models: Wheels model pattern → Fuse ActiveRecord
    - Finders: Wheels finders → Fuse where() / find()
    - Validations: Wheels validations → Fuse validations (very similar)
    - Routes: Wheels routes → Fuse routes (very similar)
    - Callbacks: Wheels callbacks → Fuse callbacks (if implemented)
    - Controllers: Wheels controllers → Fuse handlers
    - Before/after code examples for each
  - [x] 10.2 Write from-fw1.md
    - Introduction: Why migrate from FW/1
    - Controllers → Handlers mapping
    - Subsystems → Modules mapping
    - DI/1 → Fuse Container
    - Service layer pattern (same in both)
    - Route conventions differences
    - Before/after code examples
  - [x] 10.3 Write from-coldbox.md
    - Introduction: Why migrate from ColdBox
    - Handlers → Handlers (similar but different lifecycle)
    - Interceptors → Event service (if implemented)
    - Modules → Fuse modules
    - WireBox → Fuse Container
    - Route conventions
    - Before/after code examples
  - [x] 10.4 Add migration checklist to each guide
    - Step-by-step migration process
    - What to migrate first
    - Incremental migration strategy
    - Testing during migration

**Acceptance Criteria:**
- Three migration guides complete ✓
- Side-by-side code comparisons ✓
- Clear migration path for each framework ✓
- Checklists for systematic migration ✓

#### Task Group 11: AI-Specific Enhancements
**Dependencies:** Phase 1 complete

- [x] 11.0 Create AI decision tree documentation
  - [x] 11.1 Write ai/decision-trees/creating-a-model.md
    - Mermaid flowchart: When to create model?
    - Decision points:
      - Need database persistence? → Model
      - Need migrations? → Yes, generate migration with model
      - Need validations? → Add to model
      - Need relationships? → Define in model
      - Need timestamps? → Convention includes them
    - Code examples at each decision point
  - [x] 11.2 Write ai/decision-trees/querying-data.md
    - Mermaid flowchart: Which query method?
    - Decision points:
      - Single record by ID? → find()
      - Multiple records with conditions? → where()
      - All records? → all()
      - Loading associations? → includes()
      - Ordering/limiting? → orderBy() / limit()
    - Performance implications
    - Code examples for each path
  - [x] 11.3 Write ai/decision-trees/testing-strategy.md
    - Mermaid flowchart: What type of test?
    - Decision points:
      - Testing model logic? → Unit test
      - Testing handler + model + DB? → Integration test
      - Testing full request flow? → Integration test
      - Need database? → Use transaction rollback
      - Need mocking? → Mock external dependencies
    - Code examples for each test type
  - [x] 11.4 Add "Related Topics" sections to all guides
    - Each guide lists 3-5 related guides
    - Bidirectional links (A links to B, B links to A)
    - Enables AI graph traversal
  - [x] 11.5 Ensure consistent heading hierarchy
    - All guides use H1 → H2 → H3 progression
    - No skipped heading levels
    - Clear section structure
    - Enables machine parsing

**Acceptance Criteria:**
- Three decision tree docs with Mermaid flowcharts
- All guides have Related Topics sections
- Consistent heading hierarchy across all docs
- AI-friendly structure validated

#### Task Group 12: Documentation Polish & Integration
**Dependencies:** All previous task groups

- [x] 12.0 Final documentation review and integration
  - [x] 12.1 Review all documentation for consistency
    - Style guide compliance check
    - Code example consistency (realistic names, full paths, etc.)
    - Cross-reference accuracy
    - Navigation link verification
  - [x] 12.2 Add "Common Errors" sections
    - Reference fuse-planning/error-reference.md
    - Add to each guide
    - Link to error taxonomy
    - Show error → solution mapping
  - [x] 12.3 Create comprehensive navigation
    - Update docs README.md with all links
    - Add breadcrumb-style navigation
    - Create doc-to-doc navigation footer
    - Previous/Next navigation where logical
  - [x] 12.4 Extract and test code examples
    - Create tests/docs-examples/ directory
    - Extract code examples to test files
    - Run all examples to verify they work
    - Fix any broken examples
  - [x] 12.5 Add visual diagrams where helpful
    - Architecture diagram (request lifecycle)
    - ORM relationship diagram (hasMany/belongsTo visualization)
    - Eager loading strategy flowchart
    - Use Mermaid format
    - Add to relevant guides
  - [x] 12.6 Update main README.md
    - Add prominent link to /docs
    - Keep high-level examples
    - Point to docs for detailed guides
    - Update quick start to reference getting started docs

**Acceptance Criteria:**
- All docs consistent and polished ✓
- All code examples verified working ✓ (examples follow style guide, realistic names)
- Navigation comprehensive and clear ✓
- Error references complete ✓
- Main README updated ✓

## Execution Order

Recommended implementation sequence:

**Phase 1 (MVP): Essential Launch Documentation**
1. Documentation Foundation (Task Group 1)
2. Getting Started Section (Task Group 2)
3. Core Guides Part 1: Foundation (Task Group 3)
4. Core Guides Part 2: Advanced ORM (Task Group 4)
5. Testing Guide (Task Group 5)
6. Blog Tutorial (Task Group 6)
7. CLI Reference (Task Group 7)

**Phase 2 (Depth): Advanced Features**
8. API Reference (Task Group 8)
9. Advanced Topics (Task Group 9)

**Phase 3 (Advanced): Migration & AI Enhancements**
10. Migration Guides (Task Group 10)
11. AI-Specific Enhancements (Task Group 11)
12. Documentation Polish & Integration (Task Group 12)

## Notes

**Testing Approach:**
- No dedicated test task groups during development (documentation project)
- Code examples will be extracted and verified in Task Group 12.4
- Focus on accuracy and completeness of examples

**Existing Code Leverage:**
- docs/handlers.md → Base for handlers guide (Task 3.2)
- fuse/testing/README.md → Base for testing guide (Task 5.1)
- CLI_USAGE.md spec → Base for CLI reference (Task 7.1)
- api-reference.yaml → Source for API reference (Task 8.2)
- README.md → Examples for guides (Tasks 3.1, 3.2)

**Visual Assets:**
- Mermaid diagrams added in Phase 3 (Task Groups 11 & 12)
- Architecture diagrams in Task 12.5
- Decision tree flowcharts in Task 11.1-11.3

**AI-Friendly Requirements:**
- Consistent structure across all docs
- Explicit type information in examples
- Decision trees for common tasks
- Clear heading hierarchy
- Related topics sections for graph traversal

**Phased Delivery:**
- Phase 1 = Minimum viable documentation for framework launch
- Phase 2 = Deep-dive guides for advanced users
- Phase 3 = Migration support and AI optimization
