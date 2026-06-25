class HorarioProfissional {
  final int? id;
  final int idProfissional;
  final int diaSemana; // 0=dom, 1=seg, …, 6=sab
  final String horaInicio; // HH:MM
  final String horaFim; // HH:MM
  final int intervaloMin;
  final bool ativo;

  HorarioProfissional({
    this.id,
    required this.idProfissional,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFim,
    this.intervaloMin = 60,
    this.ativo = true,
  });

  factory HorarioProfissional.fromJson(Map<String, dynamic> json) =>
      HorarioProfissional(
        id: json['id'] == null ? null : (json['id'] as num).toInt(),
        idProfissional: (json['id_profissional'] as num).toInt(),
        diaSemana: (json['dia_semana'] as num).toInt(),
        horaInicio: json['hora_inicio'].toString().substring(0, 5),
        horaFim: json['hora_fim'].toString().substring(0, 5),
        intervaloMin: json['intervalo_min'] == null
            ? 60
            : (json['intervalo_min'] as num).toInt(),
        ativo: json['ativo'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'id_profissional': idProfissional,
        'dia_semana': diaSemana,
        'hora_inicio': horaInicio,
        'hora_fim': horaFim,
        'intervalo_min': intervaloMin,
        'ativo': ativo,
      };
}
