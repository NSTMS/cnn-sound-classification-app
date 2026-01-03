source("config.R")
source("modules/audio_module.R")

load_class_names <- function(metadata_path) {
  metadata <- load_metadata(metadata_path)
  class_mapping <- unique(metadata[, c("classID", "class")])
  class_mapping <- class_mapping[order(class_mapping$classID), ]
  return(as.character(class_mapping$class))
}

load_metadata <- function(metadata_path) {
  if (!file.exists(metadata_path)) {
    stop("Plik metadanych nie istnieje: ", metadata_path)
  }
  metadata <- read.csv(metadata_path, stringsAsFactors = FALSE)
  return(metadata)
}

load_audio_files <- function() {
  metadata <- load_metadata(paste0(getwd(), "/",  PATHS$metadata))
  audio_files <- list()
  failed_count <- 0
  for (i in 1:nrow(metadata)) {
    audio_sample_data <- process_single_audio_sample(metadata[i, ])
    
    if (!is.null(audio_sample_data)) {
      audio_files[[length(audio_files) + 1]] <- audio_sample_data
    } else {
      failed_count <- failed_count + 1
    }
    
    if (i %% 100 == 0) {
      cat(sprintf("Przetworzono: %d/%d (błędów: %d)\n", i, nrow(metadata), failed_count))
    }
  }
  
  cat(sprintf("\nZakończono! Pomyślnie wczytano: %d/%d plików\n", 
              length(audio_files), nrow(metadata)))
  cat(sprintf("Pominięto błędnych plików: %d\n", failed_count))
  
  return(audio_files)
}

augment_audio_files <- function(audio_files) {
  extended_data <- audio_files
  for (audio_sample in audio_files) {
    # time mask augmentation
    mel_spec_with_time_mask <- augment_spectrogram_with_time_mask(
      audio_sample$mel_spec, 
      AUDIO_CONFIG$time_mask_param
    )
    extended_data[[length(extended_data) + 1]] <- list(
      mel_spec = mel_spec_with_time_mask,
      classID = audio_sample$classID
    )

    # frequency mask augmentation
    mel_spec_with_freq_mask <- augment_spectrogram_with_frequency_mask(
      audio_sample$mel_spec, 
      AUDIO_CONFIG$freq_mask_length
    )
    extended_data[[length(extended_data) + 1]] <- list(
      mel_spec = mel_spec_with_freq_mask,
      classID = audio_sample$classID
    )
  }
  return(extended_data)
}

process_single_audio_sample <- function(row) {
  fold <- row$fold
  filename <- row$slice_file_name
  classID <- row$classID
  audio_sample_path <- paste0(
    PATHS$dataset,
    PATHS$audio,
    "fold",
    fold,
    "/",
    filename
  )
  
  wav <- load_and_resample_audio_sample(audio_sample_path)
  if (is.null(wav)) {
    return(NULL)
  }
  
  mel_spec <- create_tensorized_and_normalized_mel_spectrogram(wav)
  if (is.null(mel_spec)) {
    return(NULL) 
  }

  return(list(
    mel_spec = mel_spec,
    classID = classID
  ))
}