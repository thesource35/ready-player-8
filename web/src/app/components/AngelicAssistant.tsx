"use client";
import { useState, useRef, useEffect } from "react";
import { usePathname } from "next/navigation";

interface Message {
  role: "user" | "assistant";
  content: string;
}

// Page-specific context and suggestions
const pageContext: Record<string, { title: string; greeting: string; suggestions: string[] }> = {
  "/": { title: "Home", greeting: "Welcome to ConstructionOS! I can help you explore any feature or get started.", suggestions: [
    "Give me an overview of the platform",
    "What features are available?",
    "Help me set up my account",
    "What's the best plan for a GC?",
  ]},
  "/projects": { title: "Projects", greeting: "I see you're managing projects. I can help with status updates, risk analysis, or create new project reports.", suggestions: [
    "What's the status of Riverside Lofts?",
    "Which project has the highest risk score?",
    "Generate a weekly project summary report",
    "How do I add a new project?",
  ]},
  "/contracts": { title: "Contracts", greeting: "You're in the bid pipeline. I can help analyze bids, draft proposals, or evaluate opportunities.", suggestions: [
    "Which bids are due this week?",
    "What's our bid win rate by sector?",
    "Draft a bid proposal for a healthcare project",
    "Score this bid opportunity for me",
  ]},
  "/market": { title: "Market", greeting: "Let me help you analyze market trends, find opportunities, or evaluate regions.", suggestions: [
    "Which market has the most growth?",
    "Compare Houston vs Dallas construction activity",
    "What sectors are hot right now?",
    "Find open bids in the Southeast",
  ]},
  "/maps": { title: "Maps", greeting: "I can help you plan routes, check site conditions, or coordinate deliveries.", suggestions: [
    "What's the fastest route to Riverside Lofts?",
    "Which sites have active alerts?",
    "Schedule a concrete delivery for tomorrow",
    "Check weather conditions for all sites",
  ]},
  "/feed": { title: "Network", greeting: "You're on the construction network. I can help you find connections, post updates, or search for talent.", suggestions: [
    "Who's hiring electricians near Houston?",
    "Draft a project update post",
    "Find concrete contractors with 4.8+ rating",
    "What equipment is for sale on the marketplace?",
  ]},
  "/ops": { title: "Ops Center", greeting: "I can help you prioritize alerts, manage the action queue, or draft reports.", suggestions: [
    "What are today's critical alerts?",
    "Generate a daily commander report",
    "Draft an RFI for the conduit delay",
    "Summarize all open change orders",
  ]},
  "/hub": { title: "Integration Hub", greeting: "Need help connecting your tools? I can guide you through any integration setup.", suggestions: [
    "How do I connect Supabase?",
    "Set up QuickBooks integration",
    "What integrations are available?",
    "Test my backend connection",
  ]},
  "/security": { title: "Security", greeting: "I can help you review security settings, audit access, or configure 2FA.", suggestions: [
    "Review my security audit log",
    "How do I enable Face ID?",
    "Show me active sessions",
    "What 2FA methods are recommended?",
  ]},
  "/pricing": { title: "Pricing", greeting: "Let me help you find the right plan for your team.", suggestions: [
    "Which plan is best for a superintendent?",
    "What's included in the PM plan?",
    "Compare your pricing to Procore",
    "How does the free trial work?",
  ]},
  "/ai": { title: "Angelic AI", greeting: "You're on my full chat page! Ask me anything about construction.", suggestions: [
    "What are your 56 AI tools?",
    "Help me write a safety report",
    "Analyze my project portfolio risk",
    "Create a material takeoff estimate",
  ]},
  "/field": { title: "Field Ops", greeting: "I can help you create daily logs, manage timecards, or track equipment.", suggestions: [
    "Generate today's daily log template",
    "Calculate overtime for this week's crew",
    "Which equipment needs service soon?",
    "Check permit expiration dates",
  ]},
  "/finance": { title: "Finance", greeting: "Let me help with pay apps, lien waivers, or cash flow forecasting.", suggestions: [
    "Generate Pay App #08 for Riverside Lofts",
    "Which lien waivers are pending?",
    "Forecast cash flow for next quarter",
    "Calculate retainage balance across all projects",
  ]},
  "/compliance": { title: "Compliance", greeting: "I can help you stay compliant with safety talks, payroll, and environmental requirements.", suggestions: [
    "What toolbox talks are due this week?",
    "Generate certified payroll for Week 13",
    "Check environmental compliance status",
    "Create a fall protection training outline",
  ]},
  "/clients": { title: "Client Portal", greeting: "I can help you prepare owner updates, manage selections, or track warranties.", suggestions: [
    "Draft a client progress update",
    "Which material selections are pending?",
    "List all active warranty items",
    "Prepare OAC meeting minutes template",
  ]},
  "/analytics": { title: "Analytics", greeting: "Let me help you analyze bids, productivity, or risk scores.", suggestions: [
    "What's our overall bid win rate?",
    "Which trade has the best productivity?",
    "Show me AI risk scores for all projects",
    "Compare labor costs across projects",
  ]},
  "/schedule": { title: "Schedule", greeting: "I can help with scheduling, critical path analysis, or lookahead planning.", suggestions: [
    "What's on the critical path?",
    "Generate a 3-week lookahead",
    "Which tasks are behind schedule?",
    "Optimize the trade sequence for Level 3",
  ]},
  "/training": { title: "Training", greeting: "I can help track certifications, find courses, or check compliance requirements.", suggestions: [
    "Which certifications are expiring soon?",
    "What OSHA training does my crew need?",
    "Find a PMP prep course",
    "Generate a training compliance report",
  ]},
  "/scanner": { title: "Scanner", greeting: "I can help you manage scans, track materials, or find equipment by tag.", suggestions: [
    "How many crew sign-ins today?",
    "Look up equipment tag EQ-001",
    "Track material delivery PO-4422",
    "Generate an inventory audit report",
  ]},
  "/electrical": { title: "Electrical & Fiber", greeting: "I can help you find electricians, manage leads, or plan fiber installations.", suggestions: [
    "Find a licensed electrician in Houston",
    "What electrical leads are open?",
    "Plan a fiber installation for 48 units",
    "Compare electrician rates in Texas",
  ]},
  "/tax": { title: "Tax Center", greeting: "I can help with deductions, quarterly estimates, 1099s, or finding a construction CPA.", suggestions: [
    "What are my total deductions this year?",
    "When are quarterly estimates due?",
    "Which subs need 1099s filed?",
    "Find a CPA that specializes in construction",
  ]},
  "/punch": { title: "Punch List", greeting: "I can help create punch items, prioritize the list, or generate closeout reports.", suggestions: [
    "How many punch items are open?",
    "Which items are critical priority?",
    "Generate a punch list summary by trade",
    "Create closeout documentation",
  ]},
  "/roofing": { title: "Roofing Estimator", greeting: "I can help estimate roof costs, compare materials, or calculate measurements.", suggestions: [
    "Estimate cost for a 2,400 SF roof",
    "Compare TPO vs standing seam metal",
    "What's the best material for a flat roof?",
    "Calculate pitch multiplier for 6:12",
  ]},
  "/smart-build": { title: "Smart Build", greeting: "I can help with concrete testing, BIM coordination, or sustainability planning.", suggestions: [
    "What's the 28-day break test result for B-042?",
    "Show me active BIM clashes",
    "Calculate carbon footprint for this project",
    "Plan a modular construction sequence",
  ]},
  "/contractors": { title: "Directory", greeting: "I can help you find contractors, compare qualifications, or check verifications.", suggestions: [
    "Find a verified concrete contractor in Texas",
    "Who has the highest rating in steel?",
    "Compare GCs with $10M+ bonding capacity",
    "Which contractors are available now?",
  ]},
  "/tech": { title: "Tech 2026", greeting: "I can brief you on the latest construction technology trends and applications.", suggestions: [
    "What's the ROI of digital twins?",
    "How are construction robots being used?",
    "What 5G applications work on jobsites?",
    "Compare AI risk scoring platforms",
  ]},
  "/wealth": { title: "Wealth Suite", greeting: "I can help you think strategically about wealth building, leverage, and opportunities.", suggestions: [
    "Score this opportunity for me",
    "What's my leverage system score?",
    "Apply the 10X Rule to my pipeline",
    "Analyze my wealth archetype",
  ]},
  "/cos-network": { title: "COS Network", greeting: "I can help you get verified, understand the network, or grow your presence.", suggestions: [
    "How do I get verified?",
    "What are the verification tier benefits?",
    "How does license verification work?",
    "Get me started with the network",
  ]},
  "/rentals": { title: "Equipment Rentals", greeting: "I can help you find the right equipment, compare prices, or request quotes.", suggestions: [
    "Find an excavator for under $1,000/day",
    "Compare boom lift prices across providers",
    "What equipment do I need for site prep?",
    "Request a quote for a 100-ton crane",
  ]},
  "/empire": { title: "Financial Empire", greeting: "I can help you understand the financial products and optimize your cash flow.", suggestions: [
    "How does invoice factoring work?",
    "What insurance coverage do I need?",
    "Analyze my payment processing fees",
    "How do I increase my bonding capacity?",
  ]},
  "/settings": { title: "Settings", greeting: "I can help you configure your account, change roles, or manage your subscription.", suggestions: [
    "Change my role to Executive",
    "How do I upgrade my subscription?",
    "Export all my data",
    "How do I connect Supabase?",
  ]},
  "/verify": { title: "Verification", greeting: "I can guide you through the verification process step by step.", suggestions: [
    "What documents do I need for verification?",
    "How long does verification take?",
    "What's the difference between tiers?",
    "Is my electrician license eligible?",
  ]},
  "/checkout": { title: "Checkout", greeting: "I can help you choose the right plan or answer billing questions.", suggestions: [
    "What's included in each plan?",
    "Can I cancel anytime?",
    "Is there a free trial?",
    "Which payment methods do you accept?",
  ]},
  "/login": { title: "Login", greeting: "Need help signing in or creating an account? I'm here to help.", suggestions: [
    "How do I create an account?",
    "I forgot my password",
    "Can I sign in with Apple?",
    "Is my data secure?",
  ]},
};

