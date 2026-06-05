# #60 · Umbrella restructure for independent admin app deployment

**Status:** deferred
**Opened:** 2026-06-05
**Deferred because:** Admin panel is being implemented as a router scope in the single Phoenix app. An umbrella restructure only pays off when independent deployment, separate supervision trees, or separate release cadences become real requirements. None of those exist yet.
**Priority:** low
**Tags:** discovery, architecture, ops

The admin web app is currently scoped as a `/admin` router pipeline within the main Phoenix application. If any of the following become real requirements, revisit extracting it into an OTP umbrella sub-app (`apps/gibbering_admin`):

- The admin panel needs to be deployed on a different release cadence than the game app
- The admin panel needs its own supervision tree restart policy or resource limits
- The admin panel needs a completely separate Phoenix endpoint (port, session config, static assets pipeline) that cannot be achieved via router scope alone

**Acceptance criteria**
- [ ] A concrete triggering requirement is identified (one of the above, or a new one)
- [ ] The cost of umbrella conversion at that point in the codebase is assessed
- [ ] If proceeding: all apps compile, tests pass, Docker config is updated, and dev-setup.md reflects the new structure
