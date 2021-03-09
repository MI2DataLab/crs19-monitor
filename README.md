# crs19-monitor
Monitoring wariantów SARS-COV-2
## Pre-requirements

* conda
## Setup

Żeby zainstalować zależności należy uruchomić:
``` ./setup.sh ```

Następnie aktywować utworzone przez skrypt środowisko condy:
``` conda activate crs19```

I zainstalować w nim zależności pythona:
```pip install -r requirements.txt```
## Config
Login i hasło należy umieścić w pliku secret.py
```
elogin="username"
epass="password"
```
## Usage

```python run_full_pipeline.py```

Wyniki są w `results.csv`.
Przy następnym uruchomieniu, pangolin przeanalizuje tylko nowe sekwencje.