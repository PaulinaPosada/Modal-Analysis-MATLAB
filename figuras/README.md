# Figuras

Las figuras se generan automáticamente al ejecutar `main2.m` en MATLAB.
Exportar manualmente cada figura desde MATLAB con:

```matlab
exportgraphics(gcf, 'figuras/nombre_figura.png', 'Resolution', 150);
```

## Figuras esperadas

| Archivo | Paso del código | Descripción |
|---------|----------------|-------------|
| `psd_comparativa.png` | Paso 4 | Comparación PSD de las 4 señales |
| `psd_ts1.png` – `psd_ts4.png` | Paso 4 | PSD individual por señal |
| `stress_history_elem38.png` | Paso 12 | Historia de esfuerzos en Elemento #38 |
| `deformacion_peso_propio.png` | Paso 11 | Deformada ×10 bajo peso propio |
| `turning_points.png` | Paso 13 | Señal con turning points Rainflow |
| `rainflow_3d.png` | Paso 13 | Histograma 3D del conteo Rainflow |
