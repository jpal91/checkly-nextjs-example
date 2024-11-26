import { test, expect } from "@playwright/test";

// Configure the Playwright Test timeout to 210 seconds,
// ensuring that longer tests conclude before Checkly's browser check timeout of 240 seconds.
// The default Playwright Test timeout is set at 30 seconds.
// For additional information on timeouts, visit: https://checklyhq.com/docs/browser-checks/timeouts/
test.setTimeout(210000);

// Set the action timeout to 10 seconds to quickly identify failing actions.
// By default Playwright Test has no timeout for actions (e.g. clicking an element).
// Also add in Vercel Bypass Token, see: https://www.checklyhq.com/docs/cicd/vercel-deployment-protection/
test.use({
  actionTimeout: 10000,
  extraHTTPHeaders: {
    "x-vercel-protection-bypass": process.env.VERCEL_BYPASS_TOKEN!,
  },
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

/**
 * Same as above but fails on purpose.
 *
 * When 'fail@gmail.com' is sent with the form data the api responds back with
 * a newtwork error instead of redirecting to the 'thank-you' page.
 *
 * This is used for demonstrative purposes to show what happens when a
 * test fails on Checkly, specifically to get an alert.
 * */
// test("fails every time", async ({ page }) => {
//   await page.goto("/");
//
//   const fieldsWithInputs = inputFields.map((f, i) =>
//     i === 2 ? [f, "fail@gmail.com"] : [f, f],
//   );
//
//   for (const [field, text] of fieldsWithInputs) {
//     const input = page.getByLabel(field);
//     await input.fill(text);
//   }
//
//   await page.getByRole("button", { name: "Submit" }).click();
//   // Won't actually redirect
//   await expect(page).toHaveURL("/thank-you");
// });
