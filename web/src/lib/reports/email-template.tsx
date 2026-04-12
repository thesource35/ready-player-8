import {
  Html,
  Head,
  Body,
  Container,
  Section,
  Text,
  Link,
  Hr,
  Img,
  Row,
  Column,
} from "@react-email/components";
import { render } from "@react-email/components";

// ---------------------------------------------------------------------------
// D-50c: Branded HTML email template for scheduled report delivery
// Uses @react-email/components for reliable cross-client rendering.
// ---------------------------------------------------------------------------

// Theme colors matching ConstructionOS design system
const BRAND = {
  bg: "#0a1628",
  surface: "#111d33",
  accent: "#f5a623",
  cyan: "#00d4ff",
  green: "#4ade80",
  gold: "#f5a623",
  red: "#ef4444",
  text: "#e2e8f0",
  muted: "#94a3b8",
  white: "#ffffff",
};

type ReportEmailProps = {
  healthScore: number;
  budgetPercent: number;
  projectCount: number;
  openIssues: number;
  reportUrl: string;
  generatedAt: string;
};

/** Get health color based on score */
function getHealthColor(score: number): string {
  if (score >= 80) return BRAND.green;
  if (score >= 60) return BRAND.gold;
  return BRAND.red;
}

/** Get health label based on score */
function getHealthLabel(score: number): string {
  if (score >= 80) return "On Track";
  if (score >= 60) return "At Risk";
  return "Critical";
}

/**
 * ConstructionOS Report Email Component
 *
 * D-50c: Branded HTML with header/logo, inline metrics, PDF note, and live link.
 * D-50q: Sent from noreply address (reports@constructionos.com).
 * D-50m: No unsubscribe link (team members managed by sender).
 */
