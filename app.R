source("config.R")
source("modules/data_module.R")
source("modules/cnn_module.R")

data <- load_audio_files()
# Autor biblioteki torchaudio nie zaimplementował jeszcze funkcjonalności potrzebnych do realizacji augmentacji, funkcja augment_audio_files będzie zwracała błąd: not_implemented_error()
# diversed_data <- augment_audio_files(data)

model <- train_model(data) # zwraca model i zestaw ewaluacyjny
evaluation <- evaluate_model(model$model, model$eval_data)





