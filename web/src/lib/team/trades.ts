// D-02 canonical trade taxonomy. iOS mirror: ready player 8/TeamView.swift TRADES constant.
export const TRADES = [
  "Concrete",
  "Steel",
  "MEP",
  "Framing",
  "Finishes",
  "Electrical",
  "Plumbing",
  "HVAC",
  "Roofing",
  "Crane",
  "General",
] as const;
export type Trade = (typeof TRADES)[number];

export const CERT_NAMES = [
  "OSHA 10",
  "OSHA 30",
  "First Aid/CPR",
  "Forklift",
  "Crane Operator",
  "MEWP",
  "Welding",
] as const;
