# AgriFinancial Model Module - Product Requirements Document

Version: 1.0
Date: 2026-04-24
Product: Smart Sack Farming - AgriFinancial Model
Status: Production-ready PRD for implementation and scale

## 1. Executive Summary
Smart Sack Farming's AgriFinancial Model gives Filipino farmers a practical, daily financial operating system built around three simple tabs: Overview, Transactions, and Reports. The module converts raw farm money movements into decisions farmers can immediately use: whether cash is enough for this month, whether financial records are credit-ready, and whether a crop is financially viable for the next planting cycle.

The product's value proposition is straightforward: remove guesswork from farm finance without requiring accounting literacy. Farmers can log income and expenses in minutes, view real-time cash health in Philippine Peso (PHP), and generate structured reports accepted by cooperatives, rural banks, and formal lenders. This directly addresses one of the biggest constraints in farm growth: lack of trustworthy, organized records.

At scale, this module is expected to increase financial resilience (fewer unmanaged cash gaps), improve loan readiness and approval rates, and improve crop planning outcomes through the AIS Crop Viability Analyzer. The long-term outcome is a measurable shift from intuition-only planning to data-driven farm decisions.

### Objectives and measurable targets
| Objective | Metric | 12-month Target | Owner |
|---|---|---:|---|
| Increase active financial management | % MAU generating >=1 report/month | >=65% | PM + Growth |
| Improve credit access | Loan approval delta vs non-users | +20% | Partnerships |
| Grow adoption | Registered farmer accounts | 25,000 | Growth + Field Ops |
| Improve planning accuracy | 3-month cashflow forecast within +/-15% | >=80% cases | Data + BE |
| Improve retention | Month-3 retention | >=60% | Product |

### Success criteria
- Users consistently complete the end-to-end flow: add transactions -> generate reports -> take action.
- Credit Readiness Reports are used as part of actual loan applications.
- AIS recommendations correlate with improved crop profitability decisions over time.

## 2. Problem Statement
### Current state in the Philippines
Most smallholder and semi-commercial farmers still track finances on paper notebooks, memory, chat messages, or informal lists. Records are often incomplete, delayed, or not category-structured. Seasonal spending spikes (seeds, fertilizer, labor, irrigation, fuel) are not matched with planned liquidity. Income timing from harvest sales is uncertain and heavily affected by market prices and weather disruptions.

### Pain points by real-world scenario
- Rice farmer in Nueva Ecija: Records fertilizer and labor inconsistently, cannot prove repayment capacity to LandBank, loan delayed before planting season.
- Corn farmer in Isabela: Has strong sales months but no net cash visibility because debt and input costs are untracked by period.
- Vegetable grower in Benguet: Rapid price swings make crop choice risky; no structured way to compare projected return vs required capital.

### Opportunity size and cost of poor records
- Opportunity: millions of farmers and agri-entrepreneurs with increasing smartphone adoption and growing digital ID/payment infrastructure.
- Cost of inaction:
  - Higher loan denials due to weak financial documentation.
  - Emergency borrowing at high informal rates during cash gaps.
  - Crop decisions with low margin or negative return because expected profitability was not modeled.
  - Increased financial fragility after typhoons or drought events.

## 3. Solution Overview
### End-to-end workflow (Overview -> Transactions -> Reports)
1. Farmer enters income and expense transactions using guided forms.
2. System continuously computes cash balance, monthly income, monthly expenses, and monthly net.
3. Reports transform records into decisions:
   - Cash Flow Report: period inflows, outflows, running cash balance.
   - Credit Readiness Report: data completeness and repayment capacity indicators.
   - AIS Crop Viability Analyzer: PPI, IUR, net profit margin, and two immediate action recommendations.

### Report definitions
#### A. Cash Flow Report
- Purpose: visibility into money timing, not just totals.
- Outputs:
  - Opening balance, inflows, outflows, net movement, ending balance.
  - Monthly and seasonal views.
  - Category breakdown (inputs, labor, transport, utilities, debt service, others).

