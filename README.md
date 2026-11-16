# CastaSoft

**Plataforma multiplataforma de trazabilidad genética, control sanitario y gestión operativa para criaderos de aves de raza.**

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-%E2%89%A53.0-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?logo=firebase&logoColor=black)
![Tests](https://img.shields.io/badge/Tests-72%2F72%20Passing-brightgreen)
![Linter](https://img.shields.io/badge/Linter-0%20Issues-brightgreen)
![Windows CI/CD](https://img.shields.io/badge/Windows%20CI%2FCD-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)

CastaSoft corre en **Android, Web, Linux y Windows** desde una única base de código Flutter/Dart. Se encuentra en producción gestionando **+79 ejemplares reales** del Criadero Gallo Alegre, con un modelo **multi-tenant (marca blanca)** y **$0 COP/mes de costo de servidor** gracias al filtrado en memoria sobre el plan gratuito de Firebase.

---

## Tabla de contenidos

1. [Contexto operativo y problemas resueltos](#1-contexto-operativo-y-problemas-resueltos)
2. [Características principales](#2-características-principales)
3. [Arquitectura del sistema](#3-arquitectura-del-sistema)
4. [Decisiones de ingeniería destacadas](#4-decisiones-de-ingeniería-destacadas)
5. [Requisitos previos, instalación y ejecución](#5-requisitos-previos-instalación-y-ejecución)
6. [Pruebas automatizadas y calidad de código](#6-pruebas-automatizadas-y-calidad-de-código)
7. [CI/CD](#7-cicd)

---

## 1. Contexto operativo y problemas resueltos

La cría de aves de raza depende de decisiones de largo plazo (cruces, linajes, sanidad) que tradicionalmente se sustentan en libretas de papel. CastaSoft reemplaza ese flujo por un sistema estandarizado, validado y verificable.

| # | Problema operativo | Cómo lo resuelve CastaSoft |
|---|--------------------|----------------------------|
| 1 | **Endogamia genética** por falta de trazabilidad de ancestros al programar cruces. | Árbol genealógico recursivo (padres y abuelos paternos/maternos) consultable al planificar cada cruce. |
| 2 | **Desorden sanitario** en vacunación, desparasitación y vitaminas. | Seguimiento estructurado de esquemas sanitarios por ejemplar. |
| 3 | **Vulnerabilidad de archivos físicos** (pérdida o deterioro de libretas en el campo). | Persistencia en Cloud Firestore con caché local y respaldos JSON exportables. |
| 4 | **Inconsistencia de datos** por registros manuales sin validación. | Formularios con validaciones, expresiones regulares anti-basura y rangos biológicos. |
| 5 | **Limitaciones comerciales**: sin fichas técnicas ni certificados verificables. | Certificados de pedigrí PNG en alta definición con código QR hacia el WhatsApp del criadero. |

**Modelo de negocio / operación:** esquema *multi-tenant* (marca blanca personalizable por criadero) con aislamiento lógico por cuenta y costo de infraestructura nulo.

---

## 2. Características principales

- **Gestión de ejemplares**: registro completo con foto (cámara o galería), placa, sexo, fecha, etapa de vida y fase lunar.
- **Gestión de cruces**: planificación, detalle y listado, con fórmulas de camadas.
- **Árbol genealógico recursivo** y **exportación de certificados de pedigrí** en PNG con QR dinámico.
- **Control sanitario**: vacunas, desparasitación y vitaminas.
- **Formulario en 4 pestañas** con redirección automática del `TabController` hacia el primer campo con error.
- **Filtros dinámicos según sexo**: 8 etapas de vida y 8 fases lunares.
- **Centro de seguridad**: respaldos JSON (exportar/importar) y limpieza de duplicados.
- **Offline-First**: operación fluida sin conexión en zonas rurales.
- **Marca blanca**: configuración de perfil y logo por criadero.
- **Retrocompatibilidad** con registros históricos.

---

## 3. Arquitectura del sistema

Paradigmas: POO, programación declarativa/reactiva y asíncrona. Arquitectura **en capas** combinada con **MVC**, con gestión de estado mediante **`Provider` (`ChangeNotifier`)**.

```
┌──────────────────────────────────────────────────────────┐
│  Presentación   pantallas/  +  componentes/   (Vista)    │
├──────────────────────────────────────────────────────────┤
│  Estado         proveedores/ (ChangeNotifier) (Control.) │
├──────────────────────────────────────────────────────────┤
│  Dominio        modelos/  +  servicios/       (Modelo)   │
├──────────────────────────────────────────────────────────┤
│  Datos          Cloud Firestore (caché local) + Auth     │
└──────────────────────────────────────────────────────────┘
```

**Aislamiento multi-tenant:** cada documento de Cloud Firestore está filtrado y protegido por `userId` (`FirebaseAuth`).

### Árbol del proyecto

```
castasoft/
├── .github/workflows/
│   └── windows_build.yml            # CI: compilación Windows Release
├── lib/
│   ├── main.dart                    # Punto de entrada, providers y tema
│   ├── firebase_options.dart        # Configuración generada de Firebase
│   ├── componentes/                 # Widgets reutilizables
│   │   ├── boton_limpiar_duplicados.dart
│   │   ├── icono_adaptativo.dart
│   │   ├── logo_marca.dart
│   │   ├── selector_foto.dart       # Cámara/galería, compresión a 800 px
│   │   ├── tarjeta_gallo.dart
│   │   └── tarjeta_kpi.dart
│   ├── datos/
│   │   └── ayudante_db.dart
│   ├── modelos/
│   │   ├── cruce_modelo.dart
│   │   ├── foto_base64.dart
│   │   ├── gallo_modelo.dart
│   │   └── usuario_modelo.dart
│   ├── pantallas/
│   │   ├── pantalla_centro_seguridad.dart
│   │   ├── pantalla_configuracion_perfil.dart
│   │   ├── pantalla_detalle_cruce.dart
│   │   ├── pantalla_detalle_gallo.dart
│   │   ├── pantalla_exportar_pedigree.dart
│   │   ├── pantalla_formulario_cruce.dart
│   │   ├── pantalla_formulario_gallo.dart
│   │   ├── pantalla_inicio.dart
│   │   ├── pantalla_lista_cruces.dart
│   │   ├── pantalla_login.dart
│   │   └── pantalla_vacia.dart
│   ├── proveedores/                 # Estado (ChangeNotifier)
│   │   ├── cruces_proveedor.dart
│   │   ├── gallos_proveedor.dart
│   │   └── usuario_proveedor.dart
│   └── servicios/
│       ├── deduplicacion.dart       # Huella lógica de duplicados
│       ├── servicio_backup.dart     # Export/import JSON idempotente
│       └── servicio_firestore.dart  # Acceso a datos y confirmarEscritura
├── test/
│   └── reglas_negocio_test.dart     # Suite automatizada (72 pruebas)
├── android/ · linux/ · windows/ · web/ · ios/ · macos/
├── assets/
└── pubspec.yaml
```

### Stack tecnológico

| Capa | Tecnología |
|------|-----------|
| UI / Framework | Flutter, Dart (`>=3.0.0 <4.0.0`), Material, `google_fonts`, `font_awesome_flutter` |
| Estado | `provider` (`ChangeNotifier`) |
| Backend (BaaS) | `firebase_core`, `firebase_auth`, `cloud_firestore` |
| Imágenes | `image_picker`, `screenshot`, `gal`, `qr_flutter` |
| Archivos / sistema | `file_selector`, `path_provider`, `share_plus`, `url_launcher` |
| Utilidades | `uuid`, `intl`, `path` |

---

## 4. Decisiones de ingeniería destacadas

### 4.1 Persistencia híbrida Offline-First (`confirmarEscritura`, 2.5 s)

Se aprovecha la caché local integrada del SDK de Cloud Firestore. Sin red, una escritura de Firestore **no se resuelve** hasta reconectar, lo que bloquearía la UI. El método envolvente `confirmarEscritura` aplica un **timeout controlado de 2.5 segundos**: si el servidor no confirma a tiempo, la escritura ya está en la caché local y se sincronizará automáticamente, y la interfaz continúa sin bloqueo.

```dart
// Concepto (ver servicio_firestore.dart)
Future<void> confirmarEscritura(Future<void> escritura) async {
  try {
    await escritura.timeout(const Duration(milliseconds: 2500));
  } on TimeoutException {
    // Sin conexión: el dato queda en caché local y se sincroniza al reconectar.
  }
}
```

### 4.2 Respaldo JSON idempotente y restauración en 2 pasadas con `WriteBatch`

| Etapa | Descripción |
|-------|-------------|
| **Validación previa** | El archivo JSON se valida completamente en RAM antes de escribir. |
| **Idempotencia** | Detección de duplicados por **huella lógica** (placa, nombre, sexo, fecha): reimportar el mismo respaldo no genera registros repetidos. |
| **Pasada 1** | Inserción de ejemplares y construcción del mapa `IDantiguo → IDnuevo`. |
| **Pasada 2** | Traducción de `padreId` y `madreId` antiguos a los nuevos IDs, preservando el linaje. |
| **Commit atómico** | `WriteBatch` fragmentados cada **450 operaciones** (el límite de Firestore es 500 por lote). |

### 4.3 Optimización de RAM a 60 FPS: caché `Uint8List`

Las fotos se capturan con cámara/galería (`selector_foto.dart`), se comprimen a **800 px** y se almacenan en Base64. Para evitar decodificar en cada reconstrucción del widget durante el scroll, la decodificación ocurre **una sola vez** y se conserva en memoria:

```dart
late final Uint8List? fotoBytes = _decodificar(fotoBase64);
```

### 4.4 Árbol genealógico recursivo y certificados PNG con QR

El árbol (padres y abuelos paternos/maternos) se construye en memoria. El certificado se renderiza con `RepaintBoundary` a **`pixelRatio: 3.0`** y se exporta como PNG de alta definición, incluyendo un **código QR dinámico** hacia el WhatsApp del criadero, listo para compartir con compradores.

### 4.5 Usabilidad preventiva

- Formulario de 4 pestañas con salto automático a la pestaña con error.
- Validaciones con expresiones regulares anti-basura.
- Rango biológico de peso validado en `(0.1, 25.0]`.
- Compatibilidad con registros históricos sin campos nuevos.

---

## 5. Requisitos previos, instalación y ejecución

### Requisitos

| Herramienta | Versión |
|-------------|---------|
| Flutter SDK (canal `stable`) | Compatible con Dart `>=3.0.0 <4.0.0` |
| Android Studio / SDK Android | Para compilar Android |
| Toolchain Linux | `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev` |
| Visual Studio con carga "Desarrollo para escritorio con C++" | Para Windows |
| Proyecto Firebase | Auth + Cloud Firestore (`firebase_options.dart`) |
| Navegador Chromium (p. ej. Brave) | Para ejecución web |

### Instalación

```bash
git clone https://github.com/JohanPrntln/CastaSoft---.git castasoft
cd castasoft
flutter pub get
flutter doctor
```

### Ejecución

```bash
# Android (dispositivo o emulador conectado)
flutter run -d android

# Linux
flutter run -d linux

# Windows
flutter run -d windows

# Web en Linux usando Brave
export CHROME_EXECUTABLE=$(which brave-browser || which brave) && flutter run -d chrome
```

### Compilación de producción

```bash
# Android (APK optimizado para arm64)
flutter build apk --release --target-platform android-arm64

# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

---

## 6. Pruebas automatizadas y calidad de código

| Indicador | Resultado |
|-----------|-----------|
| `flutter analyze` | **0 errores, 0 advertencias** |
| `flutter test` | **72 / 72 pruebas pasando**, 100 % en memoria RAM, < 15 s |
| Pruebas funcionales E2E | 16 incluidas en la suite |

La suite (`test/reglas_negocio_test.dart`) valida:

- Serialización de modelos (`toMap` / `fromMap`).
- Rangos biológicos de peso `(0.1, 25.0]`.
- Reglas de negocio y fórmulas de camadas.
- Flujos funcionales de extremo a extremo.

```bash
flutter analyze
flutter test
```

---

## 7. CI/CD

El pipeline de **GitHub Actions** (`.github/workflows/windows_build.yml`) se ejecuta en cada `push` a `main` y manualmente (`workflow_dispatch`):

| Paso | Acción |
|------|--------|
| 1 | `actions/checkout@v4` |
| 2 | `subosito/flutter-action@v2` (canal `stable`) |
| 3 | `flutter pub get` |
| 4 | `flutter build windows --release` |
| 5 | Publica el artefacto **`CastaSoft_Windows`** (`build/windows/x64/runner/Release/`) |

La compilación de Android se realiza con `flutter build apk --release --target-platform android-arm64`.
