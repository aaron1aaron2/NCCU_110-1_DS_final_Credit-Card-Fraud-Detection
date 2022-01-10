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

# filter parameters
# method <- 'std'
# target <- '1:6'
# tgtmp <- strsplit(unlist(strsplit(target,',')),':')
# target <- c()
# for (i in 1:length(tgtmp)) {
#   target <- c(target,tgtmp[[i]][1]:tgtmp[[i]][2])
# }
# range <- '-3,3'
# range <- as.numeric(unlist(strsplit(range,',')))
# print("features processed below:")
# print(names(train)[target])

# 實驗 1 ==============================================
# 輸出路徑
result_path <- './output/3_extremes_filter/result.Time.csv'
result_select_path <- './output/3_extremes_filter/result_select.Time.csv'
result_best_path <- './output/3_extremes_filter/result_best.Time.csv'
result_img_path <- './output/3_extremes_filter/result_best.img.png'
pred_path <- './output/3_extremes_filter/pred.Time/'

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
# extremes filter
extremes_handler <- function(method, range, data, target){
  data_eh <- data.frame(data[,target])
  data_tmp <- data_eh
  switch (method,
          IQR = {
            for (i in 1:NCOL(data_eh)) {
              # q.75 <- quantile(data[,i], probs = 0.75)
              # q.25 <- quantile(data[,i], probs = 0.25)
              iqr <- IQR(data_tmp[,i])
              # print(iqr)
              lb <- range[1] #lower bound
              ub <- range[2] #upper bound
              data_eh <- data_eh[data_eh[,i]>(lb*iqr)&data_eh[,i]<(ub*iqr),]
            }
          },
          std = {
            for (i in 1:NCOL(data_eh)) {
              isd <- sd(data_tmp[,i]) #standard deviation
              imn <- mean(data_tmp[,i]) #mean
              lb <- range[1] #lower bound
              ub <- range[2] #upper bound
              data_eh <- data_eh[data_eh[,i]>(imn+lb*isd)&data_eh[,i]<(imn+ub*isd),]
            }
          }
  )
  data <- data[rownames(data.frame(data_eh)),]
}
experiment_ls <- list(
  'IQR_3_Time' = function(data){
    extremes_handler('IQR', c(-3,3), data, c(1))
  },
  'IQR_3_Amount' = function(data){
    extremes_handler('IQR', c(-3,3), data, c(30))
  },
  'IQR_3_Time+Amount' = function(data){
    extremes_handler('IQR', c(-3,3), data, c(1,30))
  },
  'IQR_3_V2' = function(data){
    extremes_handler('IQR', c(-3,3), data, c(3))
  },
  'std_3_V3' = function(data){
    extremes_handler('std', c(-3,3), data, c(4))
  },
  'std_2_V3' = function(data){
    extremes_handler('std', c(-2,2), data, c(4))
  },
  'IQR_3_Time+V3+V4' = function(data){
    extremes_handler('IQR', c(-3,3), data, c(1,4,5))
  },
  'std_3_Time+V3+V4' = function(data){
    extremes_handler('std', c(-3,3), data, c(1,4,5))
  },
  'IQR_3_Time~V5' = function(data){
    extremes_handler('IQR', c(-3,3), data, c(1:6))
  },
  'std_3_Time~V5' = function(data){
    extremes_handler('std', c(-3,3), data, c(1:6))
  },
  'IQR_4_All' = function(data){
    extremes_handler('IQR', c(-4,4), data, c(1:30))
  },
  'IQR_4_all' = function(data){
    extremes_handler('IQR', c(-4,4), data, c(2:29))
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

result_select_best <- read.csv(result_best_path)
aggNew <- result_select_best %>% pivot_longer(cols =  c('test_accuracy',
                                                        'test_precision',
                                                        'test_recall',
                                                        'test_f1'),
                                              names_to = "Evaluation",
                                              values_to = "Value")

COLORS <- c(test_accuracy = "darkred", test_precision ="steelblue",
            test_recall = "turquoise" , test_f1 = "tan1")
png(result_img_path,width = 1200,height = 600)
ggplot(aggNew, aes(x = experiment, y = Value, group = Evaluation, color = Evaluation)) +
  geom_line(size = 0.9) +
  scale_color_manual(values = COLORS)
dev.off()
