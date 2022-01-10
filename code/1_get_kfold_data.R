source('utils.R')

# 決策樹模型
check_library('rpart')
library(rpart)

# 視覺化
check_library('ggplot2')
library(ggplot2)

# function >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# 先各個標籤分開抽樣處理，最後將各組併在一起(除不盡的隨機配到各組)
get_kfold_idx <- function (d, k, label_col) {
  if (!is.factor(d[, label_col])) {
    d[, label_col] <- as.factor(d[, label_col])
  }
  
  label_class <- levels(d[, label_col])
  
  class_gp_ls <- c()
  for (cls in label_class) {
    cls_id <- which(d[, label_col] == cls)
    # 打亂
    cls_id <- sample(cls_id)
    
    div <- length(cls_id)/k
    group_num <- round(div)
    
    # 每組分 group_num 個，多的會在 k+1 組
    group <- split(cls_id, ceiling(seq_along(cls_id)/group_num)) # https://stackoverflow.com/questions/3318333/split-a-vector-into-chunks
    
    # 除不盡的 k+1 組，隨機分配到各組
    if (paste(k+1) %in% names(group)) {
      # random assign item
      for (idx in group[[k+1]]) {
        rand_group <- sample(k)[[1]]
        group[[rand_group]] <- c(group[[rand_group]], idx)
      }
      # remove last group 
      group[[k+1]] <- NULL
    }
    
    class_gp_ls <- c(class_gp_ls, group)
  }
  
  # 將同組不同標籤的抽樣id合併
  gb_combine <- list()
  for (gp in 1:k) {
    for (i in class_gp_ls[names(class_gp_ls)==gp]) {
      if (paste(gp) %in% names(gb_combine)) {
        gb_combine[[paste(gp)]] <- c(gb_combine[[gp]], i)
      } else {
        gb_combine[[paste(gp)]] <- i
      }
    }
  }
  class_gp_ls[names(class_gp_ls)==1]
  
  
  return (gb_combine)
}

# 根據當前的 fold 和總 fold 數量，回傳 train、val、test 的 fold
get_train_val_fold <- function (test_fold, max_fold) {
  if (test_fold+1 > max_fold) {
    val_fold <- 1
  } else {
    val_fold <- test_fold+1
  }
  
  train_fold <- c()
  for (i in 1:max_fold) {
    if (!(i %in% c(test_fold, val_fold))) {
      train_fold <- c(train_fold, i)
    }
  }
  return (list(train=train_fold, val=val_fold, test=test_fold))
}
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# main process >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
label <- 'Class'
test_fold_ls <- c(4, 5, 6, 7, 8, 9, 10)
train <- read.csv('./data/train.csv')

result_path <- './output/1_kfold/result.csv'
result_select_path <- './output/1_kfold/result_selct.csv'
pred_path <- './output/1_kfold/pred/'
kfoldid_path <- './output/1_kfold/kfold_idx.rds'

build_folder(result_path)
build_folder(result_select_path)
build_folder(pred_path, isfile=FALSE)
build_folder(kfoldid_path)

# train 
fold_result <- list()
for (test_fold in test_fold_ls) {
  fold_result[[test_fold]] <- list()
}

for (test_fold in test_fold_ls) {
  kfold_idx <- get_kfold_idx(train, test_fold, label) # 將 id 分成 fold 份
  
  for (k in 1:test_fold) {
    start_time <- Sys.time()
    print(paste(test_fold, '-', k))
    # 以k決定 train、val、test 在這個 fold 分到的 idx
    split_fold <- get_train_val_fold(k, test_fold)
    
    train_fold_idx <- c()
    for (i in kfold_idx[split_fold$train]) {
      train_fold_idx <- c(train_fold_idx, i)
    }
    
    # 不用到 val 資料，所以將資料和到 train
    val_fold_idx <- kfold_idx[[split_fold$val]]
    test_fold_idx <- c(val_fold_idx, kfold_idx[[split_fold$test]])
    
    # 用 idx 選取 train、val、test 資料
    train_f <- train[train_fold_idx,]
    test_f <- train[test_fold_idx, ]
    
    train_f[, label] <- as.factor(train_f[, label])
    test_f[, label] <- as.factor(test_f[, label])
    
    DT.model <- rpart(formula(paste(label, '~', '.')),
                      data=train_f, control=rpart.control(maxdepth=4),
                      method="class")
    fold_result[[test_fold]][[k]] <- get_evaluate(DT.model, train_f, test_f, label)
    
    fold_result[[test_fold]][[k]][['timeuse']] <- Sys.time() - start_time
  }
}

