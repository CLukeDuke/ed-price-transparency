
TREATMENT_DEFS <- list(
  "Level 5 E&M" = list(what="Level 5 ED Visit (CPT 99285)",does="The highest-complexity ED evaluation involving a comprehensive history, full physical exam, and high-complexity medical decision-making.",why="This is the base visit fee billed by the hospital for physician time and facility use. Every ED patient receives an E&M code based on how complex their case was."),
  "Level 4 E&M" = list(what="Level 4 ED Visit (CPT 99284)",does="A high-complexity ED evaluation for urgent but not immediately life-threatening conditions.",why="The second-highest ED visit code. Commonly billed for fractures, severe pain, or conditions requiring significant diagnostic workup."),
  "Level 3 E&M" = list(what="Level 3 ED Visit (CPT 99283)",does="A moderate-complexity ED evaluation for conditions such as lacerations, sprains, or minor infections.",why="Mid-tier visit code billed when the case requires more than a basic exam."),
  "ECG" = list(what="Electrocardiogram (ECG/EKG) — CPT 93010",does="Records your heart electrical activity using 10 small electrodes. Painless, takes 10 seconds. Detects heart attacks and irregular rhythms in real time.",why="Standard first step for any chest pain. Results available immediately at the bedside."),
  "Chest X-Ray" = list(what="Chest X-Ray 2 views — CPT 71046",does="Frontal and side X-rays evaluating heart size, lung fields, and major blood vessels using low-dose radiation.",why="Ordered to rule out pneumonia, fluid around the lungs, or structural causes of chest pain."),
  "Troponin I" = list(what="Troponin I cardiac biomarker — CPT 84484",does="Measures a protein released when heart muscle cells are damaged. Elevated levels strongly indicate a heart attack. Results return in 1-2 hours, often repeated after 3-6 hours.",why="The definitive blood test for ruling a heart attack in or out. You may be billed twice if a repeat draw is ordered."),
  "CBC" = list(what="Complete blood count (CBC) — CPT 85025",does="Blood panel measuring red cells, white cells, and platelets. One of the most commonly ordered tests in any emergency visit.",why="Screens for anemia, active infection, or blood disorders contributing to your symptoms."),
  "CT Head" = list(what="CT scan head without contrast — CPT 70450",does="Detailed cross-sectional images of the brain within seconds. Detects bleeding, stroke, and structural abnormalities.",why="Ordered for severe sudden-onset headaches or neurological symptoms to rule out life-threatening causes."),
  "CT Abdomen/Pelvis" = list(what="CT scan abdomen and pelvis — CPT 74178",does="Detailed scan of abdominal and pelvic organs taken before and after contrast dye injection.",why="Standard imaging for abdominal pain, kidney stones, or appendicitis. Often the most expensive line item on an ED bill."),
  "Metabolic panel" = list(what="Comprehensive metabolic panel — CPT 80053",does="Blood test measuring 14 substances including glucose, electrolytes, kidney function, and liver enzymes.",why="Ordered to check for dehydration, kidney problems, or electrolyte imbalances."),
  "Lipase" = list(what="Lipase enzyme blood test — CPT 83690",does="Measures lipase produced by the pancreas. Elevated levels indicate acute pancreatitis.",why="Ordered for upper abdominal pain to check whether the pancreas is inflamed."),
  "Wrist X-Ray" = list(what="Wrist X-Ray minimum 3 views — CPT 73100",does="X-rays of wrist bones from multiple angles to identify fractures or dislocations.",why="First-line imaging for any wrist injury after a fall."),
  "Long arm cast" = list(what="Long arm fiberglass cast — CPT 29075",does="A cast immobilising both wrist and elbow joints applied after a forearm fracture.",why="Billed separately from the fracture treatment fee."),
  "Fracture tx" = list(what="Fracture treatment distal radius — CPT 25600",does="Physician fee for treating a wrist fracture that does not require manually realigning the bones.",why="Billed on top of the E&M visit and the cast as a separate charge."),
  "IM injection" = list(what="Therapeutic intramuscular injection — CPT 96372",does="Medication delivered directly into a muscle. Used for anti-nausea drugs, pain relievers, and migraine treatments.",why="Billed for the administration itself, separate from the drug cost."),
  "D-dimer" = list(what="D-dimer blood test — CPT 85379",does="Measures a protein fragment produced when a blood clot dissolves. A negative result rules out a pulmonary embolism in low-risk patients.",why="Ordered for shortness of breath when a blood clot is a concern."),
  "BNP" = list(what="BNP blood test — CPT 83880",does="Measures a hormone released when the heart is under stress. Elevated levels indicate heart failure.",why="Ordered for shortness of breath to distinguish between heart failure and lung causes."),
  "Laceration repair" = list(what="Simple laceration repair 2.6-7.5cm — CPT 12002",does="Closure of a wound using sutures, staples, or skin glue. Simple means the wound does not involve tendons or nerves.",why="Billed in addition to the E&M visit. Wound size determines which code applies."),
  "Local anesthetic" = list(what="Local anesthetic injection — CPT 64450",does="Injection of a numbing agent such as lidocaine. Takes effect in 1-5 minutes.",why="Billed as a separate procedure whenever local numbing is required."),
  "Td vaccine" = list(what="Tetanus and diphtheria vaccine (Td) — CPT 90714",does="Booster vaccine refreshing immunity against tetanus and diphtheria. Recommended every 10 years.",why="Routinely offered after lacerations or puncture wounds."),
  "Urinalysis" = list(what="Urinalysis automated — CPT 81003",does="Urine sample analysis checking for blood, protein, bacteria, and other markers.",why="Nearly universal in kidney stone and urinary symptom workups."),
  "IV infusion" = list(what="IV infusion initial hour — CPT 96365",does="Medication or fluids delivered directly into a vein. Covers setup and the first 60 minutes.",why="Billed for IV pain medication, IV fluids, or IV antibiotics.")
)

