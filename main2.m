clear;
clc;
set(0, 'DefaultFigureWindowStyle', 'docked');

% Agregar la carpeta actual y subcarpetas a la ruta
addpath(genpath(pwd));

%%Cargar los datos de cada señal
s1 = "ts1.txt";
s2 = "ts2.txt";
s3 = "ts3.txt";
s4 = "ts4.txt";



%% Guardar los datos en un array
%% Para análisis de las demás señales simplemente cambir el número 
% en segnal por el de la señal deseada.
segnal = s1;

data = load(segnal);

%%Crear el array de tiempos 
t = data(:,1);
%Crear array con aceleraciones
x = data(:,2);
%Calcular la frecuencia de muestreo
Fs = 1 / (t(2) - t(1));

%======================

%% Opción para enventanado manual.
%% Seleccionar la ventana de tiempo deseada.

%%% Definir los límites de tiempo para aislar picos

%tiempo_inicio_ventana = 488; % Segundos
%tiempo_fin_ventana = 492;    % Segundos

%%%% Encontrar en qué posiciones está el tiempo dentro de ese rango

%indices_ventana = find(t >= tiempo_inicio_ventana & t <= tiempo_fin_ventana);

%%% Sobreescribir vectores t y x

%t = t(indices_ventana);
%x = x(indices_ventana);

%=======================

%Graficar la señal en el dominio temporal

plot(t,x)
title("Aceleración vs Tiempo de Señal")
xlabel("Tiempo (t)")
ylabel("Aceleración (g)")

%=======================

%Fourier
%Preparar y graficar datos en el dominio de frecuencias

%% Restar promedio a los datos para centrar la señal
%% en 0 y evitar un pico de 1 en 0 Hz. 
x_limpia = x - mean(x);

% Filtro pasa banda 0.1–10 Hz
[b_hp, a_hp] = butter(4, 0.1/(Fs/2), 'high');
[b_lp, a_lp] = butter(4, 10/(Fs/2),  'low');
x_temp     = filtfilt(b_hp, a_hp, x_limpia);
x_filtrada = filtfilt(b_lp, a_lp, x_temp);

% Número de elementos de los datos 
l = length(x);

%%Aplicando la Transformada Rápida de Fourier
f = fftshift(fft(x_limpia));

%%Amplitud para graficar
amplitud = abs(f)/l; %%%normalizo mi resultado

%%Array de frecuencias
f_centrada = linspace(-Fs/2, Fs/2, l);

%%Encontrar frecuencias principales
[picos, frecuencias_de_picos] = findpeaks(amplitud, f_centrada,'MinPeakHeight', 0.001, 'SortStr', 'descend');

%%%Graficar en dominio frecuencial
figure;
plot(f_centrada, amplitud, 'LineWidth', 1.5);
title('Espectro de Magnitud de la Señal');
xlabel('Frecuencia (Hz)');
ylabel('Magnitud (Amplitud)');
xlim([-3,3])
grid on;


%==================================

%%Aplicación de envolvente para filtrar y aislar pico sostenido en dominio
%%temporal

% Calcular la silueta (envolvente) agarrando ventanas de 1000 puntos
[silueta_arriba, silueta_abajo] = envelope(x, 1000, 'analytic');

% Aceleración máxima de la envolvente 
[accel_max, idx_max] = max(silueta_arriba);
tiempo_max = t(idx_max);

% Definición de umbral para aislar pico (todo lo que sea x% del máximo)
if segnal == s4
    umbral = accel_max * 0.70;
else
    umbral = accel_max * 0.85;
end

% Posiciones en donde la señal supera este umbral
puntos_zona_densa = find(silueta_arriba >= umbral);

% Inicio y fin exacto del evento en el tiempo
idx_inicio = puntos_zona_densa(1);
idx_fin = puntos_zona_densa(end);

tiempo_inicio = t(idx_inicio);
tiempo_fin = t(idx_fin);


% Rango de aceleración dentro de ese pedacito de tiempo
accel_min_del_rango = min(silueta_arriba(idx_inicio:idx_fin));

% Graficar para verla encima de los datos originales
figure(1);
plot(t, x, 'Color', [0.7 0.7 0.7]); 
hold on;
plot(t, silueta_arriba, 'r', 'LineWidth', 2); % La silueta superior en rojo
title('Detección del comportamiento sostenido');
xlabel('Tiempo (s)');
ylabel('Aceleración (g)');
figure(1);
hold on;
xline(tiempo_inicio, '--g','LineWidth', 2);
xline(tiempo_fin, '--g', 'LineWidth', 2);
hold off;

figure(2);
plot(t, x, 'Color', [0.7 0.7 0.7]); 
hold on;
plot(t, silueta_arriba, 'r', 'LineWidth', 2); % La silueta superior en rojo
title('Zoom de detección del comportamiento sostenido');
xlabel('Tiempo (s)');
ylabel('Aceleración (g)');
figure(2);
hold on;
xline(tiempo_inicio, '--g','LineWidth', 2);
xline(tiempo_fin, '--g', 'LineWidth', 2);
xlim([(tiempo_inicio - 20) ,(tiempo_fin+20)])
hold off;

