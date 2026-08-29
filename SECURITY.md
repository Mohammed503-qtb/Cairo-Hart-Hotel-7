# Security Policy

## Reporting a vulnerability

If you discover a security vulnerability in **Cairo Heart Hotel**, please report
it responsibly.

- **Email**: security@cairoheart.ye
- **PGP**: available on request
- **Do not** open a public GitHub issue for security reports.

We will acknowledge receipt within 48 hours and provide an estimated timeline
for a fix within 5 business days.

## Scope

| Component | In scope |
|---|---|
| Next.js API routes (`src/app/api/**`) | Yes |
| Prisma schema (`prisma/schema.prisma`) | Yes |
| Flutter app (`mobile/lib/**`) | Yes |
| Supabase RLS / Postgres policies | Yes |
| GitHub Actions workflows (`.github/workflows/**`) | Yes |
| Anything behind a private Supabase project (not the public schema mirror) | Out of scope |

## Disclosure policy

- We follow **coordinated disclosure**.
- After a fix is shipped, we will publish a security advisory on GitHub with
  credits to the reporter (unless they prefer to remain anonymous).

## Hardening checklist for production deployments

- [ ] Rotate the Supabase `service_role` key quarterly.
- [ ] Enable RLS on every table in the public schema.
- [ ] Restrict Supabase API URL to known origins (CORS allow-list).
- [ ] Set up Supabase log drain to a SIEM.
- [ ] Enable GitHub branch protection on `main` (required status checks + signed commits).
- [ ] Use `dependabot` for dependency updates (already configured).
- [ ] Pin `flutter-action` and `setup-bun` to a SHA, not a floating tag, in workflows.
- [ ] Set Android `PRODUCTION_API_BASE` to an HTTPS URL with a valid certificate.
- [ ] Use HSTS (`max-age=63072000; includeSubDomains; preload`) on the API host.
