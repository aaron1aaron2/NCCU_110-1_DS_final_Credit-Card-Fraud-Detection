source('utils.R')

# 決策樹模型
check_library('rpart')
library(rpart)

# 視覺化
check_library('ggplot2')
library(ggplot2)

check_library('tidyr')
library(tidyr)

check_library('dplyr')
library(dplyr)
# 資料準備 =================================================
fold <- 4
label <- 'Class'
val_select_score <- 'val_f1'
test_score <- 'test_f1'
kfoldid_path <- './output/1_kfold/kfold_idx.rds'
train_path <- "./data/train.csv"
test_path <- "./data/test.csv"

kfold_idx <- readRDS(kfoldid_path)

train <- read.csv(train_path)
test <- read.csv(test_path)

# 實驗 1 ==============================================
# 輸出路徑
result_path <- './output/2_baseline/result.maxdepth.csv'
result_select_path <- './output/2_baseline/result_select.maxdepth.csv'
result_best_path <- './output/2_baseline/result_best.maxdepth.csv'
pred_path <- './output/2_baseline/pred.maxdepth/'

build_folder(result_path)
build_folder(result_select_path)
build_folder(result_best_path)
build_folder(pred_path, isfile=FALSE)

experiment_ls <- list(
  'decision trees(depth=1)' = function(train, label){
    model <- rpart(formula(paste(label, '~', '.')),
                   data=train, control=rpart.control(maxdepth=1),
                   method="class")
  },
  'decision trees(depth=5)' = function(train, label){
    model <- rpart(formula(paste(label, '~', '.')),
                   data=train, control=rpart.control(maxdepth=5),
                   method="class")
  },  
  'decision trees(depth=10)' = function(train, label){
    model <- rpart(formula(paste(label, '~', '.')),
                   data=train, control=rpart.control(maxdepth=10),
                   method="class")
  },
  'decision trees(depth=15)' = function(train, label){
    model <- rpart(formula(paste(label, '~', '.')),
                   data=train, control=rpart.control(maxdepth=15),
                   method="class")
  },
  'decision trees(depth=20)' = function(train, label){
    model <- rpart(formula(paste(label, '~', '.')),
                   data=train, control=rpart.control(maxdepth=20),
                   method="class")
  }
)

fold_result <- list()
for (experiment in names(experiment_ls)) {
  fold_result[[experiment]] <- list()
  for (k in 1:fold) {
    print(paste(experiment, '-', k))
    start_time <- Sys.time()
    split_fold <- get_train_val_fold(k, fold)
    
    train_fold_idx <- c()
    for (i in kfold_idx[split_fold$train]) {
      train_fold_idx <- c(train_fold_idx, i)
    }
    
    # 不用到 test，所以將資料和到 train
    train_fold_idx <- c(train_fold_idx, kfold_idx[[split_fold$test]])
    
    val_fold_idx <- kfold_idx[[split_fold$val]]
    
    # 用 idx 選取 train、val、test 資料
    train_f <- train[train_fold_idx,]
    val_f <- train[val_fold_idx, ]
    test_f <- test # 固定的 test 資料集
    
    train_f[, label] <- as.factor(train_f[, label])
    val_f[, label] <- as.factor(val_f[, label])
    test_f[, label] <- as.factor(test_f[, label])
    
    model <- experiment_ls[[experiment]](train_f, label)
    fold_result[[experiment]][[k]] <- get_evaluate(model, 
                                                  train = train_f, 
                                                  test = test_f, 
                                                  val = val_f,
                                                  label = label)
    
    fold_result[[experiment]][[k]][['timeuse']] <- Sys.time() - start_time
  }
}

result <- data.frame()
for (experiment in names(experiment_ls)) {
  for (k in 1:fold) {
    print(paste(experiment, '-', k))
    k_result <- list(experiment=experiment, fold=k)
    k_result <- c(k_result,
                  fold_result[[experiment]][[k]]$result
    )
    k_result <- c(k_result,
                  list(timeuse=fold_result[[experiment]][[k]]$timeuse[[1]])
    )
    result <- rbind(result, data.frame(k_result))
    
    pred_tables <- fold_result[[experiment]][[k]]$table
    for (pred_table in names(pred_tables)) {
      write.csv(pred_tables[[pred_table]], 
                paste0(pred_path, experiment, '_fold', k, '_', pred_table, '.csv'), 
                row.names = FALSE, quote = FALSE)
    }
  }
}

