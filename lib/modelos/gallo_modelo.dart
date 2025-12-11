/// Clase modelo para la entidad Gallo
///
/// Representa un gallo en la aplicación CastaSoft con todas sus características
/// genéticas, físicas y administrativas.
///
/// Propiedades principales:
/// - Identificación única (id, placa)
/// - Datos personales (nombre, sexo, fecha de nacimiento)
/// - Genealogía (padre, madre, línea genética)
/// - Características físicas (color de pluma)
/// - Información adicional (fase lunar, estado, notas)
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

  /// Identificador del padre del gallo
  /// Opcional para mantener registro genealógico
  /// Permite null si se desconoce o no existe registro
  final String? idPadre;

  /// Identificador de la madre del gallo
  /// Opcional para mantener registro genealógico
  /// Permite null si se desconoce o no existe registro
  final String? idMadre;

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
  /// Valores permitidos: 'Activo', 'Vendido', 'Baja'
  /// Determina si el gallo sigue activo en el sistema
  final String estado;

  /// Notas o comentarios adicionales sobre el gallo
  /// Campo opcional para información adicional
  /// Permite null si no hay notas
  final String? notas;

  /// Constructor de la clase Gallo
  ///
  /// Parámetros:
  /// - [id] - Identificador único (obligatorio)
  /// - [placa] - Número de anillo (obligatorio)
  /// - [nombre] - Nombre del gallo (obligatorio)
  /// - [sexo] - Sexo del gallo (obligatorio)
  /// - [fechaNacimiento] - Fecha de nacimiento (obligatorio)
  /// - [lineaGenetica] - Línea genética (obligatorio)
  /// - [colorPluma] - Color de pluma (obligatorio)
  /// - [faseLunar] - Fase lunar de nacimiento (obligatorio)
  /// - [estado] - Estado del gallo (obligatorio)
  /// - [idPadre] - ID del padre (opcional)
  /// - [idMadre] - ID de la madre (opcional)
  /// - [fotoPath] - Ruta de la foto (opcional)
  /// - [notas] - Notas adicionales (opcional)
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
    this.idPadre,
    this.idMadre,
    this.fotoPath,
    this.notas,
  });

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
      'idPadre': idPadre,
      'idMadre': idMadre,
      'lineaGenetica': lineaGenetica,
      'colorPluma': colorPluma,
      'faseLunar': faseLunar,
      'fotoPath': fotoPath,
      'estado': estado,
      'notas': notas,
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
      idPadre: mapa['idPadre'] as String?,
      idMadre: mapa['idMadre'] as String?,
      lineaGenetica: mapa['lineaGenetica'] as String,
      colorPluma: mapa['colorPluma'] as String,
      faseLunar: mapa['faseLunar'] as String,
      fotoPath: mapa['fotoPath'] as String?,
      estado: mapa['estado'] as String,
      notas: mapa['notas'] as String?,
    );
  }

  /// Método toString para depuración
  /// Retorna una representación legible del objeto Gallo
  @override
  String toString() {
    return 'Gallo(id: $id, placa: $placa, nombre: $nombre, sexo: $sexo, '
        'fechaNacimiento: $fechaNacimiento, lineaGenetica: $lineaGenetica, '
        'colorPluma: $colorPluma, estado: $estado)';
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
