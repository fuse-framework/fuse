# Open Questions

Unresolved questions and decisions deferred for later.

---

## Architecture Questions

### Session Management
**Question**: How should sessions be handled?

**Options**:
1. Built-in session module with pluggable stores (cookie, database, Redis)
2. Use CFML native sessions + helpers
3. Stateless (JWT) by default, sessions optional

**Impact**: Auth, CSRF, flash messages depend on sessions

**Decision needed by**: Week 3 (for auth considerations)

---

### CSRF Protection
**Question**: Where should CSRF protection live?

**Options**:
1. Core module (always available)
2. Separate module (opt-in)
3. Middleware pattern (explicit per-route)

**Considerations**:
- Modern SPAs may not need CSRF (using tokens)
- Traditional forms need protection
- Should it be automatic or explicit?

**Decision needed by**: Week 4 (when implementing forms)

---

### Asset Pipeline
**Question**: Should Fuse include asset compilation?

**Options**:
1. Built-in asset pipeline (Rails-like)
2. Integration with Vite/esbuild
3. No opinion (users choose)
4. Module ecosystem approach

**Considerations**:
- Modern frontend often separate build process
- Some apps want integrated pipeline
- Complexity vs convenience trade-off

**Decision needed by**: Post-1.0 (not critical for MVP)

---

### Background Jobs
**Question**: How to handle async/background processing?

**Options**:
1. Built-in queue module
2. Integration with external queues (Redis, RabbitMQ)
3. Simple thread-based solution
4. Separate package

**Considerations**:
- Common need for modern apps
- Lucee threading vs proper queue
- Job persistence and retry logic

**Decision needed by**: Post-1.0 (common request)

---

## ORM Questions

### Query Builder Immutability
**Question**: Should query builder clone on each method or mutate?

**Options**:
1. **Mutate** (ActiveRecord/Eloquent pattern)
   - Faster, less memory
   - Can cause bugs if query reused
2. **Clone** (Django pattern)
   - Safer, immutable
   - More memory/CPU overhead

**Current decision**: Mutate (performance)
**Revisit if**: Users report bugs from query reuse

---

### Soft Deletes
**Question**: Built-in soft delete support?

**Options**:
1. Built into ActiveRecord (global scope)
2. Trait/mixin pattern
3. Module/plugin
4. User implements manually

**Considerations**:
- Common feature
- Adds complexity to queries
- Not all models need it

**Decision needed by**: Week 10 (with validations)

---

### Multi-Database Support
**Question**: Support for multiple database connections?

**Options**:
1. Single connection (simpler)
2. Multiple named connections
3. Read/write splitting
4. Sharding support

**Considerations**:
- Many apps need multiple DBs
- Read replicas common in production
- Adds routing complexity

**Decision needed by**: Week 6 (during ActiveRecord implementation)

---

### Database Support
**Question**: Which databases to support initially?

**Options**:
- MySQL/MariaDB ✓ (definitely)
- PostgreSQL ✓ (definitely)
- MSSQL ? (Lucee support?)
- Oracle ? (less common)
- H2 ? (embedded, testing)

**Decision needed by**: Week 5 (query builder)

---

## Testing Questions

### Test Database Strategy
**Question**: How to handle test databases?

**Options**:
1. Separate test database (config-based)
2. In-memory database (H2)
3. Transaction rollback (faster)
4. Database cleaning (DatabaseCleaner pattern)

**Recommendation**: Transaction rollback + cleaning
**Decision needed by**: Week 12

---

### Browser Testing
**Question**: Support for browser/integration testing?

**Options**:
1. Headless browser integration (Selenium)
2. HTTP client testing only
3. Third-party tool integration (TestBox, Selenium)
4. No built-in support

**Decision needed by**: Post-1.0

---

## CLI Questions

### Interactive Console (REPL)
**Question**: Should we build interactive console?

**Options**:
1. Full REPL with model access
2. Basic command runner
3. lucli integration only
4. Skip for 1.0

**Considerations**:
- Very useful for debugging
- Complex to implement well
- lucli may provide this

**Decision needed by**: Week 14

---

### Code Generation Customization
**Question**: How customizable should generators be?

**Options**:
1. Fixed templates (simple)
2. User can override templates
3. Hooks for customization
4. Full template engine

**Decision needed by**: Week 13

---

## Module System Questions

### Module Versioning
**Question**: How to handle module version compatibility?

**Options**:
1. Semantic versioning enforcement
2. Framework version in module manifest
3. No formal system (trust developers)
4. Compatibility matrix

**Decision needed by**: Post-1.0 (as ecosystem grows)

---

### Module Conflicts
**Question**: What if two modules provide same service?

**Options**:
1. Last loaded wins
2. Explicit priority system
3. Error on conflict
4. Configuration overrides

**Decision needed by**: Week 4 (module system implementation)

---

## Security Questions

### Authentication Strategy
**Question**: Built-in auth or module?

**Options**:
1. Core auth module (basic)
2. Separate fuse-auth module
3. Multiple auth modules (fuse-devise, fuse-jwt)
4. User implements

