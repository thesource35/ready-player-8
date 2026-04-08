import { describe, it, expect } from 'vitest'

// Wave 0 stubs — implementation lands in Plan 15-03
describe('TEAM-01: team member CRUD', () => {
  it.todo('POST /api/team creates a member with kind/name/role/trade')
  it.todo('POST /api/team rejects empty name')
})

describe('TEAM-02: project assignments', () => {
  it.todo('POST /api/team/assignments enforces unique active (project, member)')
})

describe('TEAM-03: certifications', () => {
  it.todo('POST /api/team/certifications accepts document_id FK')
})

describe('TEAM-05: daily crew', () => {
  it.todo('POST /api/projects/[id]/daily-crew enforces one row per (project, date)')
})
