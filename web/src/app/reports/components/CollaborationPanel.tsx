"use client";

import { useState, useEffect, useCallback } from "react";

// D-98: Threaded comments per report section
// Inline styles per project convention

type Comment = {
  id: string;
  user_id: string;
  report_history_id: string;
  section: string;
  content: string;
  parent_id: string | null;
  created_at: string;
  replies: Comment[];
};

type CollaborationPanelProps = {
  reportHistoryId: string;
  sections: string[];
};

export default function CollaborationPanel({
  reportHistoryId,
  sections,
}: CollaborationPanelProps) {
  const [activeSection, setActiveSection] = useState(sections[0] ?? "general");
  const [comments, setComments] = useState<Comment[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [newComment, setNewComment] = useState("");
  const [replyingTo, setReplyingTo] = useState<string | null>(null);
  const [replyContent, setReplyContent] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const fetchComments = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams({
        report_history_id: reportHistoryId,
        section: activeSection,
      });
      const res = await fetch(`/api/reports/comments?${params}`);
      if (!res.ok) {
        const err = await res.json().catch(() => ({ error: "Failed to load" }));
        throw new Error(err.error || "Failed to load comments");
      }
      const data = await res.json();
      setComments(data.comments ?? []);
      setTotalCount(data.total ?? 0);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load comments");
    } finally {
      setLoading(false);
    }
  }, [reportHistoryId, activeSection]);

  useEffect(() => {
    if (reportHistoryId) {
      fetchComments();
    }
  }, [reportHistoryId, activeSection, fetchComments]);

  async function handleSubmitComment(parentId?: string) {
    const content = parentId ? replyContent : newComment;
    if (!content.trim()) return;

    setSubmitting(true);
    try {
      const res = await fetch("/api/reports/comments", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          report_history_id: reportHistoryId,
          section: activeSection,
          content: content.trim(),
          parent_id: parentId || undefined,
        }),
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({ error: "Failed to post" }));
        throw new Error(err.error || "Failed to post comment");
      }

      // Reset form and refresh
      if (parentId) {
        setReplyContent("");
        setReplyingTo(null);
      } else {
        setNewComment("");
      }
      await fetchComments();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to post comment");
    } finally {
      setSubmitting(false);
    }
  }

  function formatTimestamp(iso: string): string {
    const d = new Date(iso);
    return d.toLocaleDateString(undefined, {
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  }

  function renderComment(comment: Comment, depth: number = 0) {
    return (
      <div
        key={comment.id}
        style={{
          marginLeft: depth * 20,
          padding: "10px 12px",
          borderLeft: depth > 0 ? "2px solid var(--border, #333)" : "none",
          marginBottom: 8,
        }}
      >
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            marginBottom: 4,
          }}
        >
          <span
            style={{
              fontSize: 12,
              fontWeight: 600,
              color: "var(--accent, #f59e0b)",
            }}
          >
            {comment.user_id.slice(0, 8)}...
          </span>
          <span style={{ fontSize: 11, color: "var(--muted, #888)" }}>
            {formatTimestamp(comment.created_at)}
          </span>
        </div>
        <p
          style={{
            fontSize: 13,
            color: "var(--text, #e5e5e5)",
            margin: "4px 0 6px",
            lineHeight: 1.5,
          }}
        >
          {comment.content}
        </p>
        <button
          onClick={() => {
            setReplyingTo(replyingTo === comment.id ? null : comment.id);
            setReplyContent("");
          }}
          style={{
            background: "none",
            border: "none",
            color: "var(--cyan, #22d3ee)",
            fontSize: 11,
            cursor: "pointer",
            padding: 0,
          }}
        >
          {replyingTo === comment.id ? "Cancel" : "Reply"}
        </button>

        {replyingTo === comment.id && (
          <div style={{ marginTop: 8 }}>
            <textarea
              value={replyContent}
              onChange={(e) => setReplyContent(e.target.value)}
              placeholder="Write a reply..."
              style={{
                width: "100%",
                minHeight: 60,
                padding: 8,
                fontSize: 13,
                background: "var(--surface, #1a1a2e)",
                color: "var(--text, #e5e5e5)",
                border: "1px solid var(--border, #333)",
                borderRadius: 6,
                resize: "vertical",
              }}
            />
            <button
              onClick={() => handleSubmitComment(comment.id)}
              disabled={submitting || !replyContent.trim()}
              style={{
                marginTop: 4,
                padding: "4px 12px",
                fontSize: 12,
                fontWeight: 600,
                background: "var(--accent, #f59e0b)",
                color: "#000",
                border: "none",
                borderRadius: 4,
                cursor: submitting ? "not-allowed" : "pointer",
                opacity: submitting || !replyContent.trim() ? 0.5 : 1,
              }}
            >
              {submitting ? "Posting..." : "Reply"}
            </button>
          </div>
        )}

        {comment.replies?.map((reply) => renderComment(reply, depth + 1))}
      </div>
    );
  }

  return (
    <div
      style={{
        background: "var(--surface, #1a1a2e)",
        borderRadius: 14,
        padding: 16,
        border: "1px solid var(--border, #333)",
      }}
    >
      <h3
        style={{
          fontSize: 14,
          fontWeight: 800,
          color: "var(--text, #e5e5e5)",
          marginBottom: 12,
          letterSpacing: 1,
          textTransform: "uppercase",
        }}
      >
        Comments ({totalCount})
      </h3>

      {/* Section tabs */}
      <div
        style={{
          display: "flex",
          gap: 4,
          marginBottom: 12,
          overflowX: "auto",
          paddingBottom: 4,
        }}
      >
        {sections.map((section) => (
          <button
            key={section}
            onClick={() => setActiveSection(section)}
            style={{
              padding: "4px 10px",
              fontSize: 11,
              fontWeight: activeSection === section ? 700 : 500,
              background:
                activeSection === section
                  ? "var(--accent, #f59e0b)"
                  : "transparent",
              color:
                activeSection === section ? "#000" : "var(--muted, #888)",
              border: "1px solid var(--border, #333)",
              borderRadius: 4,
              cursor: "pointer",
              whiteSpace: "nowrap",
            }}
          >
            {section}
          </button>
        ))}
      </div>

      {/* Error display */}
      {error && (
        <div
          style={{
            padding: 8,
            marginBottom: 8,
            background: "rgba(239,68,68,0.1)",
            border: "1px solid var(--red, #ef4444)",
            borderRadius: 6,
            fontSize: 12,
            color: "var(--red, #ef4444)",
          }}
        >
          {error}
        </div>
      )}

      {/* Comment list */}
      <div
        style={{
          maxHeight: 400,
          overflowY: "auto",
          marginBottom: 12,
        }}
      >
        {loading && (
          <p style={{ fontSize: 12, color: "var(--muted, #888)", textAlign: "center", padding: 20 }}>
            Loading comments...
          </p>
        )}

        {!loading && comments.length === 0 && (
          <p style={{ fontSize: 12, color: "var(--muted, #888)", textAlign: "center", padding: 20 }}>
            No comments yet for this section.
          </p>
        )}

        {!loading && comments.map((comment) => renderComment(comment))}
      </div>

      {/* New comment form */}
      <div>
        <textarea
          value={newComment}
          onChange={(e) => setNewComment(e.target.value)}
          placeholder={`Add a comment on ${activeSection}...`}
          aria-label={`Add comment on ${activeSection}`}
          style={{
            width: "100%",
            minHeight: 70,
            padding: 10,
            fontSize: 13,
            background: "var(--bg, #0d1117)",
            color: "var(--text, #e5e5e5)",
            border: "1px solid var(--border, #333)",
            borderRadius: 8,
            resize: "vertical",
          }}
        />
        <button
          onClick={() => handleSubmitComment()}
          disabled={submitting || !newComment.trim()}
          style={{
            marginTop: 6,
            padding: "6px 16px",
            fontSize: 13,
            fontWeight: 700,
            background: "var(--accent, #f59e0b)",
            color: "#000",
            border: "none",
            borderRadius: 6,
            cursor: submitting ? "not-allowed" : "pointer",
            opacity: submitting || !newComment.trim() ? 0.5 : 1,
          }}
        >
          {submitting ? "Posting..." : "Post Comment"}
        </button>
      </div>
    </div>
  );
}
