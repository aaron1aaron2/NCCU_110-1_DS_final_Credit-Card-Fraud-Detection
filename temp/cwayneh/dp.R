file <- '../creditcard.csv'
dataset <- read.csv(file, header = TRUE)
summary(dataset)
str(dataset)
dataset[is.na(dataset)]
hist(dataset$Class)
summary(dataset$Amount)
hist(dataset$Time)
hist(dataset$Time[dataset$Class==1])
hist(dataset$Time[dataset$Amount==0])
hist(dataset$Time[dataset$Amount==0&dataset$Class==1])
cor(dataset$Time,dataset$Amount)
cor(dataset$Amount,dataset$Class)
cor(dataset$Time,dataset$Class)

for (i in 1:ncol(dataset)) {
  ccor <- c(paste0(colnames(dataset)[i],":"))
  for (j in 1:ncol(dataset)) {
    ccor <- c(ccor,
              paste0("(",colnames(dataset)[j],",",
                     cor(dataset[,i],dataset[,j],method = "pearson"),")"))
  }
  print(ccor)
}
table(time=dataset$Time,class=dataset$Class)
table(time=dataset$Class,class=dataset$Amount)

f <- dataset[dataset$Class==1,]
nf <- dataset[!dataset$Class==1,]
foldn <- 8
smp1 <- sample(foldn,nrow(f),replace = TRUE,prob = NULL)
smp2 <- sample(foldn,nrow(nf),replace = TRUE,prob = NULL)
cacu <- c()
cpcn <- c()
crcl <- c()
cf1 <- c()
require(rpart)
start.time <- Sys.time()
for (i in 1:foldn) {
  train <- rbind(f[smp1!=i,],nf[smp2!=i,])
  valid <- rbind(f[smp1==i,],nf[smp2==i,])
  model_v <- rpart(train$Class~., train)
  pred_v <- predict(model_v, valid)
  cm_v <- table(truth=valid$Class, pred=round(pred_v,0))
  precision <- diag(cm_v) / colSums(cm_v)
  recall <- diag(cm_v) / rowSums(cm_v)
  f1 <- ifelse(precision + recall == 0, 0, 2 * precision * recall / (precision + recall))
  f1[is.na(f1)] <- 0
  acu_v <- round(sum(diag(cm_v))/sum(cm_v),8)
  cacu <- c(cacu,acu_v)
  cpcn <- c(cpcn,precision)
  crcl <- c(crcl,recall)
  cf1 <- c(cf1,f1)
}
end.time <- Sys.time()
time.taken <- end.time - start.time
print(time.taken)
cacu
cpcn
crcl
cf1
cm_v
#random guess
nrow(f)
nrow(nf)
