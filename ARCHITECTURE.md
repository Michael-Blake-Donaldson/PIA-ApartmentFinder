# PIA Architecture Notes

## Backend Architecture

### Modular Monolith
PIA uses a **modular monolith** approach — the codebase is structured like microservices (clear domain boundaries, no cross-package direct repo calls) but ships as a single deployable JAR. This enables fast local development while keeping the door open to service extraction later.

### Package Conventions
Each domain module follows:
```
com.pia.<domain>/
  controller/    HTTP layer only — delegates to service
  service/       Business logic, orchestration
  domain/        JPA entities
  repository/    Spring Data JPA repos
  dto/           Request/response shapes (never expose entities)
  mapper/        Entity ↔ DTO mapping
  exception/     Domain-specific exceptions
  event/         Domain events (Spring ApplicationEvent)
  scheduler/     @Scheduled jobs scoped to domain
  validator/     Custom Bean Validation constraints
```

### Parser Architecture
The parsing system is designed around the **Adapter Strategy Pattern**:
```
ParserOrchestrator
  └── selects SourceAdapter by domain
        ├── ApartmentsComAdapter
        ├── ZillowRentalAdapter
        ├── RealtorRentalAdapter
        ├── GenericMetadataAdapter  ← fallback (OG/JSON-LD/Schema.org)
        └── ManualEntryFallback
```

Each adapter returns a `ParsedListing` with a `parserConfidence` score (0.0–1.0) and `parserWarnings` list. The system never claims certainty — it always shows the user what it found and what it missed.

### Change Detection
On every listing refresh:
1. Fetch current page state
2. Create new `ListingSnapshot`
3. Compare against previous snapshot via `SnapshotDiffService`
4. Emit `ListingChangedEvent` with `ChangeType` enum payload
5. `AlertService` consumes event → persists `Alert` record
6. `NotificationService` consumes event → sends email if user preference set

### Scoring Engine
Scores are computed as a weighted sum, normalized to 0–100:
```
score = Σ(weight_i × normalized_value_i) / Σ(weight_i) × 100
```

Each dimension (price, size, commute, safety, amenities, etc.) is normalized against the user's tracked listings pool so scores are relative, not absolute. The score breakdown is always returned alongside the total.

### Providers (Abstraction Pattern)
External integrations use provider interfaces with clear swap points:
- `GeocodingProvider` → `NominatimGeocodingProvider` (dev) / can swap to Google
- `CommuteProvider` → `MockCommuteProvider` (dev) / can swap to GMAPS Distance Matrix
- `SafetyProvider` → `AdminSeedSafetyProvider` (dev) / can swap to NeighborhoodScout

### Security
- JWT access token (15 min default) + refresh token (7 days, stored in DB)
- Refresh token rotation: each use issues a new refresh token, invalidates old
- BCrypt password hashing (strength 12)
- Role-based access: `ROLE_USER`, `ROLE_ADMIN`
- All endpoints require auth except `/api/auth/*` and public actuator
- Rate limiting on auth endpoints via HandlerInterceptor

---

## Frontend Architecture

### Feature-Based Structure
Pages and logic are co-located by feature, not by technical layer:
```
features/auth/      LoginPage, RegisterPage, auth store, hooks
features/dashboard/ DashboardPage, widgets
features/listings/  ListingsPage, ListingDetail, AddListing, hooks, api
features/map/       MapPage, MapPanel, clustering logic
...
```

### State Strategy
- **Server state**: TanStack Query (caching, invalidation, optimistic updates)
- **Global client state**: Zustand (auth session, UI preferences)
- **Local UI state**: React `useState` / `useReducer`
- Avoid storing server data in Zustand — TanStack Query owns that

### Animation Strategy
Framer Motion is used sparingly for high-value moments:
- `AnimatePresence` for route transitions (fade + slide)
- Staggered entrance for card lists (`staggerChildren: 0.05`)
- `whileHover` / `whileTap` for interactive elements
- `motion.div` for filter drawers (slide in from side)
- No infinite animations, no bouncing, no particles

### Design Token System
Tailwind config extends the default palette with semantic tokens:
```ts
colors: {
  surface: { ... },
  primary: { ... },
  accent: { ... },
  muted: { ... },
  danger: { ... },
}
```
Switching themes requires only updating `tailwind.config.ts` tokens.

---

## Database Design Notes

- All tables have `created_at` + `updated_at` with `DEFAULT NOW()`
- Soft delete via `deleted_at` only where audit trail matters (listings, users)
- Snapshots are append-only — never updated, only inserted
- Alerts are immutable records — marked read, never deleted
- Parser runs and failures are log tables — insert only
- Indexes on all FK columns, search-heavy columns (city, state, rent, status)
- UUIDs as PKs for user-facing entities (harder to enumerate)
- BIGSERIAL for internal log/event tables (performance)
