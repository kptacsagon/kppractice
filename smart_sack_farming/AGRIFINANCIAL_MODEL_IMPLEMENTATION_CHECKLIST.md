# AgriFinancial Model Module - Flutter Implementation Checklist

Version: 1.0
Date: 2026-04-24
Source PRD: AGRIFINANCIAL_MODEL_MODULE_PRD.md

## Purpose
This checklist converts the PRD into executable Flutter tasks mapped to the existing module code.

## Current Baseline (validated in code)
- 3-tab structure exists: Overview, Transactions, Reports.
- Built reports exist: Cash Flow, Credit Readiness, AIS Crop Viability.
- Supabase-backed service layer exists for transactions and report generation.

## File Map (Current Module Surfaces)
| Layer | File | Current role |
|---|---|---|
| Main module UI | lib/screens/features/agri_financial_model_screen.dart | Hosts Overview/Transactions/Reports tabs |
| Transaction form | lib/screens/features/financial_transaction_form_screen.dart | Create/update income and expense entries |
| Cash flow report UI | lib/screens/features/financial_cashflow_report_screen.dart | Range picker, chart, summary, sharing |
| Credit report UI | lib/screens/features/financial_credit_readiness_screen.dart | Score, summary, repayment capacity, sharing |
| AIS UI | lib/screens/features/ais_market_viability_screen.dart | Inputs + report rendering |
| AIS engine | lib/models/agri_financial_model.dart | PPI/IUR/net-profit logic + recommendations |
| Service layer | lib/services/agri_financial_service.dart | Supabase reads/writes, report computations |
| Transaction model | lib/models/financial_transaction.dart | Ledger schema and JSON conversion |
| Report models | lib/models/financial_reports.dart | Cash flow and credit report model contracts |
| Dashboard model | lib/models/financial_summary.dart | Overview summary contract |

## Priority Execution Matrix
Status legend:
- Done: already in module
- Next: ready to implement immediately
- Later: phase-scheduled

| ID | Priority | Requirement | Status | Primary files |
|---|---|---|---|---|
| P0-01 | P0 | Add income transaction (amount/date/category/notes) | Done | financial_transaction_form_screen.dart, agri_financial_service.dart |
| P0-02 | P0 | Add expense transaction | Done | financial_transaction_form_screen.dart, agri_financial_service.dart |
| P0-03 | P0 | Real-time dashboard balances and monthly totals | Done | agri_financial_model_screen.dart, agri_financial_service.dart |
| P0-04 | P0 | Transaction filtering (type/search/date) | Done | agri_financial_model_screen.dart, agri_financial_service.dart |
| P0-05 | P0 | Cash Flow report generation | Done | financial_cashflow_report_screen.dart, agri_financial_service.dart |
| P0-06 | P0 | Credit Readiness report generation | Done | financial_credit_readiness_screen.dart, agri_financial_service.dart |
| P0-07 | P0 | AIS Crop Viability analysis | Done | ais_market_viability_screen.dart, agri_financial_model.dart |
| P1-01 | P1 | Farm profile setup (crop, land area, barangay, season) | Next | new files + agri_financial_service.dart |
| P1-02 | P1 | Crop/season tagging in transactions | Next | financial_transaction.dart, financial_transaction_form_screen.dart |
| P1-03 | P1 | 3-6 month forecast report | Next | financial_reports.dart, new forecast screen, service |
| P1-04 | P1 | Break-even analyzer per crop | Next | new break-even model/screen/service methods |
| P1-05 | P1 | Scenario simulator (price shock) | Next | ais_market_viability_screen.dart + new simulator UI |
| P1-06 | P1 | Loan tracking module | Next | new model/screen/service methods |
| P2-01 | P2 | Weather risk alerts | Later | new integration service + alert UI |
| P2-02 | P2 | Offline transaction queue and sync | Later | local persistence layer + service sync adapter |
| P2-03 | P2 | Language toggle (EN/FIL/CEB) | Later | app localization files + strings migration |
| P2-04 | P2 | PDF export for all reports | Later | export service + report screen actions |

## Immediate Engineering Backlog (Next 2 Sprints)

### Sprint A - Data Contract Hardening
1. Use schema-backed `farm_item_id` tagging in `FinancialTransaction` and UI selectors.
2. Update transaction form to capture crop context via `farm_items` dropdown.
3. Extend `AgriFinancialService.getTransactions()` filtering for `farm_item_id`.
4. Update filters in `AgriFinancialModelScreen` with `farm_items` selector.
5. Add migration notes if future `season_id` tagging is required at transaction level.

