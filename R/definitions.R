# =============================================================================
# R/definitions.R
# Plain-language treatment definitions for ED billing codes
# Shown as hover tooltips on billing code badges and service line items
# =============================================================================

TREATMENT_DEFS <- list(

  "Level 5 E&M" = list(
    what = "Level 5 Emergency Department Visit (CPT 99285)",
    does = "The highest-complexity ED evaluation. Involves a comprehensive history, full physical exam, and high-complexity medical decision-making — typically for life-threatening or severe presentations.",
    why  = "This is the base visit fee billed by the hospital for physician time and facility use. Every ED patient receives an E&M code (levels 1-5) based on how complex their case was."
  ),

  "Level 4 E&M" = list(
    what = "Level 4 Emergency Department Visit (CPT 99284)",
    does = "A high-complexity ED evaluation for urgent but not immediately life-threatening conditions. Requires a detailed history, physical exam, and moderate-to-high complexity decision-making.",
    why  = "The second-highest ED visit code. Commonly billed for fractures, severe pain, or conditions requiring significant diagnostic workup."
  ),

  "Level 3 E&M" = list(
    what = "Level 3 Emergency Department Visit (CPT 99283)",
    does = "A moderate-complexity ED evaluation for conditions requiring expanded assessment such as lacerations, sprains, or minor infections requiring treatment.",
    why  = "Mid-tier visit code. Billed when the case requires more than a basic exam but does not meet the threshold for high-complexity billing."
  ),

  "ECG" = list(
    what = "Electrocardiogram (ECG / EKG) — CPT 93010",
    does = "Records your heart's electrical activity using 10 small electrodes placed on your skin. Painless and takes about 10 seconds. Detects heart attacks, irregular heart rhythms, and other cardiac conditions in real time.",
    why  = "Standard first step for any chest pain or shortness of breath. Results are available immediately at the bedside."
  ),

  "Chest X-Ray" = list(
    what = "Chest X-Ray, 2 views — CPT 71046",
    does = "Frontal and side X-rays of your chest using low-dose radiation. Evaluates heart size, lung fields, and major blood vessels.",
    why  = "Ordered to rule out pneumonia, fluid around the lungs, an enlarged heart, or other structural causes of chest pain or breathing difficulty."
  ),

  "Troponin I" = list(
    what = "Troponin I cardiac biomarker blood test — CPT 84484",
    does = "Measures a protein released into the bloodstream when heart muscle cells are damaged. Elevated levels strongly indicate a heart attack. Results typically return in 1-2 hours and are often repeated after 3-6 hours to detect a rising trend.",
    why  = "The definitive blood test for ruling a heart attack in or out. Cannot be skipped for a serious chest pain workup — you may be billed for it twice if a repeat draw is ordered."
  ),

  "CBC" = list(
    what = "Complete blood count (CBC) — CPT 85025",
    does = "A routine blood panel measuring red blood cells, white blood cells, and platelets. One of the most commonly ordered tests in any emergency visit.",
    why  = "Provides a broad snapshot of overall health and flags anemia, active infection, or blood disorders that might be contributing to your symptoms."
  ),

  "CT Head" = list(
    what = "CT scan of the head without contrast — CPT 70450",
    does = "A computerised X-ray that produces detailed cross-sectional images of the brain within seconds. Detects bleeding, stroke, tumours, and structural abnormalities.",
    why  = "Ordered for severe or sudden-onset headaches, head injuries, or neurological symptoms to rule out life-threatening causes."
  ),

  "CT Abdomen/Pelvis" = list(
    what = "CT scan of abdomen and pelvis with and without contrast — CPT 74178",
    does = "A detailed X-ray scan of the organs in your abdomen and pelvis, taken before and after injection of contrast dye. One of the most information-rich tests in emergency medicine.",
    why  = "The standard imaging study for abdominal pain, suspected appendicitis, kidney stones, or internal injuries. Often the single most expensive line item on an ED bill."
  ),

  "Metabolic panel" = list(
    what = "Comprehensive metabolic panel (CMP) — CPT 80053",
    does = "A blood test measuring 14 substances including glucose, electrolytes, kidney function markers, and liver enzymes. Provides a broad picture of organ function.",
    why  = "Ordered in most ED visits to check for dehydration, kidney problems, electrolyte imbalances, or liver issues."
  ),

  "Lipase" = list(
    what = "Lipase enzyme blood test — CPT 83690",
    does = "Measures the level of lipase, an enzyme produced by the pancreas. Significantly elevated levels indicate acute pancreatitis.",
    why  = "Ordered for abdominal pain — particularly upper abdominal pain — to check whether the pancreas is inflamed."
  ),

  "Wrist X-Ray" = list(
    what = "Wrist X-Ray, minimum 3 views — CPT 73100",
    does = "Standard X-rays of the wrist bones from multiple angles to identify fractures, dislocations, or joint abnormalities.",
    why  = "The first-line imaging for any wrist injury after a fall. Determines whether a fracture is present and what type of treatment is needed."
  ),

  "Long arm cast" = list(
    what = "Long arm fiberglass cast application — CPT 29075",
    does = "A cast that immobilises both the wrist and elbow joints, typically made of lightweight fibreglass. Applied after a forearm or wrist fracture to hold bones in place during healing.",
    why  = "Billed separately from the fracture treatment fee. The materials and time to apply the cast are a distinct charge."
  ),

  "Fracture tx" = list(
    what = "Fracture treatment, distal radius, without manipulation — CPT 25600",
    does = "The physician fee for treating a wrist fracture that does not require manually realigning the bones. Includes the initial evaluation and management of the fracture.",
    why  = "Billed on top of the E&M visit and the cast when a fracture is diagnosed. These are three separate charges."
  ),

  "IM injection" = list(
    what = "Therapeutic intramuscular injection — CPT 96372",
    does = "Delivery of medication directly into a muscle. Used when medication needs to work faster than an oral pill or when a patient is vomiting. Common for anti-nausea drugs, pain relievers, and migraine treatments.",
    why  = "Billed for the administration of the injection itself, separate from the cost of the drug."
  ),

  "D-dimer" = list(
    what = "D-dimer blood test — CPT 85379",
    does = "Measures a protein fragment produced when a blood clot dissolves. A negative result effectively rules out a blood clot in the lung (pulmonary embolism) in low-to-moderate risk patients.",
    why  = "Ordered for shortness of breath or chest pain when a blood clot is a concern. A very sensitive screening test."
  ),

  "BNP" = list(
    what = "B-type natriuretic peptide (BNP) blood test — CPT 83880",
    does = "Measures a hormone released by the heart when it is under stress. Elevated levels indicate heart failure — meaning the heart is not pumping efficiently.",
    why  = "Ordered for shortness of breath to distinguish between heart failure and lung causes, which require very different treatments."
  ),

  "Laceration repair" = list(
    what = "Simple laceration repair, 2.6-7.5 cm — CPT 12002",
    does = "Closure of a wound between 2.6 and 7.5 centimetres long using sutures, staples, or skin glue. Simple means the wound does not involve deeper layers like tendons or nerves.",
    why  = "Billed in addition to the E&M visit. The size and complexity of the wound determines which repair code and charge applies."
  ),

  "Local anesthetic" = list(
    what = "Therapeutic injection of local anesthetic — CPT 64450",
    does = "Injection of a numbing agent such as lidocaine around a nerve or into a wound to eliminate pain in a specific area. Takes effect within 1-5 minutes.",
    why  = "Billed as a separate procedure whenever local numbing is required, separate from the drug cost itself."
  ),

  "Td vaccine" = list(
    what = "Tetanus and diphtheria toxoid (Td) vaccine — CPT 90714",
    does = "A booster vaccine that refreshes your immunity against tetanus and diphtheria. Recommended every 10 years or immediately after a wound if the last booster was more than 5 years ago.",
    why  = "Routinely offered after lacerations or puncture wounds where tetanus risk is elevated."
  ),

  "Urinalysis" = list(
    what = "Urinalysis, automated — CPT 81003",
    does = "Analysis of a urine sample checking for blood, protein, glucose, white cells, bacteria, and other markers of kidney problems or urinary tract infections.",
    why  = "Nearly universal in kidney stone and urinary symptom workups. Blood in urine is a key diagnostic finding for kidney stones."
  ),

  "IV infusion" = list(
    what = "Intravenous (IV) infusion, initial hour — CPT 96365",
    does = "Delivery of medication or fluids directly into a vein. Allows drugs to work faster and at higher concentrations than oral routes. The initial-hour code covers setup and the first 60 minutes.",
    why  = "Billed for IV pain medication, IV fluids for dehydration, or IV antibiotics. Additional hours are billed with a separate code."
  )
)

