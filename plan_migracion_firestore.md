# Plan de Migración: SQLite a Firebase Firestore

## Información Recopilada

### Archivos Analizados:
1. **lib/proveedores/gallos_proveedor.dart** - Proveedor actual que usa SQLite
2. **lib/servicios/servicio_firestore.dart** - Nuevo servicio para Firestore 
3. **lib/modelos/gallo_modelo.dart** - Modelo de datos con campo userId

### Estado Actual:
- ✅ El modelo `Gallo` ya incluye el campo `userId` 
- ✅ El servicio `ServicioFirestore` está creado y tiene todos los métodos CRUD
- ❌ El proveedor `GallosProveedor` aún usa SQLite via `AyudanteDB`

## Plan de Modificación

### Archivo: lib/proveedores/gallos_proveedor.dart

#### Cambios Requeridos:

1. **Importaciones**: 
   - Mantener: `gallo_modelo.dart`, `cloud_firestore`, `firebase_auth`
   - Cambiar: Remover `ayudante_db.dart` y agregar `servicio_firestore.dart`
   - Actualizar: Importar `servicio_firestore.dart` si no está

2. **Propiedades Privadas**:
   - Cambiar: `_ayudanteDB` → `_servicioFirestore`
   - Mantener: `_gallos`, `_filtroTexto`, `_filtroEstado`

3. **Constructor**:
   - Cambiar: `_inicializarBaseDatos()` → `_verificarAutenticacion()`
   - Remover: Toda referencia a inicialización de SQLite

4. **Método cargarGallos()**:
   - Cambiar: Query a SQLite → `await _servicioFirestore.obtenerGallos()`
   - Procesar: Convertir `QuerySnapshot` a `List<Gallo>`
   - Usar: `Gallo.fromMap()` para cada documento

5. **Método crearGallo()**:
   - Cambiar: `await _ayudanteDB.baseDatos.insert()` → `await _servicioFirestore.crearGallo()`
   - Enviar: `gallo.toMap()` sin modificaciones
   - El servicio maneja automáticamente userId y timestamps

6. **Método actualizarGallo()**:
   - Cambiar: `await _ayudanteDB.baseDatos.update()` → `await _servicioFirestore.actualizarGallo()`
   - Enviar: `galloEditado.toMap()` sin modificaciones
   - El servicio maneja automáticamente timestamps

7. **Método eliminarGallo()**:
   - Cambiar: `await _ayudanteDB.baseDatos.delete()` → `await _servicioFirestore.eliminarGallo()`
   - Mantener: Lógica de eliminación de archivos de imagen
   - El servicio verifica permisos automáticamente

8. **Método validarPlacaDuplicada()**:
   - Cambiar: Consulta local → `await _servicioFirestore.validarPlacaDuplicada()`
   - Cambiar: `_existePlaca()` → usar el servicio directamente

9. **Método dispose()**:
   - Cambiar: `await _ayudanteDB.cerrar()` → `await _servicioFirestore.dispose()`
   - O simplemente `super.dispose()` si no hay limpieza específica

10. **Métodos de Consulta (estadísticas, obtenerPorEstado, etc.)**:
    - Mantener: Lógica de filtrado en memoria (sin cambios)
    - Estos métodos trabajan sobre `_gallos` que ya está sincronizado

### Beneficios de la Migración:
- ✅ Filtrado automático por usuario (seguridad)
- ✅ Sincronización en tiempo real opcional
- ✅ Escalabilidad en la nube
- ✅ Eliminación de gestión manual de SQLite
- ✅ Manejo automático de timestamps

### Archivos Dependientes a Revisar:
- **lib/pantallas/pantalla_inicio.dart** - Para asegurar que funcione con la nueva lógica
- **lib/pantallas/pantalla_formulario_gallo.dart** - Para validar que las operaciones CRUD funcionen
- **lib/main.dart** - Verificar configuración de Firebase

### Pasos de Implementación:
1. Modificar las importaciones
2. Cambiar propiedades privadas
3. Actualizar constructor
4. Migrar métodos CRUD uno por uno
5. Actualizar método dispose
6. Probar la aplicación
7. Eliminar archivos de SQLite obsoletos (opcional)

## Estado: Listo para Implementación