write.csv(result, result_path, 
          row.names = FALSE, quote = FALSE)

result_select <- data.frame()
result_select_best <- data.frame()
for (experiment in names(experiment_ls)) {
  test_fold_result <- result[result$experiment == experiment, ]
  
  test_fold_result_ls <-list(experiment=experiment)
  for (col in names(test_fold_result)) {
    if (!col %in% c('experiment', 'fold')) {
      test_fold_result_ls[[paste0(col, '_ave')]]  <- mean(test_fold_result[[col]])
      test_fold_result_ls[[paste0(col, '_var')]]  <- var(test_fold_result[[col]])
    }
  }
  result_select <- rbind(result_select, data.frame(test_fold_result_ls))
  
  test_fold_result['rank'] <- rank(-test_fold_result[val_select_score])
  val_select_result <- test_fold_result[test_fold_result['rank'] == 1, ][1,]
  result_select_best <- rbind(result_select_best, val_select_result)
}

result_select_best['rank'] <- rank(-result_select_best[test_score]) 

write.csv(result_select, result_select_path, 
          row.names = FALSE, quote = FALSE)
write.csv(result_select_best, result_best_path, 
          row.names = FALSE, quote = FALSE)
result_select_best <- read.csv(result_best_path)
aggNew <- result_select_best %>% pivot_longer(cols =  c('test_accuracy',
                                                        'test_precision',
                                                        'test_recall',
                                                        'test_f1'),
                                              names_to = "Evaluation", 
                                              values_to = "Value")

COLORS <- c(test_accuracy = "darkred", test_precision ="steelblue",  
            test_recall = "turquoise" , test_f1 = "tan1")
ggplot(aggNew, aes(x = experiment, y = Value, group = Evaluation, color = Evaluation)) +
  geom_line(size = 0.9) +
  scale_color_manual(values = COLORS) +
  scale_x_discrete(labels= c('maxdepth=1', 'maxdepth=5', 'maxdepth=10', 'maxdepth=15', 'maxdepth=20'))

# 實驗 2 ==============================================
# 輸出路徑
result_path <- './output/2_baseline/result.minsplit.csv'
result_select_path <- './output/2_baseline/result_select.minsplit.csv'
result_best_path <- './output/2_baseline/result_best.minsplit.csv'
pred_path <- './output/2_baseline/pred.minsplit/'
build_folder(pred_path, isfile = FALSE)

experiment_ls <- list(
  'decision trees(minsplit=10)' = function(train, label){
    model <- rpart(formula(paste(label, '~', '.')),
                   data=train, control=rpart.control(minsplit=10),
                   method="class")
  },
  'decision trees(minsplit=15)' = function(train, label){
    model <- rpart(formula(paste(label, '~', '.')),
                   data=train, control=rpart.control(minsplit=15),
                   method="class")
  },
  'decision trees(minsplit=20)' = function(train, label){
    model <- rpart(formula(paste(label, '~', '.')),
                   data=train, control=rpart.control(minsplit=20),
                   method="class")
  },
  'decision trees(minsplit=25)' = function(train, label){
    model <- rpart(formula(paste(label, '~', '.')),
                   data=train, control=rpart.control(minsplit=25),
                   method="class")
  },
  'decision trees(minsplit=30)' = function(train, label){
    model <- rpart(formula(paste(label, '~', '.')),
                   data=train, control=rpart.control(minsplit=30),
                   method="class")
  },
  'decision trees(minsplit=35)' = function(train, label){
    model <- rpart(formula(paste(label, '~', '.')),
                   data=train, control=rpart.control(minsplit=30),
                   method="class")
  }
)

