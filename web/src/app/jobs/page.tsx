"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import type { JobListing } from "@/lib/jobs";
import { useSubscriptionTier } from "@/lib/subscription/useSubscriptionTier";
import { hasFeatureAccess } from "@/lib/subscription/featureAccess";

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

type JobsResponse = {
  jobs?: JobListing[];
  source?: string;
  error?: string;
};

const tradeOptions = [
  "General",
  "Concrete",
  "Electrical",
  "Plumbing",
  "HVAC",
  "Roofing",
  "Steel",
  "Crane",
  "Solar",
  "Low Voltage",
  "Civil",
  "Mechanical",
];

const employmentTypes = ["Full-time", "Part-time", "Contract", "Temp", "Union", "Per Diem"];

const defaultForm = {
  title: "",
  company: "",
  location: "",
  pay: "",
  trade: "General",
  employmentType: "Full-time",
  startLabel: "Immediate",
  duration: "",
  description: "",
  requirements: "",
  contactEmail: "",
  urgent: false,
};

function formatDateLabel(value: string) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "Just now";

  return date.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
  });
}

function buildApplyAiHref(job: JobListing) {
  const prompt = encodeURIComponent(`Help me write a strong application for the ${job.title} role at ${job.company} in ${job.location}.`);
  return `/ai?prompt=${prompt}`;
}

function buildApplyMailtoHref(job: JobListing) {
  if (!job.contactEmail) return "";

  const subject = encodeURIComponent(`ConstructionOS application: ${job.title}`);
  const body = encodeURIComponent(
    `Hi ${job.company} hiring team,\n\nI’m interested in the ${job.title} role. Here’s a quick summary of my experience:\n- \n\nThanks,\n`,
  );

  return `mailto:${job.contactEmail}?subject=${subject}&body=${body}`;
}

