# ED Price Transparency Tool — Hillsborough County, FL
### GLHLTH 562: Data Science and Visualization with R
### Final Project Proposal

---

## What We Are Building

This project is an interactive emergency department (ED) price transparency tool designed for uninsured, underinsured, and cost-conscious patients in Hillsborough County, Florida. The tool allows a user to type a symptom — such as "chest pain" or "broken arm" — and instantly see a ranked comparison of cash prices, gross charges, and negotiated rate ranges across all seven major emergency departments in the county, including Tampa General Hospital, St. Joseph's Hospital, AdventHealth Tampa, HCA Florida Brandon, HCA Florida South Tampa, HCA Florida West Tampa, and South Florida Baptist Hospital. Because patients do not know billing codes, a generative AI model (Anthropic Claude) bridges the gap between plain-language symptoms and the standardized CPT, HCPCS, and MS-DRG codes that hospitals use to report prices — making government-mandated price transparency data actually usable for the first time.

---

## Capabilities Targeted

This product combines all three additional capabilities on top of the required user input:

**API integration** — the pipeline programmatically fetches each hospital's machine-readable file (MRF) directly from their publicly posted URLs at runtime, rather than using a static CSV downloaded by hand. The Anthropic Claude API is also called at query time to map user symptoms to billing codes. Both data sources are accessed programmatically with no manual steps.

**Generative AI in the pipeline** — Claude performs real clinical classification work as a functional component of the pipeline. When a user types a free-text symptom, a structured prompt is sent to the Claude API, which returns the most likely CPT/HCPCS codes and MS-DRG for that ED presentation as a JSON object. This is not a cosmetic use of AI — without it, the app cannot connect a patient's words to the pricing database.

**Automation** — a GitHub Actions workflow runs every Monday at 6:00 AM UTC, executing the `R/fetch_mrf_data.R` pipeline script. This script re-downloads all seven hospital MRF files, filters them to ED-relevant billing codes, and commits the updated `data/hillsborough_ed_prices.json` back to the repository. The Shiny app always reads from this refreshed file, so prices stay current without any manual intervention.

---

## Data Sources

**CMS Hospital Price Transparency Machine-Readable Files (MRFs)**
Since January 1, 2021, all U.S. hospitals have been required under 45 CFR Part 180 to publicly post a machine-readable file containing their standard charges for every item and service. As of July 1, 2024, all files must conform to a standardized CMS template (CSV or JSON format) and must be discoverable via a `.txt` file placed at the hospital's domain root. Each hospital's MRF contains five price types for every billing code: gross charge, discounted cash price, payer-specific negotiated charge, de-identified minimum negotiated charge, and de-identified maximum negotiated charge. These files are fetched programmatically by the pipeline script using each hospital's publicly posted MRF URL — no authentication or account is required, as CMS regulations explicitly prohibit hospitals from placing barriers to automated access.

**Anthropic Claude API**
The Claude API (`claude-sonnet-4-20250514`) is called at query time via the `/v1/messages` endpoint. It receives a structured prompt containing the user's symptom description and returns a JSON object with the most likely CPT/HCPCS codes, MS-DRG, and a plain-language description of the typical ED workup. The API key is stored as an environment variable (`ANTHROPIC_API_KEY`) and never committed to the repository.

---

## Technical Plan

### Key packages

| Package | Role |
|---------|------|
| `shiny` | Core web application framework — UI, server, reactivity |
| `bslib` | Bootstrap 5 theming — `page_navbar()`, `card()`, `value_box()` |
| `httr2` | HTTP client — fetches MRF files and calls the Claude API |
| `jsonlite` | JSON parsing — reads Claude API responses and MRF JSON files |
| `readr` | Fast CSV reading — processes large MRF CSV files in chunks |
| `dplyr` | Data manipulation — filtering, sorting, joining hospital data |
| `ggplot2` | Static chart construction — bar charts passed to Plotly |
| `plotly` | Interactive charts — `ggplotly()` and native `plot_ly()` |
| `reactable` | Interactive heatmap table with per-cell dynamic color styling |
| `stringr` | String manipulation — symptom matching, code normalisation |
| `glue` | String interpolation — building API prompts and status messages |
| `logger` | Structured logging for the automated pipeline script |
| `purrr` | `safely()` for fault-tolerant hospital iteration in the pipeline |

### Pipeline sketch

```
User types symptom
        │
        ▼
find_match() — fuzzy keyword match against known conditions
        │
        ├─── Match found ──────────────────────────────────────────────────┐
        │                                                                  │
        └─── No match → Claude API (/v1/messages)                         │
                         │                                                 │
                         ▼                                                 ▼
                  Returns CPT/HCPCS/DRG           Look up codes in
                  codes as JSON                   hillsborough_ed_prices.json
                         │                                                 │
                         └─────────────────────────────────────────────────┘
                                                  │
                                                  ▼
                                    Render results in Shiny UI:
                                    • Metric cards (lowest/highest/savings)
                                    • Sortable hospital cards with prices
                                    • Interactive bar chart (Compare tab)
                                    • Stacked cost breakdown chart
                                    • Heatmap across all conditions

─────────────────────────────────────────────────────────
Automated weekly refresh (GitHub Actions — every Monday)
─────────────────────────────────────────────────────────

For each hospital:
  1. Fetch https://www.{domain}/cdm.txt
  2. Parse MachineReadableURL field
  3. Stream download MRF file (CSV or JSON, up to 2 GB)
  4. Filter to ED-relevant CPT/HCPCS/DRG codes
  5. Extract: gross charge, cash price, min/max negotiated
  6. Write → data/hillsborough_ed_prices.json
  7. Commit updated file to GitHub repository
```

### Services and infrastructure

- **Shiny app** — runs locally via RStudio or deployed to shinyapps.io
- **GitHub Actions** — scheduled weekly workflow (`.github/workflows/mrf-refresh.yml`) runs `Rscript R/fetch_mrf_data.R` and commits updated price data
- **Anthropic Claude API** — `claude-sonnet-4-20250514` model, called at query time for unrecognized symptoms
- **CMS MRF public URLs** — no authentication required; hospitals are legally prohibited from blocking automated access

### Division of labor

This project was completed individually.

---

## Repository Structure

```
ed-price-transparency/
├── README.md                        ← This file
├── app.R                            ← Shiny application (UI + server)
├── install_packages.R               ← One-time package installation script
├── R/
│   ├── price_data.R                 ← Hospital registry and price data
│   ├── helpers.R                    ← Utility functions (matching, formatting)
│   └── fetch_mrf_data.R             ← Automated MRF download pipeline
├── data/
│   └── hillsborough_ed_prices.json  ← Processed price data (auto-refreshed weekly)
├── logs/                            ← Pipeline run logs (gitignored)
└── .github/
    └── workflows/
        └── mrf-refresh.yml          ← GitHub Actions weekly automation
```

---

*Built for GLHLTH 562: Data Science and Visualization with R — Duke University*
