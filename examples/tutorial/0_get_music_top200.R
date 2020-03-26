Sys.setenv(SPOTIFY_CLIENT_ID = '528ddf3f2f6f45b5bf1a6009b1153df6')
Sys.setenv(SPOTIFY_CLIENT_SECRET = '3900d0a4ec514e309b82bebdc06137fe')

countries <- c(
  "us", "gb", "ad", "ar", "at", "au", "be",
  "bg", "bo", "br", "ca", "ch", "cl", "co",
  "cr", "cy", "cz", "de", "dk", "do", "ec",
  "ee", "es", "fi", "fr", "gr", "gk", "hk",
  "hn", "hu", "id", "ie", "il", "in", "is",
  "it", "jp", "lt", "lu", "lv", "mc", "mt",
  "mx", "my", "ni", "nl", "no", "nz", "pa",
  "pe", "ph", "pl", "pt", "py", "ro", "se",
  "sg", "sk", "sv", "th", "tr", "tw", "uy",
  "vn", "za"
)
library(glue)
library(readr)
out <- list()

for (country in countries) {
  Sys.sleep(.1)
  tryCatch({
    out[[country]] <- read_csv(
      url(glue("https://spotifycharts.com/regional/{country}/weekly/latest/download")),
      skip = 1
      )
  },
  error = function(e) e
  )
}

song_links_raw <-
  bind_rows(out, .id = 'country_code') %>%
  select(-`<html>`)

# monaco missing song_links
song_links_raw %>%
  group_by(country_code) %>%
  summarize(n_missing = sum(is.na(`Track Name`))) %>%
  arrange(desc(n_missing))

song_links <-
  song_links_raw %>%
  filter(country_code != "mc") %>%
  mutate(track_id = str_split(URL, 'track/', simplify = TRUE)[,2]) %>%
  select(-URL) %>%
  rename_all(~tolower(gsub(" ", "_", .)))


track_ids <-
  song_links %>%
  pull(track_id) %>% unique()

track_id_chunks <- split(track_ids, ceiling(seq_along(track_ids) / 100))
track_features <- map_df(track_id_chunks, slowly(get_track_audio_features, rate = rate_delay(2)))

## final dataset
library(ISOcodes)

country_names <-
  ISOcodes::ISO_3166_1 %>%
  transmute(country_code = tolower(Alpha_2), country = Name)

music_top200 <-
  song_links %>%
  left_join(track_features, c(track_id = "id")) %>%
  inner_join(country_names, "country_code")
