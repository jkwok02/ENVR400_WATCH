#Buidling mode-bootstrapping sample---------------
pacman::p_load(ROSE, randomForest, pROC, caret,ggplot2,dplyr,tidyverse, stringr,tidyr,lubridate,readxl,nnet)
set.seed(1) 

#import asp, psp data first
df1 <- asp_data
df1=df1[,-1] 
df1$Above_Reg <- as.factor(df1$Above_Reg) 
df1<- df1|> select(-species,-date,-DFO_id,-longitude,-latitude,-subarea_id,
                   -salinity,-tp,-t2m,-speed,-sst,-no3.x,-no3.y,-no3,-po4.x,-po4.y,-po4)#24180 rows asp

df1<- na.omit(df1)

# Perform bootstrap resampling to balance the classes
balanced_df <- ROSE(Above_Reg ~ ., data = df1)$data

set.seed(123) 
training_indices <- sample(1:nrow(balanced_df), 0.8 * nrow(balanced_df))
training_df <- balanced_df[training_indices, ] # Training set with 19336 rows
test_df <- balanced_df[-training_indices, ] # Test set with 4834 rows

#standarize
numeric_cols <- sapply(training_df, is.numeric)
means <- sapply(training_df[numeric_cols], mean, na.rm = TRUE)
sds <- sapply(training_df[numeric_cols], sd, na.rm = TRUE)

training_df[numeric_cols] <- scale(training_df[numeric_cols])
test_df[numeric_cols] <- mapply(function(x, mean, sd) {
  (x - mean) / sd
}, test_df[numeric_cols], mean = means, sd = sds)

# Remove the variables from the dataset before model fitting
training_df_modified <- training_df %>%
  select(-PO4_0_5_10days_before, -NO3_0_5_10days_before, 
         -PO4_20_10days_before, -NO3_20_10days_before, 
         -PO4_30_10days_before, -NO3_30_10days_before)

test_df_modified <- test_df %>%
  select(-PO4_0_5_10days_before, -NO3_0_5_10days_before, 
         -PO4_20_10days_before, -NO3_20_10days_before, 
         -PO4_30_10days_before, -NO3_30_10days_before)

#Construct model
rf_full <- randomForest(Above_Reg ~ ., data = training_df, ntree = 500, mtry = 2, importance=T)
rf_pred_full<- predict(rf_full, newdata = test_df, type = "prob")
rf_positive_full<- rf_pred_full[, 2]
rf_roc_full <- roc(response = test_df$Above_Reg, predictor = rf_positive_full)

rf_partial <- randomForest(Above_Reg ~ . , data = training_df_modified, ntree = 500, mtry = 2,importance=T)
rf_pred_partial <- predict(rf_partial, newdata = test_df_modified, type = "prob")
rf_positive_partial <- rf_pred_partial[, 2]
rf_roc_partial <- roc(response = test_df$Above_Reg, predictor = rf_positive_partial)

rf_tpr_full <- rf_roc_full$sensitivities
rf_fpr_full <- rf_roc_full$specificities

rf_tpr_partial <- rf_roc_partial$sensitivities
rf_fpr_partial <- rf_roc_partial$specificities

plot(1 - rf_fpr_full, rf_tpr_full, type = "l", col = "#00008B",
     xlab = "1 - Specificity", ylab = "Sensitivity",
     xlim = c(0, 1), ylim = c(0, 1),)
rf_auc_full <- auc(rf_roc_full)
text(0.6, 0.2, paste("Full AUC =", round(rf_auc_full, 2)), col = "#00008B")

lines(1 - rf_fpr_partial, rf_tpr_partial, type = "l", col = "#ADD8E6")
rf_auc_partial <- auc(rf_roc_partial)
text(0.6, 0.1, paste("Partial AUC =", round(rf_auc_partial, 2)), col = "#ADD8E6")

#importance of variables-----------------
importance_long<- data.frame(Feature = importance_name,
                             Gini = importance(rf_full, type = 1),
                             MDA = importance(rf_full, type = 2)) %>%
  pivot_longer(cols = -Feature, names_to = "Metric", values_to = "Importance") %>%
  mutate(Importance = Importance / max(Importance)) # Normalize importance


importance_name_psp <- c("Salinity", "TP", "T2M","Speed",
                             "SST","PO4 0.5m","NO3 0.5m", "PO4 20m", 
                             "NO4 20m", "PO4 30m", "NO4 30m", "DOY")


ggplot(importance_long, aes(x = reorder(Feature, Importance), y = Importance, fill = Metric)) +
  geom_bar(stat = 'identity', position = 'dodge') +
  coord_flip() +
  theme_minimal() +
  scale_fill_manual(values = c("MeanDecreaseGini" = "#454545", "MeanDecreaseAccuracy" = "#D35400")) +
  labs(x = "", y = "Relative Importance", fill = "Metric") +
  theme(legend.position = "bottom")

#height550 width450


#MLP model--------------------
library(nnet)
mlp_train_targets <- as.numeric(as.character(training_df$Above_Reg))
mlp_train_predictors <- training_df[, !(names(training_df) %in% 'Above_Reg')]
mlp_full <- nnet(mlp_train_predictors, mlp_train_targets, size=10, decay=0.01, maxit=200, linout=TRUE)