const defaultContext = { title: "ConstructionOS", greeting: "I'm Angelic — your AI construction assistant. How can I help?", suggestions: [
  "What can you help me with?",
  "Show me my projects",
  "Find equipment to rent",
  "Navigate to a feature",
]};

// Proactive insights that trigger based on page + timing
const proactiveInsights: Record<string, { delay: number; type: string; message: string }[]> = {
  "/projects": [
    { delay: 8000, type: "🔔 ALERT", message: "**Pine Ridge Ph.2** is 28% complete and marked DELAYED. Risk score is 61. I'd recommend reviewing the schedule slip — the grading permit expires Jun 1. Want me to draft an action plan?" },
    { delay: 20000, type: "💡 MANAGEMENT", message: "**Tip:** Projects with scores below 70 have a 3x higher chance of cost overrun. Consider pulling the Riverside Lofts superintendent to consult on Pine Ridge recovery." },
    { delay: 35000, type: "💰 WEALTH", message: "**Wealth Insight:** Your $43.9M project pipeline represents 10X your current annual revenue. Apply the 10X Rule — you're thinking at the right scale. Focus on margin optimization (target 18%+ on each project)." },
  ],
  "/contracts": [
    { delay: 8000, type: "🔔 ALERT", message: "**Houston Medical Complex** ($18.2M, score 94) is your highest-scoring bid. Deadline is Apr 15 — 14 days away. Want me to draft the proposal package?" },
    { delay: 22000, type: "💡 MANAGEMENT", message: "**Tip:** Your 68% win rate is strong, but Infrastructure sector is only 40%. Consider partnering with a specialty firm for the Port of Houston bid to improve your position." },
    { delay: 38000, type: "💰 WEALTH", message: "**Wealth Insight:** The DFW Airport Terminal C bid ($45M) would be your largest contract. Win this and your bonding capacity needs to increase. Start the conversation with your surety now — don't wait for the award." },
  ],
  "/ops": [
    { delay: 6000, type: "🔔 ALERT", message: "**2 CRITICAL alerts need attention now:**\n1. Delayed conduit shipment (PO-4422) — impacts electrical rough-in\n2. Open recordable incident (Grid B-7) — corrective action still open\n\nBoth are due TODAY. Want me to draft response actions?" },
    { delay: 18000, type: "💡 MANAGEMENT", message: "**Tip:** Your action queue has 4 items. The most impactful is CO-003 ($22,800 foundation depth increase). Get the geotech memo submitted today — owner approval on change orders takes avg 5 days." },
  ],
  "/finance": [
    { delay: 8000, type: "🔔 ALERT", message: "**Pay App #07** ($284,500) is SUBMITTED but not yet approved. Average approval time is 12 days. Follow up with Metro Development if no response by Friday." },
    { delay: 22000, type: "💰 WEALTH", message: "**Cash Flow Insight:** Your net positive is +$143K/mo for Q2. But retainage of $95K is locked up. Consider invoice factoring — ConstructionOS Capital offers 90% advance at 2.5% fee. That puts $85K back in your pocket in 24 hours.\n\n[→ View Capital Options](/empire)" },
  ],
  "/rentals": [
    { delay: 8000, type: "💡 MANAGEMENT", message: "**Tip:** Based on your project phases, you'll need aerial equipment for Harbor Crossing exterior work starting Week 14. Book now — boom lifts have 1-week lead times in Houston. Want me to request quotes?" },
    { delay: 25000, type: "💰 WEALTH", message: "**Wealth Insight:** You're spending ~$8,500/mo on equipment rentals. At that volume, buying a used Bobcat S770 ($38K) pays for itself in 4.5 months vs renting. The depreciation is also a tax deduction.\n\n[→ View Tax Deductions](/tax)" },
  ],
  "/feed": [
    { delay: 10000, type: "💡 MANAGEMENT", message: "**Network Tip:** Darnell Washington's post about the 8,400 SF mat slab got 421 likes. Your network values real project content. Post your Riverside Lofts Level 3 pour results — it builds credibility and attracts talent." },
    { delay: 30000, type: "💰 WEALTH", message: "**Wealth Insight:** Every professional in the network is a potential customer. Every post you make is free marketing. The builders with the strongest networks win the best projects. Post 3x per week minimum." },
  ],
  "/analytics": [
    { delay: 8000, type: "🔔 ALERT", message: "**Riverside Lofts risk score is 92/100 (HIGH).** Factors: 3 weather delays in 30 days, sub default risk, and pending permit renewal. This project needs daily superintendent attention." },
    { delay: 20000, type: "💡 MANAGEMENT", message: "**Tip:** Your electrical trade productivity (3.1 dev/hr) is 11% below benchmark. This could indicate understaffing or design issues. Schedule a coordination meeting with Prime Electric this week." },
  ],
  "/schedule": [
    { delay: 8000, type: "🔔 ALERT", message: "**Structural Steel** is on the critical path and 75% complete. The remaining 25% gates the Exterior Envelope (Week 14). Any slip here cascades to Drywall, Finishes, and Commissioning." },
    { delay: 22000, type: "💡 MANAGEMENT", message: "**Tip:** Your 3-week lookahead shows 55 crew needed in Week 15 — that's your peak. Confirm labor availability with all subs NOW. Construction labor shortages are up 12% in the Southeast." },
  ],
  "/wealth": [
    { delay: 5000, type: "💰 WEALTH", message: "**Mansa Musa Principle:** You're sitting on $4.2M in business revenue with +18% growth. The next move: deploy capital into assets that generate MORE capital. Real estate equity ($1.8M) is your strongest lever right now." },
    { delay: 18000, type: "💰 WEALTH", message: "**10X Rule Applied:** Your pipeline is $43.9M. To 10X, you need $439M. That means: 3 more project managers, bonding capacity to $50M, and a presence in 3 more metro markets. Start with Dallas — it's your closest expansion." },
    { delay: 32000, type: "💰 WEALTH", message: "**Leverage Score: 74/100.** Your weakest category is Digital Capital (55). Invest in automation — every automated report, invoice, or schedule update saves 15-30 min. At your billing rate, that's $50K/year recovered.\n\n[→ View Leverage System](/wealth)" },
  ],
  "/empire": [
    { delay: 8000, type: "💰 WEALTH", message: "**Empire Insight:** Your ConstructionOS Pay processes $4.2M at 1.5% = $63K revenue from fees alone. Scale to $20M in transactions and you're generating $300K/yr in payment processing revenue — a business within a business." },
    { delay: 25000, type: "💡 MANAGEMENT", message: "**Tip:** Invoice factoring (Capital) has $434K in available advances. If cash flow is tight before a big material order, factor your next pay app. The 2.5% fee is worth it to avoid late-payment penalties from suppliers." },
  ],
  "/compliance": [
    { delay: 6000, type: "🔔 ALERT", message: "**Noise Compliance is DUE** — last inspection Mar 10, next due Mar 25. This is overdue. Schedule the inspection immediately to avoid a stop-work order." },
    { delay: 18000, type: "💡 MANAGEMENT", message: "**Tip:** 6 of 8 toolbox talks are REQUIRED this week. Fall Protection and Silica Dust are the most common OSHA citation topics. Run those first." },
  ],
  "/": [
    { delay: 5000, type: "💡 MANAGEMENT", message: "**Good morning!** Here's your daily brief:\n• 2 critical ops alerts need attention\n• Pay App #07 ($284K) awaiting approval\n• Pine Ridge Ph.2 is behind schedule\n• Houston Medical Complex bid due in 14 days\n\nWant me to generate your full Commander Report?" },
    { delay: 25000, type: "💰 WEALTH", message: "**Daily Wealth Thought:** \"Don't just build buildings — build the company that builds buildings.\" Your platform serves a growing network of professionals. Every feature you add increases the value of the network exponentially. That's the real empire.\n\n[→ View Financial Empire](/empire)" },
  ],
  "/market": [
    { delay: 8000, type: "🔔 ALERT", message: "**Phoenix** is leading the nation in permit growth (+15% YoY). Semiconductor and data center construction is booming. Your bid pipeline has 0 projects in AZ — consider expanding." },
    { delay: 22000, type: "💰 WEALTH", message: "**Wealth Insight:** The Southeast labor market is tightening (costs up 8-12%). This means contractors who lock in crews NOW will have a competitive advantage in 6 months. Invest in workforce retention." },
  ],
  "/maps": [
    { delay: 8000, type: "🔔 ALERT", message: "**Pine Ridge Ph.2** has 2 active alerts and only 12 crew on site. The other 3 sites are running at capacity. Consider rebalancing crew from Riverside Lofts (24 crew, 72% complete)." },
    { delay: 20000, type: "💡 MANAGEMENT", message: "**Tip:** The delivery route from Steel Fabricator to Skyline Tower shows HEAVY traffic (35 min). Schedule steel deliveries before 6:30 AM to avoid I-10 congestion." },
  ],
  "/hub": [
    { delay: 8000, type: "💡 MANAGEMENT", message: "**Integration Tip:** Connect QuickBooks to auto-sync your pay apps, invoices, and 1099 data. This eliminates 4-6 hours of manual data entry per week.\n\n[→ Set Up QuickBooks](/hub)" },
    { delay: 22000, type: "💰 WEALTH", message: "**Wealth Insight:** Every manual process you automate through integrations recovers billable hours. At a PM billing rate of $125/hr, 6 hours/week = $39K/year recovered. Automate aggressively." },
  ],
  "/security": [
    { delay: 8000, type: "🔔 ALERT", message: "**Security Notice:** There was a failed login attempt from unknown@gmail.com on Mar 30. 2FA blocked it. Your security is working — but review the audit log for any patterns." },
    { delay: 20000, type: "💡 MANAGEMENT", message: "**Tip:** Enable biometric lock for all team members. 73% of construction data breaches come from shared or weak passwords. Face ID eliminates this risk." },
  ],
  "/field": [
    { delay: 8000, type: "🔔 ALERT", message: "**Bobcat S770** (EQ-008) is SERVICE DUE — only 40 hours until next scheduled maintenance. If it goes down on Pine Ridge, you'll lose 2 days. Schedule service this weekend." },
    { delay: 20000, type: "💡 MANAGEMENT", message: "**Tip:** Sarah Kim logged 2.5 OT hours yesterday at $55/hr. Your electrical trade is consistently running overtime — you may need a 4th electrician on Harbor Crossing to control labor costs." },
    { delay: 35000, type: "💰 WEALTH", message: "**Wealth Insight:** Your daily log shows 47 workers producing $4.2M in value. That's $89K revenue per worker annually. Industry average is $65K. You're running a high-productivity operation — protect it by investing in safety and retention." },
  ],
  "/clients": [
    { delay: 8000, type: "🔔 ALERT", message: "**3 material selections are PENDING** with deadlines this week: Kitchen Countertops (Apr 5), Cabinet Hardware (Apr 8), Exterior Paint (Apr 10). Follow up with the owner today." },
    { delay: 22000, type: "💡 MANAGEMENT", message: "**Tip:** Send owners a weekly photo update even when they don't ask. It builds trust, reduces RFIs, and prevents scope disputes. I can auto-generate these from your daily log photos." },
  ],
  "/training": [
    { delay: 8000, type: "🔔 ALERT", message: "**Scaffolding Competent Person** certification expires Feb 2026 — that's EXPIRED. Renew immediately or you can't have anyone on scaffolds. Fine is $16,131 per violation." },
    { delay: 20000, type: "💡 MANAGEMENT", message: "**Tip:** OSHA 30-Hour is 65% complete. Prioritize finishing it — OSHA 30 is required on all federal projects and many state/local jobs. It opens up a bigger bid market." },
  ],
  "/electrical": [
    { delay: 8000, type: "💡 MANAGEMENT", message: "**Tip:** The Fire Alarm Retrofit lead (Downtown Houston, $28K-$35K) has only 1 bid. Low competition = higher margin opportunity. If you have fire alarm capability, bid this today." },
    { delay: 22000, type: "💰 WEALTH", message: "**Wealth Insight:** Electrical contractors who add solar installation capability see 40% revenue growth. NABCEP PV certification takes 4-6 weeks. The IRA tax credits are driving massive demand through 2028." },
  ],
  "/tax": [
    { delay: 8000, type: "🔔 ALERT", message: "**Q1 2026 quarterly estimate is DUE Apr 15.** Estimated payment: $18,400. Have you set aside the funds? I can calculate your exact liability from your current deductions." },
    { delay: 22000, type: "💰 WEALTH", message: "**Tax Strategy:** Your equipment rental expense is $48.2K. If you buy a used excavator instead ($85K), you can take Section 179 depreciation and deduct the FULL purchase price this year. Net tax savings: ~$25K." },
  ],
  "/punch": [
    { delay: 8000, type: "🔔 ALERT", message: "**2 CRITICAL punch items need same-day attention:**\n• PL-004: Caulk gap at window frame, unit 405 (DUE TODAY)\n• PL-007: Fire caulking incomplete at shaft 3 (DUE Apr 1)\n\nFire caulking failures can block your CO inspection." },
    { delay: 20000, type: "💡 MANAGEMENT", message: "**Tip:** You have 5 open items and 2 complete. At this rate, closeout will take 2 more weeks. To accelerate, assign all critical items to the same crew for a focused punch day this Saturday." },
  ],
  "/roofing": [
    { delay: 8000, type: "💡 MANAGEMENT", message: "**Tip:** For your project budgets, Architectural Shingles ($4.25/SF) offer the best value — 30-year lifespan at half the cost of standing seam metal. Best ROI for residential projects." },
    { delay: 22000, type: "💰 WEALTH", message: "**Wealth Insight:** Roofing is a $56B market in the US. The satellite estimator tool gives you an edge — you can quote 10X faster than competitors doing manual measurements. Volume wins in roofing." },
  ],
  "/smart-build": [
    { delay: 8000, type: "🔔 ALERT", message: "**BIM CLASH: CLASH-042 is CRITICAL** — HVAC duct vs structural beam at Grid D-4, Level 2. This must be resolved before drywall starts or you'll be tearing out work. Schedule a coordination meeting TODAY." },
    { delay: 22000, type: "💰 WEALTH", message: "**Wealth Insight:** BIM coordination saved 340 hours on Gateway Office Tower. At $75/hr average, that's $25,500 in avoided rework on ONE project. Multiply across your portfolio — BIM pays for itself 10X over." },
  ],
  "/contractors": [
    { delay: 8000, type: "💡 MANAGEMENT", message: "**Tip:** Dubai Build Corp ($120M revenue, 4.9 rating) specializes in mega projects. If you're pursuing contracts over $50M, a JV partnership with an international firm adds credibility and bonding capacity." },
    { delay: 22000, type: "💰 WEALTH", message: "**Wealth Insight:** Your directory has contractors in 6 countries. The global construction market is $13T. Even capturing 0.001% through your platform = $130M in facilitated transactions. Think globally." },
  ],
  "/tech": [
    { delay: 8000, type: "💡 MANAGEMENT", message: "**Trend Alert:** Digital twin adoption is becoming standard on projects over $10M in 2026. If you're not using them yet, you'll lose bids to competitors who do. Start with one pilot project." },
    { delay: 22000, type: "💰 WEALTH", message: "**Wealth Insight:** Companies that invest in construction tech early see 15-25% profit margin improvement within 2 years. The ROI on wearable safety tech alone (reduced incidents, lower insurance) pays for all other tech investments." },
  ],
  "/cos-network": [
    { delay: 8000, type: "💡 MANAGEMENT", message: "**Network Growth Tip:** Licensed Professional verification ($27.99/mo) gives you priority in search results and a gold badge. Verified contractors get 5X more profile views and 3X more bid invitations." },
    { delay: 22000, type: "💰 WEALTH", message: "**Wealth Insight:** Your verification system creates a trust moat. Every verified contractor increases the network's value for ALL users. At scale, this is what makes ConstructionOS irreplaceable — switching costs go through the roof.\n\n[→ Get Verified](/verify)" },
  ],
  "/settings": [
    { delay: 8000, type: "💡 MANAGEMENT", message: "**Tip:** You're on the Project Manager plan ($27.99/mo). If you manage more than 3 projects, the Company Owner plan ($49.99/mo) includes multi-project dashboards, API access, and priority support — worth it at your scale." },
  ],
  "/verify": [
    { delay: 8000, type: "💡 MANAGEMENT", message: "**Verification Tip:** Licensed Professional tier gives you the gold badge, priority search placement, and ability to bid on projects. Most verified users report 3X more inbound opportunities within 30 days." },
  ],
  "/checkout": [
    { delay: 8000, type: "💡 MANAGEMENT", message: "**Smart Move:** The annual plan saves 17%. At $279.99/yr for PM (vs $335.88 monthly), you save $56/yr. Over the life of your subscription, that adds up." },
  ],
  "/pricing": [
    { delay: 10000, type: "💰 WEALTH", message: "**ROI Calculation:** The PM plan at $27.99/mo costs $336/year. If Angelic AI saves you just 2 hours/week on reports, RFIs, and estimates — at your billing rate — that's $13,000/year in recovered time. ROI: 38X." },
  ],
};

