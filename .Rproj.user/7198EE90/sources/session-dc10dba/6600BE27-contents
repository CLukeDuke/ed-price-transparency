# =============================================================================
# app.R
# ED Price Transparency Tool — Hillsborough County, FL
# GLHLTH 562 Final Project
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

source("R/price_data.R")
source("R/helpers.R")

# =============================================================================
# UI
# =============================================================================
ui <- page_navbar(
  title = "ED Price Transparency — Hillsborough County, FL",
  theme = bs_theme(
    version    = 5,
    bootswatch = "flatly",
    primary    = "#1D9E75",
    font_scale = 0.95
  ),
  
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
  
  nav_panel(
    title = "Compare",
    icon  = icon("chart-bar"),
    conditionalPanel(
      condition = "input.search_btn > 0",
      card(
        card_header("Price comparison — all hospitals"),
        card_body(
          radioButtons(
            inputId  = "chart_metric",
            label    = "Show",
            choices  = c(
              "Cash price"     = "cash",
              "Gross charge"   = "gross",
              "Min negotiated" = "min_neg",
              "Max negotiated" = "max_neg"
            ),
            selected = "cash",
            inline   = TRUE
          ),
          plotlyOutput("bar_chart", height = "380px")
        )
      ),
      card(
        card_header("Cost breakdown by service"),
        card_body(plotlyOutput("stack_chart", height = "320px"))
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
  
  call_claude_api <- function(symptom) {
    api_key <- Sys.getenv("ANTHROPIC_API_KEY")
    if (nchar(api_key) == 0) {
      warning("ANTHROPIC_API_KEY not set")
      return(NULL)
    }
    
    prompt <- paste0(
      'Patient presents to an ED with: "', symptom, '". ',
      'Identify the most likely CPT/HCPCS codes and MS-DRG for an ED visit. ',
      'Respond ONLY with valid JSON, no other text: ',
      '{"description":"...","codes":["CPT XXXXX"],"codeLabels":["..."],"notFound":false}'
    )
    
    result <- tryCatch({
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
    }, error = function(e) {
      message("Claude API error: ", e$message)
      NULL
    })
    
    result
  }
  
  output$status_text <- renderUI({
    status <- search_status()
    msg    <- status_message()
    
    color <- switch(status,
                    idle    = "text-muted",
                    loading = "text-warning",
                    ok      = "text-success",
                    error   = "text-danger",
                    "text-muted"
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
    
    div(
      class = paste("small", color, "d-flex align-items-center gap-2"),
      icon_tag,
      msg
    )
  })
  
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
    
    code_badges <- lapply(seq_along(d$codes), function(i) {
      lbl <- if (!is.null(d$codeLabels) && i <= length(d$codeLabels)) d$codeLabels[i] else ""
      span(
        class = "badge bg-info-subtle text-info-emphasis border border-info-subtle",
        style = "font-family: monospace;",
        d$codes[i],
        span(class = "ms-1 fw-normal opacity-75", style = "font-family: sans-serif;", lbl)
      )
    })
    
    all_cash <- sapply(d$prices, function(p) p$cash)
    min_cash <- min(all_cash)
    max_cash <- max(all_cash)
    min_name <- get_hospital_name(d, "cash", "min")
    max_name <- get_hospital_name(d, "cash", "max")
    savings  <- max_cash - min_cash
    
    tagList(
      div(
        class = "mb-3",
        p("Billing codes identified:", class = "text-muted small mb-1"),
        div(class = "d-flex flex-wrap gap-1", code_badges)
      ),
      layout_columns(
        col_widths = c(4, 4, 4),
        value_box(
          title    = "Lowest cash price",
          value    = fmt_dollar(min_cash),
          showcase = tags$i(class = "fa fa-circle-check"),
          theme    = "success",
          p(min_name, class = "small opacity-75")
        ),
        value_box(
          title    = "Highest cash price",
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
  
  output$hospital_cards <- renderUI({
    d <- current_data()
    req(d)
    
    all_cash <- sapply(HOSPITALS$id, function(i) d$prices[[i]]$cash)
    min_cash <- min(all_cash)
    
    sorted_hosps <- if (input$sort_by == "cash") {
      HOSPITALS[order(sapply(HOSPITALS$id, function(i) d$prices[[i]]$cash)), ]
    } else if (input$sort_by == "gross") {
      HOSPITALS[order(sapply(HOSPITALS$id, function(i) d$prices[[i]]$gross)), ]
    } else {
      HOSPITALS[order(HOSPITALS$distance_mi), ]
    }
    
    cards <- lapply(seq_len(nrow(sorted_hosps)), function(i) {
      h       <- sorted_hosps[i, ]
      p       <- d$prices[[h$id]]
      is_best <- p$cash == min_cash
      
      card_class <- if (is_best) "border-success mb-2" else "mb-2"
      
      best_badge <- if (is_best) {
        span(class = "ms-2 badge bg-success-subtle text-success-emphasis small fw-normal",
             "lowest cash price")
      } else {
        NULL
      }
      
      badge_class <- if (h$badge == "trauma") {
        "badge bg-danger-subtle text-danger-emphasis"
      } else {
        "badge bg-info-subtle text-info-emphasis"
      }
      
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
                span(paste0(h$distance_mi, " mi")),
                span(class = badge_class, h$badge_text),
                tags$a(href = h$mrf_url, target = "_blank",
                       class = "text-info", "MRF link")
              )
            ),
            div(
              class = "d-flex gap-3 text-end",
              div(
                div(class = "text-muted", style = "font-size:10px", "Cash"),
                div(class = "fw-semibold text-success", fmt_dollar(p$cash))
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
          )
        )
      )
    })
    
    do.call(tagList, cards)
  })
  
  output$bar_chart <- renderPlotly({
    d <- current_data()
    req(d)
    
    metric_col <- input$chart_metric
    metric_label <- switch(metric_col,
                           cash    = "Cash / self-pay price",
                           gross   = "Gross charge",
                           min_neg = "Min negotiated",
                           max_neg = "Max negotiated"
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
    
    p <- ggplot(chart_df, aes(x = hospital, y = value, fill = is_min, text = tooltip)) +
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
  })
  
  output$stack_chart <- renderPlotly({
    d <- current_data()
    req(d)
    
    if (length(d$services) == 0) {
      return(plotly_empty() |>
               layout(title = list(
                 text = "Itemized breakdown not available for this condition",
                 font = list(size = 13)
               )))
    }
    
    palette <- c("#534AB7", "#1D9E75", "#D85A30", "#378ADD",
                 "#BA7517", "#D4537E", "#639922")
    
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
      data          = stack_df,
      x             = ~hospital,
      y             = ~value,
      color         = ~service,
      colors        = palette,
      type          = "bar",
      text          = ~paste0(service, ": ", fmt_dollar(value)),
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
        name     = col_name,
        minWidth = 90,
        align    = "right",
        cell     = function(value) fmt_dollar(value),
        style    = function(value, index) {
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