mlp_pred_set_full <- test_df[, !(names(test_df) %in% 'Above_Reg')]
mlp_pred_full <- predict(mlp_full, mlp_pred_set_full, type="raw")

mlp_partial_train_targets <- as.numeric(as.character(training_df_modified$Above_Reg))
mlp_partial_train_predictors <- training_df_modified[, !(names(training_df_modified) %in% 'Above_Reg')]
mlp_partial <- nnet(mlp_partial_train_predictors, mlp_partial_train_targets, size=10, decay=0.01, maxit=200, linout=TRUE)

mlp_pred_set_partial <- test_df_modified[, !(names(test_df_modified) %in% 'Above_Reg')]
mlp_pred_partial<- predict(mlp_partial, mlp_pred_set_partial, type="raw")

#model evaluation plot---mlp_full#model evaluation plot-------------
rf_full_accuracy_asp <- mean(ifelse(rf_positive_full > 0.5, 1, 0) == test_df$Above_Reg) * 100
rf_partial_accuracy_asp <- mean(ifelse(rf_positive_partial > 0.5, 1, 0) == test_df$Above_Reg) * 100

rf_full_accuracy_psp <- mean(ifelse(rf_positive_full > 0.5, 1, 0) == test_df$Above_Reg) * 100
rf_partial_accuracy_psp <- mean(ifelse(rf_positive_partial > 0.5, 1, 0) == test_df$Above_Reg) * 100

mlp_full_accuracy_asp <- mean(ifelse(mlp_pred_full > 0.5, 1, 0) == test_df$Above_Reg) * 100
mlp_partial_accuracy_asp <- mean(ifelse(mlp_pred_partial > 0.5, 1, 0) == test_df$Above_Reg) * 100

mlp_full_accuracy_psp <- mean(ifelse(mlp_pred_full > 0.5, 1, 0) == test_df$Above_Reg) * 100
mlp_partial_accuracy_psp <- mean(ifelse(mlp_pred_partial > 0.5, 1, 0) == test_df$Above_Reg) * 100

combined_data <- data.frame(Group = rep(c("Random Forest", "Multi-layer Perceptrons"), each = 2, times=2),
 Model_Detail = rep(c("Full", "Partial"), 4),
Accuracy = c(rf_full_accuracy_asp, rf_partial_accuracy_asp, mlp_full_accuracy_asp, 
             mlp_partial_accuracy_asp,rf_full_accuracy_psp, rf_partial_accuracy_psp, mlp_full_accuracy_psp, mlp_partial_accuracy_psp),Model = factor(rep(c("RF Full", "RF Partial", "MLP Full", "MLP Partial"), 2), levels = c("RF Full", "RF Partial", "MLP Full", "MLP Partial")),Biotoxin = rep(c("AST", "PST"), each = 4))

ggplot(combined_data, aes(x = Group, y = Accuracy, fill = Model, colour = Model)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.6, alpha = 0.5) +
  geom_text(aes(label = Model_Detail),   
            position = position_dodge(width = 0.6), 
            size = 3, 
            vjust = -0.5) +  # Adjust vjust as needed to position labels below the bars
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, by = 20)) +
  labs(x = "Model", y = "% Correctly Predicted") +
  theme_bw() +
  theme(legend.position = "none",
        panel.grid.major = element_blank(),   
        panel.grid.minor = element_blank(),
        strip.background = element_blank(), # Remove the background of the facet label
        strip.text.x = element_text(size = 10)) + # Format the facet label text
  scale_fill_manual(values = c("RF Full" = "#3567b5", "RF Partial" = "#7b90b0", 
                               "MLP Full" = "#DC143C", "MLP Partial" = "#d17d8e")) +
  scale_colour_manual(values = c("RF Full" = "#3567b5", "RF Partial" = "#7b90b0", 
                                 "MLP Full" = "#DC143C", "MLP Partial" = "#d17d8e")) +
  facet_wrap(~Biotoxin, ncol = 2) # Use facet_wrap to combine plots

ggsave("combined_barplot.png", width = 8, height = 3, dpi = 300) 



#best mtry----- 
set.seed(123) 
oob_errors <- sapply(1:floor(sqrt(ncol(training_df))), function(m) {
  model <- randomForest(Above_Reg ~ ., data = training_df, mtry = m, ntree = 500)
  return(model$err.rate[500])
})

# Identify the mtry value with the lowest OOB error
optimal_mtry <- which.min(oob_errors)
print(optimal_mtry)

#FInd ntree---------------
# Initialize vectors to store ntree values and corresponding OOB error rates
ntree_values <- seq(100, 1000, by=100) # Adjust by to a higher step if needed
oob_error_rates <- numeric(length(ntree_values))

# Iterate over the range of ntree values
for (i in seq_along(ntree_values)) {
  ntree <- ntree_values[i]
  # Train the Random Forest model with the current ntree value
  rf_model <- randomForest(Above_Reg ~ ., data = training_df, ntree = ntree, mtry = 2, importance = TRUE)
  
  # Directly extract the overall OOB error rate for the model
  oob_error_rates[i] <- rf_model$err.rate[ntree]
}

# Plot OOB error rate against ntree values
plot(ntree_values, oob_error_rates, type = "b", col = "blue", xlab = "Number of Trees", ylab = "OOB Error Rate", main = "OOB Error Rate vs. Number of Trees")

