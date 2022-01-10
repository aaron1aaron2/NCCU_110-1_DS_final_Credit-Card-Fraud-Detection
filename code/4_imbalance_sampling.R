source('utils.R')

# 決策樹模型
check_library('rpart')
library(rpart)

# 視覺化
check_library('ggplot2')
library(ggplot2)

# 資料處理套件
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
train_path <- "./dataset/train.csv"
test_path <- "./dataset/test.csv"

kfold_idx <- readRDS(kfoldid_path)

train <- read.csv(train_path)
test <- read.csv(test_path)

# sampling parameters
# nsmp <- 200
# amp <- 200

# 實驗 1 ==============================================
# 輸出路徑
result_path <- './output/4_imbalance_sampling/result.Time.csv'
result_select_path <- './output/4_imbalance_sampling/result_select.Time.csv'
result_best_path <- './output/4_imbalance_sampling/result_best.Time.csv'
result_img_path <- './output/4_imbalance_sampling/result_best.img.png'
pred_path <- './output/4_imbalance_sampling/pred.Time/'

build_folder(result_path)
build_folder(result_select_path)
build_folder(result_best_path)
build_folder(result_img_path)
build_folder(pred_path, isfile=FALSE)

baseline_model <- function(train, label){
  rpart(formula(paste(label, '~', '.')),
        data=train, control=rpart.control(maxdepth=10, minsplit=20),
        method="class")
}

imbalance_handler <- function(data, nsmp, amp){
  f_ind <- which(data$Class == 1)
  nf_ind <- which(data$Class == 0)
  pick_f <- sample(f_ind, nsmp, replace = ifelse(nsmp>length(f_ind),T,F))
  pick_nf <- sample(nf_ind, nsmp*amp, replace = ifelse(nsmp*amp>length(nf_ind),T,F))
  blnsmp.data <- data[c(pick_f, pick_nf),]
  blnsmp.data <- blnsmp.data[order(blnsmp.data$Time),]
}

experiment_ls <- list(
  '200_200' = function(data){
    imbalance_handler(data, 200, 200)
  },
  '250_200' = function(data){
    imbalance_handler(data, 250, 200)
  },
  '415_475' = function(data){
    imbalance_handler(data, 415, 475)
  },
  '415_300' = function(data){
    imbalance_handler(data, 415, 300)
  },
  '830_120' = function(data){
    imbalance_handler(data, 830, 120)
  },
  '1660_10' = function(data){
    imbalance_handler(data, 1660, 10)
  },
  '200_100' = function(data){
    imbalance_handler(data, 200, 100)
  },
  '300_200' = function(data){
    imbalance_handler(data, 300, 200)
  },
  '400_50' = function(data){
    imbalance_handler(data, 400, 50)
  },
  '350_200' = function(data){
    imbalance_handler(data, 350, 200)
  },
  '650_80' = function(data){
    imbalance_handler(data, 650, 80)
  },
  '560_120' = function(data){
    imbalance_handler(data, 560, 120)
  }
)

fold_result <- list()
for (experiment in names(experiment_ls)) {
  fold_result[[experiment]] <- list()
}

for (experiment in names(experiment_ls)) {
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
    
    
    # 實驗加工處理 
    train_f <- experiment_ls[[experiment]](train_f)
    val_f <- experiment_ls[[experiment]](val_f)
    # test_f <- experiment_ls[[experiment]](test_f)
    
    # 模型
    model <- baseline_model(train_f, label)
    
    # 評估結果
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
  
  test_fold_result['rank'] <- rank(-test_fold_result[val_select_score], ties.method = 'first')
  val_select_result <- test_fold_result[test_fold_result['rank'] == 1, ][1,]
  result_select_best <- rbind(result_select_best, val_select_result)
}

result_select_best['rank'] <- rank(-result_select_best[test_score], ties.method = 'min') 

write.csv(result_select, result_select_path, 
          row.names = FALSE, quote = FALSE)
write.csv(result_select_best, result_best_path, 
          row.names = FALSE, quote = FALSE)

# result_select_best <- read.csv(result_best_path)
aggNew <- result_select_best %>% pivot_longer(cols =  c('test_accuracy',
                                                        'test_precision',
                                                        'test_recall',
                                                        'test_f1'),
                                              names_to = "Evaluation",
                                              values_to = "Value")

COLORS <- c(test_accuracy = "darkred", test_precision ="steelblue",
            test_recall = "turquoise" , test_f1 = "tan1")
png(result_img_path,width = 800,height = 600)
ggplot(aggNew, aes(x = experiment, y = Value, group = Evaluation, color = Evaluation)) +
  geom_line(size = 0.9) +
  scale_color_manual(values = COLORS)
dev.off()