# sort result
result <- data.frame()
for (test_fold in test_fold_ls) {
  for (k in 1:test_fold) {
    print(paste(test_fold, '-', k))
    k_result <- list(test_fold=test_fold, fold=k)
    k_result <- c(k_result,
                  fold_result[[test_fold]][[k]]$result
    )
    k_result <- c(k_result,
      list(timeuse=fold_result[[test_fold]][[k]]$timeuse[[1]])
    )
    result <- rbind(result, data.frame(k_result))
    
    pred_tables <- fold_result[[test_fold]][[k]]$table
    for (pred_table in names(pred_tables)) {
      write.csv(pred_tables[[pred_table]], 
                paste0(pred_path, 'test', test_fold, '_fold', k, '_', pred_table, '.csv'), 
                row.names = FALSE, quote = FALSE)
    }
  }
}

write.csv(result, result_path, 
          row.names = FALSE, quote = FALSE)


# Visualization of results
result_select <- data.frame()
for (test_fold in test_fold_ls) {
  test_fold_result <- result[result$test_fold == test_fold, ]
  test_fold_result$fold <- NULL
  
  test_fold_result_ls <-list(test_fold=test_fold)
  for (col in names(test_fold_result)) {
    if (col != 'test_fold') {
      test_fold_result_ls[[paste0(col, '_ave')]]  <- mean(test_fold_result[[col]])
      test_fold_result_ls[[paste0(col, '_var')]]  <- var(test_fold_result[[col]])
    }
  }
  result_select <- rbind(result_select, data.frame(test_fold_result_ls))
}

write.csv(result_select, result_select_path, 
          row.names = FALSE, quote = FALSE)

# ggplot(result_select, aes(x=test_fold)) + 
#   geom_line(aes(y = test_ave), color = "darkred", size=2) +
#   geom_line(aes(y = test_precision_ave), color="steelblue", size=2) +
#   geom_line(aes(y = test_recall_ave), color="turquoise", size=2) +
#   geom_line(aes(y = test_f1_ave), color="tan1", size=2) +
#   theme_bw()

# 平均
aggNew <- result_select %>% pivot_longer(cols =  c('test_ave',
                                                   'test_precision_ave',
                                                   'test_recall_ave',
                                                   'test_f1_ave'
                                                   ),
                                    names_to = "Evaluation", 
                                    values_to = "Value")

COLORS <- c(test_ave = "darkred", test_precision_ave ="steelblue",  
            test_recall_ave = "turquoise" , test_f1_ave = "tan1")
ggplot(aggNew, aes(x = test_fold, y = Value, group = Evaluation, color = Evaluation)) +
  geom_line(size = 0.9) +
  scale_color_manual(values = COLORS)

# 變異
aggNew <- result_select %>% pivot_longer(cols =  c('test_var',
                                                   'test_precision_var',
                                                   'test_recall_var',
                                                   'test_f1_var'
                                                   ),
                                         names_to = "Evaluation", 
                                         values_to = "Value")

COLORS <- c(test_var = "darkred", test_precision_var ="steelblue",  
            test_recall_var = "turquoise" , test_f1_var = "tan1")
ggplot(aggNew, aes(x = test_fold, y = Value, group = Evaluation, color = Evaluation)) +
  geom_line(size = 0.9) +
  scale_color_manual(values = COLORS)


# 時間
result_select$timeuse_total <- result_select$timeuse_ave* result_select$test_fold
ggplot(result_select, aes(x = test_fold, y = timeuse_total)) +
  geom_line(size = 0.9, color="darkred")
# output/fold_idx

kfold_idx <- get_kfold_idx(train, 4, label) # 將 id 分成 fold 份

saveRDS(kfold_idx, kfoldid_path)
