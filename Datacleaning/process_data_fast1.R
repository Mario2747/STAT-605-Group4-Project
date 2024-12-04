args <- commandArgs(trailingOnly = TRUE)
input_folder <- args[1]  # Input folder containing data files
output_file <- args[2]   # Output file to save the results

library(data.table)  # Load data.table for faster data processing

# 1. Read NIBRS_OFFENSE.csv
nibrs_offense <- fread(file.path(input_folder, "NIBRS_OFFENSE.csv"),
                       select = c("data_year", "incident_id", "offense_code", "location_id"))
# Select required columns
offense_data <- nibrs_offense[, .(data_year, incident_id, offense_code, location_id)]

# 2. Read NIBRS_INCIDENT.csv
nibrs_incident <- fread(file.path(input_folder, "NIBRS_incident.csv"),
                        select = c("incident_id", "agency_id", "incident_date", "incident_hour"))
# Filter rows where incident_id matches offense_data
incident_data <- nibrs_incident[incident_id %in% offense_data$incident_id]

# 3. Read NIBRS_VICTIM.csv
nibrs_victim <- fread(file.path(input_folder, "NIBRS_VICTIM.csv"),
                      select = c("incident_id", "victim_type_id", "age_num", "sex_code", "race_id"))
# Filter rows where incident_id matches offense_data
victim_data <- nibrs_victim[incident_id %in% offense_data$incident_id]

# 4. Merge data tables
# Merge offense and incident data by "incident_id"
final_data <- merge(offense_data, incident_data, by = "incident_id", all.x = TRUE)
# Merge the resulting table with victim data
final_data <- merge(final_data, victim_data, by = "incident_id", all.x = TRUE)

# 5. Process dates
# Convert incident_date to Date format
final_data[, incident_date := as.Date(incident_date, format = "%Y-%m-%d")]
# Extract month from the incident_date
final_data[, incident_date_month := format(incident_date, "%m")]
# Set locale to English for day of the week processing
Sys.setlocale("LC_TIME", "C")
# Extract the day of the week (e.g., Monday, Tuesday)
final_data[, incident_date_dayofweek := weekdays(incident_date)]

# 6. Add time of day column
# Classify incidents into "night" or "day" based on incident_hour
final_data[, time_of_day := ifelse(incident_hour %in% c(22, 23, 0, 1, 2, 3, 4), "night", "day")]

# 7. Read agencies.csv and merge with the final data
agencies_data <- fread(file.path(input_folder, "agencies.csv"),
                       select = c("agency_id", "county_name"))
# Merge county_name into the final data by "agency_id"
final_data <- merge(final_data, agencies_data, by = "agency_id", all.x = TRUE)

# 8. Write the final dataset to the output file
fwrite(final_data, output_file, row.names = FALSE)
