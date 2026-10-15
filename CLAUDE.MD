# Contexto y Reglas de Arquitectura — CastaSoft (Criadero Gallo Alegre)

## 1. Entorno y Stack Tecnológico
- **SDK:** Flutter 3.47.5 (Canal stable) en Pop!_OS 24.04 LTS (Linux x86_64).
- **Ejecución en Linux Dev:** Se corre en Web (`flutter run -d chrome` o `web-server`) porque `firebase_core`/`cloud_firestore` no tienen soporte C++ oficial en Linux Desktop. Targets de producción: Android, Web y Windows Desktop.
- **Estado y Arquitectura:** Arquitectura por Capas en Español (3-Tier MVC/MVVM Reactivo) usando `provider` (`ChangeNotifier`, `Consumer`, `MultiProvider`).
  - `lib/modelos/`: DTOs y dominio (`gallo_modelo.dart`, `cruce_modelo.dart`, `usuario_modelo.dart`).
  - `lib/proveedores/`: Estado en RAM y lógica de negocio (`gallos_proveedor.dart`, `cruces_proveedor.dart`, `usuario_proveedor.dart`).
  - `lib/servicios/`: Infraestructura externa (`servicio_firestore.dart`, `servicio_backup.dart`).
  - `lib/datos/`: `ayudante_db.dart` (Singleton SQLite legado/local).
  - `lib/pantallas/` y `lib/componentes/`: UI pasiva en Material Design.

## 2. ZONAS PROHIBIDAS (Parches aplicados que NO debes romper ni revertir)
1. **IconData vs FaIconData (`font_awesome_flutter: ^11.0.0`):** En Flutter 3.47.5 `IconData` es `final class`. NUNCA pases `FontAwesomeIcons.*` dentro de un widget `Icon()` ni tipes parámetros de íconos mixtos como `IconData?`. Usa siempre `FaIcon()` o tipado `dynamic icon` con renderizado condicional: `icon is IconData ? Icon(icon, ...) : FaIcon(icon as FaIconData, ...)`.
2. **Compatibilidad Flutter Web (`kIsWeb`):** NUNCA uses `dart:io` (`Platform.*`, `File`, `Directory`) ni `getTemporaryDirectory()` sin protegerlos con `if (!kIsWeb)`. Para imágenes seleccionadas usa `XFile` (`kIsWeb ? NetworkImage(xfile.path) : FileImage(File(xfile.path))`) y para descargas en Web usa `XFile.fromData(...).saveTo(...)`.
3. **Contextos asíncronos (`SnackBar`):** Captura siempre `final messenger = ScaffoldMessenger.of(context);` antes de cualquier `await` o transición de pantalla para evitar errores de `unmounted context`.

## 3. Reglas de Negocio Inquebrantables (Tesis de Grado)
- **RN-01 (Unicidad de Placa):** Ningún ejemplar del mismo `userId` puede repetir `placa` (validación excluyendo el propio `id` en edición).
- **RN-02 (Coherencia Biológica en Cruces):** `pollitosMuertos <= cantidadHuevos` (o total inicial) y `(pollitosMachos + pollitosHembras) <= pollitosVivos`.
- **RN-03 (Genealogía en Cascada):** Al seleccionar `padreId` o `madreId`, se autocompletan en cascada los nombres de padres y abuelos en texto plano (desnormalizados) para conservar el pedigrí aunque se borre el ancestro.
- **RN-04 (Progenitores Obligatorios):** Todo cruce exige `padreId` (Macho) y `madreId` (Hembra) válidos.
- **RN-05 (Multi-Tenant por UID):** Toda consulta/escritura en Firestore debe filtrar e inyectar el `userId` autenticado.
- **RN-06 (Integridad en Backups JSON):** `ServicioBackup.restaurarBackupJSON` debe usar `WriteBatch`, reasignar `userId` al usuario activo y mapear en un diccionario `Map<String, String>` los `id` antiguos a los nuevos para re-vincular `padreId` y `madreId` en gallos y cruces sin romper el árbol genealógico.
- **RN-07 (Tipado y Finanzas):** `costoAdquisicion` y `precioVenta` usan formato moneda en UI y se guardan como `double`. `Gallo.fromMap` debe parsear tipos de forma segura. Prohibido insertar strings vacíos en `vacunas` o `peleas`.