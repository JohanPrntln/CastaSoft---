/// Clase modelo para la entidad Gallo
///
/// Representa un gallo en la aplicación CastaSoft con todas sus características
/// genéticas, físicas y administrativas.
///
/// Propiedades principales:
/// - Identificación única (id, placa)
/// - Datos personales (nombre, sexo, fecha de nacimiento)
/// - Genealogía (padre, madre, línea genética)
/// - Características físicas (color de pluma, peso, jaula)
/// - Información adicional (fase lunar, estado, notas, criadero de origen)
///
/// Métodos para persistencia en base de datos:
/// - toMap(): Serializa el objeto a formato compatible con SQLite
/// - fromMap(): Deserializa desde un mapa de base de datos
class Gallo {
  /// Identificador único del gallo (UUID o timestamp único)
  /// Requerido para identificación interna en la base de datos
  final String id;

  /// Número de anillo o placa de identificación
  /// Identificador visual del gallo
  final String placa;

  /// Nombre del gallo
  /// Identificador amigable para el usuario
  final String nombre;

  /// Sexo del gallo
  /// Valores permitidos: 'Macho' o 'Hembra'
  final String sexo;

  /// Fecha de nacimiento del gallo
  /// Se utiliza para calcular la edad
  final DateTime fechaNacimiento;

  /// Identificador del padre del gallo (nuevo nombre: `padreId`)
  /// Opcional para mantener registro genealógico
  /// Permite null si se desconoce o no existe registro
  final String? padreId;

  /// Identificador de la madre del gallo (nuevo nombre: `madreId`)
  /// Opcional para mantener registro genealógico
  /// Permite null si se desconoce o no existe registro
  final String? madreId;

  /// Compatibilidad: getters con nombres antiguos
  String? get idPadre => padreId;
  String? get idMadre => madreId;

  /// Línea genética del gallo
  /// Ejemplos: 'Kelso', 'Sweater', 'Blueface', 'Hatch'
  /// Determina la raza o línea de reproducción
  final String lineaGenetica;

  /// Color de las plumas del gallo
  /// Ejemplos: 'Rojo', 'Negro', 'Colorín', 'Dorado'
  /// Importante para identificación visual
  final String colorPluma;

  /// Fase lunar en la que nació el gallo
  /// Dato astrológico utilizado en algunas tradiciones de crianza
  /// Ejemplos: 'Luna Nueva', 'Cuarto Creciente', 'Luna Llena', 'Cuarto Menguante'
  final String faseLunar;

  /// Ruta local de la fotografía del gallo
  /// Opcional - permite null si no hay foto
  /// Se almacena la ruta local para cargar la imagen en la aplicación
  final String? fotoPath;

  /// Estado actual del gallo
  /// Valores permitidos: 'Activo', 'Vendido', 'Baja', 'Retirado'
  /// Determina si el gallo sigue activo en el sistema
  final String estado;

  /// Notas o comentarios adicionales sobre el gallo
  /// Campo opcional para información adicional
  /// Permite null si no hay notas
  final String? notas;

  /// Peso del gallo (puede estar en libras o kilos según la configuración)
  final double? peso;

  /// Identificador de la jaula o ubicación física
  final String? jaula;

  /// Criadero de origen. Por defecto 'Propio' cuando no se especifica
  final String criaderoOrigen;

  /// Constructor de la clase Gallo
  ///
  /// Nota: por compatibilidad con el código existente se aceptan los
  /// parámetros nombrados `idPadre` y `idMadre` en el constructor, pero
  /// internamente se almacenan en `padreId`/`madreId`.
  const Gallo({
    required this.id,
    required this.placa,
    required this.nombre,
    required this.sexo,
    required this.fechaNacimiento,
    required this.lineaGenetica,
    required this.colorPluma,
    required this.faseLunar,
    required this.estado,
    String? idPadre,
    String? idMadre,
    this.fotoPath,
    this.notas,
    this.peso,
    this.jaula,
    this.criaderoOrigen = 'Propio',
  }) : padreId = idPadre,
       madreId = idMadre;

