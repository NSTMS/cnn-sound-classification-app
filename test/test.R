source("modules/cnn_modules/predict_class.R")
source("modules/audio_module.R")
source("modules/data_module.R")

model_path <- file.path(getwd(), PATHS$models, "v1", "model_v1.pt")
class_labels <- load_class_names(paste0(getwd(), "/", PATHS$metadata))
test_audio_path <- file.path(getwd(), "test", "dominik.wav")

resampled_wav <- load_and_resample_audio_sample(test_audio_path)
show_mel_spectogram(resampled_wav)
mel_spec <- create_tensorized_and_normalized_mel_spectrogram(resampled_wav)
prediction <- predict_class(model_path, mel_spec, class_labels)
print(prediction)