# Security Policy

## Supported Versions

| Version | Supported |
|---|---|
| 1.0.x | ✅ |
| < 1.0 | ❌ (archived in `archived-original` branch) |

## Reporting a Vulnerability

Please **DO NOT** open a public issue for security vulnerabilities. Instead,
email the maintainer privately at the address listed on the GitHub profile.

You should receive a response within 72 hours. Please include:

- Description of the issue and its potential impact
- Steps to reproduce
- Suggested fix (if any)

## Production Hardening Checklist

Before deploying to a commercial environment:

- [ ] Replace in-memory store with a real database (Postgres/Supabase recommended).
- [ ] Add authentication + per-stay authorization middleware.
- [ ] Move secrets (DB credentials, payment gateway keys, WhatsApp API) to a
      secrets manager — never commit them.
- [ ] Configure Android signing keystore via CI secrets (see README).
- [ ] Configure iOS signing certificate + provisioning profile via CI secrets.
- [ ] Enable HTTPS everywhere (Caddy/Cloudflare in front of the web build).
- [ ] Set up monitoring + alerting (Sentry / Crashlytics).
- [ ] Run `flutter test` in CI and add unit/widget tests for the booking,
      check-in, billing, and checkout flows.
- [ ] Review the audit log retention policy.
- [ ] Run a security review of the payment flow.

## Guest Data Isolation

The platform enforces guest data isolation by design:
- A guest session is bound to a specific stay via an activation code.
- A guest can only read their own stay, requests, charges, and notifications.
- Reception and Admin roles are separated; reception does not inherit admin rights.
- All state transitions are recorded in the audit log.
