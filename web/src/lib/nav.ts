// Single source of truth for navigation structure.
// Used by layout.tsx, MobileNav.tsx, and AngelicAssistant.tsx.

export interface NavLink {
  href: string;
  label: string;
  icon?: string;
}

export interface NavGroup {
  label: string;
  color?: string;
  links: NavLink[];
}

export const navGroups: NavGroup[] = [
  { label: "CORE", color: "#F29E3D", links: [
    { href: "/projects", label: "Projects", icon: "🏗" },
    { href: "/contracts", label: "Contracts", icon: "📋" },
    { href: "/market", label: "Market", icon: "📊" },
    { href: "/maps", label: "Maps", icon: "🗺" },
    { href: "/feed", label: "Network", icon: "👥" },
    { href: "/jobs", label: "Jobs", icon: "💼" },
  ]},
  { label: "INTEL", color: "#4AC4CC", links: [
    { href: "/team", label: "Team", icon: "👥" },
    { href: "/ops", label: "Ops", icon: "⚙️" },
    { href: "/hub", label: "Hub", icon: "🔌" },
    { href: "/security", label: "Security", icon: "🔐" },
    { href: "/pricing", label: "Pricing", icon: "💲" },
    { href: "/ai", label: "Angelic AI", icon: "🏗" },
  ]},
  { label: "FIELD", color: "#69D294", links: [
    { href: "/field", label: "Field Ops", icon: "📱" },
    { href: "/finance", label: "Finance", icon: "💵" },
    { href: "/compliance", label: "Compliance", icon: "🛡" },
    { href: "/clients", label: "Clients", icon: "👤" },
    { href: "/analytics", label: "Analytics", icon: "📈" },
  ]},
  { label: "PLAN", color: "#8A8FCC", links: [
    { href: "/schedule", label: "Schedule", icon: "📅" },
    { href: "/training", label: "Training", icon: "🎓" },
    { href: "/scanner", label: "Scanner", icon: "📷" },
  ]},
  { label: "TRADE", color: "#FCC757", links: [
    { href: "/electrical", label: "Electrical", icon: "⚡" },
    { href: "/tax", label: "Tax", icon: "💰" },
  ]},
  { label: "BUILD", color: "#D94D48", links: [
    { href: "/punch", label: "Punch List", icon: "✅" },
    { href: "/roofing", label: "Roofing", icon: "🏠" },
    { href: "/smart-build", label: "Smart Build", icon: "🧠" },
    { href: "/contractors", label: "Directory", icon: "📒" },
    { href: "/tech", label: "Tech 2026", icon: "🔬" },
  ]},
  { label: "WEALTH", color: "#69D294", links: [
    { href: "/wealth", label: "Wealth", icon: "💎" },
    { href: "/cos-network", label: "COS Net", icon: "🌐" },
    { href: "/rentals", label: "Rentals", icon: "🚜" },
  ]},
  { label: "EMPIRE", color: "#F29E3D", links: [
    { href: "/empire", label: "Empire", icon: "👑" },
    { href: "/settings", label: "Settings", icon: "⚙️" },
  ]},
];