# -----------------------------------------------------------------------------
# make_tooltip_badge()
# Builds a billing code badge with an embedded hover tooltip
# -----------------------------------------------------------------------------
make_tooltip_badge <- function(code, label, def = NULL) {
  tooltip_content <- if (!is.null(def)) {
    div(
      class = "tt-popup",
      div(class = "tt-name", def$what),
      div(class = "tt-body", def$does),
      div(class = "tt-why", tags$strong("Why you see this: "), def$why)
    )
  } else NULL

  tags$span(
    class    = "tt-badge",
    tabindex = "0",
    tags$span(style = "font-family: monospace;", code),
    tags$span(class = "tt-label", label),
    if (!is.null(def)) tags$span(class = "tt-q", "?"),
    tooltip_content
  )
}

# -----------------------------------------------------------------------------
# make_service_row()
# Builds one table row with an info button showing the treatment definition
# -----------------------------------------------------------------------------
make_service_row <- function(service_name, code, price) {
  def <- TREATMENT_DEFS[[service_name]]

  info_btn <- if (!is.null(def)) {
    tags$span(
      class    = "tt-info-btn",
      tabindex = "0",
      "i",
      div(
        class = "tt-popup tt-popup-below",
        div(class = "tt-name", def$what),
        div(class = "tt-body", def$does),
        div(class = "tt-why", tags$strong("Why you see this: "), def$why)
      )
    )
  } else NULL

  tags$tr(
    tags$td(
      div(class = "svc-name-wrap", tags$span(service_name), info_btn),
      div(class = "svc-code-label", code)
    ),
    tags$td(class = "svc-price-col", fmt_dollar(price))
  )
}

