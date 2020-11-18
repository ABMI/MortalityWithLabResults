# .toJson <- function(object) {
#   return(as.character(jsonlite::toJSON(object, force = TRUE, auto_unbox = TRUE)))
# }
# .fromJson <- function(json) {
#   return(jsonlite::fromJSON(json, simplifyVector = TRUE, simplifyDataFrame = FALSE))
# }

table1Function <- function (cdmDatabaseSchema,
                            oracleTempSchema,
                            #longTermStartDays = -365, #shortTermStartDays = -3,
                            cohortDatabaseSchema,
                            connectionDetails,
                            cohortTable,
                            outputLocation)
{
  covariateSettings <- FeatureExtraction::createCovariateSettings(useDemographicsGender = T)

  plpData <- PatientLevelPrediction::getPlpData(connectionDetails,
                                                cdmDatabaseSchema = cdmDatabaseSchema,
                                                cohortId = 356, outcomeIds = 355,
                                                cohortDatabaseSchema = cohortDatabaseSchema,
                                                outcomeDatabaseSchema = cohortDatabaseSchema,
                                                cohortTable = cohortTable,
                                                outcomeTable = cohortTable,
                                                covariateSettings=covariateSettings)

  population <- PatientLevelPrediction::createStudyPopulation(plpData = plpData,
                                                              outcomeId = 355,
                                                              binary = T,
                                                              includeAllOutcomes = T,
                                                              requireTimeAtRisk = T,
                                                              minTimeAtRisk = 3,
                                                              riskWindowStart = 0,
                                                              riskWindowEnd = 27,
                                                              firstExposureOnly = FALSE, washoutPeriod = 3,
                                                              removeSubjectsWithPriorOutcome = T)


  #covariateSettings = FeatureExtraction::createTable1CovariateSettings()
  connection <- DatabaseConnector::connect(connectionDetails)

  covariateSettings <- list()
  covariateSettings <- FeatureExtraction::createDefaultCovariateSettings()
  covariateSettings$MeasurementValueShortTerm = TRUE
  covariateSettings$MeasurementValueLongTerm = FALSE
  covariateSettings$shortTermStartDays <- -3
  Table1_30days <- inHospitalgetPlpTable(cdmDatabaseSchema = cdmDatabaseSchema,
                               oracleTempSchema = oracleTempSchema,
                               covariateSettings = covariateSettings,
                               longTermStartDays = -365,
                               population = population,
                               connectionDetails = connectionDetails,
                               cohortTable = "#temp_person")


  population <- PatientLevelPrediction::createStudyPopulation(plpData = plpData,
                                                              outcomeId = 355,
                                                              binary = T,
                                                              includeAllOutcomes = T,
                                                              requireTimeAtRisk = T,
                                                              minTimeAtRisk = 3,
                                                              riskWindowStart = 0,
                                                              riskWindowEnd = 87,
                                                              firstExposureOnly = FALSE, washoutPeriod = 3,
                                                              removeSubjectsWithPriorOutcome = T)


  covariateSettings <- list()
  covariateSettings <- FeatureExtraction::createDefaultCovariateSettings()
  covariateSettings$MeasurementValueShortTerm = TRUE
  covariateSettings$MeasurementValueLongTerm = FALSE
  covariateSettings$shortTermStartDays <- -3
  Table1_90days <- inHospitalgetPlpTable(cdmDatabaseSchema = cdmDatabaseSchema,
                               oracleTempSchema = oracleTempSchema,
                               covariateSettings = covariateSettings,
                               longTermStartDays = -365,
                               population = population,
                               connectionDetails = connectionDetails,
                               cohortTable = "#temp_person")

  write.csv(Table1_30days, file.path(outputLocation,"Table1_30days.csv"))
  write.csv(Table1_90days, file.path(outputLocation,"Table1_90days.csv"))
}




inHospitalgetPlpTable <- function (cdmDatabaseSchema, oracleTempSchema, covariateSettings,
          longTermStartDays = -365, population, connectionDetails,
          cohortTable = "#temp_person")
{
  if (missing(cdmDatabaseSchema))
    stop("Need to enter cdmDatabaseSchema")
  if (missing(population))
    stop("Need to enter population")
  if (missing(connectionDetails))
    stop("Need to enter connectionDetails")
  if (class(population) != "data.frame")
    stop("wrong population class")
  if (sum(c("subjectId", "cohortStartDate") %in% colnames(population)) !=
      2)
    stop("population missing required column")
  if (sum(population$outcomeCount > 0) == 0)
    stop("No outcomes")
  if (sum(population$outcomeCount == 0) == 0)
    stop("No non-outcomes")
  connection <- DatabaseConnector::connect(connectionDetails)
  popCohort <- population[population$outcomeCount == 0, c("subjectId",
                                                          "cohortStartDate", "cohortStartDate")]
  popCohort <- data.frame(cohortId = -1, popCohort)
  colnames(popCohort)[4] <- "cohortEndDate"
  colnames(popCohort) <- SqlRender::camelCaseToSnakeCase(colnames(popCohort))
  DatabaseConnector::insertTable(connection = connection,
                                 tableName = cohortTable, data = popCohort, tempTable = T)
  settings <- list()
  if (!missing(covariateSettings)) {
    settings$covariateSettings <- covariateSettings
  }
  else {
    settings$covariateSettings <- FeatureExtraction::createCovariateSettings(useDemographicsGender = T,
                                                                             useDemographicsAge = T, useDemographicsAgeGroup = T,
                                                                             useDemographicsRace = T, useDemographicsEthnicity = T,
                                                                             useConditionGroupEraLongTerm = T, useDrugGroupEraLongTerm = T,
                                                                             useCharlsonIndex = T, useChads2Vasc = T, useDcsi = T,
                                                                             longTermStartDays = longTermStartDays)
  }
  settings$aggregated <- T
  settings$cdmDatabaseSchema <- cdmDatabaseSchema
  if (!missing(oracleTempSchema)) {
    settings$oracleTempSchema <- oracleTempSchema
  }
  settings$cohortTable <- cohortTable
  settings$cohortId <- -1
  settings$cohortTableIsTemp <- T
  settings$connection <- connection
  covariateData1 <- do.call(FeatureExtraction::getDbCovariateData,
                            settings)
  popCohort <- population[population$outcomeCount > 0, c("subjectId",
                                                         "cohortStartDate", "cohortStartDate")]
  popCohort <- data.frame(cohortId = -1, popCohort)
  colnames(popCohort)[4] <- "cohortEndDate"
  colnames(popCohort) <- SqlRender::camelCaseToSnakeCase(colnames(popCohort))
  DatabaseConnector::insertTable(connection = connection,
                                 tableName = cohortTable, data = popCohort, tempTable = T)
  covariateData2 <- do.call(FeatureExtraction::getDbCovariateData,
                            settings)
  tabSpec <- inHospitalgetDefaultTable1Specifications()
  tabSpec <- rbind(tabSpec, c(label = "Age in years", analysisId = 2,
                              covariateIds = 1002))
  tab1 <- FeatureExtraction::createTable1(covariateData1 = covariateData1,
                                          covariateData2 = covariateData2, specifications = tabSpec,
                                          output = "two columns")
  return(tab1)
}



inHospitalgetDefaultTable1Specifications <- function ()
{
  fileName <- system.file("csv", "Table1Specs.csv", package = "MortalityWithLabResults")
  colTypes <- list(label = readr::col_character(), analysisId = readr::col_integer(),
                   covariateIds = readr::col_character())
  specifications <- readr::read_csv(fileName, col_types = colTypes,
                                    guess_max = )
  return(specifications)
}
