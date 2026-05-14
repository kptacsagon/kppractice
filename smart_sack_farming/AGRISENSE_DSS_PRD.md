# PRODUCT REQUIREMENTS DOCUMENT
# Smart Sack Farming
# AgriSense DSS
# Decision Support System Module
# Full Platform PRD — Standalone Module Specification

Document Version: v1.0 — Full Platform Scope
Status: Draft — For Stakeholder Review
Date: May 14, 2026
Product Module: AgriSense DSS (within Smart Sack Farming)
Module Owner: Product Team — AgriTech Division
Reviewers: CTO, DA-Region VII Liaison, UX Lead, Backend Lead, Agronomist Consultant
Related Docs: Smart Sack Farmer Dashboard PRD v2.1 | RSBSA Integration Spec

## Table of Contents
1. Executive Summary & Vision
2. What is AgriSense DSS?
3. Problem Statement & Gap Analysis
4. AgriSense DSS — Module Architecture
5. Sub-Module 1: Crop Saturation Intelligence (CSI)
6. Sub-Module 2: Planting Input & Advisory Engine (PIAE)
7. Sub-Module 3: Weather & Climate Risk Advisor (WCRA)
8. Sub-Module 4: Pest & Disease Early Warning (PDEW)
9. Sub-Module 5: Market Price Intelligence (MPI)
10. Sub-Module 6: Farm Financial Planner (FFP)
11. Sub-Module 7: Post-Harvest & Market Linkage (PHML)
12. Sub-Module 8: DA Program Access & Compliance Hub (DPAC)
13. Cross-Cutting Platform Requirements
14. Data Architecture & Integration
15. UX Architecture & Navigation
16. Phased Rollout Plan
17. Success Metrics & KPIs
18. Risks & Mitigation
19. Open Questions
20. Appendix: Glossary & Data Sources

## 1. Executive Summary & Vision
Philippine smallholder farmers — particularly the 2.4 million registered under RSBSA in Visayas and Mindanao — face a compounding set of decisions every cropping season: what to plant, how to manage inputs, what weather and pest risks to prepare for, where to sell, and how to finance it all. These decisions are currently made through fragmented channels: word-of-mouth, outdated DA flyers, inconsistent barangay technician visits, and personal experience that may not reflect rapidly shifting market conditions.

Smart Sack Farming's existing dashboard addresses submission tracking and basic market alerts. AgriSense DSS is the intelligence layer that transforms Smart Sack from a submission portal into a true end-to-end farm decision partner — one that gives every farmer access to the quality of advice previously reserved for large commercial farms with dedicated agronomists and market analysts.

Vision Statement
- AgriSense DSS empowers every Smart Sack-registered farmer to make data-driven planting, input, market, and financial decisions — reducing crop losses, increasing farm income, and preventing community-level market oversaturation — regardless of farm size, literacy level, or connectivity.

### 1.1 Strategic Objectives
Objective | Target Outcome | Timeline
---|---|---
Reduce regional crop oversaturation | Average municipal Saturation Risk Score drops below 75 for staple crops | Season 2 post-launch
Increase average net farm income | +15–20% per participating household vs. control group | 12 months post-launch
Reduce post-harvest crop losses | From ~20% avg (PHilMech baseline) to <12% | 18 months post-launch
Improve DA program reach | 50% of eligible farmers access at least 1 DA subsidy/program via AgriSense | 6 months post-launch
Pest & disease early intervention | 80% of farmers who receive a PDEW alert take action within 72 hours | 3 months post-launch

## 2. What is AgriSense DSS?
AgriSense DSS (Decision Support System) is a standalone module within the Smart Sack Farming platform. It is accessed from the main Farmer Dashboard as a dedicated section — separate from the planting intention submission flow — and is composed of eight tightly integrated sub-modules, each targeting a distinct decision domain in the farming lifecycle.

AgriSense DSS is not a replacement for the DA extension system or local agronomists. It is a force multiplier: it surfaces the right information at the right time so that when a DA technician does visit, the farmer arrives prepared; and when a technician cannot visit, the farmer is not left without guidance.