**Recommendation**: Separate fuse-auth module
**Decision needed by**: Post-1.0

---

### Authorization/Permissions
**Question**: Built-in authorization?

**Options**:
1. Built-in (CanCan/Pundit-like)
2. Separate module
3. User implements
4. Policy objects pattern

**Decision needed by**: Post-1.0

---

### Input Sanitization
**Question**: Automatic XSS protection?

**Options**:
1. Auto-escape in views (Rails pattern)
2. Manual escaping (explicit)
3. Configurable per-app
4. Content Security Policy focus

**Recommendation**: Auto-escape with explicit raw() helper
**Decision needed by**: Week 4 (views)

---

## Performance Questions

### Caching Strategy
**Question**: What should be cached by default?

**Options**:
1. Nothing (explicit only)
2. Query results (configurable)
3. Rendered views (configurable)
4. Route resolution

**Decision needed by**: Week 7 (based on benchmarks)

---

### Production Optimizations
**Question**: Special production mode?

**Options**:
1. Production environment config
2. Compiled route table
3. Cached templates
4. Optimized DI container

**Decision needed by**: Week 15 (production prep)

---

## Developer Experience Questions

### Error Pages
**Question**: How detailed should error pages be?

**Options**:
1. Full stack traces in dev
2. Better Errors / Whoops-style pages
3. Simple errors in production
4. Configurable detail level

**Decision needed by**: Week 2 (early feedback)

---

### Logging
**Question**: Built-in logging or external?

**Options**:
1. Built-in logger (PSR-3 style)
2. Lucee native logging
3. LogBox integration
4. Pluggable logging

**Decision needed by**: Week 15

---

### Development Reload
**Question**: Hot reload in development?

**Options**:
1. Lucee 7 singleton mode (restart required)
2. File watching + selective reload
3. Module hot reload only
4. No hot reload (fast restart)

**Decision needed by**: Week 16 (developer feedback)

---

## Configuration Questions

### Config Format
**Question**: CFCs only or support JSON/YAML?

**Options**:
1. CFC only (current decision)
2. JSON support
3. YAML support
4. Multiple formats

**Current**: CFC only (type safety, IDE support)
**Revisit if**: Users strongly prefer JSON/YAML

---

### Environment Detection
**Question**: How to detect environment?

**Current**: `FUSE_ENV` environment variable
**Alternative**: Hostname patterns, file presence

---

## Deployment Questions

### Docker Support
**Question**: Provide official Docker images?

**Options**:
1. Official Lucee 7 + Fuse images
2. Dockerfile examples only
3. Community-maintained
4. No official support

**Decision needed by**: Post-1.0

---

### Cloud Platform Support
**Question**: Optimize for specific platforms?

**Platforms**: AWS, Azure, Heroku, Kubernetes
**Decision needed by**: Post-1.0 (based on adoption)

---

## Documentation Questions

### API Documentation
**Question**: Auto-generate API docs?

**Options**:
1. Use Lucee 7 AST API
2. JavaDoc-style comments
3. Manual documentation
4. DocBox integration

**Decision needed by**: Week 15

---

### Tutorial Complexity
**Question**: Simple or comprehensive tutorial?

**Options**:
1. Simple blog (CRUD basics)
2. Complex app (relationships, auth, etc)
3. Multiple tutorials (basic + advanced)

**Decision needed by**: Week 16

---

## Community Questions

### Contribution Guidelines
**Question**: How open to contributions?

**Considerations**:
- Code style enforcement
- Test requirements
- Review process
- Release cadence

**Decision needed by**: Week 16 (before 1.0)

---

### Module Registry
**Question**: Central module registry?

**Options**:
1. ForgeBox integration
2. Custom registry
3. GitHub topics/tags
4. No formal registry

**Decision needed by**: Post-1.0

---

## Migration Questions

### From Other Frameworks
**Question**: Provide migration tools?

**Frameworks**: Wheels, FW/1, ColdBox

**Options**:
1. Migration CLI commands
2. Code generators from existing
3. Documentation only
4. Community-driven

**Decision needed by**: Week 16 (migration guides)

---

## Priority Rankings

### Critical (Must decide for 1.0)
1. Input sanitization strategy (Week 4)
2. Multi-database support (Week 6)
3. Soft deletes (Week 10)
4. Test database strategy (Week 12)

### Important (Should decide for 1.0)
1. CSRF protection approach (Week 4)
2. Error page detail (Week 2)
3. Logging strategy (Week 15)

### Nice to Have (Can defer)
1. Background jobs
2. Asset pipeline
3. Browser testing
4. Hot reload

### Post-1.0
1. Auth/authorization
2. Docker images
3. Module registry
4. Cloud platform optimization

---

## Decision Process

For each question:
1. **Research**: Look at Rails, Django, Laravel approaches
2. **Prototype**: Try implementation if unclear
3. **Document**: Write decision in appropriate MD file
4. **Implement**: Code the solution
5. **Test**: Validate decision with real usage

---

## Notes

Keep this doc updated as decisions are made. Move resolved questions to decision docs. Add new questions as they arise during implementation.
