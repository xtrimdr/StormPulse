# StormPulse

Panel modular y personalizable de telemetría y clima para **Rainmeter** (Windows 10/11), con estética dark-glass neón y menú de configuración completo por pestañas.

## Características

- **6 módulos configurables** (mostrar/ocultar y reordenar libremente con ajuste automático de altura):
  - **CPU**: uso %, gráfico con grilla técnica (6×4) y temperatura en vivo (vía `idcool` o `Core Temp`).
  - **GPU**: uso %, VRAM dedicada, gráfico y temperatura nativa (AMD Radeon vía `atiadlxx.dll` y NVIDIA vía `nvidia-smi`).
  - **RAM**: uso %, GB usados/totales y gráfico.
  - **NET**: descarga/subida con autoescala y gráfico dual.
  - **DISK**: lectura/escritura, espacio libre en `C:` y gráfico dual.
  - **CLIMA**: temperatura actual, sensación térmica, humedad, viento y pronóstico configurable **Solo actual**, **Por hora (4–10 h)** o **Por días (3–10 días)** con búsqueda de cualquier ciudad (Open-Meteo, sin API key).
- **Menú de Ajustes por pestañas** (acceso con clic en el ícono `⚙` del panel o clic derecho):
  - **Módulos**: activar/desactivar, subir/bajar orden, activar temperaturas.
  - **Clima**: buscar ciudad, elegir modo (actual / por hora / por días hasta 10), °C / °F.
  - **Temas**: 4 temas completos en 1 clic (*Tormenta*, *Cyberpunk*, *Grafito*, *Bosque*), opacidad, brillo ambiental neón y borde.
  - **Colores**: 10 colores por módulo, relleno de gráficos, grilla y umbral de alerta.
  - **Diseño**: escala, márgenes independientes **X / Y** para snap al borde de pantalla, esquinas, grosor de línea y frecuencia de actualización.
  - **Texto**: fuentes independientes para cabecera, números y unidades + tono de texto.

## Requisitos

- [Rainmeter](https://www.rainmeter.net/) 4.5+
- Python 3 en el `PATH` (para temperatura GPU y clima)
- Opcional para temperatura de CPU: [idcool](https://github.com/xtrimdr/idcool) o Core Temp

## Instalación rápida en cualquier PC

1. Clonar o descargar este repositorio.
2. Ejecutar `install.bat` (copia `StormPulse` a `Documentos\Rainmeter\Skins\StormPulse` y activa el panel automáticamente).
