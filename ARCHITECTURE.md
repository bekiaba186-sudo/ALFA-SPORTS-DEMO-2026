# ALFA Sports Platform — Architecture Blueprint

## Product scope
A multilingual (English, Amharic, Afaan Oromo) sports platform designed for a future regulated launch. The included runnable app is a local demo prototype only. It uses sample fixtures and browser-local demo credits with no cash value. It does not connect to payment providers, live sports feeds, casino games, or real-money wagering.

## Target scale
Design target: 100,000+ registered accounts. This is a capacity objective, not a performance guarantee. Validate using load tests and production telemetry.

## Recommended production topology
- Web: Next.js / React, responsive PWA.
- Android: React Native or native Kotlin client, sharing typed API contracts.
- API gateway: TLS termination, WAF, rate limiting, request validation.
- Identity: managed OIDC or hardened auth service; MFA for staff; short-lived access tokens and rotating refresh tokens.
- Core services: identity/profile, sports catalogue, event ingestion, market/odds, demo ticket service, ledger, admin/audit, notifications, localization.
- Data: PostgreSQL primary with read replicas; Redis for cache/rate limiting; object storage for documents; queue/event bus for provider updates and notifications.
- Observability: central logs, metrics, tracing, alerting, immutable audit trail.
- Deployment: containers, CI/CD, secrets manager, backups, disaster-recovery runbooks.

## Core data flow
1. Licensed data provider sends signed event/odds updates.
2. Ingestion adapter validates schema, provider identity, timestamp, version and replay protection.
3. Event/market service persists updates and publishes events.
4. Client reads catalogue through cache/API.
5. Demo selection service validates fixture state and stores a demo ticket only.
6. Ledger records append-only demo-credit movements.
7. Admin dashboard reads permission-filtered analytics and audit history.

## Security and integrity requirements
- Never store plaintext passwords; use Argon2id or bcrypt with tuned parameters.
- Enforce MFA for privileged accounts and least-privilege RBAC.
- Use server-side authorization; never trust client-calculated balances or outcomes.
- Idempotency keys for all state-changing requests.
- Append-only financial/audit records; compensating reversals instead of deletion.
- Encrypt transport and sensitive data at rest; rotate keys; store secrets outside source control.
- Rate-limit login, OTP, search and state-changing endpoints; bot and abuse protection.
- Secure SDLC, dependency scanning, SAST/DAST, penetration tests and independent audit.
- Age/identity checks, AML, sanctions screening, privacy, data retention and incident response must be designed with local counsel and regulator.
- Responsible-use controls: self-exclusion, cooling-off, time/limit tools and help resources.
- Do not enable real-money features until legal authorization, regulator approvals, payment approval and independent certification are confirmed.

## Availability and scale
- Stateless API replicas behind load balancer.
- Cache public fixture/catalogue reads; keep writes transactional.
- Queue provider bursts; partition high-volume append-only event/audit tables as needed.
- PostgreSQL connection pooling; read replicas for reporting.
- Load-test realistic peaks, failover, replay and duplicate-message scenarios.
- Define SLOs, RPO/RTO and operational ownership before launch.

## Suggested service boundaries
- identity-service
- account-service
- sports-catalogue-service
- provider-ingestion-service
- event-market-service
- demo-ticket-service
- demo-ledger-service
- admin-reporting-service
- audit-compliance-service
- notification-service

## Environment separation
- Local demo: sample data, browser storage, demo credits only.
- Staging: synthetic users and provider sandbox credentials.
- Production: only after legal/compliance/security go-live gates; segregated infrastructure and credentials.
