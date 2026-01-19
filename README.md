# Przygotowanie środowiska do uruchomienia aplikacji

## Struktura folderu z danymi audio
```
dataset/
├── audio
│ ├── fold_1/
│ ├── ├── wavefile.wav
│ ├── fold_2/
...
│ ├── fold_10/
├── metadata.csv
```

*W projekcie korzystam z danych z zestawu [UrbanSound8K](https://urbansounddataset.weebly.com/urbansound8k.html)*

## Instalacja bibliotek

``` bash
  source("install.R")
```

## Uruchomienie aplikacji

``` bash
  source("app.R")
```

# Schemat działania aplikacji

## Przygotowanie etykiet do klasyfikacji ścieżek

- Wczytanie pliku CSV z etykietami
- Przygotowanie wektora etykiet (x=ścieżka do pliku audio, y=etykieta klasy)

## Przygotowanie ścieżek audio

- Wczytanie plików audio z katalogu
- Konwersja stereo(jeśli ścieżka ma dwa kanały) do `mono`
- Normalizacja długości ścieżek audio (do `4s`)
- Resampling domyślnej częstotoliwości ścieżki do `41kHz`
- Przekształcenie ścieżek audio do `spektrogramów melowych` (skala decybelowa zamiast amplitud, użycie STFT)
- Konwersja spektogramów do postaci `tensorów` 
- Normalizacja wartości

#### Uwagi:
- Używam `STFT`(w funkcji `transform_mel_spectrogram` z biblioteki `torchaudio` ) do uzyskania spektrogramów, ponieważ wykonuje ona `FFT` na krótkich, nakładających się fragmentach sygnału audio, co pozwala na analizę zmian częstotliwości w czasie. Nie używam DFT bezpośrednio, ponieważ jest ona mniej efektywna obliczeniowo i nie dostarcza informacji o czasie. 
- Po wygenerowaniu spektogramu melowego używam przekształcenia do `skali decybelowej`, ponieważ ludzkie ucho posiada logartymiczną percepcję głośności(przez co np. podwojenie głośności fizycznej nie jest odbierane jako 2x głośniejsze).
- Po przekształceniu na skalę logarytmiczną `normalizuję wartości spektrogramu`, aby ułatwić uczenie modelu.

## Budowa modelu CNN
- Definicja architektury modelu `CNN` 
- Kompilacja modelu

#### Uwagi:
- Stosuję prostą strukturę sieci, opartą na 4 warstwach konwolucyjnych z `ReLU`, każda z nich jest połączona z warstwą `MaxPooling`, na koniec używam warstw `Fully Connected`. 
- Stosuję `Dummy Forward Pass` do wstępnej weryfikacji działania modelu przed rozpoczęciem właściwego treningu oraz do określenia wymiarów wejściowych i wyjściowych modelu. `dummy_output`([batch, features]) jest używany do sprawdzenia, czy model zwraca dane o oczekiwanym kształcie i typie podczas testowego przejścia danych przez sieć. 
- Zamiast stosować `softmax` na końcu sieci, używam `CrossEntropyLoss`, która łączy w sobie `softmax`(przekształca wyniki z ostatniej warstwy sieci na prawodpodobieństwa) i `log likelihood`(czyli logarytmiczne prawodpodobieństwo, które oblicza karę za błąd na podstawie logarytmu z przewidzianego prawodpodobieństwa), co jest bardziej stabilne numerycznie i efektywne obliczeniowo.
- Używam `lr_step`(`learning rate scheduler`), aby poprawić stabilność i efektywność procesu uczenia się modelu poprzez stopniowe zmniejszanie współczynnika uczenia się w trakcie treningu(co 10 epok zmniejszam learning rate o połowę).

## Trenowanie modelu
- Podział danych na zbiór treningowy(65% danych), walidacyjny(25%) i ewaluacyjny(10%)
- Trenowanie modelu na danych treningowych
- Testowanie modelu na danych walidacyjnych po każdej epoce

#### Uwagi:
- Używam coro:loop, aby program nie blokował głównego wątku podczas trenowania modelu, bierze 1 batch danych na raz, zamiast ładować cały zbiór treningowy do pamięci(potrzebujemy użyć coro, bo R natywnie nie wspiera iteratorów)

## Ewaluacja modelu
- Ocena modelu na zbiorze testowym
- Wyświetlenie metryk wydajności modelu
- Generacja i wyświetlenie macierzy pomyłek

## Ocena modelu v1
- Do trenowania modelu v1 użyłem całego zbioru UrbanSound8K(z zastosowaniem proprocji wymienionych wyżej) oraz 50 epok treningowych. To połączenie dało zadowalające wyniki w postaci dokładności rzędu ~85% dokładności na zbiorze testowym. Z utworzonych wykresów można wywnioskować, że model najlepiej rozpoznaje `strzały z pistoletu` (około **93%** dokładności, co wydaje się logiczne, z uwagi na powtarzalność i głośność próbek), a najgorzej radzi sobie z rozpoznawaniem `bawiących się dzieci`(dokładność na poziomie ok. **73%**, co może wynikać z charakterystyki próbek, jako mniej powtarzalnych i bardziej zróżnicowanych).
- Co więcej, możemy zaobserować największy skok jakościowy modelu w okolicach 10-13 epoki, a po 30 epoce skok ten był już minimalny(z 83.85% do 84.54%), co sugeruje, że model osiągnął swój limit przy obecnej architekturze.