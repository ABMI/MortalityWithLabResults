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
                                                              removeSubjectsWithPriorOutcome = T)


  #covariateSettings = FeatureExtraction::createTable1CovariateSettings()
  connection <- DatabaseConnector::connect(connectionDetails)

  covariateSettings <- list()
  covariateSettings <- FeatureExtraction::createDefaultCovariateSettings()
  Table1_30days <- PatientLevelPrediction::getPlpTable(cdmDatabaseSchema = cdmDatabaseSchema,
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
                                                              removeSubjectsWithPriorOutcome = T)


  covariateSettings <- list()
  covariateSettings <- FeatureExtraction::createDefaultCovariateSettings()
  Table1_90days <- PatientLevelPrediction::getPlpTable(cdmDatabaseSchema = cdmDatabaseSchema,
                               oracleTempSchema = oracleTempSchema,
                               covariateSettings = covariateSettings,
                               longTermStartDays = -365,
                               population = population,
                               connectionDetails = connectionDetails,
                               cohortTable = "#temp_person")

  write.csv(Table1_30days, file.path(outputLocation,"Table1_30days.csv"))
  write.csv(Table1_90days, file.path(outputLocation,"Table1_90days.csv"))
}


# {
#   covariateSettings <- FeatureExtraction::createCovariateSettings(useDemographicsGender = T)
#
#   plpData <- PatientLevelPrediction::getPlpData(connectionDetails,
#                                                 cdmDatabaseSchema = cdmDatabaseSchema,
#                                                 cohortId = 356, outcomeIds = 355,
#                                                 cohortDatabaseSchema = cohortDatabaseSchema,
#                                                 outcomeDatabaseSchema = cohortDatabaseSchema,
#                                                 cohortTable = cohortTable,
#                                                 outcomeTable = cohortTable,
#                                                 covariateSettings=covariateSettings)
#
#   population <- PatientLevelPrediction::createStudyPopulation(plpData = plpData,
#                                                               outcomeId = 355,
#                                                               binary = T,
#                                                               includeAllOutcomes = T,
#                                                               requireTimeAtRisk = T,
#                                                               minTimeAtRisk = 364,
#                                                               riskWindowStart = 1,
#                                                               riskWindowEnd = 365,
#                                                               removeSubjectsWithPriorOutcome = T)
#
#   if (missing(cdmDatabaseSchema))
#     stop("Need to enter cdmDatabaseSchema")
#   if (missing(population))
#     stop("Need to enter population")
#   if (missing(connectionDetails))
#     stop("Need to enter connectionDetails")
#   if (class(population) != "data.frame")
#     stop("wrong population class")
#   if (sum(c("cohortId", "subjectId", "cohortStartDate") %in%
#           colnames(population)) != 3)
#     stop("population missing required column")
#   if (sum(population$outcomeCount > 0) == 0)
#     stop("No outcomes")
#   if (sum(population$outcomeCount == 0) == 0)
#     stop("No non-outcomes")
#   connection <- DatabaseConnector::connect(connectionDetails)
#   popCohort <- population[population$outcomeCount == 0, c("cohortId",
#                                                           "subjectId", "cohortStartDate", "cohortStartDate")]
#   colnames(popCohort)[4] <- "cohortEndDate"
#   colnames(popCohort) <- SqlRender::camelCaseToSnakeCase(colnames(popCohort))
#   cohortTable <- "#temp_person"
#   DatabaseConnector::insertTable(connection = connection,
#                                  tableName = cohortTable, data = popCohort, tempTable = T)
#   settings <- list()
#   settings$covariateSettings <- FeatureExtraction::createCovariateSettings(useDemographicsGender = T,
#                                                                              useDemographicsAge = T, useDemographicsAgeGroup = T,
#                                                                              useDemographicsRace = T, useDemographicsEthnicity = T,
#                                                                              useConditionGroupEraLongTerm = T, useDrugGroupEraLongTerm = T,
#                                                                              useCharlsonIndex = T, useChads2Vasc = T, useDcsi = T,
#                                                                              useProcedureOccurrenceShortTerm = T, useMeasurementValueShortTerm = T, shortTermStartDays = -3,
#                                                                              longTermStartDays = -365)
#   settings$aggregated <- T
#   settings$cdmDatabaseSchema <- cdmDatabaseSchema
#   if (!missing(oracleTempSchema)) {
#     settings$oracleTempSchema <- oracleTempSchema
#   }
#   settings$cohortTable <- cohortTable
#   settings$cohortId <- -1
#   #settings$cohortTableIsTemp <- T
#   settings$connection <- connection
#
#   covariateData1 <- do.call(FeatureExtraction::getDbDefaultCovariateData, settings)
#
#   popCohort <- population[population$outcomeCount > 0, c("cohortId",
#                                                          "subjectId", "cohortStartDate", "cohortStartDate")]
#   colnames(popCohort)[4] <- "cohortEndDate"
#   colnames(popCohort) <- SqlRender::camelCaseToSnakeCase(colnames(popCohort))
#   DatabaseConnector::insertTable(connection = connection,
#                                  tableName = cohortTable, data = popCohort, tempTable = T)
#   covariateData2 <- do.call(FeatureExtraction::getDbDefaultCovariateData,
#                             settings)
#   fileName <- system.file("csv", "Table1Specs.csv", package = "MortalityWithLabResults")
#   tabSpec <-  read.csv(fileName, stringsAsFactors = FALSE)
#   tabSpec <- rbind(tabSpec, c(label = "Age in years", analysisId = 2,
#                               covariateIds = 1002))
#   tab1 <- FeatureExtraction::createTable1(covariateData1 = covariateData1,
#                                           covariateData2 = covariateData2, specifications = tabSpec,
#                                           output = "two columns")
#   #return(tab1)
#
#
#   #Save RDS
#   ParallelLogger::logInfo(paste0("table1 result save in ",
#                                  file.path(outputLocation, "table1Result.rds")))
#   saveRDS(tab1, file.path(outputLocation, "table1Result.rds"))
# }
#
#
# # df <- ff::as.ram(covariateData1$covariates)
# # df[substr(df$covariateId, nchar(df$covariateId)-2, nchar(df$covariateId))=="504",]
