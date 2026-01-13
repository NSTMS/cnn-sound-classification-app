library(shiny)
library(bslib)
library(shinyFeedback)
library(dplyr)
library(DT)
library(ggplot2)

source("modules/cnn_modules/predict_class.R")
source("modules/audio_module.R")
source("modules/data_module.R")

MODEL_PATH <- file.path(getwd(), PATHS$models, "v1", "model_v1.pt")
CLASS_LABELS <- load_class_names(paste0(getwd(), "/", PATHS$metadata))

theme <- bs_theme(
  version = 5,
  bg = "#FFFFFF",
  fg = "#2C2D30",
  primary = "#C47335",
  secondary = "#6B7280",
  base_font = font_google("Inter"),
  code_font = font_google("Roboto Mono"),
  heading_font = font_google("Inter"),
  font_scale = 0.95,
  "input-bg" = "#F9FAFB",
  "input-border-color" = "#E5E7EB",
  "card-border-color" = "#E5E7EB"
)

css_ <- "
  body {
    background-color: #FAFAFA;
  }
  
  .navbar, .sidebar {
    background-color: #FFFFFF;
    border-right: 1px solid #E5E7EB;
  }
  
  .nav-tabs .nav-link {
    color: #6B7280;
    border: none;
    border-bottom: 2px solid transparent;
    padding: 0.75rem 1.25rem;
    font-weight: 500;
  }
  
  .nav-tabs .nav-link:hover {
    color: #C47335;
    border-bottom-color: #C47335;
  }
  
  .nav-tabs .nav-link.active {
    color: #C47335;
    background-color: transparent;
    border-bottom-color: #C47335;
  }
  
  .card {
    border: 1px solid #E5E7EB;
    border-radius: 12px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.05);
  }
  
  .btn-primary {
    background-color: #C47335;
    border-color: #C47335;
    border-radius: 8px;
    padding: 0.625rem 1.25rem;
    font-weight: 500;
    transition: all 0.2s;
  }
  
  .btn-primary:hover {
    background-color: #A85D2A;
    border-color: #A85D2A;
    transform: translateY(-1px);
    box-shadow: 0 4px 6px rgba(196, 115, 53, 0.2);
  }
  
  .file-input-wrapper {
    background-color: #F9FAFB;
    border: 2px dashed #E5E7EB;
    border-radius: 12px;
    padding: 2rem;
    text-align: center;
    transition: all 0.2s;
  }
  
  .file-input-wrapper:hover {
    border-color: #C47335;
    background-color: #FEF7F3;
  }
  
  .main-card {
    text-align: center;
    padding: 3rem 2rem;
  }
  
  .main-card h2 {
    color: #2C2D30;
    font-weight: 600;
    margin-bottom: 1rem;
  }
  
  .main-card p {
    color: #6B7280;
    font-size: 1.1rem;
    line-height: 1.6;
  }
  
  .prediction-card {
    background: linear-gradient(135deg, #FEF7F3 0%, #FFFFFF 100%);
    border-radius: 12px;
    padding: 1.5rem;
    margin-bottom: 1rem;
  }
  
  .prediction-label {
    font-size: 0.875rem;
    color: #6B7280;
    font-weight: 500;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }
  
  .prediction-value {
    font-size: 1.75rem;
    color: #2C2D30;
    font-weight: 600;
    margin-top: 0.25rem;
  }
  
  .prediction-confidence {
    font-size: 1.25rem;
    color: #C47335;
    font-weight: 500;
  }
  
  .status-badge {
    display: inline-block;
    padding: 0.375rem 0.75rem;
    border-radius: 6px;
    font-size: 0.875rem;
    font-weight: 500;
  }
  
  .status-success {
    background-color: #D1FAE5;
    color: #065F46;
  }
"
