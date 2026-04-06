import { test, expect } from "@playwright/test";

// ---------------------------------------------------------------------------
// Fake JWT for middleware bypass (same pattern as auth-project spec)
// ---------------------------------------------------------------------------

function makeFakeJWT(): string {
  const header = { alg: "HS256", typ: "JWT" };
  const payload = {
    sub: "user-e2e-001",
    email: "e2e@test.com",
    exp: Math.floor(Date.now() / 1000) + 3600,
    aud: "authenticated",
    role: "authenticated",
  };

  const encode = (obj: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(obj))
      .toString("base64url")
      .replace(/=+$/, "");

  return `${encode(header)}.${encode(payload)}.fake-signature`;
}

const FAKE_JWT = makeFakeJWT();

const MOCK_RESPONSE = "I can help you with construction project management.";

// ---------------------------------------------------------------------------
// Setup: fake auth cookie + intercept chat API
// ---------------------------------------------------------------------------

test.beforeEach(async ({ page, context }) => {
  // Set fake auth cookie so middleware JWT fast-path passes
  await context.addCookies([
    {
      name: "sb-test-auth-token",
      value: FAKE_JWT,
      domain: "localhost",
      path: "/",
    },
  ]);

  // Intercept Supabase auth endpoints
  await page.route("**/auth/v1/**", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        user: { id: "user-e2e-001", email: "e2e@test.com" },
        session: { access_token: FAKE_JWT },
      }),
    });
  });

  // Intercept POST /api/chat with a plain text streaming response
  // The AI page reads the response body as a stream via res.body.getReader()
  // and appends decoded chunks to the assistant message content
  await page.route("**/api/chat", async (route) => {
    if (route.request().method() === "POST") {
      await route.fulfill({
        status: 200,
        contentType: "text/plain; charset=utf-8",
        body: MOCK_RESPONSE,
      });
    } else {
      await route.continue();
    }
  });
});

// ---------------------------------------------------------------------------
// Test: Chat page renders and shows initial assistant greeting
// ---------------------------------------------------------------------------

test("AI chat page renders with greeting message", async ({ page }) => {
  await page.goto("/ai");

  // The page shows a greeting from Angelic on load
  await expect(page.getByText("Angelic")).toBeVisible({ timeout: 10_000 });

  // Chat input should be visible
  const chatInput = page.locator("#chat-input");
  await expect(chatInput).toBeVisible();

  // Send button should be visible
  await expect(page.getByRole("button", { name: /send/i })).toBeVisible();
});

// ---------------------------------------------------------------------------
// Test: Send a message and receive a mocked AI response
// ---------------------------------------------------------------------------

test("sending a chat message shows AI response", async ({ page }) => {
  await page.goto("/ai");

  // Wait for page to finish loading
  await expect(page.locator("#chat-input")).toBeVisible({ timeout: 10_000 });

  // Type a message
  const chatInput = page.locator("#chat-input");
  await chatInput.fill("How do I create a new project?");

  // Click send
  await page.getByRole("button", { name: /send/i }).click();

  // The user message should appear
  await expect(
    page.getByText("How do I create a new project?")
  ).toBeVisible();

  // The mocked AI response should appear
  await expect(
    page.getByText("construction project management")
  ).toBeVisible({ timeout: 10_000 });
});

// ---------------------------------------------------------------------------
// Test: Send message via Enter key
// ---------------------------------------------------------------------------

test("pressing Enter sends the chat message", async ({ page }) => {
  await page.goto("/ai");

  await expect(page.locator("#chat-input")).toBeVisible({ timeout: 10_000 });

  const chatInput = page.locator("#chat-input");
  await chatInput.fill("What is my bid win rate?");
  await chatInput.press("Enter");

  // User message should appear
  await expect(page.getByText("What is my bid win rate?")).toBeVisible();

  // Mocked response should appear
  await expect(
    page.getByText("construction project management")
  ).toBeVisible({ timeout: 10_000 });
});
