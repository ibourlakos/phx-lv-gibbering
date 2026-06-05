import { test, expect, Page } from "@playwright/test";

async function login(page: Page) {
  await page.goto("/login");
  await page.fill("input[name='session[username]']", "dungeon_master");
  await page.fill("input[name='session[password]']", "gibbering");
  await page.click("button[type='submit']");
  await expect(page).toHaveURL("/");
}

test.describe("Campaign navigation", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("home page shows campaign list", async ({ page }) => {
    await expect(page.locator("text=Campaigns")).toBeVisible();
  });

  test("can navigate to the lobby", async ({ page }) => {
    // Find the first Lobby link and click it
    const lobbyLink = page.getByRole("link", { name: /lobby/i }).first();
    await expect(lobbyLink).toBeVisible();
    await lobbyLink.click();

    await expect(page).toHaveURL(/\/lobby\//);
    // Lobby should show character slots
    await expect(page.locator("text=The Proving Grounds").or(page.locator("[data-entity-id]")).first()).toBeVisible();
  });

  test("can navigate from lobby to the game", async ({ page }) => {
    const lobbyLink = page.getByRole("link", { name: /lobby/i }).first();
    await lobbyLink.click();
    await expect(page).toHaveURL(/\/lobby\//);

    const gameLink = page.getByRole("link", { name: /game/i }).first();
    await expect(gameLink).toBeVisible();
    await gameLink.click();

    await expect(page).toHaveURL(/\/game\//);
    // The SVG grid should render
    await expect(page.locator("svg")).toBeVisible();
  });

  test("game board renders the SVG grid", async ({ page }) => {
    // Get the campaign id from the first lobby link
    const lobbyLink = page.getByRole("link", { name: /lobby/i }).first();
    const href = await lobbyLink.getAttribute("href");
    const id = href?.split("/").pop();

    await page.goto(`/game/${id}`);
    await expect(page.locator("svg")).toBeVisible();
    // Check at least one tile is rendered
    await expect(page.locator("svg rect, svg polygon").first()).toBeVisible();
  });
});
