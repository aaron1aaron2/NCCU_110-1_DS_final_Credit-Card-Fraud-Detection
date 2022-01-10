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
# read parameters
args = commandArgs(trailingOnly=TRUE)
if (length(args)==0) {
  stop("USAGE: Rscript extremes_filter.R --method IQR --range -3,3 --target 2:29 --train train.csv --test test.csv --report output/performance.ef.csv", call.=FALSE)
}
# parse parameters
i<-1 
while(i < length(args))
{
  if(args[i] == "--method"){
    method<-args[i+1]
    i<-i+1
  }else if(args[i] == "--range"){
    range<-as.numeric(unlist(strsplit(args[i+1],',')))
    i<-i+1
  }else if(args[i] == "--target"){
    target <- strsplit(unlist(strsplit(args[i+1],',')),':')
    tgtmp <- c()
    for (j in 1:length(target)) {
      tgtmp <- c(tgtmp,target[[j]][1]:target[[j]][2])
    }
    target <- tgtmp
    i<-i+1
  }else if(args[i] == "--train"){
    filen<-args[i+1]
    i<-i+1
  }else if(args[i] == "--test"){
    filen2<-args[i+1]
    i<-i+1
  }else if(args[i] == "--report"){
    out_f<-args[i+1]
    i<-i+1
  }else{
    stop(paste("Unknown flag or input illegal file name etc. include'--' :", args[i]), call.=FALSE)
  }
  i<-i+1
}
start.time <- Sys.time()
# filen <- 'train.csv'
# filen2 <- 'test.csv'
train <- read.csv(filen, header = TRUE)
test <- read.csv(filen2, header = TRUE)
require(rpart)
# method <- 'IQR'
# target <- '2:7,9:9,11:30'
# tgtmp <- strsplit(unlist(strsplit(target,',')),':')
# target <- c()
# for (i in 1:length(tgtmp)) {
#   target <- c(target,tgtmp[[i]][1]:tgtmp[[i]][2])
# }
# range <- '-3,3'
# range <- as.numeric(unlist(strsplit(range,',')))
print("features processed below:")
names(train)[target]
train_v <- extremes_handler(method, range, train, target)
ifelse(!nrow(train_v[train_v$Class==1,]),
       res <- c('NA','NA','NA'),
       {
         model_v <- rpart(Class~., train_v, method = "class")
         pred_v <- predict(model_v, test, type = "class")
         cm_v <- table(truth=test$Class, pred=pred_v)
         print(cm_v)
         p <- diag(cm_v) / colSums(cm_v)
         r <- diag(cm_v) / rowSums(cm_v)
         f1 <- ifelse(p + r == 0, 0, 2 * p * r / (p + r))
         f1[is.na(f1)] <- 0
         res <- round(c(p["1"],r["1"],f1["1"]),6)
       }
       )

print(paste("precision, recall of fraud:",res[1],",",res[2]))
print(paste("f1:",res[3]))
out_data <- data.frame(Method=method, 
                       Range=paste(range,collapse = "~"), 
                       TargetFeatures=paste(names(train)[target],collapse = "+"),
                       Precision=res[1],
                       Recall=res[2],
                       F1=res[3],
                       FraudNumberOfRow=nrow(train_v[train_v$Class==1,]),
                       NumberOfRow=nrow(train_v),
                       stringsAsFactors = FALSE)
print(out_data)

#first check path existed with parsing out-path
pth_chk <- unlist(strsplit(out_f,'/'))
pth_chk2 <- unlist(strsplit(out_f,pth_chk[length(pth_chk)]))
#second create dir if existed or not
dir.create(pth_chk2,showWarnings = FALSE)
# then write file
# out_f <- 'outtest.csv'
write.table(out_data, file=out_f, append = T, row.names = F, 
            col.names = ifelse(file.exists(out_f),F,T), quote = F, sep=",")
print("DONE")

end.time <- Sys.time()
time.taken <- end.time - start.time
print(time.taken)
