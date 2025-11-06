# Implementation Roadmap

Week-by-week implementation plan for Fuse framework.

## Overview

16-week implementation plan covering bootstrap, core modules, ORM, testing, and CLI.

---

## Phase 1: Bootstrap Core (Weeks 1-2)

### Week 1: Foundation
**Goals**: Basic bootstrap, config loading, Application.cfc pattern

**Deliverables**:
- [ ] `fuse/system/Bootstrap.cfc` - Basic initialization
- [ ] `fuse/system/Framework.cfc` - Request handler skeleton
- [ ] `fuse/system/ModuleLoader.cfc` - Module discovery
- [ ] `Application.cfc` - Lucee 7 singleton pattern
- [ ] `config/fuse.cfc` - Configuration structure
- [ ] `.env` file loading support

**Tests**:
- Bootstrap initialization
- Config loading with environment overrides
- .env variable parsing

**Success Criteria**:
- Application starts successfully
- Config loaded from fuse.cfc
- Environment variables override config

### Week 2: DI Container
**Goals**: Dependency injection foundation

**Deliverables**:
- [ ] `fuse/di/Injector.cfc` - DI container
- [ ] `fuse/di/Binder.cfc` - Binding registry
- [ ] Constructor injection support
- [ ] Property injection support
- [ ] Singleton/transient scopes
- [ ] Interface binding

**Tests**:
- Basic getInstance()
- Constructor injection
- Property injection
- Singleton caching
- Interface to implementation binding

**Success Criteria**:
- Can register and resolve dependencies
- Auto-wiring works for properties
- Singletons cached correctly

---

## Phase 2: Core Modules (Weeks 3-4)

### Week 3: Routing & Events
**Goals**: Basic routing and event system

**Deliverables**:
- [ ] `fuse/modules/routing/Module.cfc`
- [ ] `fuse/modules/routing/Router.cfc` - Route registration
- [ ] `fuse/modules/routing/RouteResolver.cfc` - Pattern matching
- [ ] `fuse/modules/events/Module.cfc`
- [ ] `fuse/modules/events/EventService.cfc` - Interceptor system
- [ ] Route pattern matching (static, params, wildcards)
- [ ] Named routes
- [ ] RESTful resource routes

**Tests**:
- Route matching
- Route parameters extraction
- Named route generation
- Event registration and announcement

**Success Criteria**:
- Can define routes in config/routes.cfm
- Routes resolve to handlers
- Can register and trigger interceptors

### Week 4: Cache & Views
**Goals**: Cache abstraction and view rendering

**Deliverables**:
- [ ] `fuse/modules/cache/Module.cfc`
- [ ] `fuse/modules/cache/CacheManager.cfc`
- [ ] `fuse/modules/cache/providers/RAMProvider.cfc`
- [ ] `fuse/interfaces/ICacheProvider.cfc`
- [ ] `fuse/modules/views/Module.cfc`
- [ ] `fuse/modules/views/ViewRenderer.cfc`
- [ ] `fuse/modules/views/LayoutManager.cfc`
- [ ] View helpers system

**Tests**:
- Cache get/set/delete
- Cache expiration
- View rendering
- Layout wrapping
- Helper methods in views

**Success Criteria**:
- Can cache and retrieve values
- Can render views with layouts
- Helpers available in views

---

## Phase 3: ORM Foundation (Weeks 5-7)

### Week 5: Query Builder
**Goals**: Two-layer query builder foundation

**Deliverables**:
- [ ] `fuse/modules/orm/Module.cfc`
- [ ] `fuse/modules/orm/QueryBuilder.cfc` - Raw queries
- [ ] `fuse/modules/orm/ModelBuilder.cfc` - ORM features
- [ ] Hash-based where() implementation
- [ ] Operator structs ({gte:, like:, in:})
- [ ] orderBy(), limit(), offset()
- [ ] Raw SQL support (whereRaw, selectRaw)

