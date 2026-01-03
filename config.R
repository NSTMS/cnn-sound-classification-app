AUDIO_CONFIG <- list(
  sample_rate = 44100, 
  duration = 4, 
  units = "seconds",
  n_mels = 128, # liczba mel-filtrów, 128 jest odpowiednie dla dźwięków środowiskowych, optymalnie szybki trening CNN
  n_fft = 2048, # rozmiar okna FFT
  hop_length = 512, # co ile przesuwa się okno FFT
  fmin = 0,
  fmax = 22050, # sample_rate / 2
  freq_mask_length = 80, # maksymalna długość maski dla augmentacji spektrogramu
  time_mask_param = 80 # współczynnik przyspieszenia/zwolnienia dla augmentacji spektrogramu
)

MODEL_CONFIG <- list(
  img_height = 128,           # n_mels
  img_width = 345,            # floor(sample_rate * duration / hop_length) + 1 + padding w CNN(2*2)
  num_classes = 10,           
  batch_size = 32,
  epochs = 50,                 
  learning_rate = 0.0001
)

PATHS <- list(
  dataset = "dataset/",
  audio = "audio/",
  metadata = "dataset/metadata.csv",
  models = "models"
)