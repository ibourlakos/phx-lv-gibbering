# #64 · Admin router scope and pipeline

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-06
**Priority:** medium
**Tags:** architecture, ops

Create the `/admin` router scope in `GibberingWeb.Router` with a dedicated pipeline that gates all admin routes behind support user authentication. This is the foundation all other admin features build on.

**Acceptance criteria**
- [x] `:admin` pipeline defined — includes `:browser` plug chain + a `RequireSupportUser` plug that redirects unauthenticated requests to a support login page
- [x] `scope "/admin"` wired to `pipe_through [:browser, :admin]`
- [x] `GibberingWeb.Plugs.RequireSupportUser` implemented — checks `support_user_id` in session; redirects to `/admin/login` if absent
- [x] A minimal `/admin` index page renders for authenticated support users and returns 302 for unauthenticated requests
- [x] Player session cookies do not grant access to any `/admin` route
