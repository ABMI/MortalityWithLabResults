# getDbDefaultCovariateData <- function (connection, oracleTempSchema = NULL, cdmDatabaseSchema,
#           cohortTable = "#cohort_person", cohortId = -1, cdmVersion = "5",
#           rowIdField = "subject_id", covariateSettings, targetDatabaseSchema,
#           targetCovariateTable, targetCovariateRefTable, targetAnalysisRefTable,
#           aggregated = FALSE)
# {
#   if (!is(covariateSettings, "covariateSettings")) {
#     stop("Covariate settings object not of type covariateSettings")
#   }
#   if (cdmVersion == "4") {
#     stop("Common Data Model version 4 is not supported")
#   }
#   if (!missing(targetCovariateTable) && !is.null(targetCovariateTable) &&
#       aggregated) {
#     stop("Writing aggregated results to database is currently not supported")
#   }
#   settings <- .toJson(covariateSettings)
#   rJava::J("org.ohdsi.featureExtraction.FeatureExtraction")$init(system.file("",
#                                                                              package = "MortalityWithLabResults"))
#   json <- rJava::J("org.ohdsi.featureExtraction.FeatureExtraction")$createSql(settings,
#                                                                               aggregated, cohortTable, rowIdField, as.integer(cohortId),
#                                                                               cdmDatabaseSchema)
#   todo <- .fromJson(json)
#   if (length(todo$tempTables) != 0) {
#     writeLines("Sending temp tables to server")
#     for (i in 1:length(todo$tempTables)) {
#       DatabaseConnector::insertTable(connection, tableName = names(todo$tempTables)[i],
#                                      data = as.data.frame(todo$tempTables[[i]]),
#                                      dropTableIfExists = TRUE, createTable = TRUE,
#                                      tempTable = TRUE, oracleTempSchema = oracleTempSchema)
#     }
#   }
#   writeLines("Constructing features on server")
#   sql <- SqlRender::translate(sql = todo$sqlConstruction,
#                               targetDialect = attr(connection, "dbms"), oracleTempSchema = oracleTempSchema)
#   profile <- (!is.null(getOption("dbProfile")) && getOption("dbProfile") ==
#                 TRUE)
#   DatabaseConnector::executeSql(connection, sql, profile = profile)
#   if (missing(targetCovariateTable) || is.null(targetCovariateTable)) {
#     writeLines("Fetching data from server")
#     start <- Sys.time()
#     if (!is.null(todo$sqlQueryFeatures)) {
#       sql <- SqlRender::translate(sql = todo$sqlQueryFeatures,
#                                   targetDialect = attr(connection, "dbms"), oracleTempSchema = oracleTempSchema)
#       covariates <- DatabaseConnector::querySqlToAndromeda(connection,
#                                                      sql)
#       if (nrow(covariates) == 0) {
#         covariates <- NULL
#       }
#       else {
#         colnames(covariates) <- SqlRender::snakeCaseToCamelCase(colnames(covariates))
#       }
#     }
#     else {
#       covariates <- NULL
#     }
#     if (!is.null(todo$sqlQueryContinuousFeatures)) {
#       sql <- SqlRender::translate(sql = todo$sqlQueryContinuousFeatures,
#                                   targetDialect = attr(connection, "dbms"), oracleTempSchema = oracleTempSchema)
#       covariatesContinuous <- DatabaseConnector::querySqlToAndromeda(connection,
#                                                                sql)
#       if (nrow(covariatesContinuous) == 0) {
#         covariatesContinuous <- NULL
#       }
#       else {
#         colnames(covariatesContinuous) <- SqlRender::snakeCaseToCamelCase(colnames(covariatesContinuous))
#       }
#     }
#     else {
#       covariatesContinuous <- NULL
#     }
#     sql <- SqlRender::translate(sql = todo$sqlQueryFeatureRef,
#                                 targetDialect = attr(connection, "dbms"), oracleTempSchema = oracleTempSchema)
#     covariateRef <- DatabaseConnector::querySqlToAndromeda(connection,
#                                                      sql)
#     colnames(covariateRef) <- SqlRender::snakeCaseToCamelCase(colnames(covariateRef))
#     sql <- SqlRender::translate(sql = todo$sqlQueryAnalysisRef,
#                                 targetDialect = attr(connection, "dbms"), oracleTempSchema = oracleTempSchema)
#     analysisRef <- DatabaseConnector::querySqlToAndromeda(connection,
#                                                     sql)
#     colnames(analysisRef) <- SqlRender::snakeCaseToCamelCase(colnames(analysisRef))
#     delta <- Sys.time() - start
#     writeLines(paste("Fetching data took", signif(delta,
#                                                   3), attr(delta, "units")))
#   }
#   else {
#     writeLines("Writing data to table")
#     start <- Sys.time()
#     convertQuery <- function(sql, databaseSchema, table) {
#       if (missing(databaseSchema) || is.null(databaseSchema)) {
#         tableName <- table
#       }
#       else {
#         tableName <- paste(databaseSchema, table, sep = ".")
#       }
#       return(sub("FROM", paste("INTO", tableName, "FROM"),
#                  sql))
#     }
#     if (!is.null(todo$sqlQueryFeatures)) {
#       sql <- convertQuery(todo$sqlQueryFeatures, targetDatabaseSchema,
#                           targetCovariateTable)
#       sql <- SqlRender::translate(sql = sql, targetDialect = attr(connection,
#                                                                   "dbms"), oracleTempSchema = oracleTempSchema)
#       DatabaseConnector::executeSql(connection, sql, progressBar = FALSE,
#                                     reportOverallTime = FALSE)
#     }
#     if (!missing(targetCovariateRefTable) && !is.null(targetCovariateRefTable)) {
#       sql <- convertQuery(todo$sqlQueryFeatureRef, targetDatabaseSchema,
#                           targetCovariateRefTable)
#       sql <- SqlRender::translate(sql = sql, targetDialect = attr(connection,
#                                                                   "dbms"), oracleTempSchema = oracleTempSchema)
#       DatabaseConnector::executeSql(connection, sql, progressBar = FALSE,
#                                     reportOverallTime = FALSE)
#     }
#     if (!missing(targetAnalysisRefTable) && !is.null(targetAnalysisRefTable)) {
#       sql <- convertQuery(todo$sqlQueryAnalysisRef, targetDatabaseSchema,
#                           targetAnalysisRefTable)
#       sql <- SqlRender::translate(sql = sql, targetDialect = attr(connection,
#                                                                   "dbms"), oracleTempSchema = oracleTempSchema)
#       DatabaseConnector::executeSql(connection, sql, progressBar = FALSE,
#                                     reportOverallTime = FALSE)
#     }
#     delta <- Sys.time() - start
#     writeLines(paste("Writing data took", signif(delta,
#                                                  3), attr(delta, "units")))
#   }
#   sql <- SqlRender::translate(sql = todo$sqlCleanup, targetDialect = attr(connection,
#                                                                           "dbms"), oracleTempSchema = oracleTempSchema)
#   DatabaseConnector::executeSql(connection, sql, progressBar = FALSE,
#                                 reportOverallTime = FALSE)
#   if (length(todo$tempTables) != 0) {
#     for (i in 1:length(todo$tempTables)) {
#       sql <- "TRUNCATE TABLE @table;\nDROP TABLE @table;\n"
#       sql <- SqlRender::render(sql, table = names(todo$tempTables)[i])
#       sql <- SqlRender::translate(sql = sql, targetDialect = attr(connection,
#                                                                   "dbms"), oracleTempSchema = oracleTempSchema)
#       DatabaseConnector::executeSql(connection, sql, progressBar = FALSE,
#                                     reportOverallTime = FALSE)
#     }
#   }
#   if (missing(targetCovariateTable) || is.null(targetCovariateTable)) {
#     covariateData <- list(covariates = covariates, covariatesContinuous = covariatesContinuous,
#                           covariateRef = covariateRef, analysisRef = analysisRef,
#                           metaData = list())
#     if (is.null(covariateData$covariates) && is.null(covariateData$covariatesContinuous)) {
#       warning("No data found")
#     }
#     else {
#       if (!is.null(covariateData$covariates)) {
#         open(covariateData$covariates)
#       }
#       if (!is.null(covariateData$covariatesContinuous)) {
#         open(covariateData$covariatesContinuous)
#       }
#     }
#     class(covariateData) <- "covariateData"
#     return(covariateData)
#   }
# }