export default function AngelicAssistant() {
  const pathname = usePathname();
  const ctx = pageContext[pathname] || defaultContext;

  const [isOpen, setIsOpen] = useState(true);
  const [messages, setMessages] = useState<Message[]>([
    { role: "assistant", content: ctx.greeting },
  ]);
  const [input, setInput] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [lastPath, setLastPath] = useState(pathname);
  const [insightIndex, setInsightIndex] = useState(0);
  const bottomRef = useRef<HTMLDivElement>(null);
  const timersRef = useRef<NodeJS.Timeout[]>([]);

  // Clear timers on unmount or page change
  const clearTimers = () => {
    timersRef.current.forEach(t => clearTimeout(t));
    timersRef.current = [];
  };

  // Schedule proactive insights for current page
  useEffect(() => {
    clearTimers();
    setInsightIndex(0);

    const insights = proactiveInsights[pathname] || [];
    insights.forEach((insight, idx) => {
      const timer = setTimeout(() => {
        setMessages(prev => [...prev, {
          role: "assistant",
          content: `${insight.type}\n\n${insight.message}`,
        }]);
        setIsOpen(true);
        setInsightIndex(idx + 1);
      }, insight.delay);
      timersRef.current.push(timer);
    });

    return () => clearTimers();
  }, [pathname]);

  // Auto-open when navigating to a new page
  useEffect(() => {
    if (pathname !== lastPath) {
      const newCtx = pageContext[pathname] || defaultContext;
      setMessages(prev => [...prev, { role: "assistant", content: `📍 You're now on **${newCtx.title}**. ${newCtx.greeting}` }]);
      setLastPath(pathname);
      setIsOpen(true);
    }
  }, [pathname, lastPath]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, insightIndex]);

  async function send(text?: string) {
    const msg = (text || input).trim();
    if (!msg || isLoading) return;

    const userMsg: Message = { role: "user", content: msg };
    const newMessages = [...messages, userMsg];
    setMessages(newMessages);
    setInput("");
    setIsLoading(true);

    try {
      const res = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          messages: newMessages.slice(-10).map(m => ({ role: m.role, content: m.content })),
        }),
      });

      if (!res.ok || !res.body) throw new Error("API error");

      const reader = res.body.getReader();
      const decoder = new TextDecoder();
      let assistantContent = "";
      setMessages(prev => [...prev, { role: "assistant", content: "" }]);

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        assistantContent += decoder.decode(value, { stream: true });
        setMessages(prev => {
          const updated = [...prev];
          updated[updated.length - 1] = { role: "assistant", content: assistantContent };
          return updated;
        });
      }
    } catch {
      setMessages(prev => [...prev, {
        role: "assistant",
        content: `I can help with that! Here are some things I'd suggest on the **${ctx.title}** page:\n\n${ctx.suggestions.map(s => `• ${s}`).join("\n")}\n\nOr ask me anything about construction — I have access to 56 tools across the entire platform.`,
      }]);
    }

    setIsLoading(false);
  }

  const renderContent = (content: string) => {
    // Handle markdown bold
    const parts = content.split(/(\*\*[^*]+\*\*|\[→[^\]]+\]\([^)]+\))/g);
    return parts.map((part, i) => {
      const linkMatch = part.match(/\[→\s*([^\]]+)\]\(([^)]+)\)/);
      if (linkMatch) {
        return (
          <a key={i} href={linkMatch[2]} style={{ display: "inline-block", marginTop: 6, padding: "6px 14px", borderRadius: 8, background: "linear-gradient(90deg, #F29E3D, #FCC757)", color: "#080E12", fontWeight: 800, fontSize: 10, textDecoration: "none" }}>
            → {linkMatch[1]}
          </a>
        );
      }
      const boldMatch = part.match(/\*\*([^*]+)\*\*/);
      if (boldMatch) {
        return <strong key={i} style={{ color: "#F29E3D" }}>{boldMatch[1]}</strong>;
      }
      return <span key={i}>{part}</span>;
    });
  };

  return (
    <>
      {/* Floating Button */}
      {!isOpen && (
        <button
          onClick={() => setIsOpen(true)}
          aria-label="Open AI assistant"
          style={{
            position: "fixed", bottom: 24, right: 24, zIndex: 1000,
            width: 60, height: 60, borderRadius: "50%",
            background: "linear-gradient(135deg, #F29E3D, #FCC757)",
            border: "none", cursor: "pointer",
            boxShadow: "0 4px 20px rgba(242,158,61,0.4)",
            display: "flex", alignItems: "center", justifyContent: "center",
            fontSize: 24, transition: "transform 0.2s",
          }}
          onMouseEnter={e => (e.currentTarget.style.transform = "scale(1.1)")}
          onMouseLeave={e => (e.currentTarget.style.transform = "scale(1)")}
        >
          👼
        </button>
      )}

      {/* Tooltip on hover */}
      {!isOpen && (
        <div style={{
          position: "fixed", bottom: 90, right: 24, zIndex: 999,
          background: "#0F1C24", border: "1px solid rgba(242,158,61,0.2)",
          borderRadius: 10, padding: "8px 12px", maxWidth: 200,
          pointerEvents: "none",
        }}>
          <div style={{ fontSize: 10, fontWeight: 800, color: "#F29E3D" }}>Angelic AI</div>
          <div style={{ fontSize: 9, color: "#9EBDC2" }}>Ask me anything about {ctx.title}</div>
        </div>
      )}

      {/* Chat Panel */}
      {isOpen && (
        <div style={{
          position: "fixed", bottom: 24, right: 24, zIndex: 1000,
          width: 400, height: 620, maxHeight: "85vh",
          borderRadius: 20, overflow: "hidden",
          display: "flex", flexDirection: "column",
          background: "#080E12",
          border: "1px solid rgba(242,158,61,0.2)",
          boxShadow: "0 8px 40px rgba(0,0,0,0.5)",
        }}>
          {/* Header */}
          <div style={{
            padding: "12px 16px", display: "flex", alignItems: "center", justifyContent: "space-between",
            background: "linear-gradient(135deg, rgba(242,158,61,0.1), rgba(74,196,204,0.05))",
            borderBottom: "1px solid rgba(51,84,94,0.2)",
          }}>
            <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
              <div style={{ width: 34, height: 34, borderRadius: "50%", background: "linear-gradient(135deg, #F29E3D, #FCC757)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16 }}>👼</div>
              <div>
                <div style={{ fontSize: 12, fontWeight: 900 }}>Angelic AI</div>
                <div style={{ fontSize: 8, color: "#69D294", display: "flex", alignItems: "center", gap: 4 }}>
                  <span style={{ width: 4, height: 4, borderRadius: "50%", background: "#69D294" }} />
                  {ctx.title} &bull; 56 tools
                </div>
              </div>
            </div>
            <button onClick={() => setIsOpen(false)} aria-label="Close AI assistant" style={{ background: "none", border: "none", color: "#9EBDC2", fontSize: 18, cursor: "pointer", padding: 4 }}>✕</button>
          </div>

          {/* Messages */}
          <div style={{ flex: 1, overflowY: "auto", padding: 12, display: "flex", flexDirection: "column", gap: 8 }}>
            {messages.map((m, i) => (
              <div key={i} style={{ display: "flex", justifyContent: m.role === "user" ? "flex-end" : "flex-start" }}>
                <div style={{
                  maxWidth: "85%", borderRadius: 14, padding: "10px 14px",
                  background: m.role === "user" ? "linear-gradient(135deg, #F29E3D, #FCC757)" : "#0F1C24",
                  color: m.role === "user" ? "#080E12" : "#F0F8F8",
                }}>
                  {m.role === "assistant" && <div style={{ fontSize: 8, fontWeight: 800, color: "#8A8FCC", marginBottom: 3 }}>Angelic</div>}
                  <div style={{ fontSize: 11, lineHeight: 1.6, whiteSpace: "pre-wrap" }}>
                    {renderContent(m.content)}
                    {isLoading && i === messages.length - 1 && m.role === "assistant" && <span style={{ opacity: 0.5 }}> ▊</span>}
                  </div>
                </div>
              </div>
            ))}
            <div ref={bottomRef} />

            {/* Page-specific suggestions */}
            {messages.length <= 2 && (
              <div style={{ marginTop: 4 }}>
                <div style={{ fontSize: 8, fontWeight: 800, color: "#9EBDC2", letterSpacing: 2, marginBottom: 6 }}>SUGGESTIONS FOR {ctx.title.toUpperCase()}</div>
                <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
                  {ctx.suggestions.map(s => (
                    <button key={s} onClick={() => send(s)} style={{
                      background: "#0F1C24", border: "1px solid rgba(51,84,94,0.2)", borderRadius: 8,
                      padding: "8px 10px", fontSize: 10, color: "#9EBDC2", cursor: "pointer", textAlign: "left",
                    }}>{s}</button>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Input */}
          <div style={{ padding: "10px 12px", borderTop: "1px solid rgba(51,84,94,0.2)", display: "flex", gap: 8, background: "#0A1218" }}>
            <label htmlFor="angelic-chat-input" style={{ position: "absolute", width: 1, height: 1, padding: 0, margin: -1, overflow: "hidden", clip: "rect(0,0,0,0)", whiteSpace: "nowrap", borderWidth: 0 }}>Message</label>
            <input
              id="angelic-chat-input"
              value={input}
              onChange={e => setInput(e.target.value)}
              onKeyDown={e => e.key === "Enter" && send()}
              placeholder={`Ask about ${ctx.title.toLowerCase()}...`}
              disabled={isLoading}
              style={{ flex: 1, background: "#162832", border: "1px solid rgba(51,84,94,0.3)", borderRadius: 10, padding: "10px 12px", color: "#F0F8F8", fontSize: 11, outline: "none" }}
            />
            <button
              onClick={() => send()}
              disabled={isLoading}
              aria-label="Send message"
              style={{
                background: isLoading ? "#33545E" : "linear-gradient(90deg, #F29E3D, #FCC757)",
                border: "none", borderRadius: 10, padding: "0 16px",
                fontWeight: 800, fontSize: 12, color: "#080E12", cursor: "pointer",
              }}
            >{isLoading ? "..." : "→"}</button>
          </div>
        </div>
      )}
    </>
  );
}
