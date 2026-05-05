# AgriFinancial Model - Claude Prompt (Copy-Ready)

Use the following prompt in Claude to regenerate or iterate the AgriFinancial Model PRD.

---

You are an expert product manager and technical architect. Transform this PRD scaffold into a comprehensive, production-ready Product Requirements Document.

---

## PROJECT SCAFFOLD

### AgriFinancial Model - PRD Scaffold
**Product Name:** Smart Sack Farming - AgriFinancial Model
**Version:** 1.0 Scaffold
**Context:** Farmer-facing financial modeling system for smallholder and semi-commercial farmers in the Philippines

### 1. EXECUTIVE SUMMARY
- Product: Mobile-friendly web app for farm income/expense tracking, financial reporting, and crop viability analysis
- Key Objectives:
  - Give farmers real-time visibility into their cash position (PHP balance, monthly income, expenses, net)
  - Automate generation of three core financial reports: Cash Flow, Credit Readiness, AIS Crop Viability
  - Enable data-driven credit access through a structured Credit Readiness score
  - Surface crop profitability insights via PPI, IUR, and net-profit decision matrix
- Current Build State (from UI):
  - Overview dashboard: Current Cash Balance, Income (Month), Expenses (Month), Net (Month)
  - Add Income / Add Expense transaction entry
  - Transactions tab: type filter, keyword search, date range selector
  - Reports tab: Cash Flow Report, Credit Readiness Report, AIS Crop Viability Analyzer
- Success Metrics:
  - [X]% of active users generating >= 1 report per month
  - [X]% improvement in loan approval rates for platform users
  - [X] registered farmers within 12 months
  - >= 80% cash flow forecast accuracy within 15% margin

### 2. PROBLEM STATEMENT
- Pain Points:
  - Filipino smallholder farmers rely on paper-based or informal bookkeeping
  - No real-time visibility into monthly cash position or seasonal cash gaps
  - Poor financial documentation = denied loans from LandBank, cooperatives, rural banks
  - Crop viability decisions made without financial data
  - Price volatility and weather events destroy unplanned budgets
- Opportunity:
  - Millions of smallholder farmers in the Philippines with zero digital financial tools
  - Rural banks and cooperatives need structured borrower financial records
  - PhilSys and growing mobile penetration create digital readiness
- Cost of Inaction: Loan denials, post-typhoon financial collapse, low-margin cropping decisions made on intuition

### 3. SOLUTION OVERVIEW
- Core Concept: A three-tab financial platform (Overview -> Transactions -> Reports) that transforms raw income/expense entries into actionable farm financial intelligence
- How It Works:
  - Farmer logs income and expenses via Add Income / Add Expense
  - System calculates real-time cash balance, monthly net, and running totals
  - Three auto-generated reports:
    - Cash Flow Report
    - Credit Readiness Report
    - AIS Crop Viability Analyzer
- Differentiators:
  - Farm-specific categories
  - Credit Readiness directly addresses loan access barrier
  - AIS Crop Viability with PPI/IUR is unique
  - Clean, color-coded UI
  - PHP currency and Philippine crop context
- Planned Enhancements:
  - Crop/season tagging
  - Seasonal forecasting
  - Weather alerts
  - Offline mode (PWA)
  - Cebuano/Filipino toggle

### 4. USER PERSONAS
- Persona 1: Smallholder Rice/Corn Farmer
- Persona 2: Semi-Commercial Vegetable Farmer
- Persona 3: Cooperative Member / Agri-Entrepreneur

### 5. TECHNICAL ARCHITECTURE
- Frontend: React or Vue.js PWA
- Backend: Node.js or Laravel REST API
- Database: MySQL (users, transactions, crops, seasons, reports, forecasts)
- Planned Integrations: PAGASA/OpenWeatherMap, DA/PhilRice bulletin, PCIC, Semaphore SMS, PDF export
- Auth: JWT with role-based access

### 6. FUNCTIONAL REQUIREMENTS
- Built: transaction entry, dashboard metrics, filters, and three reports
- To Build: farm profile, crop tagging, forecasting, break-even, scenario simulator, loan tracking, weather alerts, language toggle, PDF export, offline sync

### 7. IMPLEMENTATION PLAN
- Phase 1: MVP Hardening
- Phase 2: Farm Intelligence
- Phase 3: Risk & Connectivity
- Phase 4: Scale & Localization

### 8. SUCCESS METRICS
- MAU
- Credit Readiness reports generated
- AIS analyses run
- Loan approval uplift
- Forecast accuracy
- Retention and export activity

---

Expand this scaffold into a detailed PRD with these requirements:

1. EXECUTIVE SUMMARY
- Vision and value proposition (2-3 compelling paragraphs)
- Key objectives with specific, measurable metrics
- Expected impact and success criteria

2. PROBLEM STATEMENT
- Current state of agriculture financial management in the Philippines
- User pain points with real Filipino farming scenarios
- Opportunity size and financial cost of poor recordkeeping

3. SOLUTION OVERVIEW
- End-to-end flow (Overview -> Transactions -> Reports)
- Detailed explanation of Cash Flow, Credit Readiness, AIS Crop Viability (PPI, IUR, net-profit matrix)
- Technical approach and design decisions
- Core differentiators

4. USER PERSONAS
- 3 detailed personas with workflows and constraints

5. TECHNICAL ARCHITECTURE
- Components based on confirmed UI
- Suggested stack (React/Vue PWA, Laravel/Node, MySQL)
- Data flow from transaction entry to report generation
- Integrations: weather, price bulletin, SMS, PDF, PCIC

6. FUNCTIONAL REQUIREMENTS
- 10-15 detailed user stories with acceptance criteria
- Priority levels (P0, P1, P2)
- User flows: add transaction, generate credit report, run AIS analysis

7. API SPECIFICATIONS
- Endpoints: auth/login, POST /transactions, GET /reports/cashflow, GET /reports/credit-readiness, GET /reports/crop-viability
- Methods and JSON payloads
- JWT and error handling

8. DATA MODELS
- Schema for users, transactions, crops, seasons, reports, forecasts
- Fields, types, relationships, validations
- PPI and IUR logic

9. IMPLEMENTATION PLAN
- 4 phases with sprint-level deliverables
- Team roles and responsibilities

10. SUCCESS METRICS
- KPIs and measurement methods

Make it comprehensive enough for a development team to start building immediately, referencing the existing three-tab UI structure (Overview / Transactions / Reports) and the three confirmed report types throughout. Use clear markdown formatting with tables where helpful.

---

Optional context for Claude:
- The current implementation also has a Flutter-based module with these same core tabs and reports.
- Keep recommendations practical for low-connectivity rural usage.
