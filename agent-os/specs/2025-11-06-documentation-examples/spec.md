# Specification: Documentation & Examples

## Goal
Create comprehensive, AI-friendly documentation for Fuse framework with code-first examples, progressive learning path, and blog tutorial application.

## User Stories
- As a new developer, I want clear installation and quickstart docs so I can build my first Fuse app in 5 minutes
- As an AI agent, I want machine-parseable docs with complete code examples so I can generate accurate code
- As a migrating developer, I want migration guides from Wheels/FW/1/ColdBox so I can translate existing patterns

## Specific Requirements

**Documentation Structure**
- Four-tier hierarchy: Getting Started → Guides → Reference → Advanced
- All docs in `/docs` directory as GitHub-flavored Markdown
- Versioned folders: `/docs/v1.0/`, `/docs/v1.1/` matching Fuse releases
- README.md overview with navigation links to all sections
- Each doc follows consistent structure: overview → basic usage → common patterns → advanced usage → API reference links

**Getting Started Section**
- installation.md: lucli installation, `lucli new` command, directory structure tour
- quickstart.md: 5-minute walkthrough from `lucli new` to running server with first model/handler
- configuration.md: .env setup, database.cfc config, datasource configuration, environment-specific settings
- All examples show complete file paths and full component declarations

**Core Guides**
- routing.md: RESTful routes, resource routes, named params, wildcards, route naming, urlFor helper
- handlers.md: Handler structure, action methods, DI injection, return values, lifecycle, request/response patterns
- models-orm.md: ActiveRecord basics (find, where, create, save), query building, model conventions, timestamps
- migrations.md: Creating migrations, up/down methods, schema builder API, running/rolling back, migration naming patterns
- validations.md: Model validations, validation rules, custom validators, error handling
- relationships.md: belongsTo, hasMany, hasOne, through relationships, foreign keys, relationship methods
- eager-loading.md: N+1 problem, includes() method, nested eager loading, performance optimization
- testing.md: TestCase setup, assertions, database transactions, test organization, factories/fixtures

**Tutorial: Blog Application**
- Single blog-application.md tutorial building complete blog app progressively
- Step 1: Setup with `lucli new blog`, database config, run migrations
- Step 2: Post model (title, body, published_at), migration, CRUD in console
- Step 3: Posts handler, RESTful routes, index/show/create/update/destroy actions
- Step 4: Comment model with post relationship, hasMany/belongsTo setup
- Step 5: Eager loading to prevent N+1 queries when loading posts with comments
- Step 6: User model with authentication basics, associating posts/comments to users
- Step 7: Validations for required fields, email format, custom validators
- Step 8: Published/draft toggle logic, timestamp display, polish
- Each step shows complete runnable code with file paths

**CLI Reference**
- cli-reference.md documenting all lucli commands: new, generate (model/handler/migration), migrate, rollback, seed, routes, serve, test
- Each command shows syntax, flags/options, examples, generated output
- Generator patterns with attribute syntax (name:type:modifier)
- Cross-reference existing CLI_USAGE.md for accuracy

**API Reference**
- Reference existing /fuse-planning/api-reference.yaml as machine-readable source of truth
- Create api-reference.md as human-readable version generated from YAML
- Group methods by module: Models, QueryBuilder, Migrations, Testing, Routing, Handlers
- Each method shows: signature with types, description, parameters table, return type, throws, example, related methods
- Note in api-reference.md that YAML is canonical source for AI agents

**Migration Guides**
- from-wheels.md: Mapping Wheels patterns to Fuse (models, finders, validations, routes, callbacks)
- from-fw1.md: FW/1 controllers → Fuse handlers, subsystems → modules, DI/1 → Container
- from-coldbox.md: ColdBox handlers → Fuse handlers, interceptors → event service, modules → Fuse modules
- Each guide shows side-by-side code comparisons with "Before" and "After" sections

**Advanced Topics**
- modules.md: Creating Fuse modules, IModule interface, register/boot lifecycle, module structure
- views.md: View rendering, view helpers, layouts, partial rendering (placeholder for future implementation)
- cache-providers.md: Cache abstraction, custom cache providers (placeholder for future implementation)
- custom-validators.md: Creating custom validation rules, validator registration
- performance.md: Query optimization, eager loading strategies, caching patterns, profiling

**Code Example Standards**
- Every example shows full file path as comment: `// app/models/User.cfc`
- Every CFC shows complete component declaration: `component extends="fuse.orm.ActiveRecord" {`
- Use realistic variable names (no foo/bar), match blog tutorial domain where possible
- Show both static and instance methods: `User::find(1)` vs `user.save()`
- Include anti-patterns section showing common mistakes with corrections
- All code must be copy-pasteable and runnable

**AI-Specific Enhancements**
- Decision tree docs in /docs/ai/decision-trees/ with Mermaid flowcharts
- creating-a-model.md: When to use migration? Validation? Relationships? Timestamps?
- querying-data.md: When find() vs where() vs includes()? When to eager load?
- testing-strategy.md: Unit vs integration? Database transactions? Mocking?
- Clear heading hierarchy (H1 → H2 → H3) for machine parsing
- Consistent code block format with `cfml` language tags
- Explicit "Related Topics" sections for graph traversal

## Visual Design

No visual assets provided. Text and code examples only. Consider adding Mermaid diagrams in Phase 2 for architecture, ORM relationships, and request lifecycle.

## Existing Code to Leverage

**docs/handlers.md**
- Already comprehensive handler documentation with lifecycle, DI injection, action methods, return values
- Use as template for documentation style: code-first, clear structure, anti-patterns
- Reference in handlers guide, extract examples

**agent-os/specs/2025-11-06-cli-generators/CLI_USAGE.md**
- Complete CLI generator documentation with examples, syntax, flags, workflows
- Use as basis for cli-reference.md in docs
- Follow same concise style with tables, code blocks, troubleshooting sections

**fuse/testing/README.md**
- Complete testing documentation with assertions, lifecycle, database transactions
- Use as basis for testing.md guide
- Maintain assertion reference, add integration test patterns

**fuse-planning/api-reference.yaml**
- Machine-readable API schema with methods, params, returns, throws
- Source of truth for all API documentation
- Reference for generating human-readable api-reference.md
- AI agents should read YAML directly, humans read generated markdown

**README.md**
- Quick start examples for routing, handlers, CLI commands
- Extract routing examples to routing.md guide
- Extract handler examples to handlers.md guide
- Keep README as high-level overview linking to /docs

**Generator templates from config/templates/**
- Show what generated code looks like (models, handlers, migrations)
- Document template customization in module-development.md advanced guide
- Examples should match generator output for consistency

**Error reference from fuse-planning/error-reference.md**
- Cross-reference in all guides' troubleshooting sections
- Add "Common Errors" section to each guide linking to taxonomy
- Use for anti-patterns sections

## Out of Scope
- Separate documentation website (use GitHub for now, can add later)
- Video tutorials or screencasts
- Interactive code examples or REPL embeds
- Multi-language translations
- Complex architecture diagrams (add Mermaid diagrams in Phase 2)
- Community contribution guides (comes with 1.0 release)
- Plugin/extension marketplace documentation (no marketplace yet)
- Auto-generated API docs from code comments (use YAML instead)
- Search functionality (GitHub search sufficient for now)
- Versioning UI/switcher (simple folder structure for now)
