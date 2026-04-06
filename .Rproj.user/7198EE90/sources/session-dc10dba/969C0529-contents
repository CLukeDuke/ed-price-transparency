# Install all required packages for the ED Price Transparency Shiny app.
# Run this script once before launching the app.
# File: install_packages.R

packages <- c(
  "shiny",      # Core Shiny framework
  "bslib",      # Bootstrap 5 UI components (value_box, card, page_navbar)
  "dplyr",      # Data manipulation
  "ggplot2",    # Static charts
  "plotly",     # Interactive charts (wraps ggplot via ggplotly())
  "httr2",      # HTTP client for Claude API calls
  "jsonlite",   # JSON serialisation / deserialisation
  "scales",     # Number formatting (dollar, comma, label_dollar)
  "stringr",    # String manipulation
  "glue",       # String interpolation
  "reactable",  # Interactive sortable/filterable tables
  "readr",      # Fast CSV reading for MRF pipeline
  "purrr",      # Functional programming (map, safely, walk)
  "logger"      # Structured logging for fetch_mrf_data.R
)

install.packages(packages, repos = "https://cran.rstudio.com/")

cat("All packages installed. You can now run the app with:\n")
cat("  shiny::runApp('.')\n")
