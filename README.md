# PIA — Private Investigator for Apartments

> A smart apartment decision-support platform that tracks listings over time, detects changes, scores options against your preferences, and helps you confidently choose your next home.

---

## The Problem

Apartment hunting is chaotic. You're tracking dozens of listings across multiple sites, prices change without warning, listings get removed, and by the time you decide, the apartment is gone or the price jumped. There's no single place to track everything, compare intelligently, or get alerted when something important changes.

## The Solution

PIA is a personal apartment intelligence platform. Paste a listing URL or enter details manually — PIA extracts the data, tracks changes over time, scores each option against your personal preferences (price, commute, amenities, safety), and alerts you the moment something meaningful changes. It's a command center for your apartment search.

---

## Features

- **Multi-source listing intake** — Paste a URL or enter manually; PIA extracts and normalizes data via an adapter-based parser system with user correction flow
- **Listing history & snapshots** — Every refresh creates a versioned snapshot; view price trends and key changes over time
- **Change detection & alerts** — Automatic detection of price drops, availability changes, listing removals, and new search matches
- **Personalized scoring** — Weighted, explainable apartment scores based on what actually matters to you
- **Commute scoring** — Architecture-ready for live travel APIs; mock provider for instant scoring estimate
- **Neighborhood safety** — Provider-abstracted safety scoring with manual admin seed data for MVP
- **Interactive map** — See all tracked apartments geographically; click to preview; city radius visualization
- **Saved searches** — Define criteria; get notified when new tracked listings match
- **Side-by-side comparison** — Compare multiple apartments across all dimensions
- **Notes** — Attach pros, cons, impressions, and red flags to each listing
- **Email notifications** — Immediate or digest mode per user preference
- **Admin panel** — Parser health monitoring, user overview, failed parse inspection, manual tools
- **JWT authentication** — Secure, refresh-token-capable auth; role-based access control

---

## Architecture Overview

```
PIA-ApartmentFinder/
├── backend/                  # Java 21 + Spring Boot 3
│   └── src/main/java/com/pia/
│       ├── auth/             # JWT auth, refresh tokens
│       ├── user/             # Profile, settings, commute origins
│       ├── listing/          # Core listing entity, notes, images
│       ├── parsing/          # Parser orchestration, adapters, run logging
│       ├── snapshot/         # Versioned listing snapshots
│       ├── detection/        # Change detection engine
│       ├── scoring/          # Weighted scoring engine
│       ├── search/           # Saved searches + matching
│       ├── comparison/       # Comparison sets
│       ├── alerts/           # In-app alerts
│       ├── notifications/    # Email dispatch
│       ├── map/              # Geocoding, radius logic
│       ├── admin/            # Admin endpoints
│       └── audit/            # Audit log
├── frontend/                 # React + Vite + TypeScript
│   └── src/
│       ├── features/         # Feature-scoped pages and logic
│       ├── components/       # Shared UI components
│       ├── hooks/            # Custom React hooks
│       ├── lib/              # API client, query config
│       ├── routes/           # Route definitions
│       └── styles/           # Design tokens, globals
└── docker-compose.yml        # Full stack local dev
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Java 21, Spring Boot 3, Spring Security, Spring Data JPA |
| Database | PostgreSQL 16, Flyway migrations |
| Auth | JWT (access + refresh tokens), BCrypt |
| Parsing | Jsoup, WebClient, adapter strategy pattern |
| Scheduling | Spring Scheduler |
| Email | Spring Mail (SMTP/Mailhog for dev) |
| Frontend | React 18, Vite, TypeScript |
| Styling | Tailwind CSS, Framer Motion |
| State | TanStack Query, Zustand |
| Maps | Leaflet (react-leaflet) |
| Charts | Recharts |
| API Docs | Swagger / OpenAPI 3 |
| DevOps | Docker, Docker Compose |

---

## Screenshots

> *(Placeholders — add screenshots after first run)*

| Landing | Dashboard | Listing Detail |
|---|---|---|
| ![landing](docs/screenshots/landing.png) | ![dashboard](docs/screenshots/dashboard.png) | ![detail](docs/screenshots/detail.png) |

| Map View | Comparison | Admin Panel |
|---|---|---|
| ![map](docs/screenshots/map.png) | ![comparison](docs/screenshots/comparison.png) | ![admin](docs/screenshots/admin.png) |

---

## Quick Start

### Prerequisites

- Docker & Docker Compose
- Java 21 (for local backend dev)
- Node.js 20+ (for local frontend dev)

### 1. Clone & configure

```bash
git clone https://github.com/your-username/pia-apartment-finder.git
cd pia-apartment-finder
cp .env.example .env
# Edit .env with your values (at minimum, set JWT_SECRET)
```

### 2. Run with Docker Compose

```bash
# Start everything (Postgres, backend, frontend, Mailhog)
docker compose --profile dev up --build

# Backend API:    http://localhost:8080
# Frontend:       http://localhost:5173
# Swagger UI:     http://localhost:8080/swagger-ui.html
# Mailhog UI:     http://localhost:8025
```

### 3. Local dev (without Docker)

**Backend:**
```bash
cd backend
# Ensure Postgres is running (via docker compose up postgres)
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

**Frontend:**
```bash
cd frontend
npm install
npm run dev
```

---

## Environment Variables

See [.env.example](.env.example) for the full reference.

Key variables:

| Variable | Description |
|---|---|
| `JWT_SECRET` | **Required.** Min 48 chars. Generate: `openssl rand -base64 64` |
| `DB_PASSWORD` | PostgreSQL password |
| `MAIL_HOST` | SMTP host (use `mailhog` in Docker dev) |
| `VITE_API_BASE_URL` | Frontend → backend URL |
| `VITE_MAPTILER_KEY` | Optional map tile key for richer maps |

---

## API Documentation

Swagger UI is available at:
```
http://localhost:8080/swagger-ui.html
```

OpenAPI JSON:
```
http://localhost:8080/v3/api-docs
```

Core route groups:
- `POST /api/auth/*` — Registration, login, refresh, logout
- `GET/PUT /api/users/me` — Profile and settings
- `POST /api/listings/url` — Submit listing URL for parsing
- `POST /api/listings/manual` — Enter listing manually
- `GET /api/listings/{id}/snapshots` — Change history
- `GET /api/searches` — Saved searches
- `POST /api/comparisons` — Create comparison set
- `GET /api/alerts` — In-app alerts
- `GET /api/map/listings` — Map-ready listing pins
- `GET /api/admin/*` — Admin tools

---

## Future Improvements

- [ ] Real Zillow / Apartments.com adapter with official API or verified scraper
- [ ] Live commute scoring via Google Maps Distance Matrix or HERE API
- [ ] Real crime/safety data via SpotCrime, NeighborhoodScout, or similar
- [ ] OAuth login (Google)
- [ ] AI-assisted pros/cons generation from listing description
- [ ] Mobile app (React Native)
- [ ] Sharing listings with roommates / co-signers
- [ ] Lease expiration reminders
- [ ] Historical rent trend aggregation across listings

---

## Author

Built by [Your Name](https://yourportfolio.com) as a full-stack portfolio project demonstrating Java / Spring Boot backend architecture, React frontend engineering, and real product thinking.

---

## License

MIT
