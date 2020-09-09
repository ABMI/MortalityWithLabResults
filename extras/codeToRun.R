# If not building locally uncomment and run:
#install.packages("devtools")
#devtools::install_github("abmi/MortalityWithLabResults")
library(MortalityWithLabResults)

# add details of your database setting:
databaseName <- 'add a shareable name for the database you are currently validating on'

# add the cdm database schema with the data
cdmDatabaseSchema <- 'your cdm database schema for the validation'

# add the work database schema this requires read/write privileges
cohortDatabaseSchema <- 'your work database schema'

# if using oracle please set the location of your temp schema
oracleTempSchema <- NULL

# the name of the table that will be created in cohortDatabaseSchema to hold the cohorts
cohortTable <- 'MortalityWithLabResults'

# the location to save the prediction models results to:
outputFolder <- '~/output/MortalityWithLabResults'

# add connection details:
options(fftempdir = 'T:/fftemp')
dbms <- "pdw"
user <- NULL
pw <- NULL
server <- Sys.getenv('server')
port <- Sys.getenv('port')
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)

# Now run the study
MortalityWithLabResults::execute(connectionDetails = connectionDetails,
                                 databaseName = databaseName,
                                 cdmDatabaseSchema = cdmDatabaseSchema,
                                 cohortDatabaseSchema = cohortDatabaseSchema,
                                 oracleTempSchema = oracleTempSchema,
                                 cohortTable = cohortTable,
                                 outputFolder = outputFolder,
                                 createCohorts = T,
                                 runValidation = T,
                                 packageResults = T,
                                 minCellCount = 5,
                                 sampleSize = NULL,
                                 table1=T)
