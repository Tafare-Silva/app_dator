/// Lojas do cliente (matriz + filiais) -- cada uma com seu próprio banco no
/// backend. `id` precisa bater exatamente com as chaves de `EMPRESAS` em
/// `app/core/config.py` no backend.
class Empresa {
  final String id;
  final String nome;

  const Empresa({required this.id, required this.nome});
}

const List<Empresa> empresasDisponiveis = [
  Empresa(id: 'puro_estilo_bandeirantes', nome: 'Feminino/Kids'),
  Empresa(id: 'puro_estilo_kids', nome: 'Linda de Bonito'),
  Empresa(id: 'puro_estilo_santa_mariana', nome: 'Masculino'),
];
