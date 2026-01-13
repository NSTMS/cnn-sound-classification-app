install.packages("seewave")
install.packages("tuneR")
install.packages("torch")
install.packages("coro")
install.packages("shiny")
install.packages("bslib")
install.packages("ggplot2")
install.packages("remotes")
remotes::install_github("mlverse/torchaudio", force=T)
torch::install_torch(force=T)


torch::torch_is_installed()
# update.packages(checkBuilt=TRUE)
