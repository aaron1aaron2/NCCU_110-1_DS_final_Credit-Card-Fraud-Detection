# use splited dataset from Ho
file1 <- 'train.csv'
file2 <- 'test.csv'
train <- read.csv(file1, header = TRUE)
test <- read.csv(file2, header = TRUE)
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
table(time=train$Time,class=train$Class)
table(time=train$Class,class=train$Amount)

f <- train[train$Class==1,]
nf <- train[!train$Class==1,]
foldn <- 6
smp1 <- sample(foldn,nrow(f),replace = TRUE,prob = NULL)
smp2 <- sample(foldn,nrow(nf),replace = TRUE,prob = NULL)
smp2 <- sample(foldn,nrow(f),replace = TRUE,prob = NULL)
a <- sample(round(224500/6,0),nrow(nf),replace = TRUE)


cacu <- c()
cpcn <- c()
crcl <- c()
cf1 <- c()
require(rpart)
start.time <- Sys.time()
for (i in 1:foldn) {
  train_v <- rbind(f[smp1!=i,],nf[smp2!=i,])
  valid <- rbind(f[smp1==i,],nf[smp2==i,])
  model_v <- rpart(train_v$Class~., train_v)
  pred_v <- predict(model_v, valid)
  cm_v <- table(truth=valid$Class, pred=round(pred_v,0))
  precision <- diag(cm_v) / colSums(cm_v)
  recall <- diag(cm_v) / rowSums(cm_v)
  f1 <- ifelse(precision + recall == 0, 0, 2 * precision * recall / (precision + recall))
  f1[is.na(f1)] <- 0
  acu_v <- round(sum(diag(cm_v))/sum(cm_v),8)
  cacu <- c(cacu,acu_v)
  cpcn <- c(cpcn,precision)
  crcl <- c(crcl,recall[2])
  cf1 <- c(cf1,f1)
  print(crcl)
}
end.time <- Sys.time()
time.taken <- end.time - start.time
print(time.taken)
cacu
cpcn
crcl
cf1
cm_v
train_t <- rbind(f[smp1!=which.max(crcl),],nf[smp2!=which.max(crcl),])
model_t <- rpart(train_t$Class~., train_t)
pred_t <- predict(model_t, test)
cm_t <- table(truth=test$Class, pred=round(pred_t,0))
recall <- diag(cm_t) / rowSums(cm_t)
recall
#random guess
nrow(f)
nrow(nf)