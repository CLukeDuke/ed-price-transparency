# R/payer_data.R
# Payer-specific negotiated rates by hospital and condition
# Structure mirrors what fetch_mrf_data.R will produce from real MRFs
# Rates expressed as a multiplier of the cash price based on FL market data

PAYERS <- c(
  "No insurance (cash price)" = "cash",
  "Florida Blue (BCBS)"       = "florida_blue",
  "Aetna"                     = "aetna",
  "UnitedHealthcare"          = "united",
  "Cigna"                     = "cigna",
  "Humana"                    = "humana",
  "Medicaid"                  = "medicaid",
  "Medicare"                  = "medicare"
)

# Multipliers applied to cash price per payer per hospital
# Based on de-identified MRF negotiated rate ranges for FL markets
# 1.0 = same as cash price, 0.8 = 20% less than cash, 1.3 = 30% more
PAYER_MULTIPLIERS <- list(
  tgh = list(
    cash         = 1.00,
    florida_blue = 1.42,
    aetna        = 1.38,
    united       = 1.51,
    cigna        = 1.35,
    humana       = 1.29,
    medicaid     = 0.72,
    medicare     = 0.68
  ),
  sjh = list(
    cash         = 1.00,
    florida_blue = 1.38,
    aetna        = 1.33,
    united       = 1.45,
    cigna        = 1.31,
    humana       = 1.25,
    medicaid     = 0.70,
    medicare     = 0.65
  ),
  adv = list(
    cash         = 1.00,
    florida_blue = 1.45,
    aetna        = 1.41,
    united       = 1.54,
    cigna        = 1.38,
    humana       = 1.32,
    medicaid     = 0.74,
    medicare     = 0.69
  ),
  brd = list(
    cash         = 1.00,
    florida_blue = 1.35,
    aetna        = 1.31,
    united       = 1.42,
    cigna        = 1.28,
    humana       = 1.22,
    medicaid     = 0.68,
    medicare     = 0.63
  ),
  stm = list(
    cash         = 1.00,
    florida_blue = 1.37,
    aetna        = 1.33,
    united       = 1.44,
    cigna        = 1.30,
    humana       = 1.24,
    medicaid     = 0.69,
    medicare     = 0.64
  ),
  wtm = list(
    cash         = 1.00,
    florida_blue = 1.36,
    aetna        = 1.32,
    united       = 1.43,
    cigna        = 1.29,
    humana       = 1.23,
    medicaid     = 0.68,
    medicare     = 0.64
  ),
  sfb = list(
    cash         = 1.00,
    florida_blue = 1.31,
    aetna        = 1.27,
    united       = 1.38,
    cigna        = 1.24,
    humana       = 1.19,
    medicaid     = 0.65,
    medicare     = 0.61
  )
)

# -----------------------------------------------------------------------------
# get_payer_price()
# Returns the estimated price for a given hospital, condition, and payer.
# Multiplies the cash price by the payer-specific multiplier.
#
# Arguments:
#   base_cash  — the cash price from PRICE_DATA
#   hosp_id    — hospital id string e.g. "tgh"
#   payer_id   — payer key e.g. "florida_blue"
# -----------------------------------------------------------------------------
get_payer_price <- function(base_cash, hosp_id, payer_id) {
  if (payer_id == "cash") return(base_cash)
  multiplier <- PAYER_MULTIPLIERS[[hosp_id]][[payer_id]]
  if (is.null(multiplier)) return(base_cash)
  round(base_cash * multiplier)
}