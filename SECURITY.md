# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, **please do not open a public issue.** Responsible disclosure helps protect users while a fix is being prepared.

### How to report

Send a private report through one of the following channels:

- Open a [private security advisory](https://github.com/hasanoso151/you-app/security/advisories/new) on GitHub (preferred)
- Or contact the maintainer directly via the email address listed on the [@hasanoso151](https://github.com/hasanoso151) GitHub profile

### What to include

To help us triage your report quickly, please include:

1. **Affected component** — the file, screen, service, or endpoint involved
2. **Type of vulnerability** — e.g., authentication bypass, injection, data leakage, privilege escalation
3. **Steps to reproduce** — minimal, deterministic steps that reliably trigger the issue
4. **Impact assessment** — what an attacker could achieve, and which users are affected
5. **Proof of concept** — code, screenshots, or videos if available
6. **Suggested mitigation** — if you have ideas, we'd love to hear them

### Our commitment

- We will **acknowledge** your report within **72 hours**.
- We will provide an **initial assessment** within **7 days**.
- We will keep you informed of remediation progress.
- We will **credit you** in the release notes once the issue is fixed, unless you prefer to remain anonymous.

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.2.x   | ✅        |
| < 1.2   | ❌        |

Only the latest minor release receives security updates.

## Security Practices in This Project

- **No secrets in source.** All API keys, signing keys, and credentials are loaded from `.env` at runtime and excluded from version control via `.gitignore`.
- **Row-Level Security.** Health and user data is stored in Supabase under RLS policies that scope access to the authenticated user only.
- **Least-privilege auth.** Anonymous keys are scoped to the public schema with explicit RLS allowlists; service-role keys are never embedded in the client.
- **Input validation at boundaries.** All user input passed to the AI scanner, database, or external APIs is validated.
- **Dependency hygiene.** Dependencies are reviewed and updated regularly; transitive vulnerabilities are tracked.

## Out of Scope

The following are explicitly **out of scope** for security reports:

- Vulnerabilities in third-party services (Supabase, Google APIs, AdMob) — please report those upstream.
- Issues requiring physical access to an unlocked device.
- Social engineering attacks against the maintainer.
- Self-XSS or attacks requiring an already-compromised user device.

---

Thank you for helping keep YOU and its users safe.
