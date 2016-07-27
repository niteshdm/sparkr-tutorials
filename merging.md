# Merging SparkR DataFrames
Sarah Armstrong, Urban Institute  
July 12, 2016  




**Objective**: The following tutorial provides an overview of how to join SparkR DataFrames by column and by row. In particular, we discuss how to:

* Merge two DFs by column condition(s) (join by row)
* Append rows of data to a DataFrame (join by column)
    + When column name lists are equal across DFs
    + When column name lists are not equal

**SparkR/R Operations Discussed**: `join`, `merge`, `sample`, `except`, `intersect`, `rbind`, `rbind.intersect` (defined function), `rbind.fill` (defined function)

***

<span style="color:red">**Warning**</span>: Before beginning this tutorial, please visit the SparkR Tutorials README file (found [here](https://github.com/UrbanInstitute/sparkr-tutorials/blob/master/README.md)) in order to load the SparkR library and subsequently initiate your SparkR and SparkR SQL contexts.



You can confirm that you successfully initiated these contexts by looking at the global environment of RStudio. Only proceed if you can see `sc` and `sqlContext` listed as values in the global environment or RStudio.

***

**Read in initial data as DF**: Throughout this tutorial, we will use the loan performance example dataset that we exported at the conclusion of the SparkR Basics I tutorial.


```r
df <- read.df(sqlContext, "s3://sparkr-tutorials/hfpc_ex", header='false', inferSchema='true')
cache(df)
```

_Note_: documentation for the quarterly loan performance data can be found at http://www.fanniemae.com/portal/funding-the-market/data/loan-performance-data.html.

***


### Join (merge) two DataFrames by column condition(s):

We begin by subsetting `df` by column, resulting in two (2) DataFrames that are disjoint, except for them both including the loan identification variable, `"loan_id"`:


```r
# Print the column names of df:
columns(df)
##  [1] "loan_id"       "period"        "servicer_name" "new_int_rt"   
##  [5] "act_endg_upb"  "loan_age"      "mths_remng"    "aj_mths_remng"
##  [9] "dt_matr"       "cd_msa"        "delq_sts"      "flag_mod"     
## [13] "cd_zero_bal"   "dt_zero_bal"

# Specify column lists to fit `a` and `b` on - these are disjoint sets (except for "loan_id"):
cols_a <- c("loan_id", "period", "servicer_name", "new_int_rt", "act_endg_upb", "loan_age", "mths_remng")
cols_b <- c("loan_id", "aj_mths_remng", "dt_matr", "cd_msa", "delq_sts", "flag_mod", "cd_zero_bal", "dt_zero_bal")

# Create `a` and `b` DFs with the `select` operation:
a <- select(df, cols_a)
b <- select(df, cols_b)

# Print several rows from each subsetted DF:
str(a)
## 'DataFrame': 7 variables:
##  $ loan_id      : num 100007365142 100007365142 100007365142 100007365142 100007365142 100007365142
##  $ period       : chr "01/01/2000" "02/01/2000" "03/01/2000" "04/01/2000" "05/01/2000" "06/01/2000"
##  $ servicer_name: chr "" "" "" "" "" ""
##  $ new_int_rt   : num 8 8 8 8 8 8
##  $ act_endg_upb : num NA NA NA NA NA NA
##  $ loan_age     : int 0 1 2 3 4 5
##  $ mths_remng   : int 360 359 358 357 356 355
str(b)
## 'DataFrame': 8 variables:
##  $ loan_id      : num 100007365142 100007365142 100007365142 100007365142 100007365142 100007365142
##  $ aj_mths_remng: int 359 358 357 356 355 355
##  $ dt_matr      : chr "01/2030" "01/2030" "01/2030" "01/2030" "01/2030" "01/2030"
##  $ cd_msa       : int 0 0 0 0 0 0
##  $ delq_sts     : chr "0" "0" "0" "0" "0" "0"
##  $ flag_mod     : chr "N" "N" "N" "N" "N" "N"
##  $ cd_zero_bal  : int NA NA NA NA NA NA
##  $ dt_zero_bal  : chr "" "" "" "" "" ""
```

We can use the SparkR operation `join` to merge `a` and `b` by row, returning a DataFrame equivalent to `df`. The `join` operation allows us to perform most SQL join types on SparkR DFs, including:

* `"inner"` (default): Returns rows where there is a match in both DFs
* `"outer"`: Returns rows where there is a match in both DFs, as well as rows in both the right and left DF where there was no match
* `"full"`, `"fullouter"`: Returns rows where there is a match in one of the DFs
* `"left"`, `"leftouter"`, `"left_outer"`: Returns all rows from the left DF, even if there are no matches in the right DF
* `"right"`, `"rightouter"`, `"right_outer"`: Returns all rows from the right DF, even if there are no matches in the left DF
* Cartesian: Returns the Cartesian product of the sets of records from the two or more joined DFs - `join` will return this DF when we _do not_ specify a `joinType` _nor_ a `joinExpr` (discussed below)

We communicate to SparkR what condition we want to join DFs on with the `joinExpr` specification in `join`. Below, we perform a `"fullouter"` join on the DFs `a` and `b` on the condition that their `"loan_id"` values be equal:


```r
ab1 <- join(a, b, a$loan_id == b$loan_id, "fullouter")
str(ab1)
## 'DataFrame': 15 variables:
##  $ loan_id      : num 100272527248 100272527248 100272527248 100272527248 100272527248 100272527248
##  $ period       : chr "01/01/2000" "01/01/2000" "01/01/2000" "01/01/2000" "01/01/2000" "01/01/2000"
##  $ servicer_name: chr "" "" "" "" "" ""
##  $ new_int_rt   : num 7.75 7.75 7.75 7.75 7.75 7.75
##  $ act_endg_upb : num NA NA NA NA NA NA
##  $ loan_age     : int 0 0 0 0 0 0
##  $ mths_remng   : int 360 360 360 360 360 360
##  $ loan_id      : num 100272527248 100272527248 100272527248 100272527248 100272527248 100272527248
##  $ aj_mths_remng: int 359 358 358 357 356 355
##  $ dt_matr      : chr "01/2030" "01/2030" "01/2030" "01/2030" "01/2030" "01/2030"
##  $ cd_msa       : int 0 0 0 0 0 0
##  $ delq_sts     : chr "0" "0" "0" "0" "0" "0"
##  $ flag_mod     : chr "N" "N" "N" "N" "N" "N"
##  $ cd_zero_bal  : int NA NA NA NA NA NA
##  $ dt_zero_bal  : chr "" "" "" "" "" ""
```

Note that the resulting DF includes two (2) `"loan_id"` columns. Unfortunately, we cannot direct SparkR to keep only one of these columns when using `join` to merge by row, and the following command (which we introduced in the subsetting tutorial) drops both `"loan_id"` columns:


```r
ab1$loan_id <- NULL
```

We can avoid this by renaming one of the columns before performing `join` and then, utilizing that the columns have distinct names, tell SparkR to drop only one of the columns. For example, we could rename `"loan_id"` in `a` with the expression `a <- withColumnRenamed(a, "loan_id", "loan_id_")`, then drop this column with `ab1$loan_id_ <- NULL` after performing `join` on `a` and `b` to return `ab1`.


The `merge` operation, alternatively, allows us to join DFs and also produces two (2) distinct merge columns. We can use this feature to retain the column on which we joined the DFs, but we must still perform a `withColumnRenamed` step if we want our merge column to retain its original column name.


Rather than defining a `joinExpr`, we explictly specify the column(s) that SparkR should `merge` the DFs on with the operation parameters `by` and `by.x`/`by.y`. Note that, if we do not specify `by`, SparkR will merge the DFs on the list of common column names shared by the DFs. Rather than specifying a type of join, `merge` determines how SparkR should merge DFs based on boolean values, `all.x` and `all.y`, which indicate which rows in `x` and `y` should be included in the join, respectively. We can specify `merge` type with the following parameter values:

* `all.x = FALSE`, `all.y = FALSE`: Returns an inner join (this is the default and can be achieved by not specifying values for all.x and all.y)
* `all.x = TRUE`, `all.y = FALSE`: Returns a left outer join
* `all.x = FALSE`, `all.y = TRUE`: Returns a right outer join
* `all.x = TRUE`, `all.y = TRUE`: Returns a full outer join

The following `merge` expression is equivalent to the `join` expression in the preceding example:


```r
ab2 <- merge(a, b, by = "loan_id")
str(ab2)
## 'DataFrame': 15 variables:
##  $ loan_id_x    : num 100004547910 100004547910 100004547910 100004547910 100004547910 100004547910
##  $ period       : chr "05/01/2000" "05/01/2000" "05/01/2000" "05/01/2000" "05/01/2000" "05/01/2000"
##  $ servicer_name: chr "" "" "" "" "" ""
##  $ new_int_rt   : num 8.875 8.875 8.875 8.875 8.875 8.875
##  $ act_endg_upb : num NA NA NA NA NA NA
##  $ loan_age     : int 0 0 0 0 0 0
##  $ mths_remng   : int 360 360 360 360 360 360
##  $ loan_id_y    : num 100004547910 100004547910 100004547910 100004547910 100004547910 100004547910
##  $ aj_mths_remng: int 356 358 357 359 359 354
##  $ dt_matr      : chr "05/2030" "05/2030" "05/2030" "05/2030" "05/2030" "05/2030"
##  $ cd_msa       : int 35840 35840 35840 35840 35840 35840
##  $ delq_sts     : chr "0" "0" "0" "0" "0" "0"
##  $ flag_mod     : chr "N" "N" "N" "N" "N" "N"
##  $ cd_zero_bal  : int NA NA NA NA NA NA
##  $ dt_zero_bal  : chr "" "" "" "" "" ""
```

Note that the two merging columns are distinct as indicated by the `_x` and `_y` column name assignments performed by `merge`. We utilize this distinction in the expressions below to retain a single merge column:


```r
# Drop "loan_id" column from `b`:
ab2$loan_id_y <- NULL

# Rename "loan_id" column from `a`:
ab2 <- withColumnRenamed(ab2, "loan_id_x", "loan_id")

# Final DF with single "loan_id" column:
str(ab2)
## 'DataFrame': 14 variables:
##  $ loan_id      : num 100004547910 100004547910 100004547910 100004547910 100004547910 100004547910
##  $ period       : chr "05/01/2000" "05/01/2000" "05/01/2000" "05/01/2000" "05/01/2000" "05/01/2000"
##  $ servicer_name: chr "" "" "" "" "" ""
##  $ new_int_rt   : num 8.875 8.875 8.875 8.875 8.875 8.875
##  $ act_endg_upb : num NA NA NA NA NA NA
##  $ loan_age     : int 0 0 0 0 0 0
##  $ mths_remng   : int 360 360 360 360 360 360
##  $ aj_mths_remng: int 356 358 357 359 359 354
##  $ dt_matr      : chr "05/2030" "05/2030" "05/2030" "05/2030" "05/2030" "05/2030"
##  $ cd_msa       : int 35840 35840 35840 35840 35840 35840
##  $ delq_sts     : chr "0" "0" "0" "0" "0" "0"
##  $ flag_mod     : chr "N" "N" "N" "N" "N" "N"
##  $ cd_zero_bal  : int NA NA NA NA NA NA
##  $ dt_zero_bal  : chr "" "" "" "" "" ""
```

***


### Append rows of data to a DataFrame:

In order to discuss how we can append the rows of one DF to those of another in SparkR, we must first subset `df` into two (2) distinct DataFrames, `A` and `B`. Below, we define `A` as a random subset of `df` with a row count that is approximately equal to half the size of `nrow(df)`. We use the DF operation `except` to create `B`, which includes every row of `df`, `except` for those included in `A`:


```r
A <- sample(df, withReplacement = FALSE, fraction = 0.5)
B <- except(df, A)
```

Let's also examine the row count for each subsetted row and confirm that `A` and `B` do not share common rows. We can check this with the SparkR operation `intersect`, which performs the intersection set operation on two DFs:


```r
(nA <- nrow(A))
## [1] 6607551
(nB <- nrow(B))
## [1] 6608965
nA + nB # Equal to nrow(df)
## [1] 13216516
nrow(intersect(A, B))
## [1] 0
```

#### Append rows when column name lists are equal across DFs:

If we are certain that the two DFs have equivalent column name lists (with respect to string values and column ordering), then appending the rows of one DF to another is straightforward. Here, we append the rows of `B` to `A` with the `rbind` operation:


```r
df1 <- rbind(A, B)

nrow(df1)
## [1] 13216516
nrow(df)
## [1] 13216516
```

We can see in the results above that `df1` is equivalent to `df`. We could, alternatively, accomplish this with the `unionALL` operation (e.g. `df1 <- unionAll(A, B)`. Note that `unionAll` is not an alias for `rbind` - we can combine any number of DFs with `rbind` while `unionAll` can only consider two (2) DataFrames at a time.




#### Append rows when DF column name lists are not equal:

Before we can discuss appending rows when we do not have column name equivalency, we must first create two DataFrames that have different column names. Let's define a new DataFrame, `B_` that includes every column in `A` and `B`, excluding the column `"loan_age"`:


```r
columns(B)
##  [1] "loan_id"       "period"        "servicer_name" "new_int_rt"   
##  [5] "act_endg_upb"  "loan_age"      "mths_remng"    "aj_mths_remng"
##  [9] "dt_matr"       "cd_msa"        "delq_sts"      "flag_mod"     
## [13] "cd_zero_bal"   "dt_zero_bal"

# Define column name list that has every column in `A` and `B`, except "loan_age":
cols_ <- c("loan_id", "period", "servicer_name", "new_int_rt", "act_endg_upb", "mths_remng", "aj_mths_remng", "dt_matr", "cd_msa", "delq_sts", "flag_mod", "cd_zero_bal", "dt_zero_bal")
# Define subsetted DF:
B_ <- select(B, cols_)
```




We can try to apply SparkR `rbind` operation to append `B_` to `A`, but the following expression will result in the error: `"Union can only be performed on tables with the same number of columns, but the left table has 14 columns and" "the right has 13"`.


```r
df2 <- rbind(A, B_)
```

Two strategies to force SparkR to merge DataFrames with different column name lists are to:

1. Append by an intersection of the column names for each DF, or
2. Use `withColumn` to add columns to DF where they are missing and set each entry in the appended rows of these columns equal to `NA`.

Below is a function, `rbind.intersect`, that accomplishes the first approach. Notice that we simply take an intesection of the column names and ask SparkR to perform `rbind`, considering only this subset of (sorted) column names.


```r
rbind.intersect <- function(x, y) {
  cols <- base::intersect(colnames(x), colnames(y))
  return(SparkR::rbind(x[, sort(cols)], y[, sort(cols)]))
}
```

Here, we append `B_` to `A` using this function and then examine the dimensions of the resulting DF, `df2`, as well as its column names. We can see that, while the row count for `df2` is equal to that for `df`, the DF does not include the `"loan_age"` column (just as we expected!).


```r
df2 <- rbind.intersect(A, B_)
dim(df2)
## [1] 13216516       13
colnames(df2)
##  [1] "act_endg_upb"  "aj_mths_remng" "cd_msa"        "cd_zero_bal"  
##  [5] "delq_sts"      "dt_matr"       "dt_zero_bal"   "flag_mod"     
##  [9] "loan_id"       "mths_remng"    "new_int_rt"    "period"       
## [13] "servicer_name"
```




Accomplishing the second approach is somewhat more involved. The `rbind.fill` function, given below, identifies the outersection of the list of column names for two (2) DataFrames and adds them onto one (1) or both of the DataFrames as needed using `withColumn`:


```r
rbind.fill <- function(x, y) {
  
  m1 <- ncol(x)
  m2 <- ncol(y)
  col_x <- colnames(x)
  col_y <- colnames(y)
  outersect <- function(x, y) {setdiff(union(x, y), intersect(x, y))}
  col_outer <- outersect(col_x, col_y)
  len <- length(col_outer)
  
  if (m2 < m1) {
    for (j in 1:len){
      y <- withColumn(y, col_outer[j], cast(lit(NULL), "double"))
    }
  } else { 
    if (m2 > m1) {
        for (j in 1:len){
          x <- withColumn(x, col_outer[j], cast(lit(NULL), "double"))
        }
      }
    if (m2 == m1 & col_x != col_y) {
      for (j in 1:len){
        x <- withColumn(x, col_outer[j], cast(lit(NULL), "double"))
        y <- withColumn(y, col_outer[j], cast(lit(NULL), "double"))
      }
    } else { }         
  }
  x_sort <- x[,sort(colnames(x))]
  y_sort <- y[,sort(colnames(y))]
  return(SparkR::rbind(x_sort, y_sort))
}
```

We again append `B_` to `A`, this time using the `rbind.fill` function:


```r
df3 <- rbind.fill(A, B_)
```



Now, the row count for `df3` is equal to that for `df` _and_ it includes all fourteen (14) columns included in `df`:


```r
dim(df3)
## [1] 13216516       14
colnames(df3)
##  [1] "act_endg_upb"  "aj_mths_remng" "cd_msa"        "cd_zero_bal"  
##  [5] "delq_sts"      "dt_matr"       "dt_zero_bal"   "flag_mod"     
##  [9] "loan_age"      "loan_id"       "mths_remng"    "new_int_rt"   
## [13] "period"        "servicer_name"
```

We know from the missing data tutorial that `df$loan_age` does not contain any `NA` or `NaN` values. By appending `B_` to `A` with the `rbind.fill` function, therefore, we should have introduced exactly `nrow(B)` many null values in `df2`. We can see that these values are equal below:


```r
nB
## [1] 6608965
count(where(df3, isNull(df3$loan_age)))
## [1] 6608965
```

Documentation for rbind.intersection can be found [here](https://github.com/UrbanInstitute/sparkr-tutorials/blob/master/R/rbind-intersection.R), and [here](https://github.com/UrbanInstitute/sparkr-tutorials/blob/master/R/rbind-fill.R) for rbind.fill.

__End of tutorial__ - Next up is [Insert next tutorial]