make_tooltip_badge <- function(code, label, def = NULL) {
  if (is.null(def)) {
    return(tags$span(
      class = "tt-badge",
      tags$span(style = "font-family: monospace;", code),
      tags$span(class = "tt-label", label)
    ))
  }
  tip <- paste0(def$what, "

", def$does, "

Why you see this: ", def$why)
  tags$span(
    class = "tt-badge", tabindex = "0", title = tip,
    tags$span(style = "font-family: monospace;", code),
    tags$span(class = "tt-label", label),
    tags$span(class = "tt-q", "?")
  )
}

make_service_row <- function(service_name, code, price) {
  def <- TREATMENT_DEFS[[service_name]]
  info_btn <- if (!is.null(def)) {
    tip <- paste0(def$what, "

", def$does, "

Why you see this: ", def$why)
    tags$span(class = "tt-info-btn", tabindex = "0", title = tip, "i")
  } else NULL
  tags$tr(
    tags$td(
      div(class = "svc-name-wrap", tags$span(service_name), info_btn),
      div(class = "svc-code-label", code)
    ),
    tags$td(class = "svc-price-col", fmt_dollar(price))
  )
}

TOOLTIP_CSS <- "
.tt-badge { display:inline-flex;align-items:center;gap:5px;padding:4px 9px;border-radius:5px;background:var(--bs-info-bg-subtle);color:var(--bs-info-text-emphasis);border:0.5px solid var(--bs-info-border-subtle);font-size:12px;cursor:default; }
.tt-label { font-size:11px;opacity:0.75; }
.tt-q { width:14px;height:14px;border-radius:50%;background:rgba(0,0,0,0.1);display:inline-flex;align-items:center;justify-content:center;font-size:9px;font-weight:500;cursor:pointer;flex-shrink:0; }
.tt-info-btn { width:15px;height:15px;border-radius:50%;background:var(--bs-secondary-bg,#f0f0f0);border:0.5px solid var(--bs-border-color,#ccc);color:var(--bs-secondary-color,#666);font-size:9px;font-weight:600;display:inline-flex;align-items:center;justify-content:center;cursor:pointer;flex-shrink:0;margin-left:4px; }
.svc-name-wrap { display:flex;align-items:center;flex-wrap:nowrap; }
.svc-code-label { font-size:10px;font-family:monospace;color:var(--bs-secondary-color,#888);margin-top:1px; }
.svc-price-col { text-align:right;font-size:12px;font-weight:500;white-space:nowrap;vertical-align:middle;padding-left:12px; }
"
 TRUE
 
 