# -----------------------------------------------------------------------------
# TOOLTIP_CSS — injected into the Shiny UI via tags$style(TOOLTIP_CSS)
# -----------------------------------------------------------------------------
TOOLTIP_CSS <- "
.tt-badge {
  display: inline-flex; align-items: center; gap: 5px;
  padding: 4px 9px; border-radius: 5px; background: var(--bs-info-bg-subtle);
  color: var(--bs-info-text-emphasis); border: 0.5px solid var(--bs-info-border-subtle);
  font-size: 12px; position: relative; cursor: default;
}
.tt-label { font-family: var(--font-sans, sans-serif); font-size: 11px; opacity: 0.75; }
.tt-q {
  width: 14px; height: 14px; border-radius: 50%; background: rgba(0,0,0,0.1);
  display: inline-flex; align-items: center; justify-content: center;
  font-size: 9px; font-weight: 500; cursor: pointer; flex-shrink: 0;
}
.tt-info-btn {
  width: 15px; height: 15px; border-radius: 50%;
  background: var(--bs-secondary-bg, #f0f0f0);
  border: 0.5px solid var(--bs-border-color, #ccc);
  color: var(--bs-secondary-color, #666);
  font-size: 9px; font-weight: 600;
  display: inline-flex; align-items: center; justify-content: center;
  cursor: pointer; position: relative; flex-shrink: 0; margin-left: 4px;
}
.svc-name-wrap { display: flex; align-items: center; flex-wrap: nowrap; }
.svc-code-label { font-size: 10px; font-family: monospace; color: var(--bs-secondary-color, #888); margin-top: 1px; }
.svc-price-col { text-align: right; font-size: 12px; font-weight: 500; white-space: nowrap; vertical-align: middle; padding-left: 12px; }
.tt-popup {
  display: none; position: absolute; bottom: calc(100% + 8px); left: 0;
  width: 270px; background: var(--bs-body-bg, white);
  border: 0.5px solid var(--bs-border-color, #ddd); border-radius: 10px;
  padding: 10px 13px; z-index: 9999; font-family: sans-serif; text-align: left;
}
.tt-popup-below { bottom: auto; top: calc(100% + 6px); }
.tt-name { font-size: 13px; font-weight: 500; margin-bottom: 5px; line-height: 1.35; }
.tt-body { font-size: 12px; color: var(--bs-secondary-color, #555); line-height: 1.55; }
.tt-why { font-size: 11px; color: var(--bs-secondary-color, #888); margin-top: 7px; padding-top: 7px; border-top: 0.5px solid var(--bs-border-color, #eee); line-height: 1.5; }
.tt-badge:hover .tt-popup, .tt-badge:focus-within .tt-popup,
.tt-info-btn:hover .tt-popup, .tt-info-btn:focus .tt-popup { display: block; }
"