**Tests**:
- Simple where conditions
- Operator conditions
- Query chaining
- SQL generation
- Parameter binding

**Success Criteria**:
- Can build complex queries via chaining
- WHERE conditions from structs
- Generates correct SQL with bindings

### Week 6: ActiveRecord Base
**Goals**: Model base class and basic CRUD

**Deliverables**:
- [ ] `fuse/modules/orm/ActiveRecord.cfc` - Base model
- [ ] Static query methods (where, find, all)
- [ ] Instance methods (save, update, delete)
- [ ] Attribute handling
- [ ] Dirty tracking
- [ ] Table name conventions
- [ ] Primary key handling

**Tests**:
- Model.find(id)
- Model.where().get()
- Create and save
- Update attributes
- Delete records
- Dirty tracking

**Success Criteria**:
- Can define models extending ActiveRecord
- CRUD operations work
- Convention-based table names

### Week 7: Schema & Migrations
**Goals**: Migration system and schema builder

**Deliverables**:
- [ ] `fuse/modules/orm/Migration.cfc` - Base migration
- [ ] `fuse/modules/orm/Schema.cfc` - Schema builder
- [ ] `fuse/modules/orm/Migrator.cfc` - Migration runner
- [ ] Table operations (create, drop, rename)
- [ ] Column types (id, string, text, integer, boolean, timestamps)
- [ ] Column modifiers (notNull, unique, default, index)
- [ ] Migration status tracking
- [ ] Up/down migrations

**Tests**:
- Create table migration
- Add column migration
- Migration status
- Rollback migration

**Success Criteria**:
- Can write CFC migrations
- Schema builder creates correct SQL
- Migrator tracks and runs migrations

---

## Phase 4: ORM Relationships (Weeks 8-9)

### Week 8: Relationship Definitions
**Goals**: hasMany, belongsTo, hasOne

**Deliverables**:
- [ ] Relationship definition methods in ActiveRecord
- [ ] hasMany() implementation
- [ ] belongsTo() implementation
- [ ] hasOne() implementation
- [ ] Relationship metadata storage
- [ ] Foreign key conventions
- [ ] Relationship queries (user.posts())

**Tests**:
- Define relationships
- Query through relationships
- Relationship metadata
- Foreign key resolution

**Success Criteria**:
- Can define relationships in models
- Can query via relationships
- Foreign keys resolved correctly

### Week 9: Eager Loading
**Goals**: Smart eager loading to prevent N+1

**Deliverables**:
- [ ] includes() implementation
- [ ] Smart strategy selection (JOIN vs separate)
- [ ] Nested eager loading
- [ ] Manual strategy override (joins, preload)
- [ ] Eager load result hydration

**Tests**:
- Single relationship eager load
- Multiple relationships
- Nested relationships
- Query count verification (no N+1)

**Success Criteria**:
- includes() eliminates N+1 queries
- Nested relationships load correctly
- Smart strategy selection works

---

## Phase 5: Validations & Callbacks (Week 10)

### Week 10: Model Lifecycle
**Goals**: Validation and callbacks

**Deliverables**:
- [ ] `fuse/modules/orm/Validator.cfc`
- [ ] validates() DSL in models
- [ ] Built-in validators (required, email, unique, length, format)
- [ ] Custom validators
- [ ] Validation errors collection
- [ ] Lifecycle callbacks (beforeSave, afterSave, etc)
- [ ] Callback registration

**Tests**:
- Required validation
- Email validation
- Unique validation
- Custom validators
- Validation errors
- Callbacks execution

**Success Criteria**:
- Models validate before save
- Errors accessible on model
- Callbacks run at correct times

---

## Phase 6: Testing Framework (Weeks 11-12)

### Week 11: Test Foundation
**Goals**: Test runner and assertions

**Deliverables**:
- [ ] `fuse/modules/testing/Module.cfc`
- [ ] `fuse/modules/testing/TestCase.cfc` - Base test class
- [ ] `fuse/modules/testing/TestRunner.cfc` - Test execution
- [ ] `fuse/modules/testing/Assertions.cfc` - Assert methods
- [ ] Test discovery (tests/ directory)
- [ ] Test reporting (console output)

