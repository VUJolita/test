#' @title Initial condition generation
#' 
#' 
#' @param parms list of parameters generated by parameters() function
#'
#' uses an rda of data from March 22nd to generate the initial conditions of the model 
#'
#' @return
#' vector which has the initial conditions of the simulation
#'
#' @export
get_initial_conditions <- function(parms,m_init_cases){
  
  init_cases_detected <- parms$init_cases_detected
  N <- parms$N
  age_prop <- parms$age_prop
  comorbidity_prop_by_age <- parms$comorbidity_prop_by_age
  df_ind <- parms$df_ind
  v_exp_str <- parms$v_exp_str
  v_inf_str <- parms$v_inf_str
  v_asym_inf_str <- parms$v_asym_inf_str 
  prop_asym <- parms$prop_asymptomatic
  prop_inf_by_age <- parms$prop_inf_by_age
  nis <- parms$n_infected_states
  nes <- parms$n_exposed_states
  
# estimate undetected cases
total_v_init_NDinf <- sum(colSums(m_init_cases) * (1 - init_cases_detected) / init_cases_detected)

v_init_NDinf <- total_v_init_NDinf * prop_inf_by_age
v_init_NDinf_asym <- rep(0, 9)
v_init_NDinf_sym <- rep(0, 9)

# Initial starting vector
init_vec <- 0 * vector(mode = "numeric", length = nrow(df_ind))
#print(length(init_vec))
# First, distribute people across age and comorbidity compartments
# indexing will be ia = (i-1) and cg=0 or 1
for (i in 1:length(age_prop)) {

  # cases (known and unknown by age)
  n_cases_by_age <- sum(m_init_cases[, i]) + v_init_NDinf[i]

  ## Susceptible (eg=1) ##
  # Num in age group i with no co-morbidities
  init_vec[df_ind[df_ind$ie_str == "S" & df_ind$ia==(i - 1) & df_ind$ic == 0, "index"]] <- (N * age_prop[i] - n_cases_by_age) * (1 - comorbidity_prop_by_age[i])

  # Num in age group i with at least one co-morbidity
  init_vec[df_ind[df_ind$ie_str == "S" & df_ind$ia == (i - 1) & df_ind$ic == 1, "index"]] <- (N * age_prop[i] - n_cases_by_age) * comorbidity_prop_by_age[i]

  ## Detected cases ##
  # Infected -> go to last infected state
  init_vec[df_ind[df_ind$ie_str == v_inf_str[length(v_inf_str)] & df_ind$ia == (i - 1) & df_ind$ic == 0, "index"]] <-
    m_init_cases["I", i] * (1 - comorbidity_prop_by_age[i])

  init_vec[df_ind[df_ind$ie_str == v_inf_str[length(v_inf_str)] & df_ind$ia == (i - 1) & df_ind$ic == 1, "index"]] <-
    m_init_cases["I", i] * comorbidity_prop_by_age[i]

  # Hospitalized -> go to H (eg=16)
  init_vec[df_ind[df_ind$ie_str == "H" & df_ind$ia == (i - 1) & df_ind$ic == 0, "index"]] <- m_init_cases["H", i] * (1 - comorbidity_prop_by_age[i])
  init_vec[df_ind[df_ind$ie_str == "H" & df_ind$ia == (i - 1) & df_ind$ic == 1, "index"]] <- m_init_cases["H", i] * comorbidity_prop_by_age[i]

  # ICU -> go to ICU (eg=17)
  init_vec[df_ind[df_ind$ie_str == "ICU" & df_ind$ia == (i - 1) & df_ind$ic == 0, "index"]] <- m_init_cases["ICU", i] * (1 - comorbidity_prop_by_age[i])
  init_vec[df_ind[df_ind$ie_str == "ICU" & df_ind$ia == (i - 1) & df_ind$ic == 1, "index"]] <- m_init_cases["ICU", i] * comorbidity_prop_by_age[i]

  # Recovered -> go to R (eg=18)
  init_vec[df_ind[df_ind$ie_str == "R" & df_ind$ia == (i - 1) & df_ind$ic == 0, "index"]] <- m_init_cases["R", i] * (1 - comorbidity_prop_by_age[i])
  init_vec[df_ind[df_ind$ie_str == "R" & df_ind$ia == (i - 1) & df_ind$ic == 1, "index"]] <- m_init_cases["R", i] * comorbidity_prop_by_age[i]

  # Dead --> got to D (eg=19)
  init_vec[df_ind[df_ind$ie_str == "D" & df_ind$ia == (i - 1) & df_ind$ic == 0, "index"]] <- m_init_cases["D", i] * (1 - comorbidity_prop_by_age[i])
  init_vec[df_ind[df_ind$ie_str == "D" & df_ind$ia == (i - 1) & df_ind$ic == 1, "index"]] <- m_init_cases["D", i] * comorbidity_prop_by_age[i]
  
  ## Distribute undetected cases proportionately across exposed, asymptomatic, and infectious compartments
  n_comp_s_e <- length(c(v_exp_str,
                         v_inf_str))
  
  n_comp_a <- length(v_asym_inf_str)
  
  v_init_NDinf_asym[i] <- v_init_NDinf[i] * prop_asym[i] * (nis + nes) / (2 * nes + nis) 
  v_init_NDinf_sym[i] <- v_init_NDinf[i] * (1 - prop_asym[i] * (nis + nes) / (2 * nes + nis))

  # no comorbidities
    #asymptomatic
  init_vec[df_ind[df_ind$ie_str %in% c(v_asym_inf_str) & df_ind$ia == (i - 1) & df_ind$ic == 0, "index"]] <-
    init_vec[df_ind[df_ind$ie_str %in% c(v_asym_inf_str) & df_ind$ia == (i - 1) & df_ind$ic == 0, "index"]] +
    (v_init_NDinf_asym[i] / (n_comp_a) * (1 - comorbidity_prop_by_age[i]))

    #symptomatic and exposed
  init_vec[df_ind[df_ind$ie_str %in% c(v_exp_str, v_inf_str) & df_ind$ia == (i - 1) & df_ind$ic == 0, "index"]] <-
    init_vec[df_ind[df_ind$ie_str %in% c(v_exp_str, v_inf_str) & df_ind$ia == (i - 1) & df_ind$ic == 0, "index"]] +
    (v_init_NDinf_sym[i] / (n_comp_s_e) * (1 - comorbidity_prop_by_age[i]))
  
  # comorbidities
    #asymptomatic
  init_vec[df_ind[df_ind$ie_str %in% c(v_asym_inf_str) & df_ind$ia == (i - 1) & df_ind$ic == 1, "index"]] <-
    init_vec[df_ind[df_ind$ie_str %in% c(v_asym_inf_str) & df_ind$ia == (i - 1) & df_ind$ic == 1, "index"]] +
    (v_init_NDinf_asym[i] / (n_comp_a) * (comorbidity_prop_by_age[i]))
    
    #symptomatic and exposed
    init_vec[df_ind[df_ind$ie_str %in% c(v_exp_str, v_inf_str) & df_ind$ia == (i - 1) & df_ind$ic == 0, "index"]] <-
      init_vec[df_ind[df_ind$ie_str %in% c(v_exp_str, v_inf_str) & df_ind$ia == (i - 1) & df_ind$ic == 0, "index"]] +
      (v_init_NDinf_sym[i] / (n_comp_s_e) * (comorbidity_prop_by_age[i]))
}
return(init_vec)
}

