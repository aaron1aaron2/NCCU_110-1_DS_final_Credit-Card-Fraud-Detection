## 偵測 & 安裝套件 ## ==========================================
check_library <- function(name) {
  if(!(name %in% rownames(installed.packages()))) {
    install.packages(name)
  }
}

## 建資料夾 ## =================================================
build_folder <- function(file_path, isfile=TRUE) {
  if (isfile) {
    dir.create(dirname(file_path), recursive = TRUE, showWarnings = FALSE)
  } else {
    dir.create(file_path, recursive = TRUE, showWarnings = FALSE)
  }
}

## 分類結果分數計算 - f1、recall、precision ## =================
# source: https://stackoverflow.com/questions/8499361/easy-way-of-counting-precision-recall-and-f1-score-in-r
evaluation_score <- function(predicted, expected, name='', positive.class="1") {
  predicted <- factor(as.character(predicted), levels=unique(as.character(expected)))
  expected  <- as.factor(expected)
  cm = as.matrix(table(expected, predicted))
  
  precision <- diag(cm) / colSums(cm)
  recall <- diag(cm) / rowSums(cm)
  f1 <-  ifelse(precision + recall == 0, 0, 2 * precision * recall / (precision + recall))
  
  #Assuming that F1 is zero when it's not possible compute it
  f1[is.na(f1)] <- 0
  
  #Binary F1 or Multi-class macro-averaged F1
  f1 <-  ifelse(nlevels(expected) == 2, f1[positive.class], mean(f1))
  
  result <- list()
  result[[paste0(name, '_precision')]] <- precision[[positive.class]]
  result[[paste0(name, '_recall')]] <- recall[[positive.class]]
  result[[paste0(name, '_f1')]] <- f1
  
  return(result)
}

## 分類結果分數計算 ## =========================================
get_evaluate <- function(model, train, test, label, val=NA, th=NA, pred_type="class") {
  # function ---------------
  calculate_accuracy <- function(frame) {
    rtab <- table(frame)
    
    return(sum(diag(rtab)) / sum(rtab)) # diag 取對角線值
  }
  
  get_truth_pred_frame <- function(data, model, label, pred_type, th) {

    # 使用門檻判斷類別(需要用 pred_type 改成 response ，讓模型預測機率)
    if (pred_type == 'prob') {
      # 模型預測
      resultframe <- data.frame(truth=data[, label],
                                pred=predict(model, data, type=pred_type)[,2])
      
      resultframe$pred <- ifelse(resultframe$pred>th, 1, 0)
    } else {
      resultframe <- data.frame(truth=data[, label],
                                pred=predict(model, data, type=pred_type))
      
    }
    
    return(resultframe)
  }
  
  # 模型預測 ---------------
  train_resultframe <- get_truth_pred_frame(train, model, label, pred_type, th)
  
  test_resultframe <- get_truth_pred_frame(test, model, label, pred_type, th)
  
  result <- list(
    train_accuracy=calculate_accuracy(train_resultframe), 
    test_accuracy=calculate_accuracy(test_resultframe)
  )
  
  pred_table <- list(
    train_table = train_resultframe,
    test_table = test_resultframe
  )
  
  # 有無 val 
  
  if (any(!is.na(val))) {
    val_resultframe <- get_truth_pred_frame(val, model, label, pred_type, th)
    
    result <- c(result, 
                list(val_accuracy=calculate_accuracy(val_resultframe))
                )
    
    pred_table <- c(pred_table,
      list(val_table=val_resultframe)
      )
  }

  
  result <- c(result,
              evaluation_score(
                test_resultframe$pred, 
                test_resultframe$truth,
                name = 'test')
  )
  if (any(!is.na(val))) {
    result <- c(result,
                evaluation_score(
                  val_resultframe$pred, 
                  val_resultframe$truth,
                  name = 'val')
    )
  }
  result <- rapply(result, f=function(x) ifelse(is.nan(x),0,x), how="replace" )
  
  return(list(result=result, table=pred_table))
}

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