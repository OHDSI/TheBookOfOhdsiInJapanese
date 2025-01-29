library(httr)
library(stringr)

getGpt4Response <- function(systemPrompt, prompt) {
  json <- jsonlite::toJSON(
    list(
      messages = list(
        list(
          role = "system",
          content = systemPrompt
        ),
        list(
          role = "user",
          content = prompt
        ),
        list(
          role = "assistant",
          content = ""
        )
      )
    ),
    auto_unbox = TRUE
  )

  startTime <- Sys.time()
  response <- POST(
    #url = keyring::key_get("genai_gpt4_32k_endpoint"),
    url = keyring::key_get("genai_gpt4o_endpoint"),
    body = json,
    add_headers("Content-Type" = "application/json",
                "api-key" = keyring::key_get("genai_api_gpt4_key")),
    timeout(6000)
  )
  delta <- Sys.time() - startTime
  message(sprintf("- Generating response took %0.1f %s", delta, attr(delta, "units")))
  result <- content(response, "text", encoding = "UTF-8")
  result <- jsonlite::fromJSON(result)
  text <- result$choices$message$content
  return(text)
}

cutInParts <- function(text, maxCharacters = 10000) {
  sections <- str_split(text, "\n## ")[[1]]
  sections[2:length(sections)] <- paste("##", sections[2:length(sections)])
  parts <- list()     # List to hold the grouped sections
  current_part <- ""  # String to accumulate sections
  current_length <- 0 # Length of the current part

  # Loop over sections and accumulate them into parts
  for (section in sections) {
    section_length <- nchar(section)

    # If adding this section exceeds 10,000 characters, start a new part
    if ((current_length + section_length) > maxCharacters) {
      # Append the current part to the list of parts
      parts <- append(parts, current_part)

      # Reset the current part and length
      current_part <- section
      current_length <- section_length
    } else {
      # Otherwise, add the section to the current part
      if (current_part == "") {
        current_part <- section
      } else {
        current_part <- paste(current_part, section, sep="\n\n")
      }
      current_length <- current_length + section_length
    }
  }

  # Add the final part
  if (nchar(current_part) > 0) {
    parts <- append(parts, current_part)
  }
  return(parts)
}


systemPrompt <- "You are a professional translator of scientific texts. Translate the given chapter of the Book of OHDSI from English to Japanese."
rmdFiles <- list.files("../TheBookOfOhdsi", "*.Rmd")
for (i in 5:length(rmdFiles)) {
  rmdFile <- rmdFiles[i]
  writeLines(sprintf("Translating file %d: %s", i, rmdFile))
  text <- paste(readLines(file.path("../TheBookOfOhdsi", rmdFile)), collapse = "\n")
  parts <- cutInParts(text)
  translation <- list()
  writeLines(sprintf("- Translating in %d parts", length(parts)))
  for (j in seq_along(parts)) {
    translation[[j]] <- getGpt4Response(systemPrompt, parts[[j]])
  }
  translation <- paste(translation, sep = "\n")
  writeLines(translation, rmdFile)
}


# Fix summary blocks -------------------------------------------------------------------------------
# The summary and important blocks require an empty line at the end or the PDF won't build.
add_empty_line_before_final_backticks <- function(fileName) {
  lines <- readLines(fileName)
  inBlock <- FALSE
  i <- 1
  while (i <= length(lines)) {
    if (grepl("^```\\{block2, type='.*'\\}", lines[i])) {
      inBlock <- TRUE
    }
    if (inBlock && grepl("^```$", lines[i])) {
      lines <- append(lines, "", after = i - 1)
      inBlock <- FALSE
      i <- i + 1
    }
    i <- i + 1
  }
  writeLines(lines, fileName)
}

rmdFiles <- list.files(pattern = "*.Rmd")
for (rmdFile in rmdFiles) {
  writeLines(sprintf("Fixing %s", rmdFile))
  add_empty_line_before_final_backticks(rmdFile)
}

# Fix |see link for back of the book index ---------------------------------------------------------
# Index entries tagged as 'see...' where nicely translated to 'voir...', but the 'see' is a special
# LaTeX control sequence.ß
fixSeeLink <- function(fileName) {
  lines <- paste(readLines(fileName), collapse = "\n")
  lines <- gsub("\\|参照", "|see", lines)
  writeLines(lines, fileName)
}

rmdFiles <- list.files(pattern = "*.Rmd")
for (rmdFile in rmdFiles) {
  writeLines(sprintf("Fixing %s", rmdFile))
  fixSeeLink(rmdFile)
}
