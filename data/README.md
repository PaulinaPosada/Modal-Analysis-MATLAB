# Datos de señales de campo

Los archivos `tsN.txt` contienen registros de aceleración (tiempo [s], aceleración [g])
adquiridos a **Fs = 1 000 Hz** durante **600 segundos** cada uno (600 000 muestras).

## Archivos incluidos (muestras de 500 filas para demostración)
- `ts1_sample.txt` — Muestra de ts1 (0.001–0.500 s)
- `ts2_sample.txt` — Muestra de ts2 (0.001–0.500 s)
- `ts3_sample.txt` — Muestra de ts3 (0.001–0.500 s)
- `ts4_sample.txt` — Muestra de ts4 (0.001–0.500 s)

## Nota sobre archivos completos
Los archivos completos (~16 MB cada uno) superan el límite recomendado de GitHub (50 MB total).
Para trabajar con las señales completas, usar **Git LFS** o incluirlas localmente.

Configuración Git LFS:
```bash
git lfs install
git lfs track "data/ts*.txt"
git add .gitattributes
```
