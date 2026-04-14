import SectionWrapper from "./SectionWrapper";

// D-46: Gantt chart + milestone checklist
// Milestones: green check for complete, gray circle for upcoming

type ScheduleSectionProps = {
  schedule: Record<string, unknown>;
  sectionNote?: string;
};

type Milestone = {
  name: string;
  percentComplete: number;
  startDate?: string;
  endDate?: string;
};

export default function ScheduleSection({
  schedule,
  sectionNote,
}: ScheduleSectionProps) {
  const milestones = (schedule.milestones as Milestone[]) ?? [];
  const totalCount = (schedule.totalCount as number) ?? 0;
  const delayedCount = (schedule.delayedCount as number) ?? 0;
  const onTrack = totalCount - delayedCount;

  return (
    <SectionWrapper
      id="schedule"
      title="Schedule"
      itemCount={totalCount}
      sectionNote={sectionNote}
    >
      {/* Schedule summary */}
      <div
        style={{
          display: "flex",
          gap: 16,
          marginBottom: 20,
          flexWrap: "wrap",
        }}
      >
        <div
          style={{
            padding: "8px 16px",
            background: "#F0FDF4",
            borderRadius: 6,
            fontSize: 13,
            color: "#16A34A",
            fontWeight: 600,
          }}
        >
          {onTrack} on track
        </div>
        {delayedCount > 0 && (
          <div
            style={{
              padding: "8px 16px",
              background: "#FEF2F2",
              borderRadius: 6,
              fontSize: 13,
              color: "#DC2626",
              fontWeight: 600,
            }}
          >
            {delayedCount} delayed
          </div>
        )}
      </div>

      {/* Milestone checklist */}
      <div>
        {milestones.slice(0, 20).map((milestone, i) => {
          const isComplete = milestone.percentComplete >= 100;
          return (
            <div
              key={i}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 12,
                padding: "10px 0",
                borderBottom:
                  i < milestones.length - 1 ? "1px solid #F1F3F5" : "none",
              }}
            >
              {/* Check or circle icon */}
              <div
                style={{
                  width: 20,
                  height: 20,
                  borderRadius: "50%",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  background: isComplete ? "#16A34A" : "#E2E5E9",
                  color: isComplete ? "#FFFFFF" : "#9CA3AF",
                  fontSize: 11,
                  fontWeight: 700,
                  flexShrink: 0,
                }}
              >
                {isComplete ? "\u2713" : ""}
              </div>

              {/* Milestone name */}
              <span
                style={{
                  flex: 1,
                  fontSize: 13,
                  color: isComplete ? "#6B7280" : "#374151",
                  textDecoration: isComplete ? "line-through" : "none",
                }}
              >
                {milestone.name}
              </span>

              {/* Progress */}
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <div
                  style={{
                    width: 60,
                    height: 4,
                    background: "#E2E5E9",
                    borderRadius: 2,
                    overflow: "hidden",
                  }}
                >
                  <div
                    style={{
                      height: "100%",
                      width: `${Math.min(milestone.percentComplete, 100)}%`,
                      background: isComplete ? "#16A34A" : "#F59E0B",
                      borderRadius: 2,
                    }}
                  />
                </div>
                <span
                  style={{
                    fontSize: 12,
                    fontWeight: 600,
                    color: isComplete ? "#16A34A" : "#F59E0B",
                    minWidth: 36,
                    textAlign: "right",
                  }}
                >
                  {milestone.percentComplete}%
                </span>
              </div>
            </div>
          );
        })}

        {milestones.length === 0 && (
          <p style={{ fontSize: 13, color: "#9CA3AF", textAlign: "center", padding: 16 }}>
            No milestones available.
          </p>
        )}
      </div>
    </SectionWrapper>
  );
}