#### B. Credit Readiness Report
- Purpose: make financial records lender-usable.
- Outputs:
  - Readiness score (0-100).
  - Data completeness index (required fields and minimum history met).
  - Repayment capacity estimate (cash surplus consistency + debt burden signals).
  - Missing requirements checklist (for immediate user action).

#### C. AIS Crop Viability Analyzer
- Purpose: decide if planting next cycle is financially viable.
- Core metrics:
  - PPI (Profitability Potential Index): revenue-to-cost signal.
  - IUR (Input Utilization Ratio): expected output efficiency per input spend.
  - Net Profit Margin: viability and risk-adjusted sustainability signal.
- Outputs:
  - Market condition label (favorable, watchlist, high risk).
  - High-risk illusion flag when gross outlook seems positive but net margin is weak.
  - Exactly two actionable recommendations.

### Technical approach and design decisions
- Mobile-first UX with low-friction forms and large touch targets.
- Color semantics: green for income/positive trend, red for expense/risk.
- Structured categories instead of free-form accounting only.
- Fast report generation from normalized transaction schema.
- Built-in support for low-connectivity behavior (sync queue in future phase).

### Core differentiators
- Credit readiness scoring focused on loan accessibility.
- AIS crop viability logic combining PPI, IUR, and margin safeguards.
- Simplicity-first flow usable by low digital literacy users.
- Philippine agricultural context and currency-first design.

## 4. User Personas
### Persona 1: Smallholder Rice/Corn Farmer
- Profile: 1-3 hectares, entry-level Android, intermittent signal, low digital confidence.
- Goals: know if monthly cash is enough, prepare for formal/informal borrowing, avoid unprofitable planting.
- Pain points: missing records, no monthly cash visibility, lender documentation gaps.
- Tab usage:
  - Overview: daily cash check.
  - Transactions: simple add income/expense after sale or purchase.
  - Reports: Credit Readiness before loan application; AIS before planting.

### Persona 2: Semi-Commercial Vegetable Farmer
- Profile: 3-10 hectares, multiple crops, moderate business skills, frequent market changes.
- Goals: compare crop economics, manage volatile inputs/prices, plan short-cycle planting.
- Pain points: profitability varies weekly, cash tied in inventory/labor, hard to compare crops.
- Tab usage:
  - Overview: weekly performance scan.
  - Transactions: higher volume logging with filters/search/date range.
  - Reports: heavy use of Cash Flow and AIS for crop decisions.

### Persona 3: Cooperative Member / Agri-Entrepreneur
- Profile: mixed income streams (farm + trading), cooperative financing pathways.
- Goals: separate and prove income streams, show repayment ability, track seasonal plans.
- Pain points: blended records reduce credibility, manual report prep consumes time.
- Tab usage:
  - Overview: consolidated status.
  - Transactions: categorization and notes for auditability.
  - Reports: Credit Readiness and Cash Flow for cooperative financing cycles.

### Device and connectivity constraints
- Primary device: entry-to-mid Android phones.
- Constraints: low RAM, unstable bandwidth, shared devices in households.
- Requirements: lightweight pages, tolerant retries, readable typography, minimal typing.

## 5. Technical Architecture
### Confirmed UI components
- Overview dashboard card: Current Cash Balance, Income (Month), Expenses (Month), Net (Month).
- Transaction actions: Add Income, Add Expense.
- Transactions tab: type filter, keyword search, date range selector.
- Reports tab: report cards for Cash Flow, Credit Readiness, AIS Crop Viability Analyzer.

### Suggested system stack (target architecture)
| Layer | Recommended Option A | Recommended Option B | Notes |
|---|---|---|---|
| Frontend | React PWA | Vue PWA | Mobile-first, installable web experience |
| Backend API | Node.js (Nest/Express) | Laravel (PHP) | REST + JWT + role-based access |
| Database | MySQL 8+ | MariaDB | Relational reporting queries |
| Caching | Redis | Redis | optional for report speed |
| Storage | S3-compatible | S3-compatible | PDF/report assets |

### Current implementation note
- Existing product implementation is in Flutter with Supabase-backed auth/data flows.
- This PRD architecture section defines a scalable reference backend model for future module expansion and partner integrations.

