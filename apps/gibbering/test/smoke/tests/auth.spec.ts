import { test, expect } from "@playwright/test";

// Uses the seeded dungeon_master account (password: gibbering).
// Requires: docker compose exec app mix ecto.setup

test.describe("Authentication", () => {
  test("login page loads", async ({ page }) => {
    await page.goto("/login");
    await expect(page.locator("input[name='session[username]']")).toBeVisible();
    await expect(page.locator("input[name='session[password]']")).toBeVisible();
    await expect(page.getByRole("button", { name: /log in/i })).toBeVisible();
  });

  test("login with valid credentials redirects to home", async ({ page }) => {
    await page.goto("/login");
    await page.fill("input[name='session[username]']", "dungeon_master");
    await page.fill("input[name='session[password]']", "gibbering");
    await page.click("button[type='submit']");

    await expect(page).toHaveURL("/");
    await expect(page.locator("text=Campaigns")).toBeVisible();
  });

  test("login with wrong password shows error", async ({ page }) => {
    await page.goto("/login");
    await page.fill("input[name='session[username]']", "dungeon_master");
    await page.fill("input[name='session[password]']", "wrongpassword");
    await page.click("button[type='submit']");

    await expect(page.locator("text=Invalid")).toBeVisible();
  });

  test("register a new account and log in", async ({ page }) => {
    const username = `smoke_${Date.now()}`;

    await page.goto("/register");
    await page.fill("input[name='user[username]']", username);
    await page.fill("input[name='user[password]']", "smoke_password");
    await page.click("button[type='submit']");

    // Should land on home after registration
    await expect(page).toHaveURL("/");
    // Nav should show the username
    await expect(page.locator(`text=${username}`)).toBeVisible();
  });

  test("logout clears the session", async ({ page }) => {
    await page.goto("/login");
    await page.fill("input[name='session[username]']", "dungeon_master");
    await page.fill("input[name='session[password]']", "gibbering");
    await page.click("button[type='submit']");
    await expect(page).toHaveURL("/");

    await page.click("button[type='submit']"); // logout button
    await expect(page).toHaveURL("/login");
  });
});
