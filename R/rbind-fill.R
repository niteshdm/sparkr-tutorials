#########################
## rbind.fill Function ##
#########################
# Sarah Armstrong, Urban Institute
# July 14, 2016

# Summary: Function that allows us to append rows of one SparkR DataFrame (DF) to another, regardless of the column names for each DF. If one DF contains columns not included in the other, that column is appended onto the first DF and the entries are set equal to null values.

# Inputs: x (a DF) and y (another DF)
# Returns: DataFrame

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