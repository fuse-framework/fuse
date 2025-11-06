# Fuse Framework Mission

## Pitch
Fuse is a modern Rails-inspired CFML framework that helps developers build web applications faster and with less boilerplate by providing convention-over-configuration patterns, batteries-included tooling, and exclusive Lucee 7 features like static methods and ActiveRecord ORM.

## Users

### Primary Customers
- **Modern CFML Developers**: Teams/individuals using Lucee 7 wanting Rails-like productivity
- **Rails/Laravel Migrants**: Developers familiar with modern frameworks bringing patterns to CFML
- **AI-Assisted Developers**: Teams leveraging AI coding tools (Cursor, Claude) needing machine-readable framework docs
- **Framework Maintainers**: Developers maintaining legacy CFML apps seeking modern upgrade path

### User Personas

**Solo Developer** (25-45)
- **Role:** Full-stack web developer, freelancer or small agency
- **Context:** Building web apps quickly, values productivity over complexity
- **Pain Points:** Existing CFML frameworks too complex (ColdBox) or outdated (FW/1), lack Rails-like conventions, poor AI code generation
- **Goals:** Ship products fast, write less boilerplate, leverage modern patterns

**Development Team Lead** (30-50)
- **Role:** Technical lead at company using Lucee
- **Context:** Managing 3-10 developers, need consistent codebases, easy onboarding
- **Pain Points:** Mixed framework adoption, inconsistent patterns across projects, slow onboarding, legacy compatibility holding back innovation
- **Goals:** Standardize tech stack, improve team velocity, attract modern talent, reduce maintenance burden

**AI-First Developer** (20-40)
- **Role:** Developer heavily using AI assistants for code generation
- **Context:** Pair programming with Claude/Cursor, needs accurate framework code generation
- **Pain Points:** AI hallucinates CFML framework APIs, no machine-readable docs, existing frameworks poorly understood by AI
- **Goals:** Generate correct framework code via AI, reduce manual corrections, trust AI suggestions

## The Problem

### Legacy Frameworks Hold CFML Back
Existing CFML frameworks (ColdBox, FW/1, Wheels) maintain Adobe CF compatibility, preventing use of Lucee 7's modern features: static methods, Jakarta EE access, improved performance. This legacy baggage creates verbose syntax, complex configuration, and outdated patterns that reduce developer productivity compared to Rails, Laravel, or Django.

**Our Solution:** Lucee 7 exclusive framework embracing static methods, convention-over-configuration, and modern patterns without compromise.

### No AI-Friendly CFML Framework
AI coding assistants struggle with CFML frameworks due to lack of machine-readable API documentation, inconsistent patterns, and complex configuration. This limits AI-assisted development effectiveness in CFML ecosystem.

**Our Solution:** Machine-readable YAML API schema, explicit types/returns, code generation templates, and decision trees enable accurate AI code generation.

### Productivity Gap vs Modern Frameworks
Rails/Laravel/Django developers experience faster development through conventions, batteries-included tools, and cohesive ecosystems. CFML frameworks require more boilerplate, separate tools (TestBox, CommandBox), and extensive configuration.

**Our Solution:** Built-in DI, ORM, testing, CLI, migrations in single cohesive package with Rails-strong conventions.

## Differentiators

### Lucee 7 Exclusive - Modern Features Without Compromise
Unlike ColdBox/FW/1/Wheels supporting Adobe CF + old Lucee, Fuse targets Lucee 7 only. This enables clean static method syntax (`User::find(1)`), Jakarta EE access, and modern runtime features. Results in expressive ActiveRecord patterns matching Rails/Laravel instead of verbose service layer architecture.

### ActiveRecord ORM with Hash-Based Queries
Unlike method-chained where clauses (`where('active', true).where('age', '>=', 18)`), Fuse uses natural CFML struct syntax: `where({active: true, age: {gte: 18}})`. Two-layer architecture (QueryBuilder + ModelBuilder) enables standalone query builder use and provides smart eager loading preventing N+1 queries automatically.

### AI-First Documentation Architecture
Unlike prose-only framework docs, Fuse provides machine-parseable YAML API reference with explicit types, returns, throws, and execution timing. Includes code generation templates, decision trees, and error taxonomy enabling AI to generate correct framework code without hallucination.

### Batteries Included, Zero External Dependencies
Unlike FW/1 (no ORM/testing) or ColdBox (requires WireBox/TestBox/CommandBox separately), Fuse includes DI, ActiveRecord ORM, migrations, testing framework, and CLI in single install. Results in version-locked, cohesive toolchain with consistent conventions.

### Convention-Over-Configuration, Rails-Strong
Unlike ColdBox's XML/annotation configuration or FW/1's minimal conventions, Fuse enforces Rails-level conventions: file structure, naming patterns, RESTful routes, table names. Results in zero-config models, automatic route generation, and consistent codebases across teams.

## Key Features

### Core Features
- **ActiveRecord ORM:** Models extending base class with automatic table mapping, CRUD methods, hash-based query syntax, relationship definitions
- **Smart Eager Loading:** Eliminates N+1 queries via includes() with automatic strategy selection (JOIN vs separate queries)
- **CFC-Based Migrations:** Type-safe database migrations with schema builder, IDE auto-complete, up/down methods
- **Built-in Testing:** Rails-like test framework with assertions, model factories, handler testing helpers, database rollback
- **lucli CLI Integration:** Code generators (model/handler/migration), database commands (migrate/rollback/seed), dev server, test runner

### Convention Features
- **Zero-Config Models:** Convention-based table names (User → users), primary keys (id), timestamps (created_at/updated_at)
- **RESTful Resource Routes:** Single `router.resource("users")` generates 7 CRUD routes automatically
- **Auto-Discovery:** Modules, models, handlers loaded automatically from conventional directories
- **Dependency Injection:** Property-based auto-wiring, constructor injection, singleton/transient scopes

### Developer Experience Features
- **Validations DSL:** Declarative model validations (required, email, unique, length, format) with error collection
- **Lifecycle Callbacks:** beforeSave, afterSave, beforeCreate, afterCreate, beforeDelete, afterDelete hooks
- **Named Routes:** Generate URLs from route names, parameter interpolation, RESTful helpers
- **View Rendering:** Layout wrapping, partial support, helper methods, template isolation

### Advanced Features
- **Module System:** Everything-is-a-module architecture, IModule interface, dependency resolution, pluggable components
- **Event System:** Interceptor points throughout request lifecycle, module-provided interceptors
- **Pluggable Cache:** ICacheProvider interface, built-in RAM provider, third-party provider support (Redis, Memcached)
- **AI Code Generation:** Templates for models/handlers/migrations, decision trees for common tasks, error reference

## Success Metrics

### Adoption Metrics
- GitHub stars/forks indicating community interest
- lucli downloads tracking framework installs
- Active projects built with Fuse (tracked via opt-in registry)

### Developer Productivity Metrics
- Time to first working CRUD app (<15 minutes target)
- Lines of code saved vs ColdBox/Wheels for equivalent features (target: 40-60% reduction)
- Onboarding time for new team members (target: <1 day productive)

### Technical Metrics
- Framework startup time (<200ms target)
- Per-request overhead (<1ms target)
- Test suite execution speed (<5s for 100 tests)
- N+1 query elimination rate (>95% via eager loading)

### Community Health Metrics
- Active contributors (target: 10+ in first year)
- Issue response time (target: <48 hours)
- Documentation coverage (target: 100% public API)
- Tutorial completion rate (target: >80%)
