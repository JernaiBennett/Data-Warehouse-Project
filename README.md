# Sales Data Warehouse

**Personal Project**  
Florida International University — 2025

---

## Overview

This project builds a modern data warehouse from scratch using SQL Server, implementing a full medallion architecture (Bronze → Silver → Gold) with ETL processes, data modeling, and analytics-ready views.

Two source systems are integrated and unified into a Star Schema for downstream reporting and analytics:

| Source | Tables | Description |
|---|---|---|
| CRM | `crm_cust_info`, `crm_prd_info`, `crm_sales_details` | Customer profiles, product catalog, and sales transactions |
| ERP | `erp_cust_az12`, `erp_loc_a101`, `erp_px_cat_g1v2` | Customer demographics, location data, and product categories |

---

## Data Architecture

The warehouse follows Medallion Architecture across three layers — Bronze for raw ingestion, Silver for cleansing and transformation, and Gold for business-ready Star Schema views consumed by BI tools, ad-hoc queries, and ML workflows.

![Data Architecture](docs/data_architecture.png)

### Layer Comparison

| | 🟫 Bronze | 🥈 Silver | 🥇 Gold |
|---|---|---|---|
| **Definition** | Raw, unprocessed data as-is from sources | Clean & standardized data | Business-ready data |
| **Objective** | Traceability & debugging | Prepare data for analysis | Reporting & analytics consumption |
| **Object Type** | Tables | Tables | Views |
| **Load Method** | Full Load (Truncate & Insert) | Full Load (Truncate & Insert) | None |
| **Transformations** | None (as-is) | Cleaning, standardization, normalization, derived columns, enrichment | Integration, aggregation, business logic & rules |
| **Data Modeling** | None (as-is) | None (as-is) | Star Schema, aggregated objects, flat tables |
| **Target Audience** | Data Engineers | Data Analysts, Data Engineers | Data Analysts, Business Users |

---

## Data Flow

End-to-end lineage from CRM and ERP source files through Bronze and Silver tables into Gold dimension and fact views.

![Data Flow](docs/data_flow.png)

---

## Data Integration

Shows how the six source tables relate to one another across CRM and ERP, and how they are joined to produce the Gold layer objects.

![Data Integration](docs/data_integration.png)

---

## Source Data

| File | Rows | Key Column | Notes |
|---|---|---|---|
| `cust_info.csv` | 18,494 | `cst_id` | 9 duplicate IDs; 4,578 blank gender values |
| `prd_info.csv` | 397 | `prd_id` | 77 duplicate `prd_key` entries (historical versions); 2 blank costs |
| `sales_details.csv` | 60,398 | `sls_ord_num` | Multi-line orders expected; 19 invalid order dates; 15 sales/price mismatches; 5 negative prices |
| `CUST_AZ12.csv` | 18,484 | `CID` | `NAS` prefix on all IDs; 1,476 blank gender values; 16 future birthdates |
| `LOC_A101.csv` | 18,484 | `CID` | Dashes in CID; inconsistent country codes (`US`/`USA`, `DE`); 337 blanks |
| `PX_CAT_G1V2.csv` | 37 | `ID` | Clean; 4 categories, 37 subcategories |

---

## Data Quality & Transformations

All issues identified in the Bronze layer are resolved during the Silver load. The table below documents every issue found and how it is handled.

### crm_cust_info (18,494 raw rows)

| Issue | Count | Resolution |
|---|---|---|
| Duplicate `cst_id` records | 9 IDs duplicated | `ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC)` — most recent record kept |
| Null `cst_id` rows | 4 | Filtered out with `WHERE cst_id IS NOT NULL` |
| Leading/trailing whitespace on names | Present | `TRIM()` applied to `cst_firstname` and `cst_lastname` |
| Marital status coded (`M`/`S`) | 7 blanks | `'M'` → `'Married'`, `'S'` → `'Single'`, else `'n/a'` |
| Gender coded (`M`/`F`) | 4,578 blanks | `'M'` → `'Male'`, `'F'` → `'Female'`, else `'n/a'` |

### crm_prd_info (397 raw rows)

