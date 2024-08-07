#' Delete documents or container
#'
#' @inheritParams docdb_create
#'
#' @param ... Optionally, specify \code{query} parameter with a
#' JSON string as per [docdb_query()] to identify documents to be deleted.
#' If not specified (default), deletes the container \code{key}.
#'
#' @return (logical) Success of operation. Typically \code{TRUE} if
#' document(s) or collection existed, and \code{FALSE} if document(s)
#' did not exist, or collection did not exist, or delete was not successful.
#'
#' @export
#'
#' @examples \dontrun{
#' src <- src_sqlite()
#' docdb_create(src, "iris", iris)
#' docdb_delete(src, "iris", query = '{"Species": {"$regex": "a$"}}')
#' docdb_delete(src, "iris")
#' }
docdb_delete <- function(src, key, ...) {
  assert(src, "docdb_src")
  assert(key, "character")
  UseMethod("docdb_delete", src)
}

#' @export
docdb_delete.src_couchdb <- function(src, key, ...) {

  params <- list(...)

  if (!is.null(params[["query"]])) {

    # get relevant doc _id's
    ids <- docdb_query(src, key, query = params[["query"]], fields = '{"_id": 1}')
    if (!length(ids)) return(FALSE)

    # delete by doc _id's
    ids <- ids[, "_id", drop = TRUE]
    params[["query"]] <- NULL
    result <- lapply(ids, function(i)
      try(
        do.call(
          sofa::doc_delete,
          c(list(
            cushion = src$con,
            dbname = key,
            docid = i,
            as = "list"),
            params)),
        silent = TRUE)
    ) # lapply

  } else {

    # delete database
    result <- try(sofa::db_delete(
      src$con, dbname = key, as = "list", ...), silent = TRUE)
  }

  # prepare return value
  result <- unlist(result)
  result <- result[names(result) == "ok"] == "TRUE"
  return(!inherits(result, "try-error") && length(result))
}

#' @export
docdb_delete.src_elastic <- function(src, key, ...) {

  params <- list(...)

  if (!is.null(params[["query"]])) {

    # get docids to be deleted
    docids <- docdb_query(
      src, key, query = params[["query"]],
      fields = '{"_id": 1}')[, "_id", drop = TRUE]

    # early exit
    if (!length(docids)) return(FALSE)

    # delete document(s) if any

    result <- sapply(docids, function(i) {

      out <- try(elastic::docs_delete(
        conn = src$con,
        index = key,
        refresh = 'true',
        id = i), silent = TRUE)

      if (inherits(out, "try-error")) {
        FALSE
      } else {
        any(out[["result"]] == "deleted")
      }

    }, USE.NAMES = FALSE, simplify = TRUE)

    result <- any(result)

  } else {

    # delete collection
    result <- try(elastic::index_delete(src$con, key, verbose = FALSE), silent = TRUE)
    result <- !inherits(result, "try-error") && result[["acknowledged"]] == TRUE

  }

  return(as.logical(result))
}

#' @export
docdb_delete.src_mongo <- function(src, key, ...) {

  params <- list(...)
  if (!is.null(params$query)) {
    # count document(s)
    result <- src$con$count(
      query = params$query)
    # delete document(s) if any
    if (result) result <- src$con$remove(
      query = params$query,
      just_one = FALSE)
  } else {
    # delete collection with metadata
    before <- any(key == docdb_list(src = src)) &
      docdb_exists(src = src, key = key)
    if (!before) return(FALSE)
    src$con$drop()
    after <- any(key == docdb_list(src = src)) &
      docdb_exists(src = src, key = key)
    result <- before & !after
  }
  return(as.logical(result))
}

#' @export
docdb_delete.src_sqlite <- function(src, key, ...) {
  return(sqlDelete(src = src, key = key, ...))
}

#' @export
docdb_delete.src_postgres <- function(src, key, ...) {
  return(sqlDelete(src = src, key = key, ...))
}

#' @export
docdb_delete.src_duckdb <- function(src, key, ...) {
  return(sqlDelete(src = src, key = key, ...))
}

## helpers --------------------------------------

#' @keywords internal
#' @noRd
sqlDelete <- function(src, key, ...) {

  # make dotted parameters accessible
  tmpdots <- list(...)

  # if valid query, delete document(s), not table
  if (!is.null(tmpdots$query)) {

    # get _id's of document(s) to be deleted
    tmpids <- docdb_query(
      src = src,
      key = key,
      query = tmpdots$query,
      fields = '{"_id": 1}')[["_id"]]

    # document delete
    statement <- paste0(
      "DELETE FROM \"", key, "\" WHERE _id IN (",
      paste0("'", tmpids, "'", collapse = ","), ");")

    # do delete
    return(
      docdb_exists(src, key) &&
        as.logical(
          DBI::dbWithTransaction(
            conn = src$con,
            code = {
              DBI::dbExecute(
                conn = src$con,
                statement = statement)
            })))

  } else {

    return(
      docdb_exists(src, key) &&
        # remove table
        as.logical(
          DBI::dbWithTransaction(
            conn = src$con,
            code = {
              DBI::dbRemoveTable(
                conn = src$con,
                name = key)
            })))

  }

}