### 2.1 The Eight Sub-Modules at a Glance
01 Crop Saturation Intelligence (CSI)
02 Planting Input & Advisory Engine (PIAE)
03 Weather & Climate Risk Advisor (WCRA)
04 Pest & Disease Early Warning (PDEW)
05 Market Price Intelligence (MPI)
06 Farm Financial Planner (FFP)
07 Post-Harvest & Market Linkage (PHML)
08 DA Program Access & Compliance Hub (DPAC)

## 3. Problem Statement & Gap Analysis
Gap Domain | Current State | Farmer Impact | AgriSense Sub-Module
---|---|---|---
Crop supply planning | Binary text alerts only; no scores/maps | Farmers ignore generic warnings | CSI
Agronomic advice | DA technician visits irregular | Suboptimal variety selection | PIAE
Weather planning | Facebook/TV; no planting calendar | Premature planting | WCRA
Pest & disease | Awareness after visible spread | 15% yield loss | PDEW
Price discovery | Traders control price info | Below-market rates | MPI
Financial planning | No digital budget tool | Cash flow crises | FFP
Post-harvest management | No storage guidance | 20% post-harvest loss | PHML
DA program access | Programs announced via LGU | Eligible farmers miss subsidies | DPAC

## 4. AgriSense DSS — Module Architecture
### 4.1 Architectural Principles
- Farm-profile-first
- Offline-resilient
- Actionable over informational
- Integrated, not siloed
- DA-aligned
- Multilingual

### 4.2 Shared Data Layer (FIP)
FIP Field | Source | Used By
---|---|---
Farm location | RSBSA / Onboarding | CSI, WCRA, PDEW, DPAC
Farm area | RSBSA / Onboarding | PIAE, FFP, PHML
Soil type | BSWM / Onboarding quiz | PIAE, WCRA
Irrigation access | RSBSA / Onboarding | PIAE, WCRA, FFP
Crop history | Planting intention submissions | CSI, PIAE, PDEW, FFP
Preferred crops | Farmer-set preferences | PIAE, MPI
Market access | Onboarding / GPS | MPI, PHML
DA program enrollments | DPAC sync | FFP, DPAC
Financial profile | PhilGuarantee / farmer-input | FFP
Language preference | Account settings | All

## 5–12. Sub-Modules
Each sub-module includes functional requirements as captured in the 2026 PRD (CSI, PIAE, WCRA, PDEW, MPI, FFP, PHML, DPAC).

## 13. Cross-Cutting Platform Requirements
Includes notification framework, accessibility, offline mode, and privacy governance (see PRD v1.0 text).

## 14. Data Architecture & Integration
All data sources and update frequencies follow the PRD v1.0 specification.

## 15. UX Architecture & Navigation
AgriSense hub → Sub-module home → Detail/action → Confirm/submit flow.

## 16. Phased Rollout Plan
Phase 0–5 as defined in PRD v1.0.

## 17. Success Metrics & KPIs
KPIs per sub-module in PRD v1.0.

## 18. Risks & Mitigation
Risks and mitigations per PRD v1.0.

## 19. Open Questions
Open questions per PRD v1.0.

## 20. Appendix
Glossary and data sources per PRD v1.0.

## Color Coding

| Color  | Meaning  |
| ------ | -------- |
| Green  | Safe     |
| Yellow | Moderate |
| Orange | High     |
| Red    | Critical |

---

# 5.8 Weather & Climate Module

## Features

* rainfall forecasting
* typhoon alerts
* drought warnings
* El Niño monitoring
* climate advisories

---

# 5.9 Notification & Early Warning System

## Alert Types

* oversaturation alerts
* severe saturation warnings
* weather alerts
* price drop alerts
* harvest reminders
* recommendation updates

---

## Delivery Channels

* in-app notifications
* SMS
* push notifications
* email alerts

---

# 5.10 Reporting & Export Module

## Export Formats

* PDF
* Excel
* CSV

---

## Reports

* municipal crop reports
* barangay summaries
* saturation forecasts
* farmer participation reports
* commodity analytics