| Issue | Count | Resolution |
|---|---|---|
| 77 `prd_key` values appear multiple times (historical versions) | 197 rows have a non-null `prd_end_dt` | Intentional — `prd_end_dt` derived via `LEAD()` window function; Gold layer filters `WHERE prd_end_dt IS NULL` for current records only |
| Null `prd_cost` | 2 | `ISNULL(prd_cost, 0)` |
| Product line coded (`M`/`R`/`S`/`T`) | 17 blanks | `'M'` → `'Mountain'`, `'R'` → `'Road'`, `'T'` → `'Touring'`, `'S'` → `'Other Sales'`, else `'n/a'` |
| Category ID and product key embedded in `prd_key` | All rows | Category ID extracted via `REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_')`; product key via `SUBSTRING(prd_key, 7, LEN(prd_key))` |
| `prd_start_dt` stored as `DATETIME` | All rows | Cast to `DATE` |

### crm_sales_details (60,398 raw rows)

| Issue | Count | Resolution |
|---|---|---|
| Order dates stored as integers (YYYYMMDD) | All rows | Validated with `LEN() = 8 AND value != 0`, then cast to `DATE`; 19 invalid → `NULL` |
| `sls_sales` missing or inconsistent with `qty × price` | 15 + 8 nulls | Recalculated as `sls_quantity × ABS(sls_price)` when null, zero, or mismatched |
| Negative `sls_price` values | 5 | `ABS(sls_price)` applied; price also derived from `sls_sales / NULLIF(sls_quantity, 0)` when invalid |

### erp_cust_az12 (18,484 raw rows)

| Issue | Count | Resolution |
|---|---|---|
| `NAS` prefix on all `CID` values | All rows | Stripped with `SUBSTRING(cid, 4, LEN(cid))` where `cid LIKE 'NAS%'` |
| Future birthdates | 16 | Set to `NULL` with `CASE WHEN bdate > GETDATE() THEN NULL` |
| Inconsistent gender codes (`M`/`Male`/`F`/`Female`) | 1,476 blanks; 9 mixed-format rows | Normalized: `'F'`/`'FEMALE'` → `'Female'`, `'M'`/`'MALE'` → `'Male'`, else `'n/a'` |

### erp_loc_a101 (18,484 raw rows)

| Issue | Count | Resolution |
|---|---|---|
| Dashes in `CID` (e.g. `AW-00011000`) | All rows | Removed with `REPLACE(cid, '-', '')` |
| Inconsistent country codes | `USA`/`US` (4,091 rows), `DE` (566 rows), 337 blanks | `'DE'` → `'Germany'`, `'US'`/`'USA'` → `'United States'`, blank/null → `'n/a'` |

### erp_px_cat_g1v2 (37 raw rows)

| Issue | Count | Resolution |
|---|---|---|
| No issues found | — | Pass-through load |

---

## Data Model (Star Schema)

The Gold layer is modeled as a Star Schema with one fact table and two dimension tables. Sales amount is derived as `quantity × price`.

![Data Model](docs/data_model.png)

### gold.dim_customers

| Column | Type | Description |
|---|---|---|
| customer_key | INT | Surrogate key (PK) |
| customer_id | INT | Source system customer ID |
| customer_number | NVARCHAR(50) | Alphanumeric customer reference |
| first_name | NVARCHAR(50) | Customer first name |
| last_name | NVARCHAR(50) | Customer last name |
| country | NVARCHAR(50) | Country of residence |
| marital_status | NVARCHAR(50) | `Married` or `Single` |
| gender | NVARCHAR(50) | `Male`, `Female`, or `n/a` |
| birthdate | DATE | Date of birth (YYYY-MM-DD) |
| create_date | DATE | Record creation date |

### gold.dim_products

| Column | Type | Description |
|---|---|---|
| product_key | INT | Surrogate key (PK) |
| product_id | INT | Source system product ID |
| product_number | NVARCHAR(50) | Structured alphanumeric product code |
| product_name | NVARCHAR(50) | Descriptive product name |
| category_id | NVARCHAR(50) | High-level category identifier |
| category | NVARCHAR(50) | Product category (e.g., Bikes, Components) |
| subcategory | NVARCHAR(50) | Product subcategory |
| maintenance_required | NVARCHAR(50) | `Yes` or `No` |
| cost | INT | Base product cost |
| product_line | NVARCHAR(50) | e.g., Road, Mountain, Touring |
| start_date | DATE | Date product became available |

### gold.fact_sales

