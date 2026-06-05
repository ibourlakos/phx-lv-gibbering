# #62 · Multi-environment infrastructure (QA + production)

**Status:** deferred
**Opened:** 2026-06-05
**Deferred because:** No production infrastructure exists yet. Placeholder setup docs have been created at docs/qa-setup.md and docs/prod-setup.md. This issue covers designing and implementing the full QA and production environments.
**Priority:** low
**Tags:** ops, architecture

Design and implement the QA and production environments for the Gibbering Engine. The dev environment (Docker Compose, local Postgres) is already established — see [docs/dev-setup.md](../docs/dev-setup.md).

See placeholder documents:
- [docs/qa-setup.md](../docs/qa-setup.md)
- [docs/prod-setup.md](../docs/prod-setup.md)

**Acceptance criteria**
- [ ] Production release build (`MIX_ENV=prod`) compiles and boots
- [ ] Hosting/orchestration choice is made and documented
- [ ] TLS termination and reverse proxy configured; `/admin` restricted to internal network
- [ ] Secrets management strategy documented and implemented (no secrets in env files)
- [ ] Database provisioning, backup, and migration workflow documented
- [ ] QA environment mirrors production config against a separate, disposable DB
- [ ] CI/CD pipeline deploys to QA on merge to `main`
- [ ] Rollback procedure documented
- [ ] docs/qa-setup.md and docs/prod-setup.md updated to reflect final setup
