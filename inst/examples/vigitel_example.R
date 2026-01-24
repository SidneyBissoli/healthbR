# example: testing vigitel functions
# run this script to test vigitel download and data loading

library(healthbR)
library(dplyr)

# check available years
cat("Available years:\n")
print(vigitel_years())

# get survey info
cat("\nSurvey information:\n")
info <- vigitel_info()
print(info$name)
print(info$description)

# download and load 2023 data (smallest file - 15MB)
cat("\nDownloading VIGITEL 2023...\n")
df <- vigitel_data(2023)

# basic checks
cat("\nData dimensions:\n")
print(dim(df))

cat("\nColumn names:\n")
print(names(df))

cat("\nFirst rows:\n")
print(head(df))

# check weight variable
cat("\nWeight variable (pesorake) summary:\n")
print(summary(df$pesorake))

# basic analysis example
cat("\nObservations by city:\n")
df |>
  count(cidade, sort = TRUE) |>
  print(n = 27)

cat("\nDone!\n")