### High-level data flow
1. User authenticates (JWT/session).
2. User submits transaction.
3. Transaction service validates and stores normalized record.
4. Aggregation service updates monthly summaries.
5. Report service computes or retrieves report snapshots.
6. UI renders report card details and recommended actions.

### Integrations
- PAGASA/OpenWeatherMap: weather risk indicators.
- DA/PhilRice pricing bulletins: commodity reference prices.
- SMS gateway (Semaphore): low-bandwidth notifications.
- PDF generator: downloadable lender-ready reports.
- PCIC: crop insurance status/events.

## 6. Functional Requirements
### Priority definitions
- P0: available in current production module.
- P1: Phase 2 (Farm Intelligence).
- P2: Phase 3+ (Risk, connectivity, localization scale).

### User stories with acceptance criteria
| ID | Priority | User Story | Acceptance Criteria |
|---|---|---|---|
| US-01 | P0 | As a farmer, I can add income with amount/date/category/notes. | Required fields validate; success updates dashboard within 2s; transaction appears in list. |
| US-02 | P0 | As a farmer, I can add expense with amount/date/category/notes. | Same behavior as income; negative cash allowed but flagged in overview state. |
| US-03 | P0 | As a farmer, I can view monthly income, expenses, net, and balance. | Values match transaction ledger for selected month; currency shown in PHP. |
| US-04 | P0 | As a farmer, I can filter transactions by type/date/search. | Filter combinations return accurate subset; clear filter restores full list. |
| US-05 | P0 | As a farmer, I can generate Cash Flow Report for a period. | Report includes opening, inflow, outflow, net movement, ending balance. |
| US-06 | P0 | As a farmer, I can generate Credit Readiness Report. | Score shown 0-100, checklist of missing items, repayment capacity indicator displayed. |
| US-07 | P0 | As a farmer, I can run AIS Crop Viability analysis. | Inputs validate; output includes PPI, IUR, margin, condition, and exactly two recommendations. |
| US-08 | P1 | As a farmer, I can create a farm profile (crop/land/barangay/season). | Profile save required before advanced analytics; edits versioned by timestamp. |
| US-09 | P1 | As a farmer, I can tag transactions by crop and season. | Tag required for crop-level analytics; supports multi-season comparisons. |
| US-10 | P1 | As a farmer, I can view 3-6 month cash flow forecast. | Forecast confidence band shown; backtest accuracy tracked monthly. |
| US-11 | P1 | As a farmer, I can run break-even analysis per crop. | Break-even price and yield displayed with sensitivity controls. |
| US-12 | P1 | As a farmer, I can simulate price drop scenarios. | At least +/-10%, +/-20%, +/-30% scenarios available; impact on net shown. |
| US-13 | P2 | As a farmer, I can receive weather-triggered risk alerts. | Alerts tied to location and crop stage; stale alerts auto-expire. |
| US-14 | P2 | As a farmer, I can use offline entry and auto-sync later. | Transactions queued offline with conflict-safe sync and status badges. |
| US-15 | P2 | As a farmer, I can switch language to Filipino/Cebuano. | Core navigation and report labels localized with fallback to English. |

### Core user flows
#### Flow A: Add transaction
1. Tap Add Income or Add Expense.
2. Enter amount, date, category, optional notes.
3. Submit and receive success feedback.
4. Overview metrics and transaction list refresh.

#### Flow B: Generate Credit Readiness Report
1. Open Reports tab.
2. Tap Credit Readiness Report.
3. Select period (default last 90 days).
4. View score, repayment capacity, checklist, and action prompts.
5. Optional export to PDF.

#### Flow C: Run AIS Crop Viability Analysis
1. Open Reports tab.
2. Tap AIS Crop Viability Analyzer.
3. Provide expected yield, projected price, production cost, perishability/risk parameters.
4. Submit analysis.
5. Review PPI, IUR, net margin, condition flag, and two recommendations.

## 7. API Specifications
### Authentication
#### POST /auth/login
Request:
```json
{
  "email": "farmer@example.com",
  "password": "StrongPass123"
}
```
Response 200:
```json
{
  "token": "jwt-token",
  "refreshToken": "refresh-token",
  "user": {
    "id": "usr_123",
    "role": "farmer",
    "fullName": "Juan Dela Cruz"
  }
}
```

