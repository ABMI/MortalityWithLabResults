MortalityWithLabResults
======================

- Analytics use case(s): **Patient-Level Prediction**
- Study type: **Clinical Application**
- Tags: **OHDSI-Korea, FEEDER-NET**
- Study lead: **Yongkeun Park, Jaehyeong Cho**
- Study lead forums tag: **[Jaehyeong Cho](https://forums.ohdsi.org/u/Jaehyeong_Cho)**
- Study start date: **March 06, 2020**
- Study end date: 
- Protocol: Not avialble now
- Publications: 
- Results explorer: 

Objective: To identify the significant risk factors associated with morbidity and mortality in non-cardiac major surgery. Based on those factors, we seek to develop simple risk classification.

Instructions To Run Package
===================


```r
# If not building locally uncomment and run:
#install.packages("devtools")
#devtools::install_github("abmi/MortalityWithLabResults")
library(MortalityWithLabResults)
devtools::install_github("ohdsi/patientlevelprediction", ref="v4.0.2")
devtools::install_github("ohdsi/featureextraction", ref="v3.0.1")

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
outputFolder <- '~/output'

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

# parameter settings for mortalityPrediction

#=======================

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
                            table1=T
                            )
```