export default function JobsPage() {
  const { tier, loading: tierLoading } = useSubscriptionTier();
  const [jobs, setJobs] = useState<JobListing[]>([]);
  const [source, setSource] = useState("live");
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState("");
  const [submitError, setSubmitError] = useState("");
  const [submitSuccess, setSubmitSuccess] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [activeTrade, setActiveTrade] = useState("All trades");
  const [lastSyncAt, setLastSyncAt] = useState("");
  const [form, setForm] = useState(defaultForm);
  const [applyJob, setApplyJob] = useState<JobListing | null>(null);

  const openApplyModal = (job: JobListing) => {
    if (!job.contactEmail) return;
    setApplyJob(job);
  };

  const closeApplyModal = () => setApplyJob(null);

  const copyText = async (value: string) => {
    try {
      await navigator.clipboard.writeText(value);
      window.alert("Copied to clipboard.");
    } catch {
      window.prompt("Copy to clipboard:", value);
    }
  };

  async function loadJobs(silent = false) {
    if (silent) setRefreshing(true);
    else setLoading(true);

    try {
      const response = await fetch("/api/jobs", { cache: "no-store" });
      const payload = (await response.json()) as JobsResponse;

      if (!response.ok) {
        throw new Error(payload.error || "Could not load jobs board");
      }

      setJobs(payload.jobs || []);
      setSource(payload.source || "live");
      setLastSyncAt(new Date().toISOString());
      setError("");
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : "Could not load jobs board");
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }

  useEffect(() => {
    loadJobs();
    const interval = window.setInterval(() => loadJobs(true), 30000);
    return () => window.clearInterval(interval);
  }, []);

  const filteredJobs = useMemo(() => {
    if (activeTrade === "All trades") return jobs;
    return jobs.filter((job) => job.trade === activeTrade);
  }, [activeTrade, jobs]);

  const canPostJobs = hasFeatureAccess(tier, "jobs");
  const urgentCount = filteredJobs.filter((job) => job.urgent).length;
  const tradeCount = new Set(jobs.map((job) => job.trade)).size;

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSubmitting(true);
    setSubmitError("");
    setSubmitSuccess("");

    if (form.contactEmail && !EMAIL_REGEX.test(form.contactEmail.trim())) {
      setSubmitError("Please enter a valid contact email address");
      setSubmitting(false);
      return;
    }

    try {
      const response = await fetch("/api/jobs", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          ...form,
          requirements: form.requirements
            .split(",")
            .map((item) => item.trim())
            .filter(Boolean),
        }),
      });

      const payload = (await response.json()) as { success?: boolean; job?: JobListing; error?: string };

      if (!response.ok || !payload.job) {
        throw new Error(payload.error || "Could not post job");
      }

      setJobs((current) => [payload.job!, ...current]);
      setSource("live");
      setLastSyncAt(new Date().toISOString());
      setForm(defaultForm);
      setSubmitSuccess("Job posted live to the ConstructionOS board.");
    } catch (submitFailure) {
      setSubmitError(submitFailure instanceof Error ? submitFailure.message : "Could not post job");
    } finally {
      setSubmitting(false);
    }
  }

  return (
	      <div className="max-w-6xl mx-auto px-4 py-8">
	        {applyJob && (
	          <div
	            role="dialog"
	            aria-modal="true"
	            className="fixed inset-0 z-[60] flex items-center justify-center px-4"
	            style={{ background: "rgba(0,0,0,0.7)" }}
	            onClick={closeApplyModal}
	          >
	            <div
	              className="w-full max-w-lg rounded-3xl p-6"
	              style={{ background: "#0F1C24", border: "1px solid rgba(74,196,204,0.12)" }}
	              onClick={(event) => event.stopPropagation()}
	            >
	              <div className="flex items-start justify-between gap-4 mb-4">
	                <div>
	                  <div className="text-[10px] font-black tracking-[0.2em] text-[#4AC4CC] mb-2">APPLY BY EMAIL</div>
	                  <h2 className="text-2xl font-black">{applyJob.title}</h2>
	                  <p className="text-sm text-[#9EBDC2] mt-1">{applyJob.company} · {applyJob.location}</p>
	                </div>
	                <button
	                  type="button"
	                  onClick={closeApplyModal}
	                  className="px-3 py-2 rounded-xl text-xs font-bold"
	                  style={{ background: "#162832", color: "#9EBDC2", border: "none", cursor: "pointer" }}
	                >
	                  Close
	                </button>
	              </div>

	              <div className="rounded-2xl p-4 mb-4" style={{ background: "rgba(74,196,204,0.06)", border: "1px solid rgba(74,196,204,0.12)" }}>
	                <div className="text-[10px] font-black tracking-[0.18em] text-[#9EBDC2] mb-2">CONTACT EMAIL</div>
	                <div className="text-sm font-bold text-[#F0F8F8] break-all">{applyJob.contactEmail}</div>
	              </div>

	              <div className="flex flex-col sm:flex-row gap-3">
	                <button
	                  type="button"
	                  onClick={() => copyText(applyJob.contactEmail)}
	                  className="flex-1 py-3 rounded-xl text-sm font-bold text-center"
	                  style={{ background: "#162832", color: "#F0F8F8", border: "none", cursor: "pointer" }}
	                >
	                  Copy Email
	                </button>
	                <button
	                  type="button"
	                  onClick={() => {
	                    const mailto = buildApplyMailtoHref(applyJob);
	                    if (mailto) window.location.href = mailto;
	                  }}
	                  className="flex-1 py-3 rounded-xl text-sm font-bold text-center text-black"
	                  style={{ background: "linear-gradient(90deg, #69D294, #4AC4CC)", border: "none", cursor: "pointer" }}
	                >
	                  Open Email App
	                </button>
	              </div>

	              <div className="mt-4">
	                <Link
	                  href={buildApplyAiHref(applyJob)}
	                  onClick={closeApplyModal}
	                  className="block w-full py-3 rounded-xl text-sm font-bold text-center text-[#4AC4CC] border border-[#4AC4CC]"
	                >
	                  Draft Message With Angelic
	                </Link>
	              </div>
	            </div>
	          </div>
	        )}
	        <div className="rounded-3xl p-6 md:p-8 mb-6" style={{ background: "linear-gradient(180deg, rgba(15,28,36,0.96), rgba(8,14,18,0.98))", border: "1px solid rgba(74,196,204,0.12)" }}>
	          <div className="text-[11px] font-black tracking-[0.3em] text-[#69D294] mb-3">LIVE JOBS BOARD</div>
	          <div className="flex flex-col md:flex-row md:items-end md:justify-between gap-4">
	            <div>
              <h1 className="text-4xl font-black mb-3">Construction Jobs In Real Time</h1>
              <p className="text-sm text-[#9EBDC2] max-w-2xl">Read the board publicly, keep hiring visible in real time, and let paid subscribers publish live openings into the ConstructionOS database. This board refreshes every 30 seconds.</p>
            </div>
            <div className="flex flex-wrap gap-3">
              <a href="#post-job" className="px-5 py-3 rounded-xl text-sm font-bold text-black" style={{ background: "linear-gradient(90deg, #F29E3D, #FCC757)" }}>{canPostJobs ? "Post A Live Job" : "Unlock Job Posting"}</a>
              <Link href="/ai?prompt=Help%20me%20write%20a%20high-converting%20construction%20job%20post%20for%20ConstructionOS." className="px-5 py-3 rounded-xl text-sm font-bold text-[#4AC4CC] border border-[#4AC4CC]">Ask Angelic To Draft It</Link>
            </div>
          </div>
          <div className="flex flex-wrap gap-3 mt-5 text-[11px] font-bold">
            <span className="px-3 py-1.5 rounded-full" style={{ background: "rgba(105,210,148,0.08)", color: "#69D294" }}>Source: {source === "live" ? "Live database" : "ConstructionOS"}</span>
            <span className="px-3 py-1.5 rounded-full" style={{ background: "rgba(74,196,204,0.08)", color: "#4AC4CC" }}>Last sync: {lastSyncAt ? new Date(lastSyncAt).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" }) : "Waiting"}</span>
            <span className="px-3 py-1.5 rounded-full" style={{ background: "rgba(242,158,61,0.08)", color: "#F29E3D" }}>{refreshing ? "Refreshing live data" : "Auto-refresh every 30s"}</span>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-3 mb-6">
          <div className="rounded-2xl p-4" style={{ background: "#0F1C24" }}>
            <div className="text-[10px] font-black tracking-[0.2em] text-[#9EBDC2] mb-2">OPEN JOBS</div>
            <div className="text-3xl font-black text-[#F29E3D]">{jobs.length}</div>
          </div>
          <div className="rounded-2xl p-4" style={{ background: "#0F1C24" }}>
            <div className="text-[10px] font-black tracking-[0.2em] text-[#9EBDC2] mb-2">URGENT</div>
            <div className="text-3xl font-black text-[#D94D48]">{urgentCount}</div>
          </div>
          <div className="rounded-2xl p-4" style={{ background: "#0F1C24" }}>
            <div className="text-[10px] font-black tracking-[0.2em] text-[#9EBDC2] mb-2">TRADES</div>
            <div className="text-3xl font-black text-[#4AC4CC]">{tradeCount || 0}</div>
          </div>
          <div className="rounded-2xl p-4" style={{ background: "#0F1C24" }}>
            <div className="text-[10px] font-black tracking-[0.2em] text-[#9EBDC2] mb-2">STATUS</div>
            <div className="text-sm font-black text-[#69D294]">{loading ? "LOADING" : "LIVE READY"}</div>
          </div>
        </div>

        <div className="grid grid-cols-1 xl:grid-cols-[1.1fr,1.7fr] gap-6 items-start">
          <section id="post-job" className="rounded-3xl p-5 md:p-6" style={{ scrollMarginTop: 80, background: "#0F1C24", border: "1px solid rgba(242,158,61,0.08)" }}>
            <div className="text-[10px] font-black tracking-[0.22em] text-[#F29E3D] mb-2">POST A JOB</div>
            <h2 className="text-2xl font-black mb-2">Publish A Real Hiring Need</h2>
            <p className="text-sm text-[#9EBDC2] mb-5">The board is public to read. Paid subscribers can publish directly into the live jobs feed so hiring stays active and believable.</p>

            {submitError && <div className="mb-4 rounded-xl px-4 py-3 text-sm font-bold" style={{ background: "rgba(217,77,72,0.12)", color: "#D94D48" }}>{submitError}</div>}
            {submitSuccess && <div className="mb-4 rounded-xl px-4 py-3 text-sm font-bold" style={{ background: "rgba(105,210,148,0.12)", color: "#69D294" }}>{submitSuccess}</div>}

            {canPostJobs ? (
              <form onSubmit={handleSubmit} className="space-y-3">
                <input value={form.title} onChange={(event) => setForm((current) => ({ ...current, title: event.target.value }))} placeholder="Job title" />
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  <input value={form.company} onChange={(event) => setForm((current) => ({ ...current, company: event.target.value }))} placeholder="Company name" />
                  <input value={form.location} onChange={(event) => setForm((current) => ({ ...current, location: event.target.value }))} placeholder="City, State" />
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  <input value={form.pay} onChange={(event) => setForm((current) => ({ ...current, pay: event.target.value }))} placeholder="Pay range or salary" />
                  <select value={form.trade} onChange={(event) => setForm((current) => ({ ...current, trade: event.target.value }))}>
                    {tradeOptions.map((trade) => <option key={trade} value={trade}>{trade}</option>)}
                  </select>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  <select value={form.employmentType} onChange={(event) => setForm((current) => ({ ...current, employmentType: event.target.value }))}>
                    {employmentTypes.map((type) => <option key={type} value={type}>{type}</option>)}
                  </select>
                  <input value={form.startLabel} onChange={(event) => setForm((current) => ({ ...current, startLabel: event.target.value }))} placeholder="Start date or label" />
                </div>
                <input value={form.duration} onChange={(event) => setForm((current) => ({ ...current, duration: event.target.value }))} placeholder="Duration (optional)" />
                <textarea value={form.description} onChange={(event) => setForm((current) => ({ ...current, description: event.target.value }))} placeholder="Role description" rows={5} />
                <input value={form.requirements} onChange={(event) => setForm((current) => ({ ...current, requirements: event.target.value }))} placeholder="Requirements, comma separated" />
                <input value={form.contactEmail} onChange={(event) => setForm((current) => ({ ...current, contactEmail: event.target.value }))} placeholder="Application email (optional)" type="email" />
                <label className="flex items-center gap-3 text-sm font-bold text-[#9EBDC2]">
                  <input type="checkbox" checked={form.urgent} onChange={(event) => setForm((current) => ({ ...current, urgent: event.target.checked }))} />
                  Mark this opening urgent
                </label>
                <button type="submit" disabled={submitting} className="w-full py-3 rounded-xl text-sm font-bold text-black" style={{ background: "linear-gradient(90deg, #F29E3D, #FCC757)", opacity: submitting ? 0.7 : 1 }}>
                  {submitting ? "Posting live job..." : "POST JOB LIVE"}
                </button>
              </form>
            ) : (
              <div className="rounded-2xl p-4" style={{ background: "rgba(74,196,204,0.06)", border: "1px solid rgba(74,196,204,0.12)" }}>
                <div className="text-[10px] font-black tracking-[0.2em] text-[#4AC4CC] mb-2">{tierLoading ? "CHECKING ACCOUNT" : "PAID POSTING ACCESS"}</div>
                <div className="text-sm text-[#F0F8F8] mb-2">Anyone can read the live board. Paid subscribers unlock job publishing, hiring visibility, and recurring posting flow.</div>
                <div className="text-xs text-[#9EBDC2] mb-4">Use the board to see demand, then upgrade when you’re ready to post real roles into the network.</div>
                <div className="flex flex-col sm:flex-row gap-3">
                  <Link href="/checkout?plan=field&redirect=%2Fjobs%23post-job" className="flex-1 py-3 rounded-xl text-sm font-bold text-center text-black" style={{ background: "linear-gradient(90deg, #F29E3D, #FCC757)" }}>
                    Unlock Job Posting
                  </Link>
                  <Link href="/login?redirect=%2Fjobs%23post-job" className="flex-1 py-3 rounded-xl text-sm font-bold text-center text-[#4AC4CC] border border-[#4AC4CC]">
                    Sign In
                  </Link>
                </div>
              </div>
            )}
          </section>

          <section>
            <div className="flex flex-wrap gap-2 mb-4">
              {["All trades", ...Array.from(new Set(jobs.map((job) => job.trade)))].map((trade) => (
                <button key={trade} type="button" onClick={() => setActiveTrade(trade)} className="px-3 py-2 rounded-lg text-[11px] font-bold" style={{ background: activeTrade === trade ? "#69D294" : "#0F1C24", color: activeTrade === trade ? "#081014" : "#9EBDC2" }}>
                  {trade.toUpperCase()}
                </button>
              ))}
            </div>

            {error && <div className="mb-4 rounded-xl px-4 py-3 text-sm font-bold" style={{ background: "rgba(217,77,72,0.12)", color: "#D94D48" }}>{error}</div>}
            {source !== "live" && !error && (
              <div className="mb-4 rounded-xl px-4 py-3 text-sm font-bold" style={{ background: "rgba(74,196,204,0.12)", color: "#4AC4CC" }}>Showing featured job listings. New postings appear in real time as employers submit them.</div>
            )}

            {loading ? (
              <div className="rounded-3xl p-8 text-center" style={{ background: "#0F1C24" }}>
                <div className="text-[11px] font-black tracking-[0.2em] text-[#4AC4CC] mb-2">LOADING JOBS</div>
                <p className="text-sm text-[#9EBDC2]">Pulling the latest jobs board entries now.</p>
              </div>
            ) : filteredJobs.length === 0 ? (
              <div className="rounded-3xl p-8 text-center" style={{ background: "#0F1C24" }}>
                <div className="text-xl font-black mb-2">No jobs in this filter yet</div>
                <p className="text-sm text-[#9EBDC2]">Switch trades or post the first role to get the board moving.</p>
              </div>
            ) : (
              <div className="space-y-4">
                {filteredJobs.map((job) => (
                  <article key={job.id} className="rounded-3xl p-5" style={{ background: "#0F1C24", border: "1px solid rgba(74,196,204,0.08)" }}>
                    <div className="flex flex-col md:flex-row md:items-start md:justify-between gap-3 mb-4">
                      <div>
                        <div className="flex items-center gap-2 flex-wrap mb-2">
                          <h3 className="text-xl font-black">{job.title}</h3>
                          {job.urgent && <span className="px-2 py-1 rounded-full text-[10px] font-black" style={{ background: "rgba(217,77,72,0.12)", color: "#D94D48" }}>URGENT</span>}
                        </div>
                        <div className="text-sm text-[#9EBDC2]">{job.company} · {job.location}</div>
                        <div className="text-[11px] font-bold text-[#4AC4CC] mt-1">Posted by {job.authorName} · {job.authorTitle}</div>
                      </div>
                      <div className="md:text-right">
                        <div className="text-2xl font-black text-[#69D294]">{job.pay}</div>
                        <div className="text-[11px] font-bold text-[#9EBDC2]">{job.employmentType} · {job.duration}</div>
                        <div className="text-[11px] font-bold text-[#F29E3D] mt-1">Start: {job.startLabel}</div>
                      </div>
                    </div>

                    <p className="text-sm leading-relaxed text-[#F0F8F8] mb-4">{job.description}</p>

                    <div className="flex flex-wrap gap-2 mb-4">
                      <span className="px-2.5 py-1 rounded-full text-[10px] font-black" style={{ background: "rgba(74,196,204,0.08)", color: "#4AC4CC" }}>{job.trade}</span>
                      {job.tags.map((tag) => (
                        <span key={`${job.id}-${tag}`} className="px-2.5 py-1 rounded-full text-[10px] font-black" style={{ background: "rgba(242,158,61,0.08)", color: "#F29E3D" }}>{tag}</span>
                      ))}
                      <span className="px-2.5 py-1 rounded-full text-[10px] font-black" style={{ background: "rgba(105,210,148,0.08)", color: "#69D294" }}>Posted {formatDateLabel(job.createdAt)}</span>
                    </div>

                    {job.requirements.length > 0 && (
                      <div className="mb-4">
                        <div className="text-[10px] font-black tracking-[0.2em] text-[#9EBDC2] mb-2">REQUIREMENTS</div>
                        <div className="flex flex-wrap gap-2">
                          {job.requirements.map((requirement) => (
                            <span key={`${job.id}-${requirement}`} className="px-2.5 py-1 rounded-full text-[10px] font-bold" style={{ background: "rgba(138,143,204,0.12)", color: "#B3B8FF" }}>{requirement}</span>
                          ))}
                        </div>
                      </div>
                    )}

                    <div className="flex flex-col sm:flex-row gap-3">
                      {job.contactEmail ? (
                        <button
                          type="button"
                          onClick={() => openApplyModal(job)}
                          className="flex-1 py-3 rounded-xl text-sm font-bold text-center text-black"
                          style={{ background: "linear-gradient(90deg, #69D294, #4AC4CC)", border: "none", cursor: "pointer" }}
                        >
                          Apply By Email
                        </button>
                      ) : (
                        <Link href={buildApplyAiHref(job)} className="flex-1 py-3 rounded-xl text-sm font-bold text-center text-black" style={{ background: "linear-gradient(90deg, #69D294, #4AC4CC)" }}>
                          Ask Angelic To Help Apply
                        </Link>
                      )}
                      <Link href="/feed" className="flex-1 py-3 rounded-xl text-sm font-bold text-center text-[#F29E3D] border border-[#F29E3D]">Open The Network</Link>
                    </div>
                  </article>
                ))}
              </div>
            )}
          </section>
        </div>
      </div>
  );
}
