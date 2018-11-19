tryCatchAdv <- function(expr)
{
  
  # Initial settings
  V <- NA
  S <- "succeeded"
  M <- NA
  
  # Warning handler
  w.handler <- function(w){
    
    # Record information about warning
    S <<- "warning"
    M <<- w
    # <<- is used for assignment outside the function scope (i.e. in the external environment)
    
    # Execute expression again, suppressing warnings
    invokeRestart("muffleWarning")
    
  }
  
  # Error handler
  e.handler <- function(e){
    
    # Record information about error
    S <<- "error"
    M <<- e
    
    # Return NA as result
    return(NA)
    
  }
  
  # Try to execute the expression, use the above handlers
  V <- withCallingHandlers(tryCatch(expr, error=e.handler), warning=w.handler)
  
  # Return value
  list(value = V,
       status = S,
       message = M)
}