| Column | Type | Description |
|---|---|---|
| order_number | NVARCHAR(50) | Unique sales order identifier (e.g., `SO54496`) |
| product_key | INT | FK → `gold.dim_products` |
| customer_key | INT | FK → `gold.dim_customers` |
| order_date | DATE | Date order was placed |
| shipping_date | DATE | Date order was shipped |
| due_date | DATE | Payment due date |
| sales_amount | INT | Total sale value (`quantity × price`) |
| quantity | INT | Units ordered |
| price | INT | Price per unit |

---

## ETL Overview

This diagram covers the full scope of ETL concepts applied in the project — extraction methods, transformation techniques (cleansing, normalization, derived columns, enrichment), load strategies, and slowly changing dimensions.

![ETL](docs/ETL.png)

### Stored Procedures

| Procedure | Layer | What it does |
|---|---|---|
| `bronze.load_bronze` | Source → Bronze | Truncates Bronze tables, bulk inserts from CSV files, logs duration per table |
| `silver.load_silver` | Bronze → Silver | Truncates Silver tables, applies all transformations, inserts cleansed data, logs duration per table |

---

## Repository Structure

```
.
├── datasets/                       # Source CSV files (not tracked)
│   ├── source_crm/
│   │   ├── cust_info.csv
│   │   ├── prd_info.csv
│   │   └── sales_details.csv
│   └── source_erp/
│       ├── cust_az12.csv
│       ├── loc_a101.csv
│       └── px_cat_g1v2.csv
├── docs/
│   ├── data_architecture.png       # Medallion architecture diagram
│   ├── data_architecture.drawio
│   ├── data_flow.png               # Data lineage diagram
│   ├── data_flow.drawio
│   ├── data_integration.png        # Source table relationship diagram
│   ├── data_integration.drawio
│   ├── data_model.png              # Star Schema ERD
│   ├── data_model.drawio
│   ├── ETL.png                     # ETL concepts mind map
│   ├── ETL.drawio
│   ├── data_layers.pdf             # Layer comparison reference
│   └── data_catalog.md             # Gold layer data catalog
├── scripts/
│   ├── init_database.sql           # Create DataWarehouse DB and schemas
│   ├── ddl_bronze.sql              # Bronze table definitions
│   ├── ddl_silver.sql              # Silver table definitions
│   ├── ddl_gold.sql                # Gold views (Star Schema)
│   ├── proc_load_bronze.sql        # Stored procedure: source → bronze
│   └── proc_load_silver.sql        # Stored procedure: bronze → silver
├── tests/                          # Query tests and validation scripts
├── LICENSE
└── README.md
```

---

## Setup

### Requirements

- SQL Server 2019+ (or SQL Server Express)
- SSMS or Azure Data Studio
- Source CSV files placed at `C:\sql\dwh_project\datasets\`

### Run Order

| Step | Script | Description |
|---|---|---|
| 1 | `init_database.sql` | Create `DataWarehouse` DB and `bronze` / `silver` / `gold` schemas |
| 2 | `ddl_bronze.sql` | Define Bronze tables |
| 3 | `ddl_silver.sql` | Define Silver tables |
| 4 | `ddl_gold.sql` | Create Gold views |
| 5 | `proc_load_bronze.sql` | Register Bronze load procedure |
| 6 | `proc_load_silver.sql` | Register Silver load procedure |

### Load Data

```sql
-- Load source CSVs into Bronze
EXEC bronze.load_bronze;

-- Transform and load Bronze into Silver
EXEC silver.load_silver;

-- Query Gold views directly
SELECT * FROM gold.fact_sales;
SELECT * FROM gold.dim_customers;
SELECT * FROM gold.dim_products;
```

> **Warning:** `init_database.sql` drops and recreates the entire `DataWarehouse` database. All existing data will be permanently deleted. Back up before running.

---

## Known Issues / Limitations

- **Hardcoded file paths:** `proc_load_bronze.sql` uses absolute paths (`C:\sql\dwh_project\datasets\`). Update these to match your local environment before running.
- **No incremental load:** All procedures use full truncate-and-reload. Incremental loading is not yet implemented.
- **CSV files not tracked:** Source datasets are excluded from version control. Place them in `datasets/source_crm/` and `datasets/source_erp/` before running the Bronze load.
- **Gold layer views only:** The Gold layer consists entirely of SQL views — no materialized tables. Query performance on large datasets may require indexing at the Silver layer.
