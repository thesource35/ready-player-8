export type RentalProviderLink = {
  name: string;
  url: string;
  color: string;
  desc: string;
};

export type RentalItemLink = {
  name: string;
  cat: string;
  daily: string;
  weekly: string;
  provider: string;
  providerUrl: string;
  avail: string;
  specs: string;
};

export const githubRepoUrl = "https://github.com/thesource35/ready-player-8";

export const rentalProviders: RentalProviderLink[] = [
  { name: "United Rentals", url: "https://www.unitedrentals.com", color: "#F29E3D", desc: "Largest equipment rental company in the world" },
  { name: "Sunbelt Rentals", url: "https://www.sunbeltrentals.com", color: "#FCC757", desc: "Second largest — tools, power, and heavy equipment" },
  { name: "DOZR", url: "https://dozr.com", color: "#4AC4CC", desc: "Online marketplace — search, compare, and book" },
  { name: "BigRentz", url: "https://www.bigrentz.com", color: "#69D294", desc: "Equipment rental aggregator — 2,500+ locations" },
  { name: "Herc Rentals", url: "https://www.hercrentals.com", color: "#8A8FCC", desc: "Specialty equipment and industrial solutions" },
  { name: "BlueLine Rental", url: "https://www.unitedrentals.com", color: "#627EEB", desc: "Legacy BlueLine inventory now served through United Rentals" },
];

export const rentalItems: RentalItemLink[] = [
  { name: "CAT 320 Excavator", cat: "Heavy Equipment", daily: "$850", weekly: "$3,200", provider: "United Rentals", providerUrl: "https://www.unitedrentals.com/marketplace/equipment/earthmoving/excavators", avail: "Available", specs: "20-ton, 158 HP" },
  { name: "CAT D6 Dozer", cat: "Earthmoving", daily: "$1,200", weekly: "$4,500", provider: "United Rentals", providerUrl: "https://www.unitedrentals.com/marketplace/equipment/earthmoving/dozers", avail: "Available", specs: "215 HP, 6-way blade" },
  { name: "JLG 1932R Scissor Lift", cat: "Aerial Lifts", daily: "$120", weekly: "$380", provider: "United Rentals", providerUrl: "https://www.unitedrentals.com/marketplace/equipment/aerial-work-platforms/scissor-lifts", avail: "Available", specs: "19ft height" },
  { name: "Genie S-65 Boom Lift", cat: "Aerial Lifts", daily: "$350", weekly: "$1,200", provider: "Sunbelt Rentals", providerUrl: "https://www.sunbeltrentals.com/equipment-rental/aerial-work-platforms-scaffolding-and-ladders/", avail: "Available", specs: "65ft height" },
  { name: "Bosch Jackhammer", cat: "Hand Tools", daily: "$65", weekly: "$220", provider: "Sunbelt Rentals", providerUrl: "https://www.sunbeltrentals.com/equipment-rental/concrete-and-masonry/", avail: "Available", specs: "35 lb, 15 Amp" },
  { name: "Concrete Pump Trailer", cat: "Concrete", daily: "$800", weekly: "$3,000", provider: "BigRentz", providerUrl: "https://www.bigrentz.com/equipment-rentals/concrete", avail: "2-day lead", specs: "120ft boom" },
  { name: "Mini Excavator 3.5-Ton", cat: "Heavy Equipment", daily: "$295", weekly: "$1,100", provider: "DOZR", providerUrl: "https://dozr.com/rent/mini-excavators", avail: "Available", specs: "Kubota KX035" },
  { name: "BOMAG BW211D Roller", cat: "Compaction", daily: "$450", weekly: "$1,600", provider: "United Rentals", providerUrl: "https://www.unitedrentals.com/marketplace/equipment/compaction", avail: "Available", specs: "84in drum" },
  { name: "Liebherr LTM 1100 Crane", cat: "Cranes", daily: "$2,800", weekly: "$12,000", provider: "DOZR", providerUrl: "https://dozr.com/rent/cranes", avail: "1-week lead", specs: "100-ton" },
  { name: "Ford F-350 Flatbed", cat: "Vehicles", daily: "$180", weekly: "$650", provider: "United Rentals", providerUrl: "https://www.unitedrentals.com/marketplace/equipment/trucks-and-trailers", avail: "Available", specs: "Diesel, 12ft bed" },
  { name: "CAT XQ60 Generator", cat: "Generators", daily: "$180", weekly: "$650", provider: "Sunbelt Rentals", providerUrl: "https://www.sunbeltrentals.com/equipment-rental/generators-and-accessories/", avail: "Available", specs: "60 kW diesel" },
  { name: "NPK GH-2 Breaker", cat: "Demolition", daily: "$280", weekly: "$950", provider: "BigRentz", providerUrl: "https://www.bigrentz.com/equipment-rentals", avail: "Available", specs: "1,500 ft-lb" },
];

export const mapResources = [
  { name: "Walker Data MapGL", url: "https://walker-data.com/mapgl", desc: "MapGL basemaps and overlays" },
  { name: "Walker Data Freestiler", url: "https://walker-data.com/freestiler", desc: "Map styling and theming tools" },
];

export function getExternalLinkRegistry() {
  const urls = [
    githubRepoUrl,
    ...mapResources.map((resource) => resource.url),
    ...rentalProviders.map((provider) => provider.url),
    ...rentalItems.map((item) => item.providerUrl),
  ];
  return Array.from(new Set(urls));
}
