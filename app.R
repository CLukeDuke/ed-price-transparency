# =============================================================================
# app.R
# ED Price Transparency Tool — Hillsborough County, FL
# GLHLTH 562 Final Project
# Features: ZIP filter, payer filter, OOP calculator, dot plot,
#           treemap, hospital map, treatment definitions
# =============================================================================

library(shiny)
library(bslib)
library(dplyr)
library(ggplot2)
library(plotly)
library(httr2)
library(jsonlite)
library(scales)
library(stringr)
library(glue)
library(reactable)
library(leaflet)

source("R/price_data.R")
source("R/helpers.R")
source("R/zip_data.R")
source("R/payer_data.R")
source("R/definitions.R")

# =============================================================================
# UI
# =============================================================================
ui <- page_navbar(
  tags$style(TOOLTIP_CSS),
  title = "ED Price Transparency — Hillsborough County, FL",
  theme = bs_theme(
    version    = 5,
    bootswatch = "flatly",
    primary    = "#1D9E75",
    font_scale = 0.95
  ),
  
  # ── Tab 1: Search ───────────────────────────────────────────────────────────
  nav_panel(
    title = "Search",
    icon  = icon("magnifying-glass"),
    layout_sidebar(
      sidebar = sidebar(
        width = 300,
        open  = TRUE,
        
        h5("Find ED prices by symptom", class = "mt-2 mb-3"),
        textInput(
          inputId     = "symptom_input",
          label       = "Describe your symptom",
          placeholder = "e.g. chest pain, broken arm..."
        ),
        actionButton(
          inputId = "search_btn",
          label   = "Search prices",
          class   = "btn-primary w-100 mb-3",
          icon    = icon("search")
        ),
        
        hr(),
        p("Common conditions:", class = "text-muted small mb-2"),
        div(
          class = "d-flex flex-wrap gap-1",
          actionButton("qs_chest",  "Chest pain",     class = "btn-outline-secondary btn-sm"),
          actionButton("qs_arm",    "Broken arm",     class = "btn-outline-secondary btn-sm"),
          actionButton("qs_head",   "Headache",       class = "btn-outline-secondary btn-sm"),
          actionButton("qs_ab",     "Abdominal pain", class = "btn-outline-secondary btn-sm"),
          actionButton("qs_breath", "SOB",            class = "btn-outline-secondary btn-sm"),
          actionButton("qs_lac",    "Laceration",     class = "btn-outline-secondary btn-sm"),
          actionButton("qs_kidney", "Kidney stone",   class = "btn-outline-secondary btn-sm")
        ),
        
        hr(),
        h6("Your location", class = "text-muted mb-1"),
        div(
          class = "d-flex gap-2 align-items-start",
          div(
            style = "flex:1",
            textInput(
              inputId     = "user_zip",
              label       = NULL,
              placeholder = "Enter ZIP code",
              width       = "100%"
            )
          ),
          div(
            style = "margin-top:1px",
            actionButton("zip_btn", "Go", class = "btn-outline-secondary btn-sm")
          )
        ),
        uiOutput("zip_status"),
        sliderInput(
          inputId = "max_distance",
          label   = "Max distance (miles)",
          min = 5, max = 35, value = 35, step = 5, width = "100%"
        ),
        
        hr(),
        h6("Your insurance", class = "text-muted mb-1"),
        selectInput(
          inputId  = "payer",
          label    = NULL,
          choices  = PAYERS,
          selected = "cash",
          width    = "100%"
        ),
        uiOutput("payer_status"),
        
        hr(),
        radioButtons(
          inputId  = "sort_by",
          label    = "Sort hospitals by",
          choices  = c(
            "Cash price (low to high)"   = "cash",
            "Gross charge (low to high)" = "gross",
            "Distance (near to far)"     = "distance"
          ),
          selected = "cash"
        ),
        
        hr(),
        uiOutput("status_text")
      ),
      
      uiOutput("results_panel")
    )
  ),
  
  # ── Tab 2: Map ──────────────────────────────────────────────────────────────
  nav_panel(
    title = "Map",
    icon  = icon("map"),
    card(
      card_header("Emergency departments — Hillsborough County, FL"),
      card_body(
        p("Click any hospital pin to see address and MRF link.",
          class = "text-muted small mb-2"),
        leafletOutput("hospital_map", height = "520px")
      )
    )
  ),
  
  # ── Tab 3: Compare ──────────────────────────────────────────────────────────
  nav_panel(
    title = "Compare",
    icon  = icon("chart-bar"),
    conditionalPanel(
      condition = "input.search_btn > 0",
      
      card(
        card_header("Price comparison — all hospitals"),
        card_body(
          div(
            class = "d-flex flex-wrap gap-3 align-items-end mb-3",
            div(
              radioButtons(
                inputId  = "chart_metric",
                label    = "Price type",
                choices  = c(
                  "Cash price"     = "cash",
                  "Gross charge"   = "gross",
                  "Min negotiated" = "min_neg",
                  "Max negotiated" = "max_neg"
                ),
                selected = "cash",
                inline   = TRUE
              )
            ),
            div(
              radioButtons(
                inputId  = "chart_type",
                label    = "Chart type",
                choices  = c("Bar chart" = "bar", "Dot plot" = "dot"),
                selected = "dot",
                inline   = TRUE
              )
            )
          ),
          plotlyOutput("price_chart", height = "400px")
        )
      ),
      
      card(
        card_header("Cost breakdown by service"),
        card_body(
          div(
            class = "d-flex flex-wrap gap-3 align-items-end mb-2",
            div(
              radioButtons(
                inputId  = "breakdown_type",
                label    = "Chart type",
                choices  = c("Stacked bars" = "stack", "Treemap" = "treemap"),
                selected = "treemap",
                inline   = TRUE
              )
            ),
            conditionalPanel(
              condition = "input.breakdown_type == 'treemap'",
              div(
                selectInput(
                  inputId  = "treemap_hosp",
                  label    = "Hospital",
                  choices  = setNames(HOSPITALS$id, HOSPITALS$name),
                  selected = "tgh",
                  width    = "220px"
                )
              )
            )
          ),
          uiOutput("breakdown_chart_ui")
        )
      )
    ),
    
    conditionalPanel(
      condition = "input.search_btn == 0",
      div(
        class = "text-center text-muted mt-5 pt-5",
        icon("magnifying-glass", style = "font-size:2rem"),
        h5("Search a symptom on the Search tab to see charts", class = "mt-3")
      )
    )
  ),
  
  # ── Tab 4: Calculator ───────────────────────────────────────────────────────
  nav_panel(
    title = "Calculator",
    icon  = icon("calculator"),
    card(
      card_header("Out-of-pocket cost estimator"),
      card_body(
        p("Estimate what you will actually pay based on your insurance details.",
          class = "text-muted small mb-3"),
        layout_columns(
          col_widths = c(4, 4, 4),
          selectInput("oop_payer", "Insurance plan", choices = PAYERS,
                      selected = "cash", width = "100%"),
          numericInput("deductible", "Annual deductible ($)",
                       value = 1500, min = 0, max = 20000, step = 100, width = "100%"),
          numericInput("deductible_met", "Already met ($)",
                       value = 0, min = 0, max = 20000, step = 100, width = "100%")
        ),
        layout_columns(
          col_widths = c(4, 4, 4),
          numericInput("coinsurance", "Coinsurance after deductible (%)",
                       value = 20, min = 0, max = 100, step = 5, width = "100%"),
          numericInput("oop_max", "Out-of-pocket maximum ($)",
                       value = 5000, min = 0, max = 30000, step = 500, width = "100%")
        ),
        hr(),
        conditionalPanel(
          condition = "input.search_btn > 0",
          uiOutput("oop_results")
        ),
        conditionalPanel(
          condition = "input.search_btn == 0",
          div(
            class = "text-center text-muted mt-3",
            p("Search a symptom on the Search tab first.")
          )
        )
      )
    )
  ),
  
  # ── Tab 5: All conditions ───────────────────────────────────────────────────
  nav_panel(
    title = "All conditions",
    icon  = icon("table"),
    card(
      card_header("Cash price heatmap — all conditions vs all hospitals"),
      card_body(
        p("Green = lower cost, orange = higher cost within each row.",
          class = "text-muted small"),
        reactableOutput("heatmap_table")
      )
    )
  ),
  
  # ── Tab 6: About ────────────────────────────────────────────────────────────
  nav_panel(
    title = "About",
    icon  = icon("circle-info"),
    card(
      card_body(
        h4("About this tool"),
        p("This app maps patient-reported symptoms to standardized billing codes
           (CPT/HCPCS/DRG) using a generative AI model (Anthropic Claude), then
           looks up the corresponding prices from each hospital's CMS-mandated
           machine-readable file (MRF)."),
        h5("Data sources"),
        tags$ul(
          tags$li("CMS Hospital Price Transparency MRFs (45 CFR Part 180)"),
          tags$li("Anthropic Claude API — symptom-to-billing-code mapping"),
          tags$li("Refreshed weekly via automated GitHub Actions pipeline")
        ),
        h5("Hospitals covered"),
        tags$ul(lapply(HOSPITALS$name, tags$li)),
        hr(),
        p(class = "text-muted small",
          "Prices shown are standard charges from hospital machine-readable files.
           Your actual cost depends on insurance coverage, deductible, and
           specific services rendered. This tool is for informational purposes
           only and does not constitute medical or financial advice.
           In a medical emergency, always call 911.")
      )
    )
  )
)

# =============================================================================
# SERVER
# =============================================================================
server <- function(input, output, session) {
  
  current_key    <- reactiveVal(NULL)
  current_data   <- reactiveVal(NULL)
  search_status  <- reactiveVal("idle")
  status_message <- reactiveVal("Enter a symptom to get started")
  user_coords    <- reactiveVal(NULL)
  user_zip_label <- reactiveVal(NULL)
  
  # ── Quick selects ────────────────────────────────────────────────────────────
  quick_searches <- list(
    qs_chest  = "chest pain",
    qs_arm    = "broken arm fracture",
    qs_head   = "severe headache migraine",
    qs_ab     = "abdominal pain stomach",
    qs_breath = "shortness of breath",
    qs_lac    = "laceration cut wound",
    qs_kidney = "kidney stone urinary pain"
  )
  
  lapply(names(quick_searches), function(btn_id) {
    local({
      btn  <- btn_id
      term <- quick_searches[[btn_id]]
      observeEvent(input[[btn]], {
        updateTextInput(session, "symptom_input", value = term)
        run_search(term)
      }, ignoreInit = TRUE)
    })
  })
  
  observeEvent(input$search_btn, {
    req(nchar(trimws(input$symptom_input)) > 0)
    run_search(input$symptom_input)
  })
  
  observeEvent(input$zip_btn, {
    zip    <- trimws(input$user_zip)
    coords <- get_zip_coords(zip)
    if (is.null(coords)) {
      user_coords(NULL)
      user_zip_label(paste0("ZIP ", zip, " not found"))
    } else {
      user_coords(coords)
      user_zip_label(paste0("Distances from ", zip))
    }
  })
  
  # ── Search logic ─────────────────────────────────────────────────────────────
  run_search <- function(term) {
    search_status("loading")
    status_message(paste0("Mapping \"", term, "\" to billing codes..."))
    matched_key <- find_match(str_to_lower(trimws(term)))
    
    if (!is.null(matched_key)) {
      current_key(matched_key)
      current_data(PRICE_DATA[[matched_key]])
      search_status("ok")
      status_message(paste0("Showing prices for: ", PRICE_DATA[[matched_key]]$desc))
    } else {
      status_message("Asking Claude to identify billing codes...")
      claude_result <- call_claude_api(term)
      if (!is.null(claude_result)) {
        current_key("_custom")
        current_data(claude_result)
        search_status("ok")
        status_message("Claude identified billing codes — showing estimated MRF prices")
      } else {
        search_status("error")
        status_message("Could not map symptom. Try a quick-select button above.")
      }
    }
  }
  
  # ── Claude API ────────────────────────────────────────────────────────────────
  call_claude_api <- function(symptom) {
    api_key <- Sys.getenv("ANTHROPIC_API_KEY")
    if (nchar(api_key) == 0) return(NULL)
    prompt <- paste0(
      'Patient presents to an ED with: "', symptom, '". ',
      'Identify the most likely CPT/HCPCS codes and MS-DRG. ',
      'Respond ONLY with valid JSON: ',
      '{"description":"...","codes":["CPT XXXXX"],"codeLabels":["..."],"notFound":false}'
    )
    tryCatch({
      resp <- request("https://api.anthropic.com/v1/messages") |>
        req_headers(
          "Content-Type"      = "application/json",
          "x-api-key"         = api_key,
          "anthropic-version" = "2023-06-01"
        ) |>
        req_body_json(list(
          model      = "claude-sonnet-4-20250514",
          max_tokens = 600L,
          messages   = list(list(role = "user", content = prompt))
        )) |>
        req_perform()
      body    <- resp_body_json(resp)
      raw_txt <- body$content[[1]]$text
      clean   <- str_remove_all(raw_txt, "```json|```")
      parsed  <- fromJSON(clean)
      if (isTRUE(parsed$notFound)) return(NULL)
      list(
        desc       = parsed$description,
        codes      = parsed$codes,
        codeLabels = parsed$codeLabels,
        prices     = build_placeholder_prices(),
        services   = list()
      )
    }, error = function(e) { message("Claude API error: ", e$message); NULL })
  }
  
  # ── Status outputs ────────────────────────────────────────────────────────────
  output$status_text <- renderUI({
    status <- search_status()
    msg    <- status_message()
    color  <- switch(status,
                     idle = "text-muted", loading = "text-warning",
                     ok = "text-success", error = "text-danger", "text-muted"
    )
    icon_tag <- if (status == "loading") {
      tags$i(class = "fa fa-spinner fa-spin")
    } else if (status == "ok") {
      tags$i(class = "fa fa-circle-check")
    } else if (status == "error") {
      tags$i(class = "fa fa-circle-xmark")
    } else {
      tags$i(class = "fa fa-circle-info")
    }
    div(class = paste("small", color, "d-flex align-items-center gap-2"), icon_tag, msg)
  })
  
  output$zip_status <- renderUI({
    lbl <- user_zip_label()
    if (is.null(lbl)) return(NULL)
    is_error   <- grepl("not found", lbl)
    css_class  <- if (is_error) "text-danger" else "text-success"
    icon_class <- if (is_error) "fa fa-circle-xmark" else "fa fa-circle-check"
    div(class = paste("small mb-2", css_class), tags$i(class = icon_class), lbl)
  })
  
  output$payer_status <- renderUI({
    payer <- input$payer
    if (is.null(payer) || payer == "cash") return(NULL)
    payer_name <- names(PAYERS)[PAYERS == payer]
    div(class = "small text-info mt-1",
        tags$i(class = "fa fa-circle-info"),
        paste0("Showing ", payer_name, " estimated rates"))
  })
  
  # ── Hospital map ──────────────────────────────────────────────────────────────
  output$hospital_map <- renderLeaflet({
    leaflet(HOSPITALS) |>
      addProviderTiles(providers$CartoDB.Positron) |>
      setView(lng = -82.45, lat = 27.97, zoom = 10) |>
      addCircleMarkers(
        lng         = ~lng,
        lat         = ~lat,
        radius      = 10,
        color       = "#1D9E75",
        fillColor   = "#1D9E75",
        fillOpacity = 0.8,
        stroke      = TRUE,
        weight      = 2,
        popup = ~paste0(
          "<strong>", name, "</strong><br>",
          address, "<br>",
          "<span style='color:#888;font-size:11px'>", badge_text, "</span><br><br>",
          "<a href='", mrf_url, "' target='_blank'>View MRF pricing file</a>"
        ),
        label = ~name
      )
  })
  
  # Update map markers when search or payer changes
  observe({
    d        <- current_data()
    payer_id <- input$payer
    if (is.null(d)) return()
    
    # Pre-compute prices outside the Leaflet formula so ~ can access them safely
    hosps         <- HOSPITALS
    hosps$price   <- sapply(hosps$id, function(i) {
      get_payer_price(d$prices[[i]]$cash, i, payer_id)
    })
    price_label   <- if (payer_id == "cash") "cash price" else {
      names(PAYERS)[PAYERS == payer_id]
    }
    hosps$popup_html <- paste0(
      "<strong>", hosps$name, "</strong><br>",
      hosps$address, "<br>",
      "<span style='color:#888;font-size:11px'>", hosps$badge_text, "</span><br><br>",
      "<strong>", fmt_dollar(hosps$price), "</strong> estimated ", price_label, "<br>",
      "<a href='", hosps$mrf_url, "' target='_blank'>View MRF pricing file</a>"
    )
    
    leafletProxy("hospital_map", data = hosps) |>
      clearMarkers() |>
      addCircleMarkers(
        lng         = ~lng,
        lat         = ~lat,
        radius      = 10,
        color       = "#1D9E75",
        fillColor   = "#1D9E75",
        fillOpacity = 0.8,
        stroke      = TRUE,
        weight      = 2,
        popup       = ~popup_html,
        label       = ~name
      )
  })
  
  # ── Results panel ─────────────────────────────────────────────────────────────
  output$results_panel <- renderUI({
    d <- current_data()
    if (is.null(d)) {
      return(div(
        class = "text-center text-muted mt-5 pt-5",
        tags$i(class = "fa fa-hospital", style = "font-size:2.5rem"),
        h5("Search a symptom to compare ED prices", class = "mt-3"),
        p("Powered by CMS hospital price transparency data", class = "small")
      ))
    }
    
    payer_id <- input$payer
    
    code_badges <- lapply(seq_along(d$codes), function(i) {
      lbl <- if (!is.null(d$codeLabels) && i <= length(d$codeLabels)) d$codeLabels[i] else ""
      def <- TREATMENT_DEFS[[lbl]]
      make_tooltip_badge(code = d$codes[i], label = lbl, def = def)
    })
    
    all_cash <- sapply(names(d$prices), function(hid) {
      get_payer_price(d$prices[[hid]]$cash, hid, payer_id)
    })
    min_cash  <- min(all_cash)
    max_cash  <- max(all_cash)
    min_name  <- get_hospital_name(d, "cash", "min")
    max_name  <- get_hospital_name(d, "cash", "max")
    savings   <- max_cash - min_cash
    price_note <- if (payer_id == "cash") "cash / self-pay price" else {
      paste0("estimated ", names(PAYERS)[PAYERS == payer_id], " rate")
    }
    
    tagList(
      div(
        class = "mb-3",
        p("Billing codes identified — hover any badge for a plain-language explanation:",
          class = "text-muted small mb-1"),
        div(class = "d-flex flex-wrap gap-1", code_badges)
      ),
      layout_columns(
        col_widths = c(4, 4, 4),
        value_box(
          title    = paste0("Lowest — ", price_note),
          value    = fmt_dollar(min_cash),
          showcase = tags$i(class = "fa fa-circle-check"),
          theme    = "success",
          p(min_name, class = "small opacity-75")
        ),
        value_box(
          title    = paste0("Highest — ", price_note),
          value    = fmt_dollar(max_cash),
          showcase = tags$i(class = "fa fa-circle-exclamation"),
          theme    = "danger",
          p(max_name, class = "small opacity-75")
        ),
        value_box(
          title    = "Potential savings",
          value    = fmt_dollar(savings),
          showcase = tags$i(class = "fa fa-piggy-bank"),
          theme    = "primary",
          p("lowest vs. highest ED", class = "small opacity-75")
        )
      ),
      h6("Hospitals", class = "mt-3 mb-2 text-muted"),
      uiOutput("hospital_cards"),
      div(
        class = "alert alert-warning small mt-3",
        tags$strong("Note: "),
        "Prices from CMS machine-readable files. Your actual cost depends on
         insurance, deductible, and services received. Not medical advice.
         In an emergency, call 911."
      )
    )
  })
  
  # ── Hospital cards ────────────────────────────────────────────────────────────
  output$hospital_cards <- renderUI({
    d <- current_data()
    req(d)
    
    payer_id <- input$payer
    coords   <- user_coords()
    hosps    <- HOSPITALS
    
    if (!is.null(coords)) {
      hosps$live_distance <- round(mapply(
        haversine_distance,
        lat1 = coords$lat, lng1 = coords$lng,
        lat2 = hosps$lat,  lng2 = hosps$lng
      ), 1)
      hosps <- hosps[hosps$live_distance <= input$max_distance, ]
      if (nrow(hosps) == 0) {
        return(div(
          class = "alert alert-warning small",
          "No hospitals within ", input$max_distance,
          " miles. Try increasing the distance slider."
        ))
      }
    } else {
      hosps$live_distance <- hosps$distance_mi
    }
    
    sorted_hosps <- if (input$sort_by == "cash") {
      hosps[order(sapply(hosps$id, function(i) {
        get_payer_price(d$prices[[i]]$cash, i, payer_id)
      })), ]
    } else if (input$sort_by == "gross") {
      hosps[order(sapply(hosps$id, function(i) d$prices[[i]]$gross)), ]
    } else {
      hosps[order(hosps$live_distance), ]
    }
    
    all_payer <- sapply(hosps$id, function(i) {
      get_payer_price(d$prices[[i]]$cash, i, payer_id)
    })
    min_payer  <- min(all_payer)
    dist_label <- ifelse(!is.null(coords), input$user_zip, "downtown Tampa")
    
    cards <- lapply(seq_len(nrow(sorted_hosps)), function(i) {
      h           <- sorted_hosps[i, ]
      p           <- d$prices[[h$id]]
      payer_price <- get_payer_price(p$cash, h$id, payer_id)
      is_best     <- payer_price == min_payer
      
      card_class  <- if (is_best) "border-success mb-2" else "mb-2"
      best_badge  <- if (is_best) {
        span(class = "ms-2 badge bg-success-subtle text-success-emphasis small fw-normal",
             "lowest price")
      } else NULL
      
      badge_class <- if (h$badge == "trauma") {
        "badge bg-danger-subtle text-danger-emphasis"
      } else {
        "badge bg-info-subtle text-info-emphasis"
      }
      
      cash_note <- if (payer_id != "cash") {
        div(class = "text-muted", style = "font-size:10px",
            paste0("cash: ", fmt_dollar(p$cash)))
      } else NULL
      
      # Build service rows with tooltip definitions
      svc_table <- if (length(d$services) > 0) {
        div(
          class = "mt-2 pt-2 border-top",
          tags$table(
            class = "table table-sm mb-0",
            style = "font-size:12px",
            tags$thead(tags$tr(
              tags$th("Service"),
              tags$th(style = "text-align:right", "Gross charge")
            )),
            tags$tbody(
              lapply(d$services, function(s) {
                make_service_row(s$name, s$code, s$prices[[h$id]])
              })
            )
          )
        )
      } else NULL
      
      card(
        class = card_class,
        card_body(
          class = "py-2",
          div(
            class = "d-flex justify-content-between align-items-start",
            div(
              div(class = "fw-semibold", h$name, best_badge),
              div(
                class = "text-muted small d-flex gap-2 flex-wrap mt-1",
                span(paste0(h$live_distance, " mi from ", dist_label)),
                span(class = badge_class, h$badge_text),
                tags$a(href = h$mrf_url, target = "_blank",
                       class = "text-info", "MRF link")
              )
            ),
            div(
              class = "d-flex gap-3 text-end",
              div(
                div(class = "text-muted", style = "font-size:10px",
                    if (payer_id == "cash") "Cash" else "Your est."),
                div(class = "fw-semibold text-success", fmt_dollar(payer_price)),
                cash_note
              ),
              div(
                div(class = "text-muted", style = "font-size:10px", "Gross"),
                div(class = "fw-semibold", fmt_dollar(p$gross))
              ),
              div(
                div(class = "text-muted", style = "font-size:10px", "Neg. range"),
                div(class = "text-muted small",
                    paste0(fmt_dollar(p$min_neg), " - ", fmt_dollar(p$max_neg)))
              )
            )
          ),
          svc_table
        )
      )
    })
    
    do.call(tagList, cards)
  })
  
  # ── Price chart (bar or dot plot) ─────────────────────────────────────────────
  output$price_chart <- renderPlotly({
    d <- current_data()
    req(d)
    
    metric_col   <- input$chart_metric
    chart_type   <- input$chart_type
    metric_label <- switch(metric_col,
                           cash = "Cash / self-pay price", gross = "Gross charge",
                           min_neg = "Min negotiated",     max_neg = "Max negotiated"
    )
    
    rows <- lapply(HOSPITALS$id, function(hid) {
      h <- HOSPITALS[HOSPITALS$id == hid, ]
      p <- d$prices[[hid]]
      data.frame(hospital = h$short_name, value = p[[metric_col]],
                 stringsAsFactors = FALSE)
    })
    chart_df          <- do.call(rbind, rows)
    chart_df          <- chart_df[order(chart_df$value), ]
    chart_df$hospital <- factor(chart_df$hospital, levels = chart_df$hospital)
    chart_df$is_min   <- chart_df$value == min(chart_df$value)
    chart_df$tooltip  <- paste0(chart_df$hospital, "\n",
                                metric_label, ": ", fmt_dollar(chart_df$value))
    chart_df$rank     <- seq_len(nrow(chart_df))
    
    if (chart_type == "bar") {
      p <- ggplot(chart_df, aes(x = hospital, y = value,
                                fill = is_min, text = tooltip)) +
        geom_col(width = 0.65, show.legend = FALSE) +
        scale_fill_manual(values = c("TRUE" = "#1D9E75", "FALSE" = "#B4B2A9")) +
        scale_y_continuous(labels = label_dollar(scale = 1/1000, suffix = "k")) +
        labs(x = NULL, y = NULL, title = metric_label) +
        theme_minimal(base_size = 12) +
        theme(
          axis.text.x        = element_text(angle = 30, hjust = 1, size = 10),
          panel.grid.major.x = element_blank(),
          plot.title         = element_text(size = 13, face = "plain")
        )
      ggplotly(p, tooltip = "text") |>
        layout(hoverlabel = list(bgcolor = "white"))
      
    } else {
      # Dot plot — also show gross charge for comparison
      gross_rows <- lapply(HOSPITALS$id, function(hid) {
        h <- HOSPITALS[HOSPITALS$id == hid, ]
        data.frame(hospital = h$short_name, gross = d$prices[[hid]]$gross,
                   stringsAsFactors = FALSE)
      })
      gross_df       <- do.call(rbind, gross_rows)
      chart_df$gross <- gross_df$gross[match(as.character(chart_df$hospital),
                                             gross_df$hospital)]
      
      plot_ly() |>
        add_segments(
          data = chart_df,
          x = ~value, xend = ~gross, y = ~rank, yend = ~rank,
          line      = list(color = "rgba(136,135,128,0.3)", width = 1.5, dash = "dot"),
          showlegend = FALSE, hoverinfo = "none"
        ) |>
        add_trace(
          data = chart_df, x = ~gross, y = ~rank,
          type = "scatter", mode = "markers",
          marker = list(size = 12, color = "rgba(226,75,74,0.35)",
                        line = list(color = "rgba(226,75,74,0.6)", width = 1)),
          name = "Gross charge",
          text = ~paste0(hospital, "<br>Gross charge: ", fmt_dollar(gross)),
          hovertemplate = "%{text}<extra></extra>"
        ) |>
        add_trace(
          data = chart_df, x = ~value, y = ~rank,
          type = "scatter", mode = "markers",
          marker = list(
            size  = 14,
            color = ifelse(chart_df$is_min, "#1D9E75", "#888780"),
            line  = list(color = "white", width = 1.5)
          ),
          name = metric_label,
          text = ~paste0(hospital, "<br>", metric_label, ": ", fmt_dollar(value)),
          hovertemplate = "%{text}<extra></extra>"
        ) |>
        layout(
          xaxis  = list(title = "", tickformat = "$,.0f",
                        gridcolor = "rgba(136,135,128,0.12)", zeroline = FALSE),
          yaxis  = list(title = "", tickmode = "array",
                        tickvals = chart_df$rank,
                        ticktext = as.character(chart_df$hospital),
                        tickfont = list(size = 11),
                        gridcolor = "rgba(136,135,128,0.08)", zeroline = FALSE),
          legend = list(orientation = "h", y = -0.15),
          margin = list(l = 110, r = 20, t = 20, b = 60),
          hoverlabel = list(bgcolor = "white")
        )
    }
  })
  
  # ── Breakdown chart (stacked bars or treemap) ─────────────────────────────────
  output$breakdown_chart_ui <- renderUI({
    if (input$breakdown_type == "stack") {
      plotlyOutput("stack_chart", height = "320px")
    } else {
      plotlyOutput("treemap_chart", height = "360px")
    }
  })
  
  output$stack_chart <- renderPlotly({
    d <- current_data()
    req(d)
    if (length(d$services) == 0) {
      return(plotly_empty() |>
               layout(title = list(text = "Itemized breakdown not available", font = list(size = 13))))
    }
    palette   <- c("#534AB7","#1D9E75","#D85A30","#378ADD","#BA7517","#D4537E","#639922")
    stack_rows <- lapply(seq_along(d$services), function(si) {
      svc  <- d$services[[si]]
      rows <- lapply(HOSPITALS$id, function(hid) {
        h <- HOSPITALS[HOSPITALS$id == hid, ]
        data.frame(hospital = h$short_name, service = svc$name,
                   value = svc$prices[[hid]], stringsAsFactors = FALSE)
      })
      do.call(rbind, rows)
    })
    stack_df <- do.call(rbind, stack_rows)
    plot_ly(
      data = stack_df, x = ~hospital, y = ~value,
      color = ~service, colors = palette, type = "bar",
      text = ~paste0(service, ": ", fmt_dollar(value)),
      hovertemplate = "%{text}<extra></extra>"
    ) |>
      layout(
        barmode = "stack",
        xaxis   = list(title = "", tickangle = -30),
        yaxis   = list(title = "", tickformat = "$,.0f"),
        legend  = list(orientation = "h", y = -0.3),
        margin  = list(b = 120)
      )
  })
  
  output$treemap_chart <- renderPlotly({
    d <- current_data()
    req(d)
    if (length(d$services) == 0) {
      return(plotly_empty() |>
               layout(title = list(text = "Itemized breakdown not available", font = list(size = 13))))
    }
    
    hid     <- input$treemap_hosp
    req(hid)
    palette <- c("#534AB7","#1D9E75","#D85A30","#378ADD","#BA7517","#D4537E","#639922")
    labels  <- sapply(d$services, `[[`, "name")
    values  <- sapply(d$services, function(s) s$prices[[hid]])
    parents <- rep("Total", length(labels))
    colors  <- palette[seq_along(labels)]
    total   <- sum(values)
    pcts    <- round(values / total * 100)
    texts   <- paste0(fmt_dollar(values), "<br>", pcts, "% of total")
    
    plot_ly(
      type   = "treemap",
      labels = c("Total", labels),
      parents = c("", parents),
      values  = c(total, values),
      text    = c("", texts),
      textinfo = "label+text",
      hovertemplate = "<b>%{label}</b><br>%{text}<extra></extra>",
      marker = list(
        colors = c("rgba(0,0,0,0)", colors),
        line   = list(width = 2, color = "white")
      ),
      textfont = list(size = 12, color = "white")
    ) |>
      layout(
        margin = list(t = 10, b = 10, l = 10, r = 10),
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor  = "rgba(0,0,0,0)"
      )
  })
  
  # ── OOP calculator ────────────────────────────────────────────────────────────
  output$oop_results <- renderUI({
    d <- current_data()
    req(d)
    
    payer_id         <- input$oop_payer
    deductible       <- input$deductible
    deductible_met   <- input$deductible_met
    coinsurance      <- input$coinsurance / 100
    oop_max          <- input$oop_max
    deduct_remaining <- max(0, deductible - deductible_met)
    
    rows <- lapply(HOSPITALS$id, function(hid) {
      h          <- HOSPITALS[HOSPITALS$id == hid, ]
      base_price <- get_payer_price(d$prices[[hid]]$cash, hid, payer_id)
      deduct_app <- min(base_price, deduct_remaining)
      after_ded  <- base_price - deduct_app
      coins_app  <- after_ded * coinsurance
      total_oop  <- deduct_app + coins_app
      oop_spent  <- deductible_met * coinsurance
      final_oop  <- min(total_oop, max(0, oop_max - oop_spent))
      
      data.frame(
        Hospital     = h$name,
        `Base price` = fmt_dollar(base_price),
        `Deductible` = fmt_dollar(deduct_app),
        `Coinsurance`= fmt_dollar(coins_app),
        `Your cost`  = fmt_dollar(final_oop),
        raw_oop      = final_oop,
        check.names  = FALSE,
        stringsAsFactors = FALSE
      )
    })
    
    oop_df  <- do.call(rbind, rows)
    oop_df  <- oop_df[order(oop_df$raw_oop), ]
    min_oop <- min(oop_df$raw_oop)
    max_oop <- max(oop_df$raw_oop)
    savings <- max_oop - min_oop
    
    tagList(
      layout_columns(
        col_widths = c(4, 4, 4),
        div(
          style = "background:var(--bs-success-bg-subtle);border-radius:8px;padding:12px",
          div(class = "small text-muted", "Lowest estimated cost"),
          div(class = "fw-semibold fs-5 text-success", fmt_dollar(min_oop)),
          div(class = "small text-muted",
              oop_df$Hospital[oop_df$raw_oop == min_oop][1])
        ),
        div(
          style = "background:var(--bs-danger-bg-subtle);border-radius:8px;padding:12px",
          div(class = "small text-muted", "Highest estimated cost"),
          div(class = "fw-semibold fs-5 text-danger", fmt_dollar(max_oop)),
          div(class = "small text-muted",
              oop_df$Hospital[oop_df$raw_oop == max_oop][1])
        ),
        div(
          style = "background:var(--bs-primary-bg-subtle);border-radius:8px;padding:12px",
          div(class = "small text-muted", "Potential savings"),
          div(class = "fw-semibold fs-5", fmt_dollar(savings)),
          div(class = "small text-muted", "by choosing wisely")
        )
      ),
      div(
        class = "mt-3",
        reactable(
          oop_df[, c("Hospital","Base price","Deductible","Coinsurance","Your cost")],
          highlight       = TRUE,
          defaultPageSize = 10,
          columns         = list(
            `Your cost` = colDef(
              style = function(value, index) {
                if (oop_df$raw_oop[index] == min_oop) {
                  list(color = "#0F6E56", fontWeight = "500")
                } else {
                  list()
                }
              }
            )
          )
        )
      ),
      div(
        class = "small text-muted mt-2",
        "Estimates assume the selected insurer's contracted rate. Actual costs vary by plan details and network status."
      )
    )
  })
  
  # ── Heatmap ───────────────────────────────────────────────────────────────────
  output$heatmap_table <- renderReactable({
    conditions <- names(PRICE_DATA)
    conditions <- conditions[conditions != "_custom"]
    
    rows <- lapply(conditions, function(key) {
      d   <- PRICE_DATA[[key]]
      row <- list(Condition = d$label)
      for (hid in HOSPITALS$id) {
        h <- HOSPITALS[HOSPITALS$id == hid, ]
        row[[h$short_name]] <- d$prices[[hid]]$cash
      }
      as.data.frame(row, check.names = FALSE, stringsAsFactors = FALSE)
    })
    heat_df   <- do.call(rbind, rows)
    row_means <- rowMeans(heat_df[, -1])
    heat_df   <- heat_df[order(-row_means), ]
    hosp_cols <- HOSPITALS$short_name
    
    col_defs <- lapply(hosp_cols, function(col_name) {
      colDef(
        name = col_name, minWidth = 90, align = "right",
        cell = function(value) fmt_dollar(value),
        style = function(value, index) {
          row_vals  <- as.numeric(heat_df[index, hosp_cols])
          mn        <- min(row_vals)
          mx        <- max(row_vals)
          bg        <- heat_color(value, mn, mx)
          txt_color <- if (value == mn) "#085041" else if (value == mx) "#712B13" else "inherit"
          fw        <- if (value == mn || value == mx) "500" else "normal"
          list(background = bg, color = txt_color, fontWeight = fw)
        }
      )
    })
    names(col_defs) <- hosp_cols
    
    all_cols <- c(
      list(Condition = colDef(name = "Condition", minWidth = 140,
                              style = list(fontWeight = "500"))),
      col_defs
    )
    reactable(heat_df, columns = all_cols, defaultPageSize = 20, highlight = TRUE)
  })
}

shinyApp(ui = ui, server = server)