export function ReportEmail({
  healthScore,
  budgetPercent,
  projectCount,
  openIssues,
  reportUrl,
  generatedAt,
}: ReportEmailProps) {
  const healthColor = getHealthColor(healthScore);
  const healthLabel = getHealthLabel(healthScore);
  const dateStr = new Date(generatedAt).toLocaleDateString("en-US", {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  });
  const timeStr = new Date(generatedAt).toLocaleTimeString("en-US", {
    hour: "2-digit",
    minute: "2-digit",
  });

  return (
    <Html lang="en">
      <Head>
        <title>ConstructionOS Portfolio Report</title>
      </Head>
      <Body
        style={{
          backgroundColor: "#f4f4f5",
          fontFamily:
            '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
          margin: 0,
          padding: 0,
        }}
      >
        <Container
          style={{
            maxWidth: 600,
            margin: "0 auto",
            backgroundColor: BRAND.white,
            borderRadius: 8,
            overflow: "hidden",
          }}
        >
          {/* ---- Header with branding (D-50c) ---- */}
          <Section
            style={{
              backgroundColor: BRAND.bg,
              padding: "24px 32px",
              textAlign: "center" as const,
            }}
          >
            <Img
              src="https://constructionos.com/logo-light.png"
              alt="ConstructionOS"
              width={180}
              height={36}
              style={{ margin: "0 auto" }}
            />
            <Text
              style={{
                color: BRAND.accent,
                fontSize: 18,
                fontWeight: 800,
                margin: "12px 0 0",
                letterSpacing: 2,
              }}
            >
              PORTFOLIO REPORT
            </Text>
            <Text
              style={{
                color: BRAND.muted,
                fontSize: 12,
                margin: "4px 0 0",
              }}
            >
              Generated {dateStr} at {timeStr}
            </Text>
          </Section>

          {/* ---- Health Score Badge (D-50c) ---- */}
          <Section style={{ padding: "24px 32px", textAlign: "center" as const }}>
            <Text
              style={{
                fontSize: 14,
                color: "#374151",
                fontWeight: 600,
                margin: "0 0 8px",
              }}
            >
              Portfolio Health
            </Text>
            <Text
              style={{
                display: "inline-block",
                backgroundColor: healthColor,
                color: BRAND.white,
                fontSize: 28,
                fontWeight: 800,
                padding: "12px 24px",
                borderRadius: 12,
                margin: "0 auto",
                lineHeight: "1",
              }}
            >
              {healthScore}
            </Text>
            <Text
              style={{
                fontSize: 12,
                color: healthColor,
                fontWeight: 700,
                margin: "8px 0 0",
                textTransform: "uppercase" as const,
                letterSpacing: 1,
              }}
            >
              {healthLabel}
            </Text>
          </Section>

          <Hr style={{ borderColor: "#e5e7eb", margin: "0 32px" }} />

          {/* ---- Inline Metrics Summary (D-50c) ---- */}
          <Section style={{ padding: "24px 32px" }}>
            <Text
              style={{
                fontSize: 14,
                color: "#374151",
                fontWeight: 600,
                margin: "0 0 16px",
              }}
            >
              Key Metrics
            </Text>

            <Row>
              <Column style={{ width: "50%", paddingRight: 8 }}>
                <Section
                  style={{
                    backgroundColor: "#f9fafb",
                    borderRadius: 8,
                    padding: 16,
                    textAlign: "center" as const,
                  }}
                >
                  <Text
                    style={{
                      fontSize: 24,
                      fontWeight: 800,
                      color: "#111827",
                      margin: 0,
                    }}
                  >
                    {projectCount}
                  </Text>
                  <Text
                    style={{
                      fontSize: 11,
                      color: "#6b7280",
                      margin: "4px 0 0",
                      textTransform: "uppercase" as const,
                    }}
                  >
                    Projects
                  </Text>
                </Section>
              </Column>
              <Column style={{ width: "50%", paddingLeft: 8 }}>
                <Section
                  style={{
                    backgroundColor: "#f9fafb",
                    borderRadius: 8,
                    padding: 16,
                    textAlign: "center" as const,
                  }}
                >
                  <Text
                    style={{
                      fontSize: 24,
                      fontWeight: 800,
                      color: "#111827",
                      margin: 0,
                    }}
                  >
                    {budgetPercent}%
                  </Text>
                  <Text
                    style={{
                      fontSize: 11,
                      color: "#6b7280",
                      margin: "4px 0 0",
                      textTransform: "uppercase" as const,
                    }}
                  >
                    Budget Used
                  </Text>
                </Section>
              </Column>
            </Row>

            <Row style={{ marginTop: 8 }}>
              <Column style={{ width: "50%", paddingRight: 8 }}>
                <Section
                  style={{
                    backgroundColor: "#f9fafb",
                    borderRadius: 8,
                    padding: 16,
                    textAlign: "center" as const,
                  }}
                >
                  <Text
                    style={{
                      fontSize: 24,
                      fontWeight: 800,
                      color: openIssues > 5 ? BRAND.red : "#111827",
                      margin: 0,
                    }}
                  >
                    {openIssues}
                  </Text>
                  <Text
                    style={{
                      fontSize: 11,
                      color: "#6b7280",
                      margin: "4px 0 0",
                      textTransform: "uppercase" as const,
                    }}
                  >
                    Open Issues
                  </Text>
                </Section>
              </Column>
              <Column style={{ width: "50%", paddingLeft: 8 }}>
                <Section
                  style={{
                    backgroundColor: "#f9fafb",
                    borderRadius: 8,
                    padding: 16,
                    textAlign: "center" as const,
                  }}
                >
                  <Text
                    style={{
                      fontSize: 24,
                      fontWeight: 800,
                      color: healthColor,
                      margin: 0,
                    }}
                  >
                    {healthScore}%
                  </Text>
                  <Text
                    style={{
                      fontSize: 11,
                      color: "#6b7280",
                      margin: "4px 0 0",
                      textTransform: "uppercase" as const,
                    }}
                  >
                    Health Score
                  </Text>
                </Section>
              </Column>
            </Row>
          </Section>

          <Hr style={{ borderColor: "#e5e7eb", margin: "0 32px" }} />

          {/* ---- CTA: View Full Report ---- */}
          <Section
            style={{ padding: "24px 32px", textAlign: "center" as const }}
          >
            <Link
              href={reportUrl}
              style={{
                display: "inline-block",
                backgroundColor: BRAND.accent,
                color: BRAND.bg,
                fontSize: 14,
                fontWeight: 700,
                padding: "12px 32px",
                borderRadius: 8,
                textDecoration: "none",
                letterSpacing: 0.5,
              }}
            >
              View Full Report
            </Link>
            <Text
              style={{
                fontSize: 11,
                color: "#9ca3af",
                margin: "12px 0 0",
              }}
            >
              Click above to view the interactive report with charts and drill-down data.
            </Text>
          </Section>

          <Hr style={{ borderColor: "#e5e7eb", margin: "0 32px" }} />

          {/* ---- Footer ---- */}
          <Section
            style={{
              padding: "16px 32px 24px",
              textAlign: "center" as const,
            }}
          >
            <Text
              style={{
                fontSize: 11,
                color: "#9ca3af",
                margin: 0,
              }}
            >
              This is an automated report from ConstructionOS.
              <br />
              You are receiving this because a team administrator scheduled this report.
              <br />
              Contact your administrator to change delivery settings.
            </Text>
            {/* D-50m: No unsubscribe link -- team members managed by sender */}
          </Section>
        </Container>
      </Body>
    </Html>
  );
}

// ---------------------------------------------------------------------------
// Render helper: returns HTML string for Resend
// ---------------------------------------------------------------------------

export async function renderReportEmail(props: ReportEmailProps): Promise<string> {
  return await render(<ReportEmail {...props} />);
}
