#' Make GET requests with repeated trials
#'
#' @param url A url, preferably from \code{make_url}
#' @param attempts_left Number of attempts of trying to request from the website
#'
#' @examples
get_resp <- function(url, attempts_left = 5) {
  
  stopifnot(attempts_left > 0)

  resp <- httr::GET(url)

  # Ensure that returned response is application/json
  if (httr::http_type(resp) != "application/json") {
    stop("API did not return json", call. = FALSE)
  }
  # On a successful GET, return the response
  if (httr::status_code(resp) == 200) {
    resp
  } else if (attempts_left == 1) { # When attempts run out, stop with an error
    stop_for_status(resp) # Return appropiate error message
  } else { # Otherwise, sleep a second and try again
    Sys.sleep(2)
    get_resp(url, attempts_left - 1)
  }


}

#' Build a custom url using the httr url class
#'
#' @param query_path the end path of the dataset of interest
#' @param param arguments for a query
#' @param ... any other arguments to building the path correctly. See \code{modify_url}
#'
#' @return
#' @export
#'
#' @examples
make_url <- function(query_path, param = NULL, ...) {
  hostname <- "datos.gob.es/apidata/catalog/dataset"
  
  # We could simply just paste together the URL
  # but `httr` has better handling for
  # character vectors of class url
  # that deal with the structure of URL's
  # more properly than I would know.
  semi_url <-
    structure(
      list(
        scheme = "http",
        hostname = hostname,
        path = query_path,
        query = param,
        ...),
      class = "url"
    )
  
  build_url(semi_url)
}

# Example:
url <- make_url(query_path = "theme/sector-publico", param = list('_pageSize' = 50, '_page' = 1))
resp <- get_resp(url)



#' Function to get datasets related to specified topic
#'
#' @param topic Related topic
#'
#' @return
#' @export
#'
#' @examples

# This function is a draft and it could be generalized. Instead of topic we could use it for retrieve the
# datasets by id, title, format, keyword, etc
# We also have to deal with pagination (see "Pagination" on https://cran.r-project.org/web/packages/httr/vignettes/api-packages.html).
# For now only retrieves 50 first results descendly sorted by date and title
get_topics <- function(topic) {

  url <- make_url(query_path = paste0("theme/", topic), param = list('_sort' = '-issued,title', '_pageSize' = 50, '_page' = 1))
  response <- get_resp(url)

  # Parse the response obtained with get_resp
  cont <- content(response, as = "parsed")

  # All items has the same root
  items <- cont$result$items

  # Create empty dataframe with returned info
  df <- data.frame(
    title = character(),
    desc = character(),
    about = character(),
    last_modified = character(),
    stringsAsFactors = FALSE
  )

  # Loop to populate previous dataframe.
  # If information is not provided, it will be filled with NAs
  # (THINK HOW TO IMPROVE THIS CODE. IT WORKS BUT I DON'T LIKE THE SYNTAX)
  for (i in 1:length(items)){
    df[i,1] <- ifelse(length(items[[i]]$title[[1]]) > 0, items[[i]]$title[[1]], NA)
    df[i,2] <- ifelse(length(items[[i]]$description[[1]]$`_value`[[1]]) > 0, items[[i]]$description[[1]]$`_value`[[1]], NA)
    df[i,3] <- ifelse(length(items[[i]]$`_about`[[1]]) > 0, items[[i]]$`_about`[[1]], NA)
    df[i,4] <- ifelse(length(items[[i]]$modified[[1]]) > 0, items[[i]]$modified[[1]], NA)
  }

  return(df)


}
