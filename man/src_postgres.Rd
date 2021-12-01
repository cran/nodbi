% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/src_postgres.R
\name{src_postgres}
\alias{src_postgres}
\title{Setup a PostgreSQL database connection}
\usage{
src_postgres(dbname = "test", host = "localhost", port = 5432L, ...)
}
\arguments{
\item{dbname}{(character) name of database,
has to exist to open a connection}

\item{host}{(character) host of the database,
see \code{\link[RPostgres:Postgres]{RPostgres::Postgres()}}}

\item{port}{(integer) port of the database,
see \code{\link[RPostgres:Postgres]{RPostgres::Postgres()}}}

\item{...}{additional named parameters passed
on to \code{\link[RPostgres:Postgres]{RPostgres::Postgres()}}}
}
\description{
Setup a PostgreSQL database connection
}
\details{
uses \pkg{RPostgres} under the hood
}
\examples{
\dontrun{
con <- src_postgres()
print(con)
}

}