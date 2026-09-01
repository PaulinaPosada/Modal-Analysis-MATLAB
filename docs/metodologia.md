# Metodología: Flujo de Cálculo Determinista

## Diagrama de dependencias entre pasos

```
ts1.txt ──┐
ts2.txt ──┤──► [Paso 0] Carga y Fs ──► [Paso 1] Filtro Butterworth
ts3.txt ──┤                                         │
ts4.txt ──┘                                         ▼
                                          [Paso 2] Envolvente + Evento
                                                     │
                              ┌──────────────────────┘
                              ▼
                    [Paso 3] PSD (Welch)
                              │
                    [Paso 4] f_media, picos
                              │
              ┌───────────────┘
              ▼
    [Paso 5] Geometría MEF (38 nodos, 73 elementos)
              │
    [Paso 6] Ensamble K global
              │
    [Paso 7] Cargas (peso propio 1g)
              │
    [Paso 8] Solución K·U = F
              │
    [Paso 9] Esfuerzos σᵢ = E·εᵢ
              │
    [Paso 10] Elemento crítico → #38
              │
    [Paso 11] Deformación deformada
              │
    ┌─────────┘
    ▼
[Paso 12] Historia esfuerzo: σ(t) = σ_max × a(t)
              │
[Paso 13] Rainflow → tabla de ciclos
              │
[Paso 14] Palmgren-Miner → D = Σ(nᵢ/Nf,ᵢ)
```

## Supuestos del modelo

1. **Linealidad material y geométrica**: los desplazamientos son pequeños respecto a la longitud del brazo.
2. **Elementos tipo truss**: solo se transmiten fuerzas axiales (sin momento). Válido dado el cociente longitud/sección del brazo.
3. **Proporcionalidad aceleración–esfuerzo**: la respuesta dinámica se aproxima escalando la solución estática por el factor de aceleración de campo.
4. **Concatenación de eventos independientes**: los eventos de distintas señales se tratan como una historia de carga continua para el conteo Rainflow.
5. **Acero homogéneo e isótropo**: E = 200 000 MPa, ρ = 7 850 kg/m³ constantes en toda la estructura.

## Parámetros calibrables

| Parámetro | Valor actual | Impacto |
|-----------|-------------|---------|
| Orden filtro Butterworth | 4 | Mayor orden → mayor pendiente de corte |
| Banda de paso | 0.1–10 Hz | Define el contenido espectral estructuralmente relevante |
| Ventana envolvente | 1 000 pts (1 s) | Controla la suavidad de la silueta |
| Umbral envolvente | 85% / 70% (ts4) | Define el límite del evento pico |
| Resolución PSD | 0.05 Hz | Discriminación de modos cercanos |
| Umbral histéresis Rainflow | 30 MPa | Filtra ciclos de baja amplitud |
