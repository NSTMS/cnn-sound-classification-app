library(seewave)
library(tuneR)
library(torchaudio)
source("config.R")

load_and_resample_audio_sample <- function(audio_sample_path) {
  tryCatch(
    {
      wav <- readWave(
        audio_sample_path,
        from = 0,
        to = AUDIO_CONFIG$duration,
        units = AUDIO_CONFIG$units,
        header = FALSE,
        toWaveMC = NULL
      )

      if (inherits(wav, "WaveMC")) {
        first_channel <- wav@.Data[, 1]
        wav <- Wave(
          left = first_channel,
          samp.rate = wav@samp.rate,
          bit = wav@bit
        )
      } else if (inherits(wav, "Wave")) {
        if (wav@stereo) {
          wav <- mono(wav, which = "both")
        }
      }
      
      wav <- resample_audio_sample(wav)
      wav <- normalize_audio_sample_length(wav)
      return(wav)
    },
    error = function(e) {
      cat("Błąd przy wczytywaniu pliku:", audio_sample_path, "-", e$message, "\n")
      return(NULL)
    }
  )
}

normalize_audio_sample_length <- function(audio_sample) {
  if (is.null(audio_sample)) return(NULL)
  
  tryCatch(
    {
      target_duration <- AUDIO_CONFIG$duration
      target_length <- AUDIO_CONFIG$sample_rate * target_duration
      
      if (inherits(audio_sample, "Wave")) {
        current_data <- audio_sample@left
      } else {
        cat("Nieoczekiwany typ obiektu audio\n")
        return(NULL)
      }
      
      current_length <- length(current_data)
      difference <- target_length - current_length
      
      if (difference > 0) {
        # dopełnianie zerami 
        padding <- rep(0, difference)
        audio_sample@left <- c(current_data, padding)
      } else if (difference < 0) {
        # przycinanie
        audio_sample@left <- current_data[1:target_length]
      }
      
      return(audio_sample)
    },
    error = function(e) {
      cat("Błąd przy normalizacji długości:", e$message, "\n")
      return(NULL)
    }
  )
}

resample_audio_sample <- function(audio_sample) {
  if (is.null(audio_sample)) return(NULL)
  
  tryCatch(
    {
      if (!is.na(audio_sample@samp.rate) &&
          audio_sample@samp.rate != AUDIO_CONFIG$sample_rate) {
        resample_wav <- resamp(
          audio_sample,
          f = audio_sample@samp.rate,
          g = AUDIO_CONFIG$sample_rate,
          output = "Wave"
        )
        return(resample_wav)
      }
      return(audio_sample)
    },
    error = function(e) {
      cat("Błąd przy próbie resamplingu:", e$message, "\n")
      return(NULL)
    }
  )
}

augment_spectrogram_with_time_mask <- function(mel_spec, time_mask_rate) {
  time_mask <- torchaudio::transform_timemasking(time_mask_param = time_mask_rate)
  time_masked_spectogram <- time_mask(mel_spec)
  return(time_masked_spectogram)
}

augment_spectrogram_with_frequency_mask <- function(mel_spec, mask_length) {
  freq_mask <- torchaudio::transform_frequencymasking(freq_mask_param = mask_length)
  frequency_masked_spectrogram <- freq_mask(mel_spec)
  return(frequency_masked_spectrogram)
}

mel_spectrogram_transformer <- torchaudio::transform_mel_spectrogram(
  sample_rate = AUDIO_CONFIG$sample_rate,
  n_mels = AUDIO_CONFIG$n_mels,
  n_fft = AUDIO_CONFIG$n_fft,
  hop_length = AUDIO_CONFIG$hop_length,
  f_min = AUDIO_CONFIG$fmin,
  f_max = AUDIO_CONFIG$fmax
)

create_tensorized_and_normalized_mel_spectrogram <- function(audio_sample) {
  if (is.null(audio_sample)) return(NULL)
  
  tryCatch(
    {
      if (!inherits(audio_sample, "Wave") || is.null(audio_sample@left)) {
        cat("Nieprawidłowy obiekt audio\n")
        return(NULL)
      }
      
      waveform <- torch::torch_tensor(
        audio_sample@left,
        dtype = torch::torch_float()
      )
      
      mel_spectogram <- mel_spectrogram_transformer(waveform)     
      mel_spectogram <- torch_log(mel_spectogram + 1e-9)
      mel_spectogram <- (mel_spectogram - mel_spectogram$mean()) / (mel_spectogram$std() + 1e-9)
      
      return(mel_spectogram)
    },
    error = function(e) {
      cat("Błąd przy tworzeniu mel-spektrogramu:", e$message, "\n")
      return(NULL)
    }
  )
}


create_mel_spectogram <- function(audio_sample) {
  if (is.null(audio_sample)) return(NULL)
  tryCatch(
    {
      if (!inherits(audio_sample, "Wave") || is.null(audio_sample@left)) {
        cat("Nieprawidłowy obiekt audio\n")
        return(NULL)
      }
      
      waveform <- torch::torch_tensor(
        audio_sample@left,
        dtype = torch::torch_float()
      )
      
      mel_spectogram <- mel_spectrogram_transformer(waveform)     
      return(mel_spectogram)
    },
    error = function(e) {
      cat("Błąd przy tworzeniu mel-spektrogramu:", e$message, "\n")
      return(NULL)
    }
  )
}

show_mel_spectogram <- function(wav) {
  spectro(
    wav,
    f = wav@samp.rate,
    collevels = seq(-100, -15, 5),
    palette = get_random_seewave_color_pallette()
  )
}

get_random_seewave_color_pallette <- function() {
  return(sample(
    list(
      temp.colors,
      reverse.gray.colors.1,
      reverse.gray.colors.2,
      reverse.heat.colors,
      reverse.terrain.colors,
      reverse.topo.colors,
      reverse.cm.colors,
      heat.colors,
      terrain.colors,
      topo.colors,
      cm.colors
    ), 1)[[1]])
}