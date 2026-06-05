# Production Setup

> This document is a placeholder. Full production environment setup is tracked in issue [#62](issues/062-multi-environment-infra.md).

---

## Key Differences from Dev

| Concern | Dev | Production |
|---|---|---|
| `MIX_ENV` | `dev` | `prod` (compiled release, no hot reload) |
| Database | `gibbering_dev` (local Docker) | Managed Postgres instance — never reset |
| Secrets | `.env` defaults | Injected via environment or secrets manager — never committed |
| Admin route exposure | Localhost only | Restricted to internal network / VPN (see Security below) |
| Monitoring | LiveDashboard (dev mode) | LiveDashboard behind admin auth + `Stores.Local` metrics |

---

## Security

> **Admin route restriction is mandatory.**
> The `/admin` scope must not be reachable from the public internet.
> Configure your reverse proxy (nginx / Caddy) to restrict `/admin` to an internal IP range or VPN.

Example nginx rule (adjust CIDR to your internal range):

```nginx
location /admin {
    allow 10.0.0.0/8;
    deny all;
    proxy_pass http://app:4000;
}
```

All HTTP access to `/admin` should also be logged at the load-balancer level, independently of the app-level audit log.

---

## Environment Variables

| Variable | Notes |
|---|---|
| `DATABASE_URL` | Production DB connection string — use a secrets manager |
| `SECRET_KEY_BASE` | Generate with `mix phx.gen.secret` — never reuse dev/qa value |
| `PHX_HOST` | Production hostname |
| `MIX_ENV` | `prod` |
| `POOL_SIZE` | Postgres connection pool size — tune to DB instance limits |

---

## To Be Defined

See issue [#62](issues/062-multi-environment-infra.md) for:

- Release build and Docker image for production (`MIX_ENV=prod`)
- Orchestration / hosting choice (fly.io, Render, VPS, k8s, etc.)
- Database provisioning, backup, and migration workflow
- TLS termination and reverse proxy config
- Secrets management strategy
- Deployment pipeline (CI → build → deploy)
- Rollback procedure
