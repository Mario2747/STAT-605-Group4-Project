rm(list = ls())

args = (commandArgs(trailingOnly=TRUE))
if(length(args) == 4){
  state = args[1]
  data1 = args[2]
  data2 = args[3]
  data3 = args[4]
} else {
  cat('usage: Rscript model.R <state> <file1> <file2> <file3>\n', file=stderr())
  stop()
}

if (!file.exists(data1) || !file.exists(data2) || !file.exists(data3)) {
  stop("Can't find data file！")
}

if (require("data.table")) {
  print("Loaded package data.table.")
} else {
  print("Failed to load package data.table.")  
}

if (require("xgboost")) {
  print("Loaded package xgboost.")
} else {
  print("Failed to load package xgboost.")  
}

if (require("caret")) {
  print("Loaded package caret.")
} else {
  print("Failed to load package caret.")  
}

set.seed(123)
# Only work for LA,TX and other large-size files
random_sample <- function(data_path) {
  data <- fread(data_path)  
  data[sample(.N, size = .N / 10)]  
}

# Combine data
data_list <- lapply(list(data1, data2, data3), random_sample)
data <- rbindlist(data_list, use.names = TRUE, fill = TRUE)

# data preprocessing
data <- data[, -c("incident_id", "data_year", "county_name")]
data[, incident_date_month := format(as.Date(incident_date, format = "%Y/%m/%d"), "%m")]
data[, incident_date := NULL]
data <- data[, lapply(.SD, as.factor)]
data$offense_code <- as.factor(data$offense_code)
data <- na.omit(data)
print("Data input successfully.")
head(data)

# Set train and test part
train_idx <- sample(1:nrow(data), size = 0.8 * nrow(data))
train_data <- data[train_idx]
test_data <- data[-train_idx]


test_data$offense_code <- factor(test_data$offense_code, levels = levels(train_data$offense_code))
num_classes <- length(levels(train_data$offense_code))


train_dmatrix <- xgb.DMatrix(data = model.matrix(~ . - 1, data = train_data[, -c("offense_code")]),
                             label = as.numeric(train_data$offense_code) - 1)
test_dmatrix <- xgb.DMatrix(data = model.matrix(~ . - 1, data = test_data[, -c("offense_code")]),
                            label = as.numeric(test_data$offense_code) - 1)
print("Train and test sets have set.")

# XGBoost
params <- list(
  objective = "multi:softprob",
  num_class = num_classes,    
  eval_metric = "mlogloss",     
  max_depth = 3,            
  eta = 0.1,                  
  tree_method = "approx",    
  subsample = 0.8,             
  colsample_bytree = 0.8,       
  nthread = 4                    
)

# subsets
batch_size <- 10
total_rounds <- 100
current_round <- 0

while (current_round < total_rounds) {
  rounds_to_run <- min(batch_size, total_rounds - current_round)
  xgb_model <- xgb.train(
    params = params,
    data = train_dmatrix,
    nrounds = rounds_to_run,
    watchlist = list(train = train_dmatrix, test = test_dmatrix),
    verbose = 1,
    xgb_model = if (current_round > 0) xgb_model else NULL
  )
  current_round <- current_round + rounds_to_run
}

predictions <- predict(xgb_model, test_dmatrix)
prob_matrix <- matrix(predictions, ncol = num_classes, byrow = TRUE)
colnames(prob_matrix) <- levels(train_data$offense_code)
head(prob_matrix)


result <- data.frame(
  actual = test_data$offense_code,
  predicted = levels(train_data$offense_code)[apply(prob_matrix, 1, which.max)],
  prob_matrix
)

# Save prediction results
prediction_name = paste0(state,"-prediction.csv")
write.csv(result, prediction_name, row.names = FALSE)


cat("Prediction finished and results are saved to prediction_probabilities.csv\n")

predicted_classes <- apply(prob_matrix, 1, which.max) 
predicted_labels <- levels(train_data$offense_code)[predicted_classes]
predicted_labels <- factor(predicted_labels, levels = levels(test_data$offense_code))

# Accuracy
accuracy <- sum(predicted_labels == as.character(test_data$offense_code)) / nrow(test_data)
print(paste("Accuracy：", round(accuracy * 100, 2), "%"))

# Save precision, recall, F1
conf_matrix <- confusionMatrix(predicted_labels, test_data$offense_code)

precision_recall_f1 <- data.frame(
  Precision = conf_matrix$byClass[, "Precision"],
  Recall = conf_matrix$byClass[, "Recall"],
  F1_Score = conf_matrix$byClass[, "F1"]
)


scores_name = paste0(state,"-scores.csv")
write.csv(precision_recall_f1, scores_name, row.names = TRUE)
cat("Precision, Recall, F1 Score are saved to precision_recall_f1_scores.csv\n")

# Output significant variables
importance_name <- paste0(state, "-importance.csv")
importance <- xgb.importance(model = xgb_model)
write.csv(importance, importance_name, row.names = FALSE)
cat("Significant variable_importance.csv\n")

# Save model
model_name = paste0(state,"xgb-model.bin")
xgb.save(xgb_model, model_name)
cat("Model has been saved xgb_model.bin\n")
