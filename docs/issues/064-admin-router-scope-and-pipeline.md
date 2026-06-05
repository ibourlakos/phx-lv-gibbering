# #64 · Admin router scope and pipeline

**Status:** open
**Opened:** 2026-06-05
**Priority:** medium
**Tags:** architecture, ops

Create the `/admin` router scope in `GibberingWeb.Router` with a dedicated pipeline that gates all admin routes behind support user authentication. This is the foundation all other admin features build on.

**Acceptance criteria**
- [ ] `:admin` pipeline defined — includes `:browser` plug chain + a `RequireSupportUser` plug that redirects unauthenticated requests to a support login page
- [ ] `scope "/admin"` wired to `pipe_through [:browser, :admin]`
- [ ] `GibberingWeb.Plugs.RequireSupportUser` implemented — checks `support_user_id` in session; redirects to `/admin/login` if absent
- [ ] A minimal `/admin` index page renders for authenticated support users and returns 302 for unauthenticated requests
- [ ] Player session cookies do not grant access to any `/admin` route
