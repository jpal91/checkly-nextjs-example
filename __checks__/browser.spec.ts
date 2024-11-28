import { test, expect } from "@playwright/test";

// Configure the Playwright Test timeout to 210 seconds,
// ensuring that longer tests conclude before Checkly's browser check timeout of 240 seconds.
// The default Playwright Test timeout is set at 30 seconds.
// For additional information on timeouts, visit: https://checklyhq.com/docs/browser-checks/timeouts/
test.setTimeout(210000);

// Set the action timeout to 10 seconds to quickly identify failing actions.
// By default Playwright Test has no timeout for actions (e.g. clicking an element).
test.use({
  actionTimeout: 10000,
});

const inputFields = ["First Name", "Last Name", "Email"];

test("has title", async ({ page }) => {
  await page.goto("/");

  await expect(page).toHaveTitle("Checkly Form Example");
});

test("has complete form", async ({ page }) => {
  await page.goto("/");

  // Has the form title
  const formHeading = page.getByRole("heading", {
    name: "Sign Up For Our Awesome Service",
  });
  await expect(formHeading).toBeVisible();

  // Makes sure all form fields are present
  for (const field of inputFields) {
    const input = page.getByLabel(field);
    await expect(input).toBeVisible();
  }
});

test("submit button is disabled", async ({ page }) => {
  await page.goto("/");

  const button = page.getByRole("button", { name: "Submit" });

  // Clicking should not take us anywhere since form isn't filled
  await button.click({ force: true });
  await expect(page).toHaveURL("/");
});

test("form won't submit with invalid inputs", async ({ page }) => {
  await page.goto("/");

  for (const field of inputFields) {
    const input = page.getByLabel(field);
    // Will be invalid for email
    await input.fill("words");
  }

  await page.getByRole("button", { name: "Submit" }).click({ force: true });
  await expect(page).toHaveURL("/");
});

test("form submits and redirects", async ({ page }) => {
  await page.goto("/");

  const fieldsWithInputs = inputFields.map((f, i) =>
    i === 2 ? [f, f + "@gmail.com"] : [f, f],
  );

  // Fills form with valid inputs
  for (const [field, text] of fieldsWithInputs) {
    const input = page.getByLabel(field);
    await input.fill(text);
  }

  // Click submit and wait for redirect
  await page.getByRole("button", { name: "Submit" }).click();
  await expect(page).toHaveURL("/thank-you");

  // Ensures heading of the new page appears
  const heading = page.getByRole("heading", { name: "Thank you" });
  await expect(heading).toBeVisible();
});