Definition of done:
- User can create/edit transactions with farm item tags.
- Transaction filters include farm item.
- Existing untagged records still load without crash.

### Sprint B - Farm Profile + Credit Report Improvements
1. Create `farm_profile_model.dart` and `farm_profile_screen.dart`.
2. Add service methods: `getFarmProfile()` and `upsertFarmProfile()`.
3. Add profile completeness contribution into credit readiness score.
4. Show missing profile fields checklist in credit report UI.
5. Add route entry from AgriFinancial screen quick actions.

Definition of done:
- Profile can be created and edited.
- Credit Readiness report reflects profile completeness.
- Missing profile data appears as actionable checklist.

## Code-Level Task Breakdown by Existing File

### lib/screens/features/agri_financial_model_screen.dart
- Keep 3-tab structure as core shell (no regression).
- Add quick-link to farm profile setup.
- Add crop/season filter chips in Transactions tab.
- Add report usage event hooks (analytics).

### lib/screens/features/financial_transaction_form_screen.dart
- Add crop selector and season selector.
- Add input helper text for low-literacy clarity.
- Preserve existing type/category/date behavior.
- Validate amount and optional future constraints by category.

### lib/services/agri_financial_service.dart
- Add farm profile CRUD methods.
- Add forecast retrieval/generation method stubs for P1.
- Add break-even and scenario computation service endpoints.
- Standardize error mapping for UI-friendly messages.

### lib/models/agri_financial_model.dart
- Keep current AIS core formulas stable.
- Add scenario method variants for price drop and cost increase simulation.
- Add confidence indicator output field for recommendation reliability.

### lib/screens/features/ais_market_viability_screen.dart
- Add optional scenario panel (base, -10%, -20%, -30% price impact).
- Add explanation tooltips for PPI, IUR, Net Margin.
- Add export/share action once PDF service is ready.

### lib/screens/features/financial_credit_readiness_screen.dart
- Add missing-document checklist section.
- Add action cards: improve score next steps.
- Add copy/share + PDF action split.

### lib/screens/features/financial_cashflow_report_screen.dart
- Add forecast overlay line (when forecast available).
- Add alert band for predicted negative balance windows.
- Add export PDF action.

## API Alignment Checklist (Flutter client readiness)
- Auth: ensure token refresh and unauthorized state handling in all report calls.
- Transactions endpoint parity:
  - create/update support for `crop_id`, `season_id`, `notes`, `counterparty`.
- Reports endpoint parity:
  - cashflow accepts explicit range.
  - credit-readiness returns score + missing items + recommendations.
  - crop-viability returns PPI/IUR/net margin + 2 recommendations.
- Error envelope mapping:
  - map 400/401/403/422/500 to user-safe messages.

## Data and Migration Checklist
- Confirm columns exist in `financial_transactions`:
  - `crop_id`, `season_id`, `description`, `notes`, `counterparty`, `is_deleted`.
- Add/confirm table for farm profiles:
  - `user_id`, `barangay`, `land_area_ha`, `primary_crop`, `season_cycle`.
- Add report snapshots table fields for auditability:
  - `report_type`, `period_start`, `period_end`, `generated_at`, `share_token`.
- Add index recommendations:
  - `(user_id, transaction_date)`
  - `(user_id, type, transaction_date)`
  - `(user_id, crop_id, season_id)`

## Testing and QA Checklist
### Unit tests
- AIS engine math and recommendation normalization.
- Credit readiness scoring branches.
- Cashflow monthly aggregation and running balance.

### Widget tests
- Transaction form validation and save state.
- Report screens loading/error/empty/success states.
- Transactions tab filter behavior.

### Integration tests
- Add transaction -> dashboard updates.
- Generate each report with realistic seeded records.
- Share link creation for cashflow and credit reports.

### Manual UAT scenarios
- Low-connectivity simulation (intermittent network).
- Large ledger (1000+ transactions) performance check.
- Loan-readiness walkthrough for first-time farmer user.

## Delivery Gates
- Gate 1: No regression on P0 flows (all three tabs + three reports).
- Gate 2: P1 crop/season tagging + farm profile available.
- Gate 3: Forecast/scenario tools validated with benchmark datasets.
- Gate 4: Localization/offline/weather alerts verified in pilot barangays.

## Suggested Command Set for Dev Validation
```powershell
Set-Location -Path c:\Users\kingp\OneDrive\Documents\GitHub\kppractice\smart_sack_farming
flutter analyze
flutter test
flutter run -d chrome
```

## Notes
- Keep UX simple and readable for entry-level Android users.
- Preserve PHP-first formatting and color cues (income vs expense).
- Do not remove the Reports tab card structure; add capabilities inside each report surface.