### Transactions
#### POST /transactions
Headers: `Authorization: Bearer <jwt>`
Request:
```json
{
  "type": "income",
  "amount": 12500.00,
  "currency": "PHP",
  "category": "harvest_sale",
  "transactionDate": "2026-04-24",
  "notes": "Palay sold to coop",
  "cropId": "crop_rice",
  "seasonId": "season_2026_dry"
}
```
Response 201:
```json
{
  "id": "txn_9f2d",
  "status": "created",
  "dashboardSnapshot": {
    "currentCashBalance": 48500.00,
    "incomeMonth": 32500.00,
    "expenseMonth": 12000.00,
    "netMonth": 20500.00
  }
}
```

### Reports
#### GET /reports/cashflow?from=2026-04-01&to=2026-04-30
Response 200:
```json
{
  "from": "2026-04-01",
  "to": "2026-04-30",
  "openingBalance": 28000.00,
  "totalInflow": 32500.00,
  "totalOutflow": 12000.00,
  "netMovement": 20500.00,
  "endingBalance": 48500.00,
  "dailySeries": []
}
```

#### GET /reports/credit-readiness?from=2026-01-01&to=2026-04-30
Response 200:
```json
{
  "score": 78,
  "completeness": 0.84,
  "repaymentCapacity": "moderate",
  "missingItems": [
    "Add at least 1 more month of expense records",
    "Attach crop-season tags for >=80% of entries"
  ],
  "recommendedActions": [
    "Record all debt repayments this month",
    "Generate PDF report before loan visit"
  ]
}
```

#### GET /reports/crop-viability?cropId=crop_rice&seasonId=season_2026_wet
Response 200:
```json
{
  "ppi": 1.32,
  "iur": 0.74,
  "netProfitMargin": 0.11,
  "marketCondition": "watchlist",
  "highRiskIllusion": false,
  "recommendations": [
    "Negotiate input costs before planting",
    "Set minimum selling price threshold"
  ]
}
```

### Error handling pattern
- 400: validation error with field details.
- 401: invalid/expired token.
- 403: role not permitted.
- 404: resource not found.
- 422: business rule failure (insufficient data for report).
- 500: unexpected server error.

