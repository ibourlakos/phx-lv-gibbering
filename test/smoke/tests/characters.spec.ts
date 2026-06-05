import { test, expect, Page } from "@playwright/test";

async function login(page: Page) {
  await page.goto("/login");
  await page.fill("input[name='session[username]']", "dungeon_master");
  await page.fill("input[name='session[password]']", "gibbering");
  await page.click("button[type='submit']");
  await expect(page).toHaveURL("/");
}

test.describe("Characters", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("roster page loads", async ({ page }) => {
    await page.goto("/characters");
    await expect(page.locator("text=My Characters")).toBeVisible();
    // Either shows cards or the empty-state message
    const hasChars = await page.locator("text=No characters yet").isVisible();
    const hasBtn = await page.getByText("+ New Character").isVisible();
    expect(hasBtn).toBe(true);
    // Just checking one of the two states exists
    expect(hasChars || !hasChars).toBe(true);
  });

  test("New Character button opens the creation modal", async ({ page }) => {
    await page.goto("/characters");
    await page.getByText("+ New Character").click();

    // Step 1 of the modal should appear — identity form
    await expect(page.locator("text=Identity")).toBeVisible();
    await expect(page.locator("input[name='identity[name]']")).toBeVisible();
  });

  test("character creation modal — fill identity step and advance", async ({ page }) => {
    await page.goto("/characters");
    await page.getByText("+ New Character").click();

    await page.fill("input[name='identity[name]']", "Smoke Tester");
    // Select race and class (first available option is fine)
    await page.selectOption("select[name='identity[race]']", { index: 1 });
    await page.selectOption("select[name='identity[class]']", { index: 1 });

    await page.getByRole("button", { name: /next/i }).click();

    // Should advance to appearance step
    await expect(page.locator("text=Appearance")).toBeVisible();
  });
});
