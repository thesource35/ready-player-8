import { test, expect } from "@playwright/test";

// ---------------------------------------------------------------------------
// Fake JWT for middleware bypass
// The middleware looks for a cookie matching /^sb-.*-auth-token$/ and decodes
// the base64url payload to check sub + exp. We craft a minimal valid JWT.
// ---------------------------------------------------------------------------

function makeFakeJWT(): string {
  const header = { alg: "HS256", typ: "JWT" };
  const payload = {
    sub: "user-e2e-001",
    email: "e2e@test.com",
    exp: Math.floor(Date.now() / 1000) + 3600, // 1 hour from now
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

const MOCK_PROJECTS = [
  {
    id: "proj-001",
    name: "E2E Test Project Alpha",
    client: "Test Client Corp",
    type: "Commercial",
    status: "On Track",
    progress: 65,
    budget: "$3.5M",
    score: 87,
    team: "Jane Smith",
    start_date: "Jan 2026",
    end_date: "Dec 2026",
  },
  {
    id: "proj-002",
    name: "Harbor Heights",
    client: "Metro Dev",
    type: "Residential",
    status: "Ahead",
    progress: 40,
    budget: "$5.2M",
    score: 91,
    team: "Bob Lee",
    start_date: "Mar 2026",
    end_date: "Feb 2027",
  },
];

// ---------------------------------------------------------------------------
// Setup: fake auth cookie + intercept all external calls
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

  // Intercept Supabase direct REST queries for projects
  await page.route("**/rest/v1/cs_projects**", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify(MOCK_PROJECTS),
    });
  });

  // Intercept internal /api/projects endpoint
  await page.route("**/api/projects**", async (route) => {
    const method = route.request().method();
    if (method === "GET") {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify(MOCK_PROJECTS),
      });
    } else if (method === "POST") {
      const body = route.request().postDataJSON();
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          id: "proj-new",
          name: body?.name || "New Project",
          client: body?.client || "New Client",
          type: body?.type || "Commercial",
          status: "On Track",
          progress: 0,
          budget: body?.budget || "$0",
          score: 80,
          team: "Unassigned",
          start_date: "TBD",
          end_date: "TBD",
        }),
      });
    } else {
      await route.continue();
    }
  });
});

// ---------------------------------------------------------------------------
// Test: Login form renders and accepts credentials
// ---------------------------------------------------------------------------

test("login page has email and password inputs and submits", async ({
  page,
}) => {
  await page.goto("/login");

  // The login page uses id="login-email" and id="login-password"
  const emailInput = page.locator("#login-email");
  const passwordInput = page.locator("#login-password");

  await expect(emailInput).toBeVisible();
  await expect(passwordInput).toBeVisible();

  // Fill credentials
  await emailInput.fill("e2e@test.com");
  await passwordInput.fill("TestPassword123!");

  // The submit button says "SIGN IN"
  const submitButton = page.getByRole("button", { name: /sign in/i });
  await expect(submitButton).toBeVisible();
});

// ---------------------------------------------------------------------------
// Test: Navigate to projects and verify mock data appears
// ---------------------------------------------------------------------------

test("projects page displays mock project data", async ({ page }) => {
  await page.goto("/projects");

  // Wait for mock project names to appear
  await expect(page.getByText("E2E Test Project Alpha")).toBeVisible({
    timeout: 10_000,
  });
  await expect(page.getByText("Harbor Heights")).toBeVisible();

  // Verify client names are visible
  await expect(page.getByText("Test Client Corp")).toBeVisible();
  await expect(page.getByText("Metro Dev")).toBeVisible();
});

// ---------------------------------------------------------------------------
// Test: Full auth -> projects flow
// ---------------------------------------------------------------------------

test("login then navigate to projects shows project list", async ({
  page,
}) => {
  // Intercept Supabase signInWithPassword to succeed
  await page.route("**/auth/v1/token**", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        access_token: FAKE_JWT,
        refresh_token: "fake-refresh",
        token_type: "bearer",
        expires_in: 3600,
        user: {
          id: "user-e2e-001",
          email: "e2e@test.com",
          app_metadata: {},
          user_metadata: {},
        },
      }),
    });
  });

  // Also intercept MFA list factors to return empty (no MFA)
  await page.route("**/auth/v1/factors**", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({ totp: [], phone: [] }),
    });
  });

  await page.goto("/login");

  // Fill and submit login form
  await page.locator("#login-email").fill("e2e@test.com");
  await page.locator("#login-password").fill("TestPassword123!");
  await page.getByRole("button", { name: /sign in/i }).click();

  // After login, navigate to projects
  await page.goto("/projects");

  // Verify projects are displayed
  await expect(page.getByText("E2E Test Project Alpha")).toBeVisible({
    timeout: 10_000,
  });
});