Error envelope:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "amount must be greater than 0",
    "details": [
      { "field": "amount", "issue": "min_value" }
    ],
    "requestId": "req_abc123"
  }
}
```

## 8. Data Models
### Entity relationship summary
- users 1:N transactions
- users 1:N reports
- crops 1:N transactions
- seasons 1:N transactions
- users 1:N forecasts

### Core schema (MySQL-style)
| Table | Key fields | Types | Validation |
|---|---|---|---|
| users | id, full_name, email, phone, role, barangay, land_area_ha | UUID, VARCHAR, ENUM, DECIMAL | unique email, role in (farmer, admin) |
| transactions | id, user_id, type, amount, category, transaction_date, crop_id, season_id, notes | UUID, FK, ENUM, DECIMAL(12,2), DATE | amount > 0, type in (income, expense) |
| crops | id, user_id, crop_type, variety, perishability_score | UUID, FK, VARCHAR, TINYINT | perishability_score 1..5 |
| seasons | id, user_id, name, start_date, end_date | UUID, FK, VARCHAR, DATE | start_date < end_date |
| reports | id, user_id, report_type, from_date, to_date, payload_json, generated_at | UUID, FK, ENUM, DATE, JSON | report_type allowed list |
| forecasts | id, user_id, horizon_months, model_version, forecast_json, accuracy_score | UUID, FK, INT, VARCHAR, JSON, DECIMAL | horizon 3..6 |

### Calculation logic definitions
- Revenue = sum(income transactions in scope)
- Cost = sum(expense transactions in scope)
- Net Profit = Revenue - Cost
- Net Profit Margin = Net Profit / Revenue (if Revenue > 0)

Recommended AIS logic:
- PPI = Revenue / Cost
  - interpretation: >1 is profitable potential, <=1 is weak/negative potential.
- IUR = OutputValue / InputCostProxy
  - where OutputValue can be expected yield x expected market price.
- High-risk illusion flag = true when PPI > 1 but Net Profit Margin <= 0.08.

Validation rules:
- Required for AIS: expected yield, expected price, projected production cost.
- All monetary values in PHP and non-negative.
- Report period must have minimum transaction count for confidence thresholds.

## 9. Implementation Plan
### Phase roadmap
1. Phase 1 (Months 1-2): MVP Hardening
2. Phase 2 (Months 3-5): Farm Intelligence
3. Phase 3 (Months 6-8): Risk & Connectivity
4. Phase 4 (Months 9-12): Scale & Localization

### Sprint-by-sprint deliverables
| Sprint | Focus | Deliverables |
|---|---|---|
| S1 | Core quality hardening | Finalize income/expense forms, validation, and dashboard consistency checks |
| S2 | Reports stabilization | Cash Flow and Credit Readiness production logic; AIS output consistency tests |
| S3 | Reporting utility | PDF export for Credit Readiness, report audit metadata |
| S4 | Farm profile | Crop type, land area, barangay, season setup |
| S5 | Crop tagging | Transaction crop/season tags and filter UX |
| S6 | Forecasting v1 | 3-month forecast model + accuracy instrumentation |
| S7 | Break-even + scenarios | Break-even report and price-drop simulations |
| S8 | Loan tracking | Formal/informal loan records and repayment events |
| S9 | Weather risk integration | PAGASA/OpenWeatherMap ingestion and alert rules |
| S10 | Offline readiness | Sync queue, conflict strategy, offline transaction states |
| S11 | SMS + localization | Semaphore alerts and Filipino/Cebuano content |
| S12 | Scale and analytics | Usage dashboards, portfolio insights, release hardening |

### Team roles and responsibilities
- Product Manager: roadmap, KPI governance, partner alignment.
- Frontend Engineer: mobile UX, tab/report interactions, offline UX.
- Backend Engineers (2): API, report engines, integrations, security.
- QA Engineer: test plans, regression automation, release quality gates.
- UX Designer: low-literacy interaction design, localization-ready content.
- Data/Analytics (shared): forecasting validation and KPI instrumentation.

## 10. Success Metrics
### KPI framework
| KPI | Definition | Target | Data Source |
|---|---|---:|---|
| MAU | Unique active users in last 30 days | [X] | In-app analytics |
| Report generation rate | % active users generating >=1 report/month | >=65% | Event tracking |
| Credit report volume | Count of Credit Readiness reports/month | [X] | Report service logs |
| AIS run volume | Count of AIS analyses/month | [X] | Analyzer events |
| Loan approval improvement | Approved loan rate delta vs non-users | +[X]% | Partner lender/co-op data |
| Forecast accuracy | Forecasts within +/-15% error band | >=80% | Forecast backtesting |
| Month-3 retention | Users active in month 3 post-signup | >=60% | Cohort analytics |
| PDF exports | Credit/Cashflow/AIS export count | [X] | Export logs |

### Measurement implementation
- Instrument events: `transaction_created`, `report_generated`, `credit_readiness_viewed`, `ais_analysis_run`, `report_exported_pdf`.
- Build monthly KPI dashboard and quarterly cohort review.
- Pair app telemetry with partner cooperative/rural bank outcomes.
- Run quarterly user surveys on usability, trust, and decision impact.

## Appendix A - Non-functional Requirements
- Performance: report page render <2.5s on 4G average conditions.
- Availability: 99.5% monthly uptime target.
- Security: JWT, encrypted-at-rest sensitive fields, audit logs for report generation.
- Compliance: explicit consent for partner data-sharing; privacy-first defaults.
- Accessibility: high contrast, large touch targets, readable text sizes.

## Appendix B - Out-of-Scope for v1
- Full double-entry accounting.
- Direct lender underwriting decision automation.
- Autonomous commodity price trading recommendations.

## Appendix C - Delivery Notes for Engineering
- The existing module baseline must retain the three-tab structure: Overview, Transactions, Reports.
- The three confirmed report types are mandatory core surfaces in all releases.
- New features must not degrade low-literacy and low-connectivity usability constraints.
