-- PART 2: SEED DATA
-- Paste this into Supabase SQL Editor and click RUN (after Part 1)

insert into cs_trade_requirements (trade, requires_state_license, license_types, accepted_certifications, verify_with, states_covered, avg_processing_days) values
  ('Electrician', true, '{"Journeyman Electrician","Master Electrician"}', '{"OSHA 30","NFPA 70E"}', 'State Licensing Board', 50, 3),
  ('Plumber', true, '{"Journeyman Plumber","Master Plumber"}', '{"OSHA 30","Medical Gas"}', 'State Licensing Board', 48, 3),
  ('HVAC', true, '{"HVAC License","EPA 608 Universal"}', '{"NATE","R-410A"}', 'EPA / State Board', 45, 4),
  ('General Contractor', true, '{"General Contractor License","Building Contractor"}', '{"PMP","LEED AP"}', 'State Contractor Board', 50, 5),
  ('Crane Operator', true, '{"NCCCO Certification"}', '{"OSHA 30","Signal Person"}', 'NCCCO Database', 50, 2),
  ('Welder', true, '{"AWS D1.1 Certified","CWI"}', '{"OSHA 10","Structural Steel"}', 'AWS Certification', 50, 3),
  ('Roofing Contractor', true, '{"Roofing Contractor License"}', '{"NRCA Certified","OSHA 30"}', 'State Contractor Board', 42, 4),
  ('Structural Engineer', true, '{"PE License"}', '{"SE Exam","FE Exam"}', 'State PE Board', 50, 7),
  ('Architect', true, '{"Architecture License"}', '{"ARE","NCARB"}', 'State Architecture Board', 50, 7),
  ('Fire Protection', true, '{"Fire Protection License"}', '{"NICET Level III","OSHA 30"}', 'State Fire Marshal', 50, 4),
  ('Concrete', false, '{"ACI Certification"}', '{"ACI Grade 1","Flatwork Finisher"}', 'ACI Certification', 50, 2),
  ('Steel/Ironwork', false, '{"AWS Certification"}', '{"AISC","Rigging Cert"}', 'AWS / AISC', 50, 3),
  ('Solar Installer', true, '{"Solar Contractor License"}', '{"NABCEP PV","OSHA 10"}', 'State Contractor Board', 35, 4),
  ('Low Voltage', true, '{"Low Voltage License"}', '{"BICSI TECH","NICET"}', 'State Licensing Board', 40, 3),
  ('Demolition', true, '{"Demolition Contractor License"}', '{"OSHA 30","Lead/Asbestos"}', 'State Contractor Board', 38, 5)
on conflict (trade) do nothing;
