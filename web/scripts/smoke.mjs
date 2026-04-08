const baseUrl = (process.env.SMOKE_BASE_URL || "http://127.0.0.1:3000").replace(/\/$/, "");

async function request(path, init = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    redirect: "manual",
    ...init,
  });

  const text = await response.text();
  return {
    status: response.status,
    location: response.headers.get("location") || "",
    contentType: response.headers.get("content-type") || "",
    body: text,
  };
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

async function check(name, fn) {
  try {
    await fn();
    console.log(`PASS ${name}`);
  } catch (error) {
    console.error(`FAIL ${name}`);
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  }
}

await check("home page loads", async () => {
  const response = await request("/");
  assert(response.status === 200, `Expected 200, got ${response.status}`);
  assert(response.body.includes("CONSTRUCTIONOS") || response.body.includes("CONSTRUCT"), "Home page content missing expected brand text");
});

await check("pricing page loads", async () => {
  const response = await request("/pricing");
  assert(response.status === 200, `Expected 200, got ${response.status}`);
  assert(response.body.includes("Built for Every Hard Hat"), "Pricing page missing expected content");
});

await check("projects preview loads", async () => {
  const response = await request("/preview/projects");
  assert(response.status === 200, `Expected 200, got ${response.status}`);
  assert(response.body.includes("Project Command"), "Projects preview missing expected title");
  assert(response.body.includes("Unlock Full Feature"), "Projects preview missing upgrade CTA");
});

await check("ai preview loads", async () => {
  const response = await request("/preview/ai");
  assert(response.status === 200, `Expected 200, got ${response.status}`);
  assert(response.body.includes("Angelic AI"), "AI preview missing expected title");
});

await check("jobs preview loads", async () => {
  const response = await request("/preview/jobs");
  assert(response.status === 200, `Expected 200, got ${response.status}`);
  assert(response.body.includes("Construction Jobs Board"), "Jobs preview missing expected title");
});

await check("jobs route loads", async () => {
  const response = await request("/jobs");
  assert(response.status === 200, `Expected 200, got ${response.status}`);
  assert(response.body.includes("Construction Jobs Board") || response.body.includes("Construction Jobs In Real Time"), "Jobs page missing expected content");
});

await check("protected live projects route redirects to login when signed out", async () => {
  const response = await request("/projects");
  assert(response.status === 307, `Expected 307, got ${response.status}`);
  assert(response.location.includes("/login?redirect=%2Fprojects"), `Unexpected redirect location: ${response.location}`);
});

await check("protected live ai route redirects to login when signed out", async () => {
  const response = await request("/ai?prompt=Show%20me%20project%20risk%20examples");
  assert(response.status === 307, `Expected 307, got ${response.status}`);
  assert(response.location.includes("/login?redirect=%2Fai"), `Unexpected redirect location: ${response.location}`);
});

await check("chat api returns angelic response", async () => {
  const response = await request("/api/chat", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      messages: [{ role: "user", content: "What plan fits a growing GC?" }],
    }),
  });

  assert(response.status === 200, `Expected 200, got ${response.status}`);
  assert(response.contentType.includes("text/plain"), `Unexpected content type: ${response.contentType}`);
  assert(response.body.includes("I'm Angelic"), "Chat response missing Angelic response");
});

await check("jobs api responds", async () => {
  const response = await request("/api/jobs");
  assert(response.status === 200, `Expected 200, got ${response.status}`);
  assert(response.contentType.includes("application/json"), `Unexpected content type: ${response.contentType}`);
  assert(response.body.includes("\"jobs\""), "Jobs API missing jobs payload");
});

await check("jobs api requires auth for posting", async () => {
  const response = await request("/api/jobs", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      title: "Test role",
      company: "ConstructionOS",
      location: "Houston, TX",
      pay: "$40/hr",
      trade: "General",
      employmentType: "Full-time",
      description: "Test description",
    }),
  });

  assert(response.status === 401, `Expected 401, got ${response.status}`);
  assert(response.body.includes("Sign in required"), "Jobs API missing auth requirement message");
});

await check("export api responds", async () => {
  const response = await request("/api/export");
  assert(response.status === 200, `Expected 200, got ${response.status}`);
  assert(response.contentType.includes("application/json"), `Unexpected content type: ${response.contentType}`);
});

await check("checkout api rejects invalid plan", async () => {
  const response = await request("/api/billing/checkout", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      planId: "invalid",
      billing: "monthly",
      payMethod: "card",
    }),
  });

  assert(response.status === 400, `Expected 400, got ${response.status}`);
  assert(response.body.includes("Invalid plan selection"), "Checkout validation message missing");
});

await check("checkout page loads", async () => {
  const response = await request("/checkout?plan=pm");
  assert(response.status === 200, `Expected 200, got ${response.status}`);
  assert(response.body.includes("Start Your Free Trial"), "Checkout page missing expected content");
});

if (process.exitCode) {
  process.exit(process.exitCode);
}
