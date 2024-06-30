## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(nodbi)

## -----------------------------------------------------------------------------
# name of container
key <- "my_container"

# nodbi can connect any of these databases
if (FALSE) {
  src <- src_duckdb()
  src <- src_mongo(collection = key)
  src <- src_sqlite()
  src <- src_postgres()
  src <- src_elastic()
  src <- src_couchdb(
    user = Sys.getenv("COUCHDB_TEST_USER"),
    pwd = Sys.getenv("COUCHDB_TEST_PWD")
  )
}

# this example is run with
src <- src_sqlite()

# note additional parameters can be specified,
# for example for local or remote MongoDb:
help("src_mongo")

## -----------------------------------------------------------------------------
# check if container already exists
docdb_exists(src = src, key = key)

# load data from a data frame with row names into
# the container specified in "key" parameter
docdb_create(src = src, key = key, value = mtcars)

# load additionally 98 NDJSON records
docdb_create(src, key, "https://httpbin.org/stream/98")

# load additionally mapdata as list
docdb_create(src, key, jsonlite::fromJSON(mapdata, simplifyVector = FALSE))

# show JSON structure of contacts
jsonlite::minify(contacts)

# load additionally contacts JSON data
docdb_create(src, key, contacts)

## -----------------------------------------------------------------------------
docdb_list(src = src)

## -----------------------------------------------------------------------------
# zero new documents created
docdb_create(src, key, value = mtcars)

## -----------------------------------------------------------------------------
# load library for more
# readable print output
library(tibble)

# get all documents, irrespective of schema
as_tibble(docdb_get(src, key))

# get just 2 documents using limit and note that
# only fields for these documents are returned
as_tibble(docdb_get(src, key, limit = 2L))

## -----------------------------------------------------------------------------
# query for some documents
docdb_query(src = src, key = key, query = '{"mpg": {"$gte": 30}}')

## -----------------------------------------------------------------------------
# query some fields from some documents; 'query' is a mandatory
# parameter and is used here in its position in the signature
docdb_query(src, key, '{"mpg": {"$gte": 30}}', fields = '{"wt": 1, "mpg": 1}')

## -----------------------------------------------------------------------------
# query some fields from some documents, limit return to one document
docdb_query(src, key, '{"mpg": {"$gte": 30}}', fields = '{"_id": 0, "mpg": 1}', limit = 1L)

## -----------------------------------------------------------------------------
# query some subitem fields from some documents
str(docdb_query(
  src, key,
  query = '{"$or": [{"age": {"$gt": 21}},
           {"friends.name": {"$regex": "^B[a-z]{3,9}.*"}}]}',
  fields = '{"age": 1, "friends.name": 1}'
))

## -----------------------------------------------------------------------------
# query with results across documents
docdb_query(
  src, key,
  query = '{"$or": [{"age": {"$gt": 21}}, {"mpg": {"$gte": 30}}]}',
  fields = '{"name": 1, "disp": 1}'
)

## -----------------------------------------------------------------------------
docdb_query(src, key, query = '{"_id": {"$regex": "^[0-9]"}}', listfields = TRUE)

## -----------------------------------------------------------------------------
# number of documents corresponding to query
nrow(docdb_query(src, key, query = '{"carb": 3}'))

# update all documents using JSON, replacing the previously existing values
docdb_update(src, key, value = '{"vs": 9, "xy": [1, 2]}', query = '{"carb": 3}')

# update with value that includes _id's
docdb_update(src, key, value = '{"_id": "Merc 450SLC", "xy": 33}', query = "{}")

# show updated values
docdb_query(src, key, query = '{"carb": 3}', fields = '{"xy": 1}')

## -----------------------------------------------------------------------------
# number of documents corresponding to query
nrow(docdb_query(src, key, query = '{"age": {"$lte": 23}}'))

# to delete selected documents, specify a query parameter
docdb_delete(src, key, query = '{"age": {"$lte": 23}}')

# this deletes the complete container from database
docdb_delete(src, key)

# check if still exists
docdb_exists(src, key)

## -----------------------------------------------------------------------------
src

# shutdown
DBI::dbDisconnect(src$con, shutdown = TRUE)
rm(src)

