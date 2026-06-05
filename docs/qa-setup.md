# QA Setup

> This document is a placeholder. Full QA environment setup is tracked in issue [#62](issues/062-multi-environment-infra.md).

A QA environment mirrors production configuration but targets a separate, disposable dataset. It is used for integration testing, pre-release verification, and stakeholder review before promoting to production.

---

## Key Differences from Dev

| Concern | Dev | QA |
|---|---|---|
| `MIX_ENV` | `dev` | `prod` (compiled release, no hot reload) |
| Database | `gibbering_dev` (local Docker) | Separate DB instance — never shares data with prod |
| Secrets | `.env` defaults | Real secrets via environment or secrets manager |
| Admin route exposure | Localhost only | Restricted to internal network / VPN (see Security below) |
| Seed data | Full dev seeds | Anonymised or synthetic dataset |

---

## Security

> **Admin route restriction is mandatory in QA and production.**
> The `/admin` scope must not be reachable from the public internet.
> Configure your reverse proxy (nginx / Caddy) to restrict `/admin` to an internal IP range or VPN before deploying.

Example nginx rule (adjust CIDR to your internal range):

```nginx
location /admin {
    allow 10.0.0.0/8;
    deny all;
    proxy_pass http://app:4000;
}
```

---

## Environment Variables

| Variable | Notes |
|---|---|
| `DATABASE_URL` | Point to the QA database instance |
| `SECRET_KEY_BASE` | Generate with `mix phx.gen.secret` — never reuse dev value |
| `PHX_HOST` | QA hostname |
| `MIX_ENV` | `prod` |

---

## To Be Defined

See issue [#62](issues/062-multi-environment-infra.md) for:

- Docker Compose / orchestration config for QA
- CI/CD pipeline integration (deploy on merge to `main`)
- Database provisioning and migration workflow
- Smoke test suite to run after each QA deploy