%======================

% Vector de aceleraciones en el pico sostenido

% Esta información es necesaria para el análisis de elemento finito y
% Rainflow

%Crea el array de aceleraciones desde que inicia hasta que termina el pico sostenido 
vector_aceleraciones_picosostenido = silueta_arriba(idx_inicio:idx_fin);


% Exportar en un archivo de Excel

writematrix(vector_aceleraciones_picosostenido, 'aceleraciones_evento_s1.xlsx'); 

%% %%Análisis de Densidad Espectral de Potencia
%% ANÁLISIS COMPARATIVO PSD — 4 SEÑALES
signals = {"ts1.txt", "ts2.txt", "ts3.txt", "ts4.txt"};
colores  = {'b', 'r', [0.1 0.7 0.1], [0.8 0.4 0]};

resultados_psd = struct();

fig_comparativa = figure('Name', 'Comparación PSD - 4 Señales', 'Color', 'w');
hold on;

for k = 1:4

    % --- 1. Cargar señal ---
    data_k = load(signals{k});
    t_k    = data_k(:,1);
    x_k    = data_k(:,2);
    Fs_k   = 1 / (t_k(2) - t_k(1));

    % --- 2. Limpiar y filtrar ---
    x_limpia_k   = x_k - mean(x_k);
    [b_hp_k, a_hp_k] = butter(4, 0.1/(Fs_k/2), 'high');
    [b_lp_k, a_lp_k] = butter(4, 10/(Fs_k/2),  'low');
    x_temp_k     = filtfilt(b_hp_k, a_hp_k, x_limpia_k);
    x_filtrada_k = filtfilt(b_lp_k, a_lp_k, x_temp_k);

    % --- 3. PSD ---
    resolucion_Hz_k = 0.05;
    long_ventana_k  = round(Fs_k / resolucion_Hz_k);
    overlap_k       = round(long_ventana_k * 0.5);
    [psd_k, f_k]    = pwelch(x_filtrada_k, hann(long_ventana_k), overlap_k, long_ventana_k, Fs_k);

    % --- 4. Verificación RMS ---
    rms_directo_k = rms(x_filtrada_k);
    rms_psd_k     = sqrt(trapz(f_k, psd_k));

    % --- 5. Frecuencia media ---
    idx_fis_k  = f_k >= 0.1 & f_k <= 10;
    f_fis_k    = f_k(idx_fis_k);
    psd_fis_k  = psd_k(idx_fis_k);
    m0_k       = trapz(f_fis_k, psd_fis_k);
    m1_k       = trapz(f_fis_k, f_fis_k .* psd_fis_k);
    f_media_k  = m1_k / m0_k;

    % --- 6. Energía por bandas ---
    bandas_k      = [0, 1; 1, 3; 3, 10];
    e_total_k     = trapz(f_k, psd_k);
    e_bandas_k    = zeros(3,1);
    for b = 1:3
        idx_b         = f_k >= bandas_k(b,1) & f_k <= bandas_k(b,2);
        e_bandas_k(b) = trapz(f_k(idx_b), psd_k(idx_b));
    end

    % --- 7. Detección de picos ---
    [pks_k, locs_k, ~, prom_k] = findpeaks(psd_k, f_k, ...
        'MinPeakProminence', max(psd_k) * 0.05, ...
        'SortStr', 'descend', 'NPeaks', 6);
    idx_picos_k  = locs_k >= 0.1 & locs_k <= 10;
    locs_k       = locs_k(idx_picos_k);
    pks_k        = pks_k(idx_picos_k);
    prom_k       = prom_k(idx_picos_k);

    % --- 8. Guardar resultados ---
    resultados_psd(k).senal    = signals{k};
    resultados_psd(k).f_media  = f_media_k;
    resultados_psd(k).rms      = rms_directo_k;
    resultados_psd(k).rms_psd  = rms_psd_k;
    resultados_psd(k).e_bandas = e_bandas_k;
    resultados_psd(k).e_total  = e_total_k;
    resultados_psd(k).picos_hz = locs_k;
    resultados_psd(k).picos_psd= pks_k;
    resultados_psd(k).f_k      = f_k;
    resultados_psd(k).psd_k    = psd_k;

    % --- 9. Figura individual ---
    figure('Name', sprintf('PSD - %s', signals{k}), 'Color', 'w');
    plot(f_k, psd_k, 'Color', colores{k}, 'LineWidth', 1.2);
    hold on;
    if ~isempty(locs_k)
        plot(locs_k, pks_k, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
        for i = 1:length(locs_k)
            text(locs_k(i), pks_k(i), sprintf('  %d: %.3f Hz', i, locs_k(i)), ...
                'VerticalAlignment', 'bottom', 'Color', 'r', ...
                'FontWeight', 'bold', 'FontSize', 9);
        end
    end
    idx_sombra_k = f_k >= 1 & f_k <= 3;
    area(f_k(idx_sombra_k), psd_k(idx_sombra_k), ...
        'FaceColor', [1 0.8 0.2], 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    xline(f_media_k, '--g', sprintf('f_{media}=%.2f Hz', f_media_k), 'LineWidth', 1.5);
    title(sprintf('PSD - %s | f_{media}=%.2f Hz', signals{k}, f_media_k));
    xlabel('Frecuencia (Hz)'); ylabel('Densidad de Potencia (g²/Hz)');
    xlim([0, 10]); grid on; grid minor;
    legend('PSD', 'Picos dominantes', 'Banda estructural (1-3 Hz)', 'Frec. media');
    hold off;

    % --- 10. Agregar a figura comparativa ---
    figure(fig_comparativa);
    plot(f_k, psd_k, 'Color', colores{k}, 'LineWidth', 1.2, ...
        'DisplayName', sprintf('%s | f_{media}=%.2f Hz', signals{k}, f_media_k));

end

% --- Figura comparativa: detalles finales ---
figure(fig_comparativa);
xlabel('Frecuencia (Hz)'); ylabel('Densidad de Potencia (g²/Hz)');
title('Comparación PSD — 4 Señales de Campo');
xlim([0, 10]); grid on; grid minor;
legend show;
hold off;

% --- Tabla resumen ---
fprintf('\n============================================================\n');
fprintf('         RESUMEN COMPARATIVO — 4 SEÑALES\n');
fprintf('============================================================\n');
fprintf('%-12s %-14s %-10s %-20s\n', ...
    'Señal', 'f_media (Hz)', 'RMS (g)', 'Pico principal (Hz)');
fprintf('------------------------------------------------------------\n');
for k = 1:4
    if ~isempty(resultados_psd(k).picos_hz)
        pico_p = resultados_psd(k).picos_hz(1);
    else
        pico_p = NaN;
    end
    fprintf('%-12s %-14.3f %-10.4f %-20.3f\n', ...
        resultados_psd(k).senal, ...
        resultados_psd(k).f_media, ...
        resultados_psd(k).rms, ...
        pico_p);
end

% --- Energía por bandas comparativa ---
nombres_bandas = {'0–1 Hz', '1–3 Hz', '3–10 Hz'};
fprintf('\n--- ENERGÍA POR BANDAS (%% del total) ---\n');
fprintf('%-12s %-20s %-20s %-20s\n', 'Señal', nombres_bandas{1}, nombres_bandas{2}, nombres_bandas{3});
fprintf('--------------------------------------------------------------\n');
for k = 1:4
    fprintf('%-12s %-20.1f %-20.1f %-20.1f\n', ...
        resultados_psd(k).senal, ...
        100 * resultados_psd(k).e_bandas(1) / resultados_psd(k).e_total, ...
        100 * resultados_psd(k).e_bandas(2) / resultados_psd(k).e_total, ...
        100 * resultados_psd(k).e_bandas(3) / resultados_psd(k).e_total);
end

% --- Consolidar frecuencias de excitación para FEM ---
todas_frecuencias = [];
for k = 1:4
    todas_frecuencias = [todas_frecuencias; resultados_psd(k).picos_hz(:)];
end

todas_frecuencias  = sort(todas_frecuencias);
frecuencias_excitacion = [];
i = 1;
while i <= length(todas_frecuencias)
    grupo = todas_frecuencias(abs(todas_frecuencias - todas_frecuencias(i)) <= 0.1);
    frecuencias_excitacion(end+1) = mean(grupo);
    i = i + sum(abs(todas_frecuencias - todas_frecuencias(i)) <= 0.1);
end

fprintf('\n--- FRECUENCIAS DE EXCITACIÓN CONSOLIDADAS PARA FEM ---\n');
for i = 1:length(frecuencias_excitacion)
    fprintf('  f_exc_%d = %.3f Hz\n', i, frecuencias_excitacion(i));
end
fprintf('\nEstas frecuencias se compararán contra las frecuencias naturales del FEM.\n');

%% %% Solver para estructuras formadas con elementos 1D tipo Truss.
% Adaptado para Brazo de Rociador John Deere

tic

%% Paso 1: Definir nodos y conectividad
% Coordenadas de los nodos (mm).
N = [
1      0.00        0.00      
2      750.00      0.00      
3      750.00      800.00    
4      1625.00     0.00      
5      1625.00     779.77    
6      2500.00     0.00      
7      2500.00     759.54    
8      3375.00     0.00      
9      3375.00     739.31    
10     4250.00     0.00      
11     4250.00     719.08    
12     5125.00     0.00      
13     5125.00     698.84    
14     6000.00     0.00      
15     6000.00     678.61    
16     6875.00     0.00      
17     6875.00     658.38    
18     7750.00     0.00      
19     7750.00     638.15    
20     8625.00     0.00      
21     8625.00     617.92    
22     9500.00     0.00      
23     9500.00     600.00    
24     10375.00    0.00      
25     10375.00    600.00    
26     11250.00    0.00      
27     11250.00    600.00    
28     12125.00    0.00      
29     12125.00    600.00    
30     13000.00    0.00      
31     13000.00    600.00    
32     13875.00    0.00      
33     13875.00    480.88    
34     14750.00    0.00      
35     14750.00    326.47    
36     15625.00    0.00      
37     15625.00    172.06    
38     16600.00    0.00     ];

% Propiedades de los Materiales (Tubo Hueco)
R_mayor = 50;  E = 200000; r_menor = 40; 
Area = pi * (R_mayor^2 - r_menor^2);
M = [1  E  Area];

% Tabla de conectividad: [Elem, Nodo_i, Nodo_j, Material]
E = [
1 1 2 1; 2 2 3 1; 3 3 4 1; 4 4 5 1; 5 5 6 1; 6 6 7 1; 7 7 8 1; 8 8 9 1;
9 9 10 1; 10 10 11 1; 11 11 12 1; 12 12 13 1; 13 13 14 1; 14 14 15 1;
15 15 16 1; 16 16 17 1; 17 17 18 1; 18 18 19 1; 19 19 20 1; 20 20 21 1;
21 21 22 1; 22 22 23 1; 23 23 24 1; 24 24 25 1; 25 25 26 1; 26 26 27 1;
27 27 28 1; 28 28 29 1; 29 29 30 1; 30 30 31 1; 31 31 32 1; 32 32 33 1;
33 33 34 1; 34 34 35 1; 35 35 36 1; 36 36 37 1; 37 37 38 1; 38 2 4 1;
39 3 5 1; 40 4 6 1; 41 5 7 1; 42 6 8 1; 43 7 9 1; 44 8 10 1; 45 9 11 1;
46 10 12 1; 47 11 13 1; 48 12 14 1; 49 13 15 1; 50 14 16 1; 51 15 17 1;
52 16 18 1; 53 17 19 1; 54 18 20 1; 55 19 21 1; 56 20 22 1; 57 21 23 1;
58 22 24 1; 59 23 25 1; 60 24 26 1; 61 25 27 1; 62 26 28 1; 63 27 29 1;
64 28 30 1; 65 29 31 1; 66 30 32 1; 67 31 33 1; 68 32 34 1; 69 33 35 1;
70 34 36 1; 71 35 37 1; 72 1 3 1; 73 36 38 1
];

nE = size(E,1);
nN = size(N,1);

%% Paso 2: Rigidez
Le = sqrt((N(E(:,3),2) - N(E(:,2),2)).^2 + (N(E(:,3),3) - N(E(:,2),3)).^2);
k = M(E(:,4),2).*M(E(:,4),3)./Le;

%% Paso 3: Transformación Global
Ke = zeros(4,4,nE);
c = (N(E(:,3),2) - N(E(:,2),2))./Le;
s = (N(E(:,3),3) - N(E(:,2),3))./Le;

for i = 1:nE
    Kezq = k(i)*[c(i)^2 s(i)*c(i);s(i)*c(i) s(i)^2];
    Ke(:,:,i) = [Kezq -Kezq;-Kezq Kezq];
end

%% Paso 4 y 5: Ensamble
L = [2*E(:,2)-1 2*E(:,2) 2*E(:,3)-1 2*E(:,3)];
K = zeros(2*nN,2*nN);
for i = 1:nE
    K(L(i,:),L(i,:)) = K(L(i,:),L(i,:)) + Ke(:,:,i);
end

%% Paso 6: Peso y Restricciones
densidad_acero = 7850; gravedad = 9.81;
gamma_mm3 = (densidad_acero * gravedad) / 1e9; 
Area_elementos = M(E(:,4), 3);
Volumen_elementos = Area_elementos .* Le;
Peso_Total_N = sum(Volumen_elementos * gamma_mm3);

F = zeros(2*nN,1);
U = zeros(2*nN,1);
DoF_F = [2:2:2*nN]; 
F(DoF_F) = -(1.0)*Peso_Total_N/nN; % Aplicamos aceleración 1g

% Restringimos Nodo 1 (apoyo tractor) y Nodo 2 y 3 (base vertical)
DoF_C = [1 2 3 4 5 6];
U(DoF_C) = 0;

%% Paso 7: Solución
DoF_A = 1:2*nN; DoF_A(DoF_C) = [];
Ua = K(DoF_A,DoF_A)\(F(DoF_A) - K(DoF_A,DoF_C)*U(DoF_C));
U(DoF_A) = Ua;

%% Paso 8: Reacciones
F(DoF_C) = K(DoF_C,DoF_A)*Ua + K(DoF_C,DoF_C)*U(DoF_C);

%% Paso 9: Esfuerzos
st = zeros(nE,1); ep = zeros(nE,1);
for i = 1:nE
   u1 = U(2*E(i,2)-1)*c(i) + U(2*E(i,2))*s(i);
   u2 = U(2*E(i,3)-1)*c(i) + U(2*E(i,3))*s(i);
   ep(i) = (u2 - u1)/Le(i);
   st(i) = M(E(i,4),2)*ep(i);
end

%% Paso 10: Resultados

fprintf('Peso Total: %.2f kg\n', Peso_Total_N/gravedad);
TE = table(E(:,1), st, 'VariableNames', {'Elemento', 'Esfuerzo_MPa'});
disp(TE(1:73,:)); % Muestra primeros 10 elementos
toc


%% Paso 11: Visualización de Desplazamientos en la Punta (Nodo 38)
% El Nodo 38 tiene sus grados de libertad en 2*38-1 (X) y 2*38 (Y)
desp_x_punta = U(2*38-1);
desp_y_punta = U(2*38);

fprintf('\n==========================================================\n');
fprintf('ANÁLISIS DE DEFORMACIÓN EN LA PUNTA:\n');
fprintf('Desplazamiento Horizontal (X): %.2f mm\n', desp_x_punta);
fprintf('Desplazamiento Vertical (Caída Y): %.2f mm\n', desp_y_punta);
fprintf('==========================================================\n');

% OPCIONAL: Graficar la estructura deformada
factor_escala = 10;
figure;
hold on;
for i = 1:nE
    % Coordenadas originales
    x_orig = [N(E(i,2),2), N(E(i,3),2)];
    y_orig = [N(E(i,2),3), N(E(i,3),3)];
    plot(x_orig, y_orig, 'b--', 'LineWidth', 0.5); % Estructura original en punteado
    
    % Coordenadas deformadas
    x_def = x_orig + [U(2*E(i,2)-1), U(2*E(i,3)-1)] * factor_escala;
    y_def = y_orig + [U(2*E(i,2)), U(2*E(i,3))] * factor_escala;
    plot(x_def, y_def, 'w', 'LineWidth', 1.5); % Estructura deformada en azul
end
axis equal; grid on;
title(['Deformación del Brazo Bajo Propio Peso (Escala Exagerada x', num2str(factor_escala), ')']);
xlabel('X (mm)'); ylabel('Y (mm)');


%% Paso 12: Consolidación de archivos Excel y Generación de Esfuerzo Temporal
archivos = {
    'aceleraciones_evento_s1.xlsx', ...
    'aceleraciones_evento_s2.xlsx', ...
    'aceleraciones_evento_s3_pico1.xlsx', ...
    'aceleraciones_evento_s3_pico2.xlsx', ...
    'aceleraciones_evento_s3_pico3.xlsx', ...
    'aceleraciones_evento_s4.xlsx'
};

acc_completa = []; 
fprintf('Leyendo archivos de aceleración...\n');
for i = 1:length(archivos)
    try
        datos_temp = readmatrix(archivos{i});
        acc_completa = [acc_completa; datos_temp(:, 1)];
        fprintf(' - Cargado: %s\n', archivos{i});
    catch
        fprintf(' !! Error: No se encontró %s\n', archivos{i});
    end
end

acc_completa = acc_completa(~isnan(acc_completa));

% --- CORRECCIÓN EJE DE TIEMPO ---
muestreo_ms = 1; % 1 ms según tus datos
tiempo_seg = (0:length(acc_completa)-1) * (muestreo_ms / 1000); 

[max_sig_u, idx_elem] = max(abs(st)); 
elemento_critico = E(idx_elem, 1);
esfuerzo_temporal_total = max_sig_u * acc_completa;

% Gráfica con eje de tiempo corregido (Segundos)
figure('Name', 'Historia de Esfuerzo Temporal de conexión crítica (#38)');
plot(tiempo_seg, esfuerzo_temporal_total, 'Color', [0.85 0.32 0.1]);
grid on; hold on;
yline(300, '--r', 'Límite Elástico (300 MPa)', 'LineWidth', 1.5);
yline(-300, '--r', 'Límite Elástico (Compresión)', 'LineWidth', 1.5);
title(['Historia de Esfuerzos en el Elemento Crítico #', num2str(elemento_critico)]);
xlabel('Tiempo (segundos)'); % Ahora en segundos
ylabel('Esfuerzo (MPa)');

max_esf_detectado = max(abs(esfuerzo_temporal_total));
fprintf('\nEsfuerzo máximo alcanzado: %.2f MPa\n', max_esf_detectado);

%% Paso 13: Exportación (Sin cambios, usamos la señal completa)
T_export = table(esfuerzo_temporal_total, 'VariableNames', {'Esfuerzo_MPa'});
writetable(T_export, 'historia_esfuerzos_brazo_JD.xlsx');
writetable(T_export, 'historia_esfuerzos_brazo_JD.csv');

%% Paso 14: Desplazamiento Máximo para la Aceleración Pico
[acc_pico_valor, idx_pico] = max(abs(acc_completa));
valor_con_signo = acc_completa(idx_pico); 

% Escalar desplazamientos
U_maximo_evento = U * abs(valor_con_signo);

% --- CORRECCIÓN DE GRÁFICA DE DEFORMACIÓN ---
% Para que la gráfica no salga "rara", usamos escala 1:1 para ver la realidad
% O escala 2 si quieres que se note un poco el doblez sin deformar la silueta.
factor_escala_visual = 1.0; 

fprintf('\n--- ANÁLISIS DE DEFORMACIÓN CRÍTICA ---');
fprintf('\nAceleración pico: %.2f g', valor_con_signo);
fprintf('\nCaída real calculada en la punta (Nodo 38): %.2f mm\n', abs(U_maximo_evento(2*38)));

figure('Name', 'Deformación Real en el Evento');
hold on;
for i = 1:nE
    x_orig = [N(E(i,2),2), N(E(i,3),2)];
    y_orig = [N(E(i,2),3), N(E(i,3),3)];
    
    % Dibujar original
    plot(x_orig, y_orig, 'w:', 'LineWidth', 0.5); 
    
    % Dibujar deformada (Escala 1:1 para precisión)
    x_def = x_orig + [U_maximo_evento(2*E(i,2)-1), U_maximo_evento(2*E(i,3)-1)] * factor_escala_visual;
    y_def = y_orig + [U_maximo_evento(2*E(i,2)), U_maximo_evento(2*E(i,3))] * factor_escala_visual;
    plot(x_def, y_def, 'b', 'LineWidth', 1.5); 
end
axis equal; grid on;
title(['Deformación Estructural Real (Escala ', num2str(factor_escala_visual), ':1)']);
xlabel('X (mm)'); ylabel('Y (mm)');
legend('Estructura Original', 'Deformada (141.17mm en punta)');


%% ANÁLISIS DE FATIGA

% La fatiga es el deterioro de las propiedades estructurales de un material 
% a causa del daño que ocasiona el estres ya sea ciclico o fluctuante. 
% La característica más relevante es que cada uno de estos estréses por 
% cuenta propia son demasiado débiles para romper el material, no obstante, 
% la fatiga se trata de un proceso progresivo donde se va ocasionando cambio 
% estructural localizado permanente. Después de suficientes fluctuaciones o 
% ciclos el material se puede fracturar completamente.
%
% Algo clave de este proceso es que opera en áreas localizadas más que en 
% toda la estrcutura y suele estar causado por cargas de transferencia 
% externas, cambios en geometria, diferenciales de temperatura, estreses 
% residuales o imperfecciones en los materiales.
%
% El proceso de fatiga se divide en 3 etapas:
% 1. Crack initiation
% 2. Crack propagation (crack growth)
% 3. Ultimate failure (fracture)
%
% Estrés: denotado por sigma, mide cuanto una fuerza externa, F, actua sobre 
% un área, A, de un objeto. Tiene unidades de N/m^2 (Pascales Pa).


%% 1. CARGA DE DATOS
% Vamos a trabajar con los datos extraídos del análisis previo.
% El estrés puede ser constante o variar en amplitud con el tiempo.
disp('Cargando datos de esfuerzos...');
data = readtable('historia_esfuerzos_brazo_JD.xlsx');
sg = data.Esfuerzo_MPa;

%% 2. CONFIGURACIÓN DEL TIEMPO Y MUESTREO
Fs = 1000;
% sg es la señal de esfuerzo medida en el tiempo (la stress history)
% Fs es la sampling frequency (frecuencia de muestreo = núm de muestras/sec)

disp(['La frecuencia de muestreo es: ', num2str(Fs), ' Hz']);

% El tiempo entre muestras entonces es 1/Fs
% Para saber en que tiempo ocurrio cada muestra hacemos:
tg = (0:length(sg)-1)'/Fs;

% Mostrar los primeros 10 datos
disp('Primeros 10 datos de la historia de esfuerzos:');
T = table(tg(1:10), sg(1:10), 'VariableNames', {'Time_s','Stress'});
disp(T)

% Graficar la historia de estrés
figure(1)
plot(tg,sg)
xlabel("Time (s)")
ylabel("Stress (MPa)")
title("Stress History")
grid on

%% 3. CONTEO RAINFLOW
% El objetivo del análisis de fatiga es calcular la vida a fatiga a partir 
% de una serie temporal de esfuerzos y determinar el daño total acumulado.
%
% El procedimiento de conteo rainflow consta de tres pasos:
% 1. Filtrado por histéresis: Se eliminan oscilaciones menores a un umbral.
% 2. Filtrado pico-valle: Se conservan únicamente valores máximos y mínimos.
% 3. Conteo de ciclos usando la función rainflow.

threshold = 30; % Umbral de histéresis
[turningptsg, indg] = findTurningPts(sg, threshold); 

disp(['Número de Turning Points encontrados: ', num2str(length(turningptsg))]);

% Gráfico de esfuerzo-tiempo con puntos de cambio (intervalo de 0 a 8 seg)
% Nota: Ajusta los límites (0, 8) si tu señal es más corta o más larga
try
    plotStressAndTurningPts(tg, sg, indg, turningptsg, 0, 8);
catch
    disp('La señal es menor a 8 segundos, ajustando gráfica a la longitud total...');
    plotStressAndTurningPts(tg, sg, indg, turningptsg, 0, tg(end));
end

%% 4. ANÁLISIS DE CICLOS (RAINFLOW)
% La serie de puntos de cambio se introduce en la función rainflow, 
% la cual devuelve el número de ciclos y los rangos de esfuerzo.

rfCountg = rainflow(turningptsg, tg(indg), "ext"); 
rfTable = array2table(rfCountg, ... 
    'VariableNames', {'Count', 'Range', 'Mean', 'StartTime', 'EndTime'});

disp('Primeros ciclos extraídos por Rainflow:');
disp(head(rfTable));

% Visualización del histograma de Rainflow
figure;
rainflow(turningptsg, tg(indg), "ext");
title('Análisis de Conteo Rainflow');

%% CÁLCULO DEL DAÑO TOTAL (WÖHLER Y PALMGREN-MINER)

% Para realizar este segundo análisis requerimos saber cuantos ciclos toma 
% en fallar y eso se determina experimentalmente mediante la curva S-N.
disp('--- El conteo de ciclos ha finalizado ---');
disp('Para el cálculo de daño, se requiere alimentar las funciones con datos de la curva S-N (Nf, S).');


%% FUNCIONES LOCALES (NO MOVER DE AQUÍ ABAJO)

function [tp,ind] = findTurningPts(x,threshold)
    % FINDTURNINGPTS finds turning points in signal x
    xLen = length(x);

    % Find minimum/maximum
    [~,~,zcm] = zerocrossrate(diff(x),Method="comparison",Threshold=0);
    index = (1:xLen)';
    zci = index(zcm);

    % Make sure that there are at least two crossing points
    if (length(zci) < 2)
        tp = [];
        return;
    end

    % Add end points
    if (x(zci(1)) > x(zci(2)))
        ind = [1;zci;xLen];
    else
        ind = [zci;xLen];
    end

    % Apply hysteresis and peak-valley filtering
    pvInd = hpvfilter(x(ind),threshold);
    ind = ind(pvInd);

    % Extract turning points
    tp = x(ind);
end

function index = hpvfilter(x,h)
    % HPVFILTER performs hysteresis and peak-valley filtering
    index = [];
    tStart = 1;

    % Ignore the first maximum
    if (x(1) > x(2))
      x(1) = [];
      tStart = 2;
    end

    Ntp = length(x);
    Nc = floor(Ntp/2);
    
    if (Nc < 1)
        return
    end

    dtp = diff(x);
    if any(dtp(1:end-1).*dtp(2:end) >= 0)
        error('Not a sequence of turning points.')
    end

    count = 0;
    index = zeros(size(x));
    for i = 0:Nc-2
        tiMinus = tStart+2*i;
        tiPlus = tStart+2*i+2;
        miMinus = x(2*i+1);
        miPlus = x(2*i+2+1);

        if (i ~= 0)
            j = i-1;
            while ((j >= 0) && (x(2*j+2) <= x(2*i+2)))
                if (x(2*j+1) < miMinus)
                    miMinus = x(2*j+1);
                    tiMinus = tStart+2*j;
                end
                j = j-1;
            end
        end
      
        if (miMinus >= miPlus)
            if (x(2*i+2) >= h+miMinus)
                count = count+1;
                index(count) = tiMinus;
                count = count+1;
                index(count) = tStart+2*i+1;
            end
        else
            j = i+1;
            tfFlag = false;
            while (j < Nc-1)
                tfFlag = (x(2*j+2) >= x(2*i+2));
                if tfFlag
                    break
                end
                if (x(2*j+2+1) <= miPlus)
                    miPlus = x(2*j+2+1);
                    tiPlus = tStart+2*j+2;
                end
                j = j+1;
            end
            if tfFlag
                if (miPlus <= miMinus)
                    if (x(2*i+2) >= h+miMinus)
                        count = count+1;
                        index(count) = tiMinus;
                        count = count+1;
                        index(count) = tStart+2*i+1;
                    end
                elseif (x(2*i+2) >= h+miPlus)
                    count = count+1;
                    index(count) = tStart+2*i+1;
                    count = count+1;
                    index(count) = tiPlus;
                end
            elseif (x(2*i+2) >= h+miMinus)
                count = count+1;
                index(count) = tiMinus;
                count = count+1;
                index(count) = tStart+2*i+1;
            end
        end
    end
    index = sort(index(1:count));
end

function plotStress(t,s)
    plot(t,s)
    title("Stress History")
    xlabel("Time (sec)")
    ylabel("Stress")
    grid("minor")
end

function plotStressAndTurningPts(t,s,ind,turningpts,ts,te)
    ind1 = (t >= ts) & (t <= te);
    ttpts = t(ind); % time stamps of turning points
    ind2 = (ttpts >= ts) & (ttpts <= te);

    figure
    plot(t(ind1),s(ind1))
    hold on
    plot(ttpts(ind2),turningpts(ind2),"-*","MarkerSize",8)
    hold off
    xlabel("Time (sec)")
    ylabel("Stress")
    xlim([ts,te])
    legend(["Stress history","Hysteresis & P-V filtering output"])
    grid("minor")
end

function plotWohlerCurve(Nf,S)
    loglog(Nf,S,"o")
    title("Wohler Curve")
    xlabel("Fatigue life")
    ylabel("Stress")
    grid("minor")
end

function plModel = piecewiseLinearFit(Nf,S)
    x = log10(2*Nf);
    y = log10(S);
    
    lcfi = Nf <= 1e3;
    xlcf = x(lcfi);
    ylcf = y(lcfi);
    plcf = polyfit(xlcf,ylcf,1);
    
    hcfi = (Nf > 1e3) & (Nf <= 1e6);
    xhcf = x(hcfi);
    yhcf = y(hcfi);
    phcf = polyfit(xhcf,yhcf,1);
    
    ili = (Nf > 1e6);
    xil = x(ili);
    yil = y(ili);
    pil = polyfit(xil,yil,0);
    
    Nflcf = 10^((phcf(2)-plcf(2))/(plcf(1)-phcf(1)))/2;
    Nfhcf = 10^((pil(1)-phcf(2))/phcf(1))/2;
    Nfil = 1e8;

    plModel.plcf = plcf;
    plModel.Nflcf = Nflcf;
    plModel.phcf = phcf;
    plModel.Nfhcf = Nfhcf;
    plModel.pil = pil;
    plModel.Nfil = Nfil;

    testNf = [logspace(0,log10(Nflcf),1e3),...            
              logspace(log10(Nflcf),log10(Nfhcf),1e4),... 
              logspace(log10(Nfhcf),log10(Nfil),1e3)...   
             ];
    testS = computeStress(plModel,testNf);

    Si = 80;
    Nfi = estimateFatigueLife(plModel,Si);

    figure
    h1 = loglog(Nf,S,"o");
    hold on
    h2 = loglog(testNf,testS,"-k","LineWidth",2);
    h3 = loglog(Nfi,Si,"h","MarkerSize",15);
    h3.MarkerFaceColor = h3.Color;
    xLim = get(gca,"XLim");
    yLim = get(gca,"YLim");
    loglog([xLim(1) Nfi],[Si Si],"--","Color",0.3*ones(1,3),"LineWidth",1)
    loglog([Nfi Nfi],[yLim(1) Si],"--","Color",0.3*ones(1,3),"LineWidth",1)
    title("Fit Model to Wohler Curve")
    xlabel("Fatigue life")
    ylabel("Stress")
    grid("minor")
    legend([h1,h2,h3],["data","model","($N_{f,i}$,$\sigma_i$)"],"Interpreter","latex")
end

function Si = computeStress(plModel,Nfi)
    Si = zeros(size(Nfi));
    for i = 1:length(Nfi)
        if (Nfi(i) < plModel.Nflcf)
            Si(i) = 10.^(polyval(plModel.plcf,log10(2*Nfi(i))));
        elseif (Nfi(i) >= plModel.Nflcf && Nfi(i) < plModel.Nfhcf)
            Si(i) = 10.^(polyval(plModel.phcf,log10(2*Nfi(i))));
        else
            Si(i) = 10.^(polyval(plModel.phcf,log10(2*plModel.Nfhcf)));
        end
    end
end

function Nfi = estimateFatigueLife(plModel,Si)
    plcf = plModel.plcf;
    Nflcf = plModel.Nflcf;
    phcf = plModel.phcf;
    Nfhcf = plModel.Nfhcf;

    logSi = log10(Si);
    Nfi = NaN(size(Si));

    for i = 1:length(Si)
        Nfi1 = 10^((logSi(i)-plcf(2))/plcf(1))/2; 
        Nfi2 = 10^((logSi(i)-phcf(2))/phcf(1))/2; 
        Nfi3 = Inf;                               
        if (Nfi1 < Nflcf)
            Nfi(i) = Nfi1;
        elseif (Nfi2 < Nfhcf)
            Nfi(i) = Nfi2;
        else
            Nfi(i) = Nfi3;
        end
    end
end

function cumulativeDamageStemPlot(ni,Nfi)
    figure
    L = length(ni);
    damage = sum(ni./Nfi);
    stem(0,NaN,"Color",[0 1 0])
    title("Cumulative Damage from Palmgren-Miner Rule")
    xlabel("Cycle $i$","Interpreter","latex")
    ylabel("Cum. damage $D_{i} = \sum_{j=1}^{i}n_{j}/N_{f,j}$","Interpreter","latex")
    set(gca,"XLim",[0 L],"YLim",[0 damage])
    grid("on")
    iter = unique([1:round(L/100):L,L]);
    hold(gca,"on")
    for i = iter
        cdi = sum(ni(1:i)./Nfi(1:i)); 
        plt = stem(i,cdi,"filled");
        setStemColor(plt,cdi,0.95)
    end
end

function setStemColor(hplt,cumulativeDamage,gamma)
    c = lines(5);
    c = c([2,3,5],:);
    if (cumulativeDamage > 1)
        color = c(1,:);
    else
        if (cumulativeDamage > gamma)
            c1 = c(1,:);
            c2 = c(2,:);
        else
            c1 = c(3,:);
            c2 = c(2,:);
        end
        color = zeros(1,3);    
        for i = 1:3
            color(i) = c1(i)+(c2(i)-c1(i))*cumulativeDamage;
        end
    end
    hplt.Color = color;
end