---

# 6. USER ROLES & PERMISSIONS

# Farmer

Can:

* register farms
* submit seasonal crops
* receive recommendations
* view alerts

Cannot:

* approve records
* access municipal analytics

---

# Barangay Agriculture Technician

Can:

* verify farmers
* validate submissions
* monitor barangay analytics
* generate barangay reports

---

# Municipal Agriculture Officer

Can:

* access municipal dashboards
* monitor forecasts
* approve records
* manage interventions

---

# Provincial Administrator

Can:

* monitor municipality analytics
* access regional production trends

---

# Super Administrator

Can:

* manage all users
* configure thresholds
* manage APIs
* audit system activity

---

# 7. PREDICTIVE ANALYTICS

## MVP Analytics

* statistical forecasting
* historical trend analysis
* saturation threshold monitoring
* supply-demand comparison

---

## Phase 3 AI Features

* ARIMA forecasting
* Random Forest prediction
* clustering analytics
* machine learning optimization

---

# 8. SYSTEM ARCHITECTURE

## Frontend

### Web

* Next.js
* TypeScript
* Tailwind CSS

### Mobile

* Flutter

---

## Backend

* Laravel API
* RESTful architecture
* modular services

---

## Database

* PostgreSQL
* PostGIS

---

## GIS

* Leaflet.js
* OpenStreetMap

---

## Analytics Engine

* Python
* Pandas
* Scikit-learn

---

# 9. SECURITY & PRIVACY

## Security Features

* JWT authentication
* RBAC permissions
* encrypted passwords
* audit logging
* secure APIs
* file upload validation

---

## Compliance

The platform must comply with:

* Philippine Data Privacy Act

---

# 10. NON-FUNCTIONAL REQUIREMENTS

| Requirement           | Target      |
| --------------------- | ----------- |
| Dashboard Load Time   | < 3 seconds |
| Concurrent Users      | 10,000+     |
| API Response Time     | < 1 second  |
| Uptime                | 99.5%       |
| Mobile Responsiveness | Required    |
| Backup Frequency      | Daily       |

---

# 11. UI/UX REQUIREMENTS

## Design Goals

* modern agriculture SaaS design
* clean analytics dashboards
* mobile-first usability
* highly readable interfaces
* modern cards and KPI sections
* responsive layouts

---

## UI Components

* KPI cards
* charts
* GIS heatmaps
* analytics panels
* forecast cards
* recommendation panels
* progress indicators

---

# 12. KEY DASHBOARDS

# Farmer Dashboard

Displays:

* submissions
* recommendations
* alerts
* market trends

---

# Barangay Dashboard

Displays:

* active farmers
* crop density
* saturation alerts
* heatmaps

---

# Municipal Dashboard

Displays:

* municipal forecasting
* commodity analytics
* oversupply trends
* barangay comparisons

---

# 13. SUCCESS METRICS

## Agricultural Metrics

* reduced oversupply incidents
* improved crop diversification
* reduced harvest congestion

---

## Farmer Metrics

* improved profitability
* improved planting decisions

---

## Government Metrics

* faster reporting
* improved intervention planning
* better agricultural visibility

---

# 14. MVP IMPLEMENTATION PHASES

# Phase 1 — Core MVP

* farmer profiling
* GIS farm registry
* crop submissions
* saturation forecasting
* dashboards
* notifications

---

# Phase 2 — Advanced Analytics

* historical analytics
* advanced GIS
* weather integration
* market intelligence

---

# Phase 3 — AI & Smart Forecasting

* machine learning forecasting
* satellite integrations
* predictive optimization
* intelligent automation

---

# 15. FINAL PRODUCT VISION

AgriSense DSS aims to become a:

* Smart Municipal Agriculture Intelligence Platform
* Government-grade Crop Programming System
* Predictive Oversaturation Prevention Platform
* Agricultural Planning & Food Security Solution

capable of supporting:

* farmers
* barangays
* municipalities
* provinces
* national agricultural agencies

through scalable, intelligent, data-driven agricultural forecasting and decision support.