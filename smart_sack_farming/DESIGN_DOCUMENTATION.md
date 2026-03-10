# Smart Sack Farming - System Design Documentation

## Table of Contents
1. [System Architecture](#1-system-architecture)
2. [Software Architecture](#2-software-architecture)
3. [Database Design (ERD)](#3-database-design-erd)
4. [Procedural Design (Flowcharts)](#4-procedural-design-flowcharts)
5. [Object-Oriented Design (UML)](#5-object-oriented-design-uml)
6. [Process Design (DFD)](#6-process-design-dfd)

---

## 1. System Architecture

### Description
The Smart Sack Farming system follows a three-tier client-server architecture with a Flutter mobile application as the presentation layer, Supabase as the Backend-as-a-Service (BaaS), and PostgreSQL as the database layer. The system integrates real-time data synchronization, user authentication, and cloud storage for farm images.

### Mermaid Code
```mermaid
flowchart TB
    subgraph ClientTier["Client Tier (Presentation Layer)"]
        MA[📱 Flutter Mobile App<br/>Android/iOS/Web]
        UI[User Interface<br/>Material Design 3]
        LC[Local Cache<br/>SharedPreferences]
    end
    
    subgraph MiddleTier["Middle Tier (Application Layer)"]
        subgraph SupabaseServices["Supabase Backend Services"]
            AUTH[🔐 Authentication<br/>Service]
            REALTIME[⚡ Realtime<br/>Subscriptions]
            STORAGE[📁 Storage<br/>Buckets]
            EDGE[Edge Functions<br/>Serverless]
        end
        
        subgraph SecurityLayer["Security Layer"]
            RLS[Row Level Security<br/>Policies]
            JWT[JWT Token<br/>Management]
        end
    end
    
    subgraph DataTier["Data Tier (Database Layer)"]
        PG[(PostgreSQL<br/>Database)]
        IMGSTORE[(farm-images<br/>Storage Bucket)]
    end
    
    subgraph ExternalServices["External Services"]
        WEATHER[🌤️ Weather API]
        MARKET[📊 Market Price API]
        NOTIF[🔔 Push Notifications]
    end
    
    MA --> UI
    UI --> LC
    MA <--> AUTH
    MA <--> REALTIME
    MA <--> STORAGE
    MA <--> EDGE
    
    AUTH --> JWT
    AUTH --> RLS
    REALTIME --> PG
    STORAGE --> IMGSTORE
    EDGE --> PG
    
    RLS --> PG
    JWT --> AUTH
    
    EDGE <-.-> WEATHER
    EDGE <-.-> MARKET
    AUTH <-.-> NOTIF
    
    classDef clientTier fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef middleTier fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef dataTier fill:#e8f5e9,stroke:#388e3c,stroke-width:2px
    classDef external fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    
    class MA,UI,LC clientTier
    class AUTH,REALTIME,STORAGE,EDGE,RLS,JWT middleTier
    class PG,IMGSTORE dataTier
    class WEATHER,MARKET,NOTIF external
```

---

## 2. Software Architecture

### Description
The application follows a layered architecture pattern with clear separation of concerns. The presentation layer uses Flutter widgets and screens, the business logic layer contains services and repositories implementing the Repository pattern, and the data layer handles database operations through Supabase client.

### Mermaid Code
```mermaid
flowchart TB
    subgraph PresentationLayer["Presentation Layer"]
        subgraph Screens["Screens"]
            AUTH_SCR[Auth Screens<br/>Login/Register]
            HOME_SCR[Home Screen<br/>Dashboard]
            SAT_SCR[Saturation<br/>Screens]
            FEAT_SCR[Feature Screens<br/>P&L, Rentals, Reports]
            ADMIN_SCR[Admin Screens<br/>Management]
        end 
        
        subgraph Widgets["UI Components"]
            THEME[AppTheme<br/>Material Design]
            FORMS[Form Widgets]
            CHARTS[Chart Components]
            CARDS[Info Cards]
        end
    end
    
    subgraph BusinessLayer["Business Logic Layer"]
        subgraph Services["Services"]
            REC_SVC[Recommendation<br/>Engine]
            FIN_SVC[Financial Forecast<br/>Service]
            PROFIT_SVC[Profit Analytics<br/>Service]
            SUPPLY_SVC[Supply Chain<br/>Service]
        end
        
        subgraph Repositories["Repositories"]
            FARM_REPO[Farming Project<br/>Repository]
            EQUIP_REPO[Equipment<br/>Repository]
            REPORT_REPO[Report<br/>Repository]
        end
    end
    
    subgraph DataLayer["Data Layer"]
        subgraph Models["Domain Models"]
            CROP_M[CropData Model]
            EXPENSE_M[Expense Model]
            EQUIP_M[Equipment Model]
            REPORT_M[Report Models]
            WEATHER_M[Weather Model]
            MARKET_M[Market Price Model]
            REC_M[Recommendation Model]
        end
        
        subgraph DataAccess["Data Access"]
            SUPA_SVC[Supabase Service<br/>Singleton]
            SUPA_CONFIG[Supabase Config]
        end
    end
    
    subgraph Infrastructure["Infrastructure Layer"]
        SUPA_CLIENT[Supabase Client]
        HTTP[HTTP Client]
        CACHE[Local Storage]
    end
    
    %% Connections
    AUTH_SCR --> SUPA_SVC
    HOME_SCR --> Services
    SAT_SCR --> CROP_M
    FEAT_SCR --> Repositories
    ADMIN_SCR --> Repositories
    
    Widgets --> Screens
    
    REC_SVC --> CROP_M
    REC_SVC --> MARKET_M
    FIN_SVC --> EXPENSE_M
    PROFIT_SVC --> FARM_REPO
    
    FARM_REPO --> SUPA_SVC
    EQUIP_REPO --> SUPA_SVC
    REPORT_REPO --> SUPA_SVC
    
    SUPA_SVC --> SUPA_CLIENT
    SUPA_CLIENT --> HTTP
    
    classDef presentation fill:#bbdefb,stroke:#1565c0,stroke-width:2px
    classDef business fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    classDef data fill:#ffe0b2,stroke:#ef6c00,stroke-width:2px
    classDef infra fill:#e1bee7,stroke:#7b1fa2,stroke-width:2px
    
    class AUTH_SCR,HOME_SCR,SAT_SCR,FEAT_SCR,ADMIN_SCR,THEME,FORMS,CHARTS,CARDS presentation
    class REC_SVC,FIN_SVC,PROFIT_SVC,SUPPLY_SVC,FARM_REPO,EQUIP_REPO,REPORT_REPO business
    class CROP_M,EXPENSE_M,EQUIP_M,REPORT_M,WEATHER_M,MARKET_M,REC_M,SUPA_SVC,SUPA_CONFIG data
    class SUPA_CLIENT,HTTP,CACHE infra
```

---

## 3. Database Design (ERD)

### Description
The database follows Third Normal Form (3NF) with proper foreign key relationships. The schema centers around the `profiles` table (extending Supabase Auth), with related entities for farming projects, expenses, equipment rentals, saturation records, and various report types. Row Level Security (RLS) policies enforce data access control.

### Mermaid Code
```mermaid
erDiagram
    AUTH_USERS ||--|| PROFILES : "extends"
    AUTH_USERS ||--o{ SATURATION_RECORDS : "owns"
    AUTH_USERS ||--o{ FARMING_PROJECTS : "owns"
    AUTH_USERS ||--o{ EQUIPMENT : "owns"
    AUTH_USERS ||--o{ RENTAL_REQUESTS : "requests"
    AUTH_USERS ||--o{ RENTAL_REQUESTS : "receives"
    AUTH_USERS ||--o{ CALAMITY_REPORTS : "reports"
    AUTH_USERS ||--o{ PRODUCTION_REPORTS : "submits"
    
    FARMING_PROJECTS ||--o{ EXPENSES : "has"
    FARMING_PROJECTS ||--o{ CALAMITY_REPORTS : "affected_by"
    EQUIPMENT ||--o{ RENTAL_REQUESTS : "requested_for"
    
    AUTH_USERS {
        uuid id PK
        varchar email
        jsonb raw_user_meta_data
        timestamp created_at
    }
    
    PROFILES {
        uuid id PK,FK
        varchar email
        varchar full_name
        varchar role "farmer|admin|mao"
        varchar phone
        text address
        text avatar_url
        timestamp created_at
        timestamp updated_at
    }
    
    SATURATION_RECORDS {
        uuid id PK
        uuid farmer_id FK
        varchar primary_crop
        text[] companion_crops
        decimal soil_moisture
        varchar saturation_level "low|medium|high"
        date planting_date
        date expected_harvest
        decimal field_size_ha
        text pesticides
        varchar fertilizer_type
        varchar irrigation_method
        varchar soil_type
        decimal expected_yield_kg
        text notes
        timestamp created_at
        timestamp updated_at
    }
    
    FARMING_PROJECTS {
        uuid id PK
        uuid farmer_id FK
        varchar crop_type
        decimal area_hectares
        date planting_date
        date harvest_date
        decimal revenue
        varchar status "active|completed|cancelled"
        decimal expected_yield_kg
        decimal actual_yield_kg
        decimal market_price_per_kg
        decimal expected_revenue
        decimal actual_sale_price_per_kg
        timestamp created_at
        timestamp updated_at
    }
    
    EXPENSES {
        uuid id PK
        uuid project_id FK
        uuid farmer_id FK
        varchar category
        text description
        decimal amount
        date expense_date
        varchar phase "planting|sowing|growing|harvest|post-harvest"
        timestamp created_at
        timestamp updated_at
    }
    
    EQUIPMENT {
        uuid id PK
        uuid owner_id FK
        varchar name
        text description
        varchar category "Tractor|Plow|Harvester|etc"
        decimal daily_rental_price
        int quantity
        varchar condition "New|Good|Fair|Poor"
        boolean is_available
        text image_url
        varchar owner_name
        varchar owner_phone
        timestamp created_at
        timestamp updated_at
    }
    
    RENTAL_REQUESTS {
        uuid id PK
        uuid equipment_id FK
        uuid requester_id FK
        uuid owner_id FK
        date start_date
        date end_date
        decimal total_cost
        varchar status "pending|approved|rejected|returned"
        text notes
        timestamp created_at
        timestamp updated_at
    }
    
    CALAMITY_REPORTS {
        uuid id PK
        uuid farmer_id FK
        uuid project_id FK
        varchar calamity_type
        varchar severity "LOW|MEDIUM|HIGH"
        date date_occurred
        decimal affected_area_acres
        text affected_crops
        varchar crop_stage
        text description
        decimal damage_estimate
        decimal estimated_financial_loss
        varchar farmer_name
        text image_url
        varchar status "reported|verified|resolved"
        timestamp created_at
        timestamp updated_at
    }
    
    PRODUCTION_REPORTS {
        uuid id PK
        uuid farmer_id FK
        varchar crop_type
        decimal area_hectares
        date planting_date
        date harvest_date
        decimal yield_kg
        int quality_rating "1-5"
        varchar quality_class "A|B|C"
        text notes
        timestamp created_at
        timestamp updated_at
    }
    
    MARKET_PRICES {
        uuid id PK
        varchar crop_type
        decimal price_per_kg
        date price_date
        varchar trend "rising|stable|falling"
        varchar source
        timestamp created_at
    }
```

---

## 4. Procedural Design (Flowcharts)

### 4.1 User Authentication Flow

```mermaid
flowchart TD
    START([Start]) --> CHECK_AUTH{User<br/>Authenticated?}
    
    CHECK_AUTH -->|No| SHOW_LOGIN[Display Login Screen]
    CHECK_AUTH -->|Yes| GO_HOME[Navigate to Home]
    
    SHOW_LOGIN --> USER_ACTION{User Action}
    
    USER_ACTION -->|Login| ENTER_CREDS[Enter Email & Password]
    USER_ACTION -->|Register| ENTER_REG[Enter Registration Details]
    
    ENTER_CREDS --> VALIDATE_LOGIN{Validate<br/>Credentials}
    VALIDATE_LOGIN -->|Invalid| SHOW_ERROR1[Show Error Message]
    SHOW_ERROR1 --> SHOW_LOGIN
    VALIDATE_LOGIN -->|Valid| CALL_AUTH[Call Supabase Auth]
    
    CALL_AUTH --> AUTH_RESULT{Authentication<br/>Result}
    AUTH_RESULT -->|Success| CREATE_SESSION[Create User Session]
    AUTH_RESULT -->|Failure| SHOW_ERROR2[Show Auth Error]
    SHOW_ERROR2 --> SHOW_LOGIN
    
    CREATE_SESSION --> CHECK_PROFILE{Profile<br/>Exists?}
    CHECK_PROFILE -->|No| CREATE_PROFILE[Create Profile via Trigger]
    CHECK_PROFILE -->|Yes| LOAD_PROFILE[Load User Profile]
    CREATE_PROFILE --> LOAD_PROFILE
    
    LOAD_PROFILE --> CHECK_ROLE{Check User Role}
    CHECK_ROLE -->|Farmer| GO_HOME
    CHECK_ROLE -->|Admin/MAO| GO_ADMIN[Navigate to Admin Dashboard]
    
    ENTER_REG --> VALIDATE_REG{Validate<br/>Registration}
    VALIDATE_REG -->|Invalid| SHOW_REG_ERROR[Show Validation Error]
    SHOW_REG_ERROR --> ENTER_REG
    VALIDATE_REG -->|Valid| CALL_SIGNUP[Call Supabase SignUp]
    
    CALL_SIGNUP --> SIGNUP_RESULT{SignUp Result}
    SIGNUP_RESULT -->|Success| SEND_VERIFY[Send Verification Email]
    SIGNUP_RESULT -->|Failure| SHOW_ERROR3[Show SignUp Error]
    SHOW_ERROR3 --> ENTER_REG
    
    SEND_VERIFY --> SHOW_CONFIRM[Show Confirmation Message]
    SHOW_CONFIRM --> SHOW_LOGIN
    
    GO_HOME --> END_AUTH([End])
    GO_ADMIN --> END_AUTH
```

### 4.2 Crop Recommendation Flow

```mermaid
flowchart TD
    START([Start]) --> INPUT[Farmer Inputs:<br/>Field Area, Planting Date, Budget]
    
    INPUT --> FETCH_DATA[Fetch Market Prices<br/>& Regional Saturation Data]
    
    FETCH_DATA --> INIT_SCORING[Initialize Scoring Engine]
    
    INIT_SCORING --> LOOP_START{More Crops<br/>to Evaluate?}
    
    LOOP_START -->|Yes| CALC_PROFIT[Calculate Profit Score<br/>P = crop_profit / max_profit]
    
    CALC_PROFIT --> CALC_CLIMATE[Calculate Climate Score<br/>Peak=1.0, Adjacent=0.6, Off=0.3]
    
    CALC_CLIMATE --> CALC_MARKET[Calculate Market Risk Score<br/>M = 1 - regional_saturation/100]
    
    CALC_MARKET --> CALC_SOIL[Calculate Soil Score<br/>S = 1 - abs_diff/100]
    
    CALC_SOIL --> CALC_DIV[Calculate Diversification Score<br/>D = 0.5 to 1.0]
    
    CALC_DIV --> COMPOSITE[Compute Composite Score<br/>Score = P×0.35 + C×0.20 + M×0.20 + S×0.15 + D×0.10]
    
    COMPOSITE --> CALC_RISK[Calculate Predictive Risk<br/>Risk = W×0.30 + MR×0.30 + CS×0.20 + F×0.20]
    
    CALC_RISK --> STORE_RESULT[Store Crop Recommendation]
    
    STORE_RESULT --> LOOP_START
    
    LOOP_START -->|No| SORT_RESULTS[Sort by Suitability Score<br/>Descending]
    
    SORT_RESULTS --> FILTER_BUDGET{Budget<br/>Filter?}
    
    FILTER_BUDGET -->|Yes| APPLY_FILTER[Filter Affordable Crops]
    FILTER_BUDGET -->|No| TAKE_TOP
    
    APPLY_FILTER --> TAKE_TOP[Take Top Recommendations]
    
    TAKE_TOP --> DISPLAY[Display Recommendations<br/>with Risk Analysis]
    
    DISPLAY --> END_REC([End])
```

### 4.3 Farming Project Lifecycle Flow

```mermaid
flowchart TD
    START([Start]) --> CREATE[Create New<br/>Farming Project]
    
    CREATE --> INPUT_DETAILS[Enter Project Details:<br/>Crop Type, Area, Dates]
    
    INPUT_DETAILS --> SAVE_PROJECT[Save Project<br/>Status: Active]
    
    SAVE_PROJECT --> PROJECT_ACTIVE{Project Status}
    
    PROJECT_ACTIVE --> ADD_EXPENSE{Add<br/>Expense?}
    
    ADD_EXPENSE -->|Yes| SELECT_PHASE[Select Phase:<br/>Planting/Sowing/Growing/Harvest]
    SELECT_PHASE --> ENTER_EXPENSE[Enter Expense Details]
    ENTER_EXPENSE --> SAVE_EXPENSE[Save Expense to Database]
    SAVE_EXPENSE --> UPDATE_TOTALS[Update Project Totals]
    UPDATE_TOTALS --> ADD_EXPENSE
    
    ADD_EXPENSE -->|No| CHECK_CALAMITY{Calamity<br/>Occurred?}
    
    CHECK_CALAMITY -->|Yes| REPORT_CALAMITY[Create Calamity Report]
    REPORT_CALAMITY --> ASSESS_DAMAGE[Assess Damage &<br/>Financial Loss]
    ASSESS_DAMAGE --> UPDATE_PROJECT[Update Project<br/>Expected Revenue]
    UPDATE_PROJECT --> CHECK_CONTINUE{Continue<br/>Project?}
    CHECK_CONTINUE -->|No| CANCEL_PROJECT[Set Status: Cancelled]
    CHECK_CONTINUE -->|Yes| ADD_EXPENSE
    
    CHECK_CALAMITY -->|No| CHECK_HARVEST{Harvest<br/>Ready?}
    
    CHECK_HARVEST -->|No| MONITOR[Monitor Project<br/>Track Progress]
    MONITOR --> ADD_EXPENSE
    
    CHECK_HARVEST -->|Yes| RECORD_YIELD[Record Actual Yield<br/>& Sale Price]
    
    RECORD_YIELD --> CALC_REVENUE[Calculate Final Revenue<br/>Yield × Sale Price]
    
    CALC_REVENUE --> CALC_PL[Calculate Profit/Loss<br/>Revenue - Total Expenses]
    
    CALC_PL --> COMPLETE[Set Status: Completed]
    
    COMPLETE --> GENERATE_REPORT[Generate Production Report]
    
    CANCEL_PROJECT --> END_PROJECT([End])
    GENERATE_REPORT --> END_PROJECT
```

### 4.4 Equipment Rental Flow

```mermaid
flowchart TD
    START([Start]) --> BROWSE[Browse Available<br/>Equipment]
    
    BROWSE --> FILTER_SEARCH[Filter by Category<br/>Search by Name]
    
    FILTER_SEARCH --> SELECT{Select<br/>Equipment?}
    
    SELECT -->|No| END_BROWSE([End])
    SELECT -->|Yes| VIEW_DETAILS[View Equipment Details]
    
    VIEW_DETAILS --> CHECK_AVAIL{Equipment<br/>Available?}
    
    CHECK_AVAIL -->|No| SHOW_UNAVAIL[Show Unavailable Message]
    SHOW_UNAVAIL --> BROWSE
    
    CHECK_AVAIL -->|Yes| SELECT_DATES[Select Rental Period<br/>Start & End Date]
    
    SELECT_DATES --> CALC_COST[Calculate Total Cost<br/>Days × Daily Rate]
    
    CALC_COST --> CONFIRM{Confirm<br/>Rental?}
    
    CONFIRM -->|No| BROWSE
    CONFIRM -->|Yes| CREATE_REQUEST[Create Rental Request<br/>Status: Pending]
    
    CREATE_REQUEST --> NOTIFY_OWNER[Notify Equipment Owner]
    
    NOTIFY_OWNER --> WAIT_RESPONSE[Await Owner Response]
    
    WAIT_RESPONSE --> OWNER_DECISION{Owner<br/>Decision}
    
    OWNER_DECISION -->|Approve| SET_APPROVED[Set Status: Approved]
    OWNER_DECISION -->|Reject| SET_REJECTED[Set Status: Rejected]
    
    SET_APPROVED --> NOTIFY_REQUESTER_A[Notify Requester<br/>Approved]
    SET_REJECTED --> NOTIFY_REQUESTER_R[Notify Requester<br/>Rejected]
    
    NOTIFY_REQUESTER_A --> USE_EQUIP[Use Equipment<br/>During Rental Period]
    
    USE_EQUIP --> RETURN_EQUIP[Return Equipment]
    
    RETURN_EQUIP --> SET_RETURNED[Set Status: Returned]
    
    SET_RETURNED --> END_RENTAL([End])
    NOTIFY_REQUESTER_R --> END_RENTAL
```

---

## 5. Object-Oriented Design (UML)

### 5.1 Use Case Diagram

```mermaid
flowchart TB
    subgraph Actors
        FARMER((👨‍🌾 Farmer))
        ADMIN((👨‍💼 Admin))
        MAO((🏛️ MAO Officer))
        SYSTEM((⚙️ System))
    end
    
    subgraph AuthModule["Authentication Module"]
        UC1[Register Account]
        UC2[Login]
        UC3[Manage Profile]
        UC4[Reset Password]
    end
    
    subgraph FarmingModule["Farming Management Module"]
        UC5[Create Farming Project]
        UC6[Track Expenses]
        UC7[Record Saturation Data]
        UC8[Generate P&L Report]
        UC9[Get Crop Recommendations]
        UC10[View Financial Forecast]
    end
    
    subgraph EquipmentModule["Equipment Rental Module"]
        UC11[List Equipment]
        UC12[Browse Equipment]
        UC13[Request Rental]
        UC14[Approve/Reject Rental]
        UC15[Return Equipment]
    end
    
    subgraph ReportingModule["Reporting Module"]
        UC16[Submit Calamity Report]
        UC17[Submit Production Report]
        UC18[View Market Prices]
        UC19[View Weather Data]
    end
    
    subgraph AdminModule["Administration Module"]
        UC20[Manage Users]
        UC21[Verify Reports]
        UC22[Update Market Prices]
        UC23[View Analytics Dashboard]
        UC24[Generate System Reports]
    end
    
    %% Farmer connections
    FARMER --> UC1
    FARMER --> UC2
    FARMER --> UC3
    FARMER --> UC5
    FARMER --> UC6
    FARMER --> UC7
    FARMER --> UC8
    FARMER --> UC9
    FARMER --> UC10
    FARMER --> UC11
    FARMER --> UC12
    FARMER --> UC13
    FARMER --> UC14
    FARMER --> UC15
    FARMER --> UC16
    FARMER --> UC17
    FARMER --> UC18
    FARMER --> UC19
    
    %% Admin connections
    ADMIN --> UC2
    ADMIN --> UC20
    ADMIN --> UC21
    ADMIN --> UC22
    ADMIN --> UC23
    ADMIN --> UC24
    
    %% MAO connections
    MAO --> UC2
    MAO --> UC21
    MAO --> UC23
    MAO --> UC24
    
    %% System connections
    SYSTEM --> UC4
    SYSTEM --> UC9
    SYSTEM --> UC10
```

### 5.2 Class Diagram

```mermaid
classDiagram
    class SupabaseService {
        -SupabaseClient client
        -static SupabaseService _instance
        +SupabaseClient get client
        +signUpWithEmail(email, password) AuthResponse
        +signInWithEmail(email, password) AuthResponse
        +signOut() void
        +currentUser User?
        +getRecords(table, filters) List~Map~
        +insertRecord(table, data) Map
        +updateRecord(table, id, data) void
        +deleteRecord(table, id) void
    }
    
    class FarmingProjectRepository {
        -SupabaseService _supabaseService
        -String _tableName
        -String _expensesTableName
        +getAllProjects(userId) List~FarmingProject~
        +getProjectById(projectId, userId) FarmingProject
        +createProject(project, userId) FarmingProject
        +updateProject(project, userId) void
        +deleteProject(projectId, userId) void
        +getExpensesForProject(projectId, userId) List~Expense~
        +addExpense(expense, projectId, userId) Expense
    }
    
    class EquipmentRepository {
        -SupabaseService _supabaseService
        +getAllEquipment() List~Equipment~
        +getEquipmentById(id) Equipment
        +createEquipment(equipment) Equipment
        +updateEquipment(equipment) void
        +deleteEquipment(id) void
        +getRentalRequests(userId) List~RentalRequest~
    }
    
    class ReportRepository {
        -SupabaseService _supabaseService
        +getCalamityReports(userId) List~CalamityReport~
        +createCalamityReport(report) CalamityReport
        +getProductionReports(userId) List~ProductionReport~
        +createProductionReport(report) ProductionReport
    }
    
    class RecommendationEngine {
        -SupabaseClient _client
        -Map _costPerHectare
        -Map _avgYieldPerHa
        +generateRecommendations(farmerId, fieldAreaHa, plantingDate, budgetLimit) List~CropRecommendation~
        -_calcProfitScore(profit, maxProfit) double
        -_calcClimateScore(crop, month) double
        -_calcMarketRiskScore(saturation) double
        -_calcSoilScore(crop, waterAvail) double
        -_compositeScore(...) double
        -_calcWeatherRisk(month, crop) double
        -_calcFinancialRisk(cost, budget) double
    }
    
    class FinancialForecastService {
        +generateForecast(projects) FinancialForecast
        +calculateROI(project) double
        +projectCashFlow(project, months) List~CashFlow~
    }
    
    class ProfitAnalyticsService {
        +analyzeProfitability(project) ProfitAnalysis
        +compareProjects(projects) ComparisonReport
        +getTrends(userId, period) List~Trend~
    }
    
    class FarmingProject {
        +String id
        +String cropType
        +double area
        +DateTime plantingDate
        +DateTime harvestDate
        +double revenue
        +List~Expense~ expenses
        +String status
        +double expectedYieldKg
        +double actualYieldKg
        +double marketPricePerKg
        +copyWith(...) FarmingProject
        +fromJson(json) FarmingProject
        +toJson() Map
        +totalExpenses() double
        +profitLoss() double
    }
    
    class Expense {
        +String id
        +String category
        +String description
        +double amount
        +DateTime date
        +String phase
        +copyWith(...) Expense
        +fromJson(json) Expense
        +toJson() Map
    }
    
    class Equipment {
        +String id
        +String name
        +String description
        +String category
        +double dailyRentalPrice
        +String ownerId
        +String ownerName
        +bool isAvailable
        +int quantity
        +String condition
        +copyWith(...) Equipment
        +fromJson(json) Equipment
        +toJson() Map
    }
    
    class CropData {
        +String name
        +String icon
        +String category
        +double idealMoistureMin
        +double idealMoistureMax
        +List~String~ bestPlantingMonths
        +String growthDuration
        +double heatSensitivity
        +double floodSensitivity
        +double droughtSensitivity
        +analyzeSaturation(waterAvail) SaturationLevel
        +getCompanionCrops(crop, waterAvail) List~CropData~
    }
    
    class CropRecommendation {
        +CropData crop
        +double suitabilityScore
        +double riskScore
        +double expectedProfit
        +String riskLevel
        +List~String~ reasons
    }
    
    %% Relationships
    FarmingProjectRepository --> SupabaseService : uses
    EquipmentRepository --> SupabaseService : uses
    ReportRepository --> SupabaseService : uses
    RecommendationEngine --> CropData : uses
    RecommendationEngine --> CropRecommendation : creates
    FarmingProject "1" --> "*" Expense : contains
    ProfitAnalyticsService --> FarmingProjectRepository : uses
    FinancialForecastService --> FarmingProject : analyzes
```

### 5.3 Activity Diagram - Create Farming Project

```mermaid
flowchart TD
    START((●)) --> INIT[Initialize Project Form]
    
    INIT --> FORK1{{"Fork"}}
    
    FORK1 --> ENTER_CROP[Enter Crop Type]
    FORK1 --> ENTER_AREA[Enter Field Area]
    FORK1 --> SELECT_DATES[Select Planting Date]
    
    ENTER_CROP --> JOIN1{{"Join"}}
    ENTER_AREA --> JOIN1
    SELECT_DATES --> JOIN1
    
    JOIN1 --> GET_REC[Fetch Crop<br/>Recommendations]
    
    GET_REC --> SHOW_REC[Display<br/>Recommendations]
    
    SHOW_REC --> ACCEPT_REC{Accept<br/>Recommendation?}
    
    ACCEPT_REC -->|Yes| APPLY_REC[Apply Recommended<br/>Parameters]
    ACCEPT_REC -->|No| MANUAL[Use Manual<br/>Settings]
    
    APPLY_REC --> CALC_EXPECTED[Calculate Expected<br/>Yield & Revenue]
    MANUAL --> CALC_EXPECTED
    
    CALC_EXPECTED --> VALIDATE{Validate<br/>Project Data}
    
    VALIDATE -->|Invalid| SHOW_ERROR[Show Validation<br/>Errors]
    SHOW_ERROR --> INIT
    
    VALIDATE -->|Valid| SAVE[Save Project<br/>to Database]
    
    SAVE --> CREATE_TRIGGER[Trigger Profile<br/>Update]
    
    CREATE_TRIGGER --> SHOW_SUCCESS[Show Success<br/>Message]
    
    SHOW_SUCCESS --> NAV_DETAIL[Navigate to<br/>Project Detail]
    
    NAV_DETAIL --> END_ACTIVITY((◉))
```

### 5.4 Sequence Diagram - Equipment Rental Process

```mermaid
sequenceDiagram
    autonumber
    participant F as Farmer
    participant UI as RentalsScreen
    participant ER as EquipmentRepository
    participant SS as SupabaseService
    participant DB as PostgreSQL
    participant O as Equipment Owner
    
    F->>UI: Browse Equipment
    UI->>ER: getAllEquipment()
    ER->>SS: getRecords("equipment")
    SS->>DB: SELECT * FROM equipment<br/>WHERE is_available = true
    DB-->>SS: Equipment List
    SS-->>ER: List<Map>
    ER-->>UI: List<Equipment>
    UI-->>F: Display Equipment Grid
    
    F->>UI: Select Equipment
    UI->>ER: getEquipmentById(id)
    ER->>SS: getRecords("equipment", {id})
    SS->>DB: SELECT * FROM equipment<br/>WHERE id = ?
    DB-->>SS: Equipment Details
    SS-->>ER: Map
    ER-->>UI: Equipment
    UI-->>F: Show Equipment Details
    
    F->>UI: Submit Rental Request
    UI->>UI: Calculate Total Cost
    UI->>ER: createRentalRequest(request)
    ER->>SS: insertRecord("rental_requests", data)
    SS->>DB: INSERT INTO rental_requests
    DB-->>SS: Created Request
    SS-->>ER: Map
    ER-->>UI: RentalRequest
    
    UI->>SS: Notify Owner (realtime)
    SS->>O: Push Notification
    
    O->>UI: View Rental Request
    O->>UI: Approve Request
    UI->>ER: updateRentalStatus(id, "approved")
    ER->>SS: updateRecord("rental_requests", id, {status})
    SS->>DB: UPDATE rental_requests<br/>SET status = 'approved'
    DB-->>SS: Success
    
    SS->>F: Notify Farmer (realtime)
    UI-->>F: Rental Approved
```

### 5.5 State Diagram - Farming Project States

```mermaid
stateDiagram-v2
    [*] --> Draft : Create Project
    
    Draft --> Active : Save Project
    Draft --> [*] : Cancel
    
    Active --> Active : Add Expense
    Active --> Active : Update Details
    Active --> Active : Record Saturation
    
    Active --> Affected : Calamity Reported
    
    Affected --> Active : Resume Project
    Affected --> Cancelled : Abandon Project
    
    Active --> Harvesting : Ready for Harvest
    
    Harvesting --> Completed : Record Yield\nCalculate P&L
    Harvesting --> Affected : Post-Harvest Damage
    
    Cancelled --> [*] : Archive
    
    Completed --> [*] : Generate Report
    
    state Active {
        [*] --> Planting
        Planting --> Sowing : Seeds Planted
        Sowing --> Growing : Crop Sprouted
        Growing --> PreHarvest : Crop Matured
        PreHarvest --> [*]
    }
    
    state Affected {
        [*] --> Assessing
        Assessing --> DamageRecorded : Submit Report
        DamageRecorded --> AwaitingVerification
        AwaitingVerification --> Verified : Admin Verifies
        AwaitingVerification --> Disputed : Farmer Disputes
        Verified --> [*]
        Disputed --> Assessing : Re-assess
    }
```

### 5.6 Deployment Diagram

```mermaid
flowchart TB
    subgraph ClientDevices["Client Devices"]
        subgraph Android["Android Device"]
            ANDROID_APP[📱 Smart Sack Farming<br/>Flutter APK]
        end
        
        subgraph iOS["iOS Device"]
            IOS_APP[📱 Smart Sack Farming<br/>Flutter IPA]
        end
        
        subgraph Web["Web Browser"]
            WEB_APP[🌐 Smart Sack Farming<br/>Flutter Web]
        end
    end
    
    subgraph SupabaseCloud["Supabase Cloud Infrastructure"]
        subgraph AuthNode["Auth Service Node"]
            AUTH_SVC[🔐 GoTrue Auth<br/>JWT + OAuth]
        end
        
        subgraph RealtimeNode["Realtime Service Node"]
            REALTIME_SVC[⚡ Phoenix Channels<br/>WebSocket Server]
        end
        
        subgraph StorageNode["Storage Service Node"]
            STORAGE_SVC[📁 Storage API<br/>S3-Compatible]
        end
        
        subgraph EdgeNode["Edge Functions Node"]
            EDGE_SVC[λ Deno Runtime<br/>Serverless Functions]
        end
        
        subgraph DatabaseNode["Database Cluster"]
            PG_PRIMARY[(PostgreSQL<br/>Primary)]
            PG_REPLICA[(PostgreSQL<br/>Replica)]
        end
        
        subgraph CDN["CDN Layer"]
            CDN_CACHE[🌍 Global CDN<br/>Static Assets]
        end
    end
    
    subgraph ExternalAPIs["External APIs"]
        WEATHER_API[🌤️ Weather API]
        MAPS_API[🗺️ Maps API]
        SMS_API[📨 SMS Gateway]
    end
    
    %% Connections
    ANDROID_APP <-->|HTTPS| AUTH_SVC
    IOS_APP <-->|HTTPS| AUTH_SVC
    WEB_APP <-->|HTTPS| AUTH_SVC
    
    ANDROID_APP <-->|WSS| REALTIME_SVC
    IOS_APP <-->|WSS| REALTIME_SVC
    WEB_APP <-->|WSS| REALTIME_SVC
    
    ANDROID_APP <-->|HTTPS| STORAGE_SVC
    IOS_APP <-->|HTTPS| STORAGE_SVC
    WEB_APP <-->|HTTPS| STORAGE_SVC
    
    AUTH_SVC --> PG_PRIMARY
    REALTIME_SVC <--> PG_PRIMARY
    EDGE_SVC --> PG_PRIMARY
    STORAGE_SVC --> CDN_CACHE
    
    PG_PRIMARY --> PG_REPLICA
    
    EDGE_SVC <-.-> WEATHER_API
    EDGE_SVC <-.-> MAPS_API
    AUTH_SVC <-.-> SMS_API
```

---

## 6. Process Design (DFD)

### 6.1 Context Diagram (Level 0)

```mermaid
flowchart LR
    FARMER((👨‍🌾 Farmer))
    ADMIN((👨‍💼 Admin/MAO))
    WEATHER[🌤️ Weather<br/>Service]
    MARKET[📊 Market<br/>Data Source]
    
    FARMER -->|Registration Data,<br/>Farm Data, Reports| SYSTEM
    SYSTEM -->|Recommendations,<br/>Forecasts, Alerts| FARMER
    
    ADMIN -->|Verification,<br/>Price Updates| SYSTEM
    SYSTEM -->|Analytics,<br/>Reports| ADMIN
    
    WEATHER -->|Weather Data| SYSTEM
    MARKET -->|Price Data| SYSTEM
    
    SYSTEM[Smart Sack<br/>Farming System]
```

### 6.2 Level 1 DFD

```mermaid
flowchart TB
    %% External Entities
    FARMER((👨‍🌾 Farmer))
    ADMIN((👨‍💼 Admin))
    WEATHER_EXT[🌤️ Weather API]
    MARKET_EXT[📊 Market API]
    
    %% Processes
    P1[["1.0<br/>User<br/>Management"]]
    P2[["2.0<br/>Farming Project<br/>Management"]]
    P3[["3.0<br/>Equipment<br/>Rental"]]
    P4[["4.0<br/>Recommendation<br/>Engine"]]
    P5[["5.0<br/>Report<br/>Generation"]]
    P6[["6.0<br/>Analytics &<br/>Forecasting"]]
    
    %% Data Stores
    D1[(D1: Profiles)]
    D2[(D2: Farming<br/>Projects)]
    D3[(D3: Expenses)]
    D4[(D4: Equipment)]
    D5[(D5: Rental<br/>Requests)]
    D6[(D6: Saturation<br/>Records)]
    D7[(D7: Market<br/>Prices)]
    D8[(D8: Reports)]
    
    %% Farmer flows
    FARMER -->|Registration Info| P1
    P1 -->|User Account| FARMER
    P1 <-->|Profile Data| D1
    
    FARMER -->|Project Details| P2
    P2 -->|Project Status| FARMER
    P2 <-->|Project Data| D2
    P2 <-->|Expense Data| D3
    
    FARMER -->|Rental Request| P3
    P3 -->|Rental Confirmation| FARMER
    P3 <-->|Equipment Data| D4
    P3 <-->|Request Data| D5
    
    FARMER -->|Farm Parameters| P4
    P4 -->|Crop Recommendations| FARMER
    P4 -->|Saturation Info| D6
    P4 -->|Price Info| D7
    
    FARMER -->|Report Data| P5
    P5 -->|Report Status| FARMER
    P5 <-->|Report Records| D8
    
    P6 -->|Forecasts & Analytics| FARMER
    
    %% Admin flows
    ADMIN -->|Verification| P5
    P5 -->|Pending Reports| ADMIN
    
    ADMIN -->|Price Updates| D7
    P6 -->|System Analytics| ADMIN
    
    %% External API flows
    WEATHER_EXT -->|Weather Data| P4
    MARKET_EXT -->|Market Prices| D7
    
    %% Internal process flows
    P2 -->|Project Data| P6
    D3 -->|Expense Data| P6
    D7 -->|Price Trends| P4
    D6 -->|Saturation Data| P4
    D8 -->|Historical Data| P6
```

### 6.3 Level 2 DFD - Farming Project Management (Process 2.0)

```mermaid
flowchart TB
    %% External Entity
    FARMER((👨‍🌾 Farmer))
    
    %% Processes
    P2_1[["2.1<br/>Create<br/>Project"]]
    P2_2[["2.2<br/>Manage<br/>Expenses"]]
    P2_3[["2.3<br/>Track<br/>Progress"]]
    P2_4[["2.4<br/>Record<br/>Harvest"]]
    P2_5[["2.5<br/>Calculate<br/>P&L"]]
    
    %% Data Stores
    D2[(D2: Farming<br/>Projects)]
    D3[(D3: Expenses)]
    D6[(D6: Saturation<br/>Records)]
    D7[(D7: Market<br/>Prices)]
    
    %% Flows from Farmer
    FARMER -->|Crop Type,<br/>Area, Dates| P2_1
    FARMER -->|Expense Details,<br/>Phase| P2_2
    FARMER -->|Progress Updates,<br/>Saturation Data| P2_3
    FARMER -->|Yield Data,<br/>Sale Price| P2_4
    
    %% Flows to Farmer
    P2_1 -->|Project Created| FARMER
    P2_2 -->|Expense Recorded| FARMER
    P2_3 -->|Progress Status| FARMER
    P2_5 -->|P&L Report| FARMER
    
    %% Internal flows
    P2_1 -->|New Project| D2
    P2_1 -->|Initial Saturation| D6
    D7 -->|Market Price| P2_1
    
    P2_2 -->|Expense Record| D3
    D2 -->|Project ID| P2_2
    
    P2_3 -->|Saturation Update| D6
    D2 -->|Project Status| P2_3
    P2_3 -->|Update Status| D2
    
    D2 -->|Project Data| P2_4
    P2_4 -->|Final Yield| D2
    
    D2 -->|Revenue, Yield| P2_5
    D3 -->|All Expenses| P2_5
    D7 -->|Current Prices| P2_5
```

### 6.4 Level 2 DFD - Recommendation Engine (Process 4.0)

```mermaid
flowchart TB
    %% External Entities
    FARMER((👨‍🌾 Farmer))
    WEATHER_EXT[🌤️ Weather API]
    
    %% Processes
    P4_1[["4.1<br/>Collect<br/>Parameters"]]
    P4_2[["4.2<br/>Analyze<br/>Climate Score"]]
    P4_3[["4.3<br/>Calculate<br/>Profit Score"]]
    P4_4[["4.4<br/>Assess<br/>Market Risk"]]
    P4_5[["4.5<br/>Compute<br/>Soil Score"]]
    P4_6[["4.6<br/>Calculate<br/>Composite Score"]]
    P4_7[["4.7<br/>Predict<br/>Risk Level"]]
    P4_8[["4.8<br/>Generate<br/>Recommendations"]]
    
    %% Data Stores
    D6[(D6: Saturation<br/>Records)]
    D7[(D7: Market<br/>Prices)]
    D9[(D9: Crop<br/>Database)]
    D10[(D10: Regional<br/>Data)]
    
    %% Input flows
    FARMER -->|Field Area,<br/>Planting Date,<br/>Budget| P4_1
    WEATHER_EXT -->|Weather Forecast,<br/>Rainfall Data| P4_2
    
    %% Process flows
    P4_1 -->|Parameters| P4_2
    P4_1 -->|Parameters| P4_3
    P4_1 -->|Parameters| P4_5
    
    D9 -->|Crop Info| P4_2
    D9 -->|Cost Data| P4_3
    D7 -->|Price Trends| P4_3
    D10 -->|Saturation %| P4_4
    D6 -->|Moisture Data| P4_5
    D9 -->|Ideal Ranges| P4_5
    
    P4_2 -->|Climate Score| P4_6
    P4_3 -->|Profit Score| P4_6
    P4_4 -->|Market Risk Score| P4_6
    P4_5 -->|Soil Score| P4_6
    
    P4_6 -->|Composite Score| P4_7
    P4_6 -->|Crop Scores| P4_8
    
    D9 -->|Sensitivity Data| P4_7
    P4_7 -->|Risk Level| P4_8
    
    P4_8 -->|Ranked<br/>Recommendations| FARMER
```

---

## How to Use in Draw.io

1. **Open Draw.io** (https://app.diagrams.net/)
2. **Create a new diagram** or open an existing one
3. Click **Arrange → Insert → Advanced → Mermaid**
4. **Paste the Mermaid code** from any section above
5. Click **Insert** to render the diagram
6. **Customize** colors, fonts, and layout as needed

### Alternative Method:
1. Go to **File → Import From → Text**
2. Select **Mermaid** format
3. Paste the code and click **Import**

---

## Document Information

| Item | Details |
|------|---------|
| **Project** | Smart Sack Farming |
| **Version** | 3.0 |
| **Date** | March 2026 |
| **Architecture** | Flutter + Supabase |
| **Database** | PostgreSQL (3NF) |
| **Pattern** | Repository + Service Layer |
