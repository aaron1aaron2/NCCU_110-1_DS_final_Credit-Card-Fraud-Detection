df <- read.csv('./data/raw/creditcard.csv')


# 訓練與測試資料切割 ===========================================
# 這次資料為時間序列，會按照時間順序去切，不隨機
# df <- df[sample(nrow(df)), ] #sample rows 

## 切法一: 造比例切 ##
bound <- floor((nrow(df)/10)*8) #define % of training and test set


df.train <- df[1:bound, ] # Time: 0 ~ 145247 -> 40 小時 20 分鐘 | Class 比例 -> 0.00183

df.test <- df[(bound+1):nrow(df), ] # Time: 145248 ~ 172792 -> 7 小時 40 分鐘 | Class 比例 -> 0.001317

## 切法二:造時間切 ##
df.train <- df[which(df$Time < 144000), ] # 40小時 | Class 比例: 0.001846 
df.test <-df[which(df$Time >= 144000), ] # 8小時 | Class 比例: 0.001285 

write.csv(df.train, './data/train.csv', row.names = FALSE)
write.csv(df.test, './data/test.csv', row.names = FALSE)