  /// Convierte el objeto Gallo a un mapa para almacenamiento en SQLite
  ///
  /// Este método serializa todos los campos del gallo a un formato
  /// compatible con la base de datos SQLite.
  ///
  /// Retorna: [Map<String, dynamic>] con todos los datos del gallo
  ///
  /// Notas:
  /// - La fecha se convierte a formato ISO 8601 (String)
  /// - Los campos opcionales se incluyen con su valor actual (null si aplica)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'placa': placa,
      'nombre': nombre,
      'sexo': sexo,
      'fechaNacimiento': fechaNacimiento.toIso8601String(),
      // Guardar ambos nombres de campo para compatibilidad con esquemas
      'padreId': padreId,
      'idPadre': padreId,
      'madreId': madreId,
      'idMadre': madreId,
      'lineaGenetica': lineaGenetica,
      'colorPluma': colorPluma,
      'faseLunar': faseLunar,
      'fotoPath': fotoPath,
      'estado': estado,
      'notas': notas,
      'peso': peso,
      'jaula': jaula,
      'criaderoOrigen': criaderoOrigen,
    };
  }

  /// Crea un objeto Gallo a partir de un mapa de base de datos
  ///
  /// Factory constructor que deserializa los datos de SQLite
  /// hacia un objeto Gallo válido.
  ///
  /// Parámetro: [mapa] - Mapa con datos del gallo desde la base de datos
  ///
  /// Retorna: Una nueva instancia de [Gallo] con los datos del mapa
  ///
  /// Notas:
  /// - La fecha se convierte de formato ISO 8601 (String) a DateTime
  /// - Se asume que todos los campos obligatorios están presentes
  /// - Los campos opcionales pueden ser null
  factory Gallo.fromMap(Map<String, dynamic> mapa) {
    return Gallo(
      id: mapa['id'] as String,
      placa: mapa['placa'] as String,
      nombre: mapa['nombre'] as String,
      sexo: mapa['sexo'] as String,
      fechaNacimiento: DateTime.parse(mapa['fechaNacimiento'] as String),
      // Compatibilidad: leer el nuevo campo 'padreId' si existe, sino 'idPadre'
      idPadre: (mapa['padreId'] ?? mapa['idPadre']) as String?,
      idMadre: (mapa['madreId'] ?? mapa['idMadre']) as String?,
      lineaGenetica: mapa['lineaGenetica'] as String,
      colorPluma: mapa['colorPluma'] as String,
      faseLunar: mapa['faseLunar'] as String,
      fotoPath: mapa['fotoPath'] as String?,
      estado: mapa['estado'] as String,
      notas: mapa['notas'] as String?,
      peso: mapa['peso'] == null ? null : (mapa['peso'] as num).toDouble(),
      jaula: mapa['jaula'] as String?,
      criaderoOrigen: (mapa['criaderoOrigen'] as String?) ?? 'Propio',
    );
  }

  /// Método toString para depuración
  /// Retorna una representación legible del objeto Gallo
  @override
  String toString() {
    return 'Gallo(id: $id, placa: $placa, nombre: $nombre, sexo: $sexo, '
        'fechaNacimiento: $fechaNacimiento, lineaGenetica: $lineaGenetica, '
        'colorPluma: $colorPluma, estado: $estado, padreId: $padreId, madreId: $madreId, '
        'peso: $peso, jaula: $jaula, criaderoOrigen: $criaderoOrigen)';
  }

  /// Método de igualdad para comparar dos objetos Gallo
  /// Compara basándose en el ID único de cada gallo
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Gallo && runtimeType == other.runtimeType && id == other.id;

  /// Método hashCode para usar Gallo en conjuntos o mapas
  @override
  int get hashCode => id.hashCode;
}
