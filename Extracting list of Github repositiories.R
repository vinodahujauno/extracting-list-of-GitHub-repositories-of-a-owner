library("ghql")
library("jsonlite")
library(rjsonpath) # use to query JSON file

# Create Token
library("httr")
token <- '6b47115a7b317428fc98931de337a996ca82a2bd' # write your github token
cli <- GraphqlClient$new(
  url = "https://api.github.com/graphql",
  headers = add_headers(Authorization = paste0("Bearer ", token))
)

# Load Schema
cli$load_schema()

# Write you user name for example I have used to get list of all mozila repositiores

username <- "mozilla"  


#Make a Query class object
qry <- Query$new()

# Create query
ghquery <- paste0('{
          repositoryOwner(login:"',username,'") {
                  repositories(first: 100) {
                  pageInfo {
                  hasNextPage
                  endCursor
                  }
                  edges {
                  node {
                  name
                  }
                  }
                  }
                  }
                  }')

qry$query('list', ghquery)
qry
qry$queries$list

# Execute query
listextraction<- cli$exec(qry$queries$list)

# Convert to proper json format
listextraction <- jsonlite::fromJSON(listextraction)

# Extract list from query
List<- data.frame(json_path(listextraction,"$.data.repositoryOwner.repositories.edges.node.name[*]"))

# Find end cursor
endCursor <- json_path(listextraction,"$.data.repositoryOwner.repositories.pageInfo.endCursor[*]")

# Find next page
hasNextPage <- json_path(listextraction,"$.data.repositoryOwner.repositories.pageInfo.hasNextPage[*]")


# Running loop for list extraction
while (hasNextPage==TRUE){
  # Write query for loop
  ghquery <- paste0('{
                    repositoryOwner(login: "',username,'") {
                    repositories(first: 100, after:"',endCursor,'") {
                    pageInfo {
                    hasNextPage
                    endCursor
                    }
                    edges {
                    node {
                    name
                    }
                    }
                    }
                    }
}')
  qry <- Query$new()
  qry$query('list', ghquery)
  qry$queries$list
  listextraction<- cli$exec(qry$queries$list)
  List<- rbind(List, data.frame(json_path(listextraction,"$.data.repositoryOwner.repositories.edges.node.name[*]")))
  endCursor <- json_path(listextraction,"$.data.repositoryOwner.repositories.pageInfo.endCursor[*]")
  hasNextPage <- json_path(listextraction,"$.data.repositoryOwner.repositories.pageInfo.hasNextPage[*]")
  }

# Rename the repository list column
colnames(List)<- "Repository Name"

View(List)

setwd("C:/My Directory") # path to location where you want to save file
write.csv(List, file = "Repository List.csv")
