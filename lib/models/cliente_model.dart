class Cliente {
  final int pkChave;
  final String nome;
  final String? cnpjCpf;
  final String? fone;
  final String? celular;

  const Cliente({
    required this.pkChave,
    required this.nome,
    this.cnpjCpf,
    this.fone,
    this.celular,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
        pkChave: json['pk_chave'] as int,
        nome: (json['nome'] as String?) ?? '',
        cnpjCpf: json['cnpj_cpf'] as String?,
        fone: json['fone'] as String?,
        celular: json['celular'] as String?,
      );
}