**Tests**:
- Test runner finds tests
- Assertions work correctly
- Test failures reported
- Test setup/teardown

**Success Criteria**:
- Can write test classes
- Test runner executes tests
- Assertions provide clear failures

### Week 12: Test Helpers
**Goals**: Framework-specific test helpers

**Deliverables**:
- [ ] Database fixtures/factories
- [ ] Model factories (`make()`, `create()`)
- [ ] Request/response testing helpers
- [ ] Handler testing helpers
- [ ] Integration test support
- [ ] Test database setup/teardown

**Tests**:
- Model factories
- Handler tests
- Integration tests
- Database rollback

**Success Criteria**:
- Can test models easily
- Can test handlers/requests
- Database resets between tests

---

## Phase 7: CLI (Weeks 13-14)

### Week 13: CLI Foundation & Generators
**Goals**: lucli integration and generators

**Deliverables**:
- [ ] `fuse/cli/FuseCLI.cfc` - lucli entry point
- [ ] `fuse/cli/commands/NewCommand.cfc` - New app generator
- [ ] `fuse/cli/commands/GenerateCommand.cfc` - Code generators
- [ ] `fuse/cli/templates/` - Generator templates
- [ ] Generate: handler, model, migration, module
- [ ] Template rendering

**Tests**:
- New app generation
- Handler generation
- Model generation
- Migration generation

**Success Criteria**:
- `lucli fuse:new myapp` creates app
- Generators create correct files
- Generated code is valid

### Week 14: DB Commands & Dev Server
**Goals**: Database and development tools

**Deliverables**:
- [ ] `fuse/cli/commands/MigrateCommand.cfc`
- [ ] `fuse/cli/commands/RollbackCommand.cfc`
- [ ] `fuse/cli/commands/SeedCommand.cfc`
- [ ] `fuse/cli/commands/RoutesCommand.cfc` - List routes
- [ ] `fuse/cli/commands/ServeCommand.cfc` - Dev server
- [ ] `fuse/cli/commands/TestCommand.cfc` - Run tests
- [ ] `fuse/cli/commands/ConsoleCommand.cfc` - REPL (stretch)

**Tests**:
- Migrate command
- Rollback command
- Routes command

**Success Criteria**:
- CLI commands work via lucli
- Migrations run from CLI
- Can list routes
- Can run tests from CLI

---

## Phase 8: Documentation & Polish (Weeks 15-16)

### Week 15: Documentation
**Goals**: Complete documentation

**Deliverables**:
- [ ] Getting Started guide
- [ ] Architecture overview
- [ ] Routing guide
- [ ] ORM guide (models, relationships, migrations)
- [ ] Testing guide
- [ ] Module development guide
- [ ] API reference
- [ ] Configuration reference
- [ ] CLI reference

### Week 16: Example App & Polish
**Goals**: Tutorial app and final polish

**Deliverables**:
- [ ] Tutorial blog application
- [ ] Performance optimization pass
- [ ] Error handling improvements
- [ ] Logging system
- [ ] Production readiness checklist
- [ ] Migration guides (from Wheels, FW/1, ColdBox)
- [ ] 1.0.0 release prep

---

## Milestones

| Week | Milestone | Description |
|------|-----------|-------------|
| 2 | Bootstrap Complete | Framework boots, DI works |
| 4 | Core Modules Complete | Routing, events, cache, views |
| 7 | ORM Foundation Complete | Query builder, ActiveRecord, migrations |
| 9 | ORM Complete | Relationships, eager loading |
| 10 | Validations Complete | Full model lifecycle |
| 12 | Testing Complete | Full test framework |
| 14 | CLI Complete | All generators and commands |
| 16 | 1.0.0 Release | Production-ready framework |

---

## Phase Validation Criteria

