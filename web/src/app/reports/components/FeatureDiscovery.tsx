"use client";

import { useState, useEffect, useCallback } from "react";

// ---------- Types ----------

type TooltipStep = {
  id: string;
  title: string;
  description: string;
  targetSelector: string;
  position: "top" | "bottom" | "left" | "right";
};

// ---------- Constants ----------

const TOUR_STORAGE_KEY = "constructos.reports.tourCompleted";

const TOUR_STEPS: TooltipStep[] = [
  {
    id: "reports-overview",
    title: "Reports Overview",
    description:
      "Your portfolio health at a glance. View KPI cards, filter by status, and drill into any project.",
    targetSelector: "[data-tour='reports-overview']",
    position: "bottom",
  },
  {
    id: "project-reports",
    title: "Project Reports",
    description:
      "Click any project to see a detailed report with budget, schedule, safety, and team sections.",
    targetSelector: "[data-tour='project-report']",
    position: "bottom",
  },
  {
    id: "portfolio-rollup",
    title: "Portfolio Rollup",
    description:
      "The Portfolio Rollup tab aggregates data across all your projects into one executive view.",
    targetSelector: "[data-tour='portfolio-rollup']",
    position: "bottom",
  },
  {
    id: "export-options",
    title: "Export Options",
    description:
      "Export reports as PDF, CSV, or PowerPoint. Share links with stakeholders directly.",
    targetSelector: "[data-tour='export-options']",
    position: "left",
  },
  {
    id: "schedule-delivery",
    title: "Schedule Delivery",
    description:
      "Set up automated report delivery on a daily, weekly, or monthly schedule via email.",
    targetSelector: "[data-tour='schedule-delivery']",
    position: "bottom",
  },
];

// ---------- Contextual Link Helper (D-66b) ----------

/**
 * Creates a contextual link to the reports section from other pages.
 * Usage: <a href={getReportLink(projectId)}>View full report &rarr;</a>
 */
export function getReportLink(projectId?: string): string {
  if (projectId) return `/reports/project/${projectId}`;
  return "/reports";
}

// ---------- Tooltip Component ----------

function Tooltip({
  step,
  currentIndex,
  totalSteps,
  onNext,
  onSkip,
}: {
  step: TooltipStep;
  currentIndex: number;
  totalSteps: number;
  onNext: () => void;
  onSkip: () => void;
}) {
  const [pos, setPos] = useState({ top: 100, left: 100 });

  useEffect(() => {
    const el = document.querySelector(step.targetSelector);
    if (el) {
      const rect = el.getBoundingClientRect();
      const scrollTop = window.scrollY;
      const scrollLeft = window.scrollX;

      let top = 0;
      let left = 0;

      switch (step.position) {
        case "bottom":
          top = rect.bottom + scrollTop + 8;
          left = rect.left + scrollLeft + rect.width / 2 - 150;
          break;
        case "top":
          top = rect.top + scrollTop - 130;
          left = rect.left + scrollLeft + rect.width / 2 - 150;
          break;
        case "left":
          top = rect.top + scrollTop + rect.height / 2 - 50;
          left = rect.left + scrollLeft - 310;
          break;
        case "right":
          top = rect.top + scrollTop + rect.height / 2 - 50;
          left = rect.right + scrollLeft + 8;
          break;
      }

      // Keep within viewport
      left = Math.max(8, Math.min(left, window.innerWidth - 320));
      top = Math.max(8, top);

      setPos({ top, left });
    }
  }, [step]);

  const isLast = currentIndex === totalSteps - 1;

  return (
    <>
      {/* Semi-transparent overlay */}
      <div
        style={{
          position: "fixed",
          inset: 0,
          background: "rgba(0,0,0,0.5)",
          zIndex: 9998,
        }}
        onClick={onSkip}
        aria-hidden="true"
      />

      {/* Tooltip card */}
      <div
        role="dialog"
        aria-label={`Tour step ${currentIndex + 1} of ${totalSteps}: ${step.title}`}
        style={{
          position: "absolute",
          top: pos.top,
          left: pos.left,
          width: 300,
          background: "var(--surface)",
          border: "1px solid var(--accent)",
          borderRadius: 10,
          padding: 16,
          zIndex: 9999,
          boxShadow: "0 8px 24px rgba(0,0,0,0.4)",
        }}
      >
        <div
          style={{
            fontSize: 10,
            color: "var(--muted)",
            marginBottom: 4,
            fontWeight: 600,
          }}
        >
          Step {currentIndex + 1} of {totalSteps}
        </div>
        <div
          style={{
            fontSize: 14,
            fontWeight: 800,
            color: "var(--text)",
            marginBottom: 6,
          }}
        >
          {step.title}
        </div>
        <div
          style={{
            fontSize: 12,
            color: "var(--muted)",
            lineHeight: 1.5,
            marginBottom: 12,
          }}
        >
          {step.description}
        </div>
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
          }}
        >
          <button
            onClick={onSkip}
            style={{
              background: "none",
              border: "none",
              color: "var(--muted)",
              fontSize: 11,
              cursor: "pointer",
              padding: "4px 8px",
            }}
          >
            Skip tour
          </button>
          <button
            onClick={onNext}
            style={{
              background: "var(--accent)",
              color: "#000",
              border: "none",
              borderRadius: 6,
              padding: "6px 14px",
              fontSize: 11,
              fontWeight: 700,
              cursor: "pointer",
            }}
          >
            {isLast ? "Finish" : "Next"}
          </button>
        </div>
      </div>
    </>
  );
}

// ---------- FeatureDiscovery Component ----------

export function FeatureDiscovery() {
  const [active, setActive] = useState(false);
  const [step, setStep] = useState(0);

  useEffect(() => {
    // D-66b: show tour on first visit
    const completed = localStorage.getItem(TOUR_STORAGE_KEY);
    if (!completed) {
      // Delay slightly so page elements render first
      const timer = setTimeout(() => setActive(true), 500);
      return () => clearTimeout(timer);
    }
  }, []);

  const completeTour = useCallback(() => {
    localStorage.setItem(TOUR_STORAGE_KEY, "true");
    setActive(false);
    setStep(0);
  }, []);

  const handleNext = useCallback(() => {
    if (step >= TOUR_STEPS.length - 1) {
      completeTour();
    } else {
      setStep((s) => s + 1);
    }
  }, [step, completeTour]);

  if (!active) return null;

  return (
    <Tooltip
      step={TOUR_STEPS[step]}
      currentIndex={step}
      totalSteps={TOUR_STEPS.length}
      onNext={handleNext}
      onSkip={completeTour}
    />
  );
}

/**
 * Restart the feature discovery tour.
 * Call this from the Help section "Restart tour" button.
 */
export function restartTour(): void {
  localStorage.removeItem(TOUR_STORAGE_KEY);
  // Force a page reload to trigger the tour
  window.location.reload();
}

/**
 * Check if tour has been completed.
 */
export function isTourCompleted(): boolean {
  if (typeof window === "undefined") return false;
  return localStorage.getItem(TOUR_STORAGE_KEY) === "true";
}