fold_result <- list()
for (experiment in names(experiment_ls)) {
  fold_result[[experiment]] <- list()
  for (k in 1:fold) {
    print(paste(experiment, '-', k))
    start_time <- Sys.time()
    split_fold <- get_train_val_fold(k, fold)
    
    train_fold_idx <- c()
    for (i in kfold_idx[split_fold$train]) {
      train_fold_idx <- c(train_fold_idx, i)
    }
    
    # 不用到 test，所以將資料和到 train
    train_fold_idx <- c(train_fold_idx, kfold_idx[[split_fold$test]])
    
    val_fold_idx <- kfold_idx[[split_fold$val]]
    
    # 用 idx 選取 train、val、test 資料
    train_f <- train[train_fold_idx,]
    val_f <- train[val_fold_idx, ]
    test_f <- test # 固定的 test 資料集
    
    train_f[, label] <- as.factor(train_f[, label])
    val_f[, label] <- as.factor(val_f[, label])
    test_f[, label] <- as.factor(test_f[, label])
    
    model <- experiment_ls[[experiment]](train_f, label)
    fold_result[[experiment]][[k]] <- get_evaluate(model, 
                                                   train = train_f, 
                                                   test = test_f, 
                                                   val = val_f,
                                                   label = label)
    
    fold_result[[experiment]][[k]][['timeuse']] <- Sys.time() - start_time
  }
}

result <- data.frame()
for (experiment in names(experiment_ls)) {
  for (k in 1:fold) {
    print(paste(experiment, '-', k))
    k_result <- list(experiment=experiment, fold=k)
    k_result <- c(k_result,
                  fold_result[[experiment]][[k]]$result
    )
    k_result <- c(k_result,
                  list(timeuse=fold_result[[experiment]][[k]]$timeuse[[1]])
    )
    result <- rbind(result, data.frame(k_result))
    
    pred_tables <- fold_result[[experiment]][[k]]$table
    for (pred_table in names(pred_tables)) {
      write.csv(pred_tables[[pred_table]], 
                paste0(pred_path, experiment, '_fold', k, '_', pred_table, '.csv'), 
                row.names = FALSE, quote = FALSE)
    }
  }
}

write.csv(result, result_path, 
          row.names = FALSE, quote = FALSE)

result_select <- data.frame()
result_select_best <- data.frame()
for (experiment in names(experiment_ls)) {
  test_fold_result <- result[result$experiment == experiment, ]
  
  test_fold_result_ls <-list(experiment=experiment)
  for (col in names(test_fold_result)) {
    if (!col %in% c('experiment', 'fold')) {
      test_fold_result_ls[[paste0(col, '_ave')]]  <- mean(test_fold_result[[col]])
      test_fold_result_ls[[paste0(col, '_var')]]  <- var(test_fold_result[[col]])
    }
  }
  result_select <- rbind(result_select, data.frame(test_fold_result_ls))
  
  test_fold_result['rank'] <- rank(-test_fold_result[val_select_score])
  val_select_result <- test_fold_result[test_fold_result['rank'] == 1, ][1,]
  result_select_best <- rbind(result_select_best, val_select_result)
}

result_select_best['rank'] <- rank(-result_select_best[test_score]) 

write.csv(result_select, result_select_path, 
          row.names = FALSE, quote = FALSE)
write.csv(result_select_best, result_best_path, 
          row.names = FALSE, quote = FALSE)

aggNew <- result_select_best %>% pivot_longer(cols =  c('test_accuracy',
                                                        'test_precision',
                                                        'test_recall',
                                                        'test_f1'),
                                              names_to = "Evaluation", 
                                              values_to = "Value")

COLORS <- c(test_accuracy = "darkred", test_precision ="steelblue",  
            test_recall = "turquoise" , test_f1 = "tan1")
ggplot(aggNew, aes(x = experiment, y = Value, group = Evaluation, color = Evaluation)) +
  geom_line(size = 0.9) +
  scale_color_manual(values = COLORS) +
  scale_x_discrete(labels= c('minsplit=10', 'minsplit=15', 'minsplit=20',
                             'minsplit=25', 'minsplit=30', 'minsplit=35'))

