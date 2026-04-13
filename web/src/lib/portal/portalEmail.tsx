// Branded notification email templates for portal (D-66, D-08, D-09, D-104)
// Uses @react-email/components for cross-client HTML + Resend for delivery.
// Pattern matches web/src/lib/reports/email-template.tsx from Phase 19.

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
} from "@react-email/components";
import { render } from "@react-email/components";
import { Resend } from "resend";
import type { CompanyBranding } from "./types";

// ---------------------------------------------------------------------------
// Resend client (lazy init)
// ---------------------------------------------------------------------------

let resendClient: Resend | null = null;

function getResend(): Resend | null {
  if (!process.env.RESEND_API_KEY) {
    console.error("[portalEmail] RESEND_API_KEY not configured");
    return null;
  }
  if (!resendClient) {
    resendClient = new Resend(process.env.RESEND_API_KEY);
  }
  return resendClient;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Get font family CSS string from branding */
function getFontFamily(branding: CompanyBranding): string {
  const font = branding.font_family || branding.theme_config?.fontFamily || "Inter";
  return `${font}, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif`;
}

/** Get primary color from branding theme */
function getPrimaryColor(branding: CompanyBranding): string {
  return branding.theme_config?.primary || "#2563EB";
}

/** Get text color for CTA button (white for dark primary, dark for light) */
function getCtaTextColor(primary: string): string {
  // Simple luminance check
  const hex = primary.replace("#", "");
  if (hex.length !== 6) return "#FFFFFF";
  const r = parseInt(hex.slice(0, 2), 16);
  const g = parseInt(hex.slice(2, 4), 16);
  const b = parseInt(hex.slice(4, 6), 16);
  const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
  return luminance > 0.5 ? "#1F2937" : "#FFFFFF";
}

// ---------------------------------------------------------------------------
// Email Components (React Email JSX)
// ---------------------------------------------------------------------------

function PortalCreatedEmailTemplate(params: {
  companyName: string;
  projectName: string;
  portalUrl: string;
  branding: CompanyBranding;
}) {
  const { companyName, projectName, portalUrl, branding } = params;
  const primaryColor = getPrimaryColor(branding);
  const fontFamily = getFontFamily(branding);
  const ctaTextColor = getCtaTextColor(primaryColor);

  return (
    <Html lang="en">
      <Head>
        <title>{`${companyName} -- Portal Invitation`}</title>
      </Head>
      <Body
        style={{
          backgroundColor: "#f4f4f5",
          fontFamily,
          margin: 0,
          padding: 0,
        }}
      >
        <Container
          style={{
            maxWidth: 600,
            margin: "0 auto",
            backgroundColor: "#FFFFFF",
            borderRadius: 8,
            overflow: "hidden",
          }}
        >
          {/* Header with company logo */}
          <Section
            style={{
              backgroundColor: primaryColor,
              padding: "24px 32px",
              textAlign: "center" as const,
            }}
          >
            {branding.logo_light_path && (
              <Img
                src={branding.logo_light_path}
                alt={companyName}
                width={180}
                height={36}
                style={{ margin: "0 auto" }}
              />
            )}
            {!branding.logo_light_path && (
              <Text
                style={{
                  color: ctaTextColor,
                  fontSize: 20,
                  fontWeight: 700,
                  margin: 0,
                }}
              >
                {companyName}
              </Text>
            )}
          </Section>

          {/* Body */}
          <Section style={{ padding: "32px" }}>
            <Text
              style={{
                fontSize: 20,
                fontWeight: 700,
                color: "#111827",
                margin: "0 0 16px",
              }}
            >
              You&apos;ve been invited to view {projectName}
            </Text>

            <Text
              style={{
                fontSize: 15,
                color: "#374151",
                lineHeight: "1.6",
                margin: "0 0 24px",
              }}
            >
              {companyName} has shared a project portal with you. View the
              latest project updates, progress photos, and documentation.
            </Text>

            {/* CTA button */}
            <Section style={{ textAlign: "center" as const }}>
              <Link
                href={portalUrl}
                style={{
                  display: "inline-block",
                  backgroundColor: primaryColor,
                  color: ctaTextColor,
                  fontSize: 15,
                  fontWeight: 600,
                  padding: "12px 32px",
                  borderRadius: 8,
                  textDecoration: "none",
                }}
              >
                View Project Portal
              </Link>
            </Section>
          </Section>

          <Hr style={{ borderColor: "#e5e7eb", margin: "0 32px" }} />

          {/* Footer with contact info + unsubscribe */}
          <Section
            style={{
              padding: "16px 32px 24px",
              textAlign: "center" as const,
            }}
          >
            {branding.contact_info?.email && (
              <Text style={{ fontSize: 12, color: "#6B7280", margin: "0 0 4px" }}>
                {branding.contact_info.email}
              </Text>
            )}
            {branding.contact_info?.phone && (
              <Text style={{ fontSize: 12, color: "#6B7280", margin: "0 0 4px" }}>
                {branding.contact_info.phone}
              </Text>
            )}
            {branding.contact_info?.address && (
              <Text style={{ fontSize: 12, color: "#6B7280", margin: "0 0 4px" }}>
                {branding.contact_info.address}
              </Text>
            )}
            <Text style={{ fontSize: 11, color: "#9CA3AF", margin: "12px 0 0" }}>
              You received this because someone shared a project portal with
              your email address. To stop receiving these emails, please contact{" "}
              {companyName}.
            </Text>
          </Section>
        </Container>
      </Body>
    </Html>
  );
}

function PortalUpdatedEmailTemplate(params: {
  companyName: string;
  projectName: string;
  portalUrl: string;
  updatedSections: string[];
  branding: CompanyBranding;
}) {
  const { companyName, projectName, portalUrl, updatedSections, branding } = params;
  const primaryColor = getPrimaryColor(branding);
  const fontFamily = getFontFamily(branding);
  const ctaTextColor = getCtaTextColor(primaryColor);

  return (
    <Html lang="en">
      <Head>
        <title>{`${companyName} -- Project Update`}</title>
      </Head>
      <Body
        style={{
          backgroundColor: "#f4f4f5",
          fontFamily,
          margin: 0,
          padding: 0,
        }}
      >
        <Container
          style={{
            maxWidth: 600,
            margin: "0 auto",
            backgroundColor: "#FFFFFF",
            borderRadius: 8,
            overflow: "hidden",
          }}
        >
          {/* Header */}
          <Section
            style={{
              backgroundColor: primaryColor,
              padding: "24px 32px",
              textAlign: "center" as const,
            }}
          >
            {branding.logo_light_path && (
              <Img
                src={branding.logo_light_path}
                alt={companyName}
                width={180}
                height={36}
                style={{ margin: "0 auto" }}
              />
            )}
            {!branding.logo_light_path && (
              <Text
                style={{
                  color: ctaTextColor,
                  fontSize: 20,
                  fontWeight: 700,
                  margin: 0,
                }}
              >
                {companyName}
              </Text>
            )}
          </Section>

          {/* Body */}
          <Section style={{ padding: "32px" }}>
            <Text
              style={{
                fontSize: 20,
                fontWeight: 700,
                color: "#111827",
                margin: "0 0 16px",
              }}
            >
              Project update: {projectName}
            </Text>

            <Text
              style={{
                fontSize: 15,
                color: "#374151",
                lineHeight: "1.6",
                margin: "0 0 12px",
              }}
            >
              The following sections have been updated:
            </Text>

            {/* Updated sections list */}
            <Section style={{ padding: "0 0 24px" }}>
              {updatedSections.map((section, i) => (
                <Text
                  key={i}
                  style={{
                    fontSize: 14,
                    color: "#374151",
                    margin: "4px 0",
                    paddingLeft: 16,
                  }}
                >
                  &bull; {section}
                </Text>
              ))}
            </Section>

            <Text
              style={{
                fontSize: 15,
                color: "#374151",
                lineHeight: "1.6",
                margin: "0 0 24px",
              }}
            >
              View the latest progress on your project portal.
            </Text>

            {/* CTA button */}
            <Section style={{ textAlign: "center" as const }}>
              <Link
                href={portalUrl}
                style={{
                  display: "inline-block",
                  backgroundColor: primaryColor,
                  color: ctaTextColor,
                  fontSize: 15,
                  fontWeight: 600,
                  padding: "12px 32px",
                  borderRadius: 8,
                  textDecoration: "none",
                }}
              >
                View Project Portal
              </Link>
            </Section>
          </Section>

          <Hr style={{ borderColor: "#e5e7eb", margin: "0 32px" }} />

          {/* Footer */}
          <Section
            style={{
              padding: "16px 32px 24px",
              textAlign: "center" as const,
            }}
          >
            {branding.contact_info?.email && (
              <Text style={{ fontSize: 12, color: "#6B7280", margin: "0 0 4px" }}>
                {branding.contact_info.email}
              </Text>
            )}
            {branding.contact_info?.phone && (
              <Text style={{ fontSize: 12, color: "#6B7280", margin: "0 0 4px" }}>
                {branding.contact_info.phone}
              </Text>
            )}
            <Text style={{ fontSize: 11, color: "#9CA3AF", margin: "12px 0 0" }}>
              You received this because someone shared a project portal with
              your email address. To stop receiving these emails, please contact{" "}
              {companyName}.
            </Text>
          </Section>
        </Container>
      </Body>
    </Html>
  );
}

function ViewNotificationEmailTemplate(params: {
  portalSlug: string;
  viewerInfo: string;
  projectName: string;
}) {
  const { viewerInfo, projectName, portalSlug } = params;

  return (
    <Html lang="en">
      <Head>
        <title>Portal View Notification</title>
      </Head>
      <Body
        style={{
          backgroundColor: "#f4f4f5",
          fontFamily:
            'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
          margin: 0,
          padding: 0,
        }}
      >
        <Container
          style={{
            maxWidth: 600,
            margin: "0 auto",
            backgroundColor: "#FFFFFF",
            borderRadius: 8,
            overflow: "hidden",
          }}
        >
          {/* Header */}
          <Section
            style={{
              backgroundColor: "#2563EB",
              padding: "20px 32px",
              textAlign: "center" as const,
            }}
          >
            <Text
              style={{
                color: "#FFFFFF",
                fontSize: 16,
                fontWeight: 600,
                margin: 0,
              }}
            >
              ConstructionOS Portal
            </Text>
          </Section>

          {/* Body */}
          <Section style={{ padding: "32px" }}>
            <Text
              style={{
                fontSize: 18,
                fontWeight: 600,
                color: "#111827",
                margin: "0 0 16px",
              }}
            >
              Your portal was viewed
            </Text>

            <Text
              style={{
                fontSize: 15,
                color: "#374151",
                lineHeight: "1.6",
                margin: "0 0 8px",
              }}
            >
              {viewerInfo} viewed your portal for{" "}
              <strong>{projectName}</strong>.
            </Text>

            <Text
              style={{
                fontSize: 13,
                color: "#6B7280",
                margin: "8px 0 0",
              }}
            >
              Portal: {portalSlug}
            </Text>
          </Section>

          <Hr style={{ borderColor: "#e5e7eb", margin: "0 32px" }} />

          <Section
            style={{
              padding: "16px 32px 24px",
              textAlign: "center" as const,
            }}
          >
            <Text style={{ fontSize: 11, color: "#9CA3AF", margin: 0 }}>
              This is an automated notification from ConstructionOS.
            </Text>
          </Section>
        </Container>
      </Body>
    </Html>
  );
}

// ---------------------------------------------------------------------------
// Public API: send functions
// ---------------------------------------------------------------------------

/**
 * Send portal invitation email to client (D-09, D-66).
 * Branded with company logo, colors, and font.
 * Non-blocking: logs errors but never throws.
 */
export async function sendPortalCreatedEmail(params: {
  to: string;
  companyName: string;
  projectName: string;
  portalUrl: string;
  branding: CompanyBranding;
}): Promise<void> {
  try {
    const resend = getResend();
    if (!resend) return;

    const html = await render(
      PortalCreatedEmailTemplate({
        companyName: params.companyName,
        projectName: params.projectName,
        portalUrl: params.portalUrl,
        branding: params.branding,
      })
    );

    await resend.emails.send({
      from: `${params.companyName} <noreply@constructionos.com>`,
      to: params.to,
      subject: `You've been invited to view ${params.projectName}`,
      html,
    });
  } catch (err) {
    console.error("[portalEmail] sendPortalCreatedEmail failed:", err);
  }
}

/**
 * Send project update notification to client (D-08, D-66).
 * Branded with company logo, colors, and font. Lists updated sections.
 * Non-blocking: logs errors but never throws.
 */
export async function sendPortalUpdatedEmail(params: {
  to: string;
  companyName: string;
  projectName: string;
  portalUrl: string;
  updatedSections: string[];
  branding: CompanyBranding;
}): Promise<void> {
  try {
    const resend = getResend();
    if (!resend) return;

    const html = await render(
      PortalUpdatedEmailTemplate({
        companyName: params.companyName,
        projectName: params.projectName,
        portalUrl: params.portalUrl,
        updatedSections: params.updatedSections,
        branding: params.branding,
      })
    );

    await resend.emails.send({
      from: `${params.companyName} <noreply@constructionos.com>`,
      to: params.to,
      subject: `Project update: ${params.projectName}`,
      html,
    });
  } catch (err) {
    console.error("[portalEmail] sendPortalUpdatedEmail failed:", err);
  }
}

/**
 * Send view notification to portal owner (D-08).
 * Simple notification: "{viewer} viewed your portal for {project}".
 * Non-blocking: logs errors but never throws.
 */
export async function sendViewNotificationEmail(params: {
  to: string;
  portalSlug: string;
  viewerInfo: string;
  projectName: string;
}): Promise<void> {
  try {
    const resend = getResend();
    if (!resend) return;

    const html = await render(
      ViewNotificationEmailTemplate({
        portalSlug: params.portalSlug,
        viewerInfo: params.viewerInfo,
        projectName: params.projectName,
      })
    );

    await resend.emails.send({
      from: "ConstructionOS <noreply@constructionos.com>",
      to: params.to,
      subject: `${params.viewerInfo} viewed your portal for ${params.projectName}`,
      html,
    });
  } catch (err) {
    console.error("[portalEmail] sendViewNotificationEmail failed:", err);
  }
}