### How to Validate Each Phase

**Phase 1 (Bootstrap):**
- Benchmark: Framework startup <200ms (measure with `getTickCount()`)
- Test: Create minimal app, run Application.cfc, verify no errors
- Validation: Config values correctly override from .env

**Phase 2 (Core Modules):**
- Benchmark: Route resolution <1ms (100 routes)
- Test: Define 10 routes, verify all resolve correctly
- Validation: Event system handles 100+ concurrent announcements

**Phase 3 (ORM Foundation):**
- Benchmark: Simple query <5ms, complex query <50ms
- Test: Build query with 10 chained conditions, verify SQL correctness
- Validation: Migration creates tables viewable in database

**Phase 4 (Relationships):**
- Benchmark: Eager loading 100 records with 2 relationships <100ms
- Test: Query N models with relationships, count queries (should be 3, not N+1)
- Validation: Relationship data correctly hydrated on parent models

**Phase 5 (Validations):**
- Test: Model with invalid data, verify save() returns false
- Test: Model with valid data, verify save() returns true
- Validation: Callbacks execute in correct order (log to verify)

**Phase 6 (Testing):**
- Test: Run test suite, verify all tests execute
- Validation: Test database rolls back between tests
- Benchmark: Test suite <1s per 100 tests

**Phase 7 (CLI):**
- Test: Generate handler, verify file created and valid CFML
- Test: Run migration via CLI, verify database updated
- Validation: All generators create compilable code

**Phase 8 (Documentation):**
- Validation: Follow getting started guide, complete without errors
- Test: Tutorial app runs and all features work
- Metric: Can create working CRUD app in <15 minutes

---

## Success Metrics

### Code Quality
- [ ] 80%+ test coverage (run coverage report)
- [ ] All public APIs documented (check for undocumented methods)
- [ ] No critical bugs (GitHub issues tagged "critical" = 0)
- [ ] Performance benchmarks met (see Performance section)

### Documentation
- [ ] Getting started guide complete (external reviewer can follow)
- [ ] All major features documented (features list vs docs coverage)
- [ ] Tutorial app functional (runs without errors)
- [ ] Migration guides for other frameworks (Wheels, FW/1, ColdBox)

### Developer Experience
- [ ] Can create new app in <5 minutes (timed test with new developer)
- [ ] Can scaffold CRUD in <10 minutes (model + handlers + views)
- [ ] Clear error messages (no stack traces in dev mode without context)
- [ ] Fast feedback (tests run in <5s, dev server restarts <2s)

### Performance
- [ ] <200ms framework startup (measured: Application.onApplicationStart)
- [ ] <1ms per-request overhead (measured: simple "Hello World" endpoint)
- [ ] <15MB memory footprint (measured: server monitor after 1000 requests)
- [ ] 1000+ requests/second (measured: JMeter benchmark, simple endpoint)

### Architecture Validation
- [ ] Two-layer query builder enables standalone use (can use QueryBuilder without models)
- [ ] Smart eager loading reduces queries (N+1 becomes 3 queries)
- [ ] Module system supports hot-reload in dev (add module, auto-detected)
- [ ] DI container resolves circular dependencies gracefully (error or resolution)
- [ ] Hash-based where syntax handles complex conditions (nested OR, subqueries)

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Lucee 7 adoption slow | Document benefits, provide migration tools |
| ORM complexity | Start simple, iterate based on feedback |
| Breaking changes | Semantic versioning, deprecation warnings |
| Performance issues | Benchmarks from start, profiling |
| Documentation debt | Write docs alongside code |

---

## Post-1.0 Roadmap

### 1.1 (Q2)
- Background jobs module
- WebSocket support
- Asset pipeline
- I18n support

### 1.2 (Q3)
- GraphQL support
- Admin panel generator
- Monitoring/metrics
- Multi-tenancy support

### 2.0 (Q4)
- Major architectural improvements based on feedback
- Performance optimizations
- Enhanced tooling