# 實驗 3 ==================================
experiment_ls <- list(
  "baseline" = function(train, label){
    rpart(formula(paste(label, '~', '.')),
          data=train, control=rpart.control(maxdepth=10, minsplit=20),
          method="class")
  }
)

result_path <- './output/2_baseline/result.baseline.csv'
result_select_path <- './output/2_baseline/result_select.baseline.csv'
result_best_path <- './output/2_baseline/result_best.baseline.csv'
pred_path <- './output/2_baseline/pred.baseline/'
build_folder(pred_path, isfile = FALSE)

fold_result <- list()
for (experiment in names(experiment_ls)) {
  fold_result[[experiment]] <- list()
  for (k in 1:fold) {
    print(paste(experiment, '-', k))
    start_time <- Sys.time()
    split_fold <- get_train_val_fold(k, fold)
    
    train_fold_idx <- c()
    for (i in kfold_idx[split_fold$train]) {
      train_fold_idx <- c(train_fold_idx, i)
    }
    
    # 不用到 test，所以將資料和到 train
    train_fold_idx <- c(train_fold_idx, kfold_idx[[split_fold$test]])
    
    val_fold_idx <- kfold_idx[[split_fold$val]]
    
    # 用 idx 選取 train、val、test 資料
    train_f <- train[train_fold_idx,]
    val_f <- train[val_fold_idx, ]
    test_f <- test # 固定的 test 資料集
    
    train_f[, label] <- as.factor(train_f[, label])
    val_f[, label] <- as.factor(val_f[, label])
    test_f[, label] <- as.factor(test_f[, label])
    
    model <- experiment_ls[[experiment]](train_f, label)
    fold_result[[experiment]][[k]] <- get_evaluate(model, 
                                                   train = train_f, 
                                                   test = test_f, 
                                                   val = val_f,
                                                   label = label)
    
    fold_result[[experiment]][[k]][['timeuse']] <- Sys.time() - start_time
  }
}

result <- data.frame()
for (experiment in names(experiment_ls)) {
  for (k in 1:fold) {
    print(paste(experiment, '-', k))
    k_result <- list(experiment=experiment, fold=k)
    k_result <- c(k_result,
                  fold_result[[experiment]][[k]]$result
    )
    k_result <- c(k_result,
                  list(timeuse=fold_result[[experiment]][[k]]$timeuse[[1]])
    )
    result <- rbind(result, data.frame(k_result))
    
    pred_tables <- fold_result[[experiment]][[k]]$table
    for (pred_table in names(pred_tables)) {
      write.csv(pred_tables[[pred_table]], 
                paste0(pred_path, experiment, '_fold', k, '_', pred_table, '.csv'), 
                row.names = FALSE, quote = FALSE)
    }
  }
}

write.csv(result, result_path, 
          row.names = FALSE, quote = FALSE)

result_select <- data.frame()
result_select_best <- data.frame()
for (experiment in names(experiment_ls)) {
  test_fold_result <- result[result$experiment == experiment, ]
  
  test_fold_result_ls <-list(experiment=experiment)
  for (col in names(test_fold_result)) {
    if (!col %in% c('experiment', 'fold')) {
      test_fold_result_ls[[paste0(col, '_ave')]]  <- mean(test_fold_result[[col]])
      test_fold_result_ls[[paste0(col, '_var')]]  <- var(test_fold_result[[col]])
    }
  }
  result_select <- rbind(result_select, data.frame(test_fold_result_ls))
  
  test_fold_result['rank'] <- rank(-test_fold_result[val_select_score])
  val_select_result <- test_fold_result[test_fold_result['rank'] == 1, ][1,]
  result_select_best <- rbind(result_select_best, val_select_result)
}

result_select_best['rank'] <- rank(-result_select_best[test_score]) 

write.csv(result_select, result_select_path, 
          row.names = FALSE, quote = FALSE)
write.csv(result_select_best, result_best_path, 
          row.names = FALSE, quote = FALSE)