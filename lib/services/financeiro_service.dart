import 'package:intl/intl.dart';
import '../models/financeiro_model.dart';
import 'api_client.dart';

final _dateFmt = DateFormat('yyyy-MM-dd');

class FinanceiroService {
  final _client = ApiClient();

  // --- Contas a PAGAR ---

  Future<List<ContaPagar>> listarContasPagar({
    DateTime? dataInicio,
    DateTime? dataFim,
    DateTime? dataBaixaInicio,
    DateTime? dataBaixaFim,
    int? pessoaId,
    int? planoContasId,
    int? centroCustosId,
    String? situacao,
    int limit = 500,
    int offset = 0,
  }) async {
    final response = await _client.dio.get(
      '/financeiro/contas-pagar',
      queryParameters: {
        if (dataInicio != null) 'data_inicio': _dateFmt.format(dataInicio),
        if (dataFim != null) 'data_fim': _dateFmt.format(dataFim),
        if (dataBaixaInicio != null) 'data_baixa_inicio': _dateFmt.format(dataBaixaInicio),
        if (dataBaixaFim != null) 'data_baixa_fim': _dateFmt.format(dataBaixaFim),
        if (pessoaId != null) 'pessoa_id': pessoaId,
        if (planoContasId != null) 'plano_contas_id': planoContasId,
        if (centroCustosId != null) 'centro_custos_id': centroCustosId,
        if (situacao != null) 'situacao': situacao,
        'limit': limit,
        'offset': offset,
      },
    );
    return (response.data as List).map((e) => ContaPagar.fromJson(e)).toList();
  }

  Future<ResumoContasPagar> getResumo({
    DateTime? dataInicio,
    DateTime? dataFim,
    DateTime? dataBaixaInicio,
    DateTime? dataBaixaFim,
    int? pessoaId,
    int? planoContasId,
    int? centroCustosId,
    String? situacao,
  }) async {
    final response = await _client.dio.get(
      '/financeiro/contas-pagar/resumo',
      queryParameters: {
        if (dataInicio != null) 'data_inicio': _dateFmt.format(dataInicio),
        if (dataFim != null) 'data_fim': _dateFmt.format(dataFim),
        if (dataBaixaInicio != null) 'data_baixa_inicio': _dateFmt.format(dataBaixaInicio),
        if (dataBaixaFim != null) 'data_baixa_fim': _dateFmt.format(dataBaixaFim),
        if (pessoaId != null) 'pessoa_id': pessoaId,
        if (planoContasId != null) 'plano_contas_id': planoContasId,
        if (centroCustosId != null) 'centro_custos_id': centroCustosId,
        if (situacao != null) 'situacao': situacao,
      },
    );
    return ResumoContasPagar.fromJson(response.data);
  }

  // --- Contas a RECEBER ---

  Future<List<ContaPagar>> listarContasReceber({
    DateTime? dataInicio,
    DateTime? dataFim,
    DateTime? dataBaixaInicio,
    DateTime? dataBaixaFim,
    int? pessoaId,
    int? planoContasId,
    int? centroCustosId,
    String? situacao,
    int limit = 500,
    int offset = 0,
  }) async {
    final response = await _client.dio.get(
      '/financeiro/contas-receber',
      queryParameters: {
        if (dataInicio != null) 'data_inicio': _dateFmt.format(dataInicio),
        if (dataFim != null) 'data_fim': _dateFmt.format(dataFim),
        if (dataBaixaInicio != null) 'data_baixa_inicio': _dateFmt.format(dataBaixaInicio),
        if (dataBaixaFim != null) 'data_baixa_fim': _dateFmt.format(dataBaixaFim),
        if (pessoaId != null) 'pessoa_id': pessoaId,
        if (planoContasId != null) 'plano_contas_id': planoContasId,
        if (centroCustosId != null) 'centro_custos_id': centroCustosId,
        if (situacao != null) 'situacao': situacao,
        'limit': limit,
        'offset': offset,
      },
    );
    return (response.data as List).map((e) => ContaPagar.fromJson(e)).toList();
  }

  Future<ResumoContasPagar> getResumoReceber({
    DateTime? dataInicio,
    DateTime? dataFim,
    DateTime? dataBaixaInicio,
    DateTime? dataBaixaFim,
    int? pessoaId,
    int? planoContasId,
    int? centroCustosId,
    String? situacao,
  }) async {
    final response = await _client.dio.get(
      '/financeiro/contas-receber/resumo',
      queryParameters: {
        if (dataInicio != null) 'data_inicio': _dateFmt.format(dataInicio),
        if (dataFim != null) 'data_fim': _dateFmt.format(dataFim),
        if (dataBaixaInicio != null) 'data_baixa_inicio': _dateFmt.format(dataBaixaInicio),
        if (dataBaixaFim != null) 'data_baixa_fim': _dateFmt.format(dataBaixaFim),
        if (pessoaId != null) 'pessoa_id': pessoaId,
        if (planoContasId != null) 'plano_contas_id': planoContasId,
        if (centroCustosId != null) 'centro_custos_id': centroCustosId,
        if (situacao != null) 'situacao': situacao,
      },
    );
    return ResumoContasPagar.fromJson(response.data);
  }

  // --- Auxiliares ---

  Future<List<FiltroItem>> listarFornecedores() async {
    final r = await _client.dio.get('/financeiro/fornecedores');
    return (r.data as List).map((e) => FiltroItem.fromJson(e)).toList();
  }

  Future<List<FiltroItem>> listarClientes() async {
    final r = await _client.dio.get('/financeiro/clientes');
    return (r.data as List).map((e) => FiltroItem.fromJson(e)).toList();
  }

  Future<List<FiltroItem>> listarPlanosContas() async {
    final r = await _client.dio.get('/financeiro/planos-contas');
    return (r.data as List).map((e) => FiltroItem.fromJson(e)).toList();
  }

  Future<List<FiltroItem>> listarCentrosCustos() async {
    final r = await _client.dio.get('/financeiro/centros-custos');
    return (r.data as List).map((e) => FiltroItem.fromJson(e)).toList();
  }

  // --- Apuração de Resultados ---

  Future<List<GrupoFinanceiro>> despesasPorPlanoContas({
    DateTime? dataInicio,
    DateTime? dataFim,
    DateTime? dataBaixaInicio,
    DateTime? dataBaixaFim,
    String? situacao,
    int? centroCustosId,
  }) async {
    final r = await _client.dio.get(
      '/financeiro/despesas/por-plano-contas',
      queryParameters: {
        if (dataInicio != null) 'data_inicio': _dateFmt.format(dataInicio),
        if (dataFim != null) 'data_fim': _dateFmt.format(dataFim),
        if (dataBaixaInicio != null) 'data_baixa_inicio': _dateFmt.format(dataBaixaInicio),
        if (dataBaixaFim != null) 'data_baixa_fim': _dateFmt.format(dataBaixaFim),
        if (situacao != null) 'situacao': situacao,
        if (centroCustosId != null) 'centro_custos_id': centroCustosId,
      },
    );
    return (r.data as List).map((e) => GrupoFinanceiro.fromJson(e)).toList();
  }

  Future<List<GrupoFinanceiro>> despesasPorCentroCusto({
    DateTime? dataInicio,
    DateTime? dataFim,
    DateTime? dataBaixaInicio,
    DateTime? dataBaixaFim,
    String? situacao,
    int? planoContasId,
  }) async {
    final r = await _client.dio.get(
      '/financeiro/despesas/por-centro-custo',
      queryParameters: {
        if (dataInicio != null) 'data_inicio': _dateFmt.format(dataInicio),
        if (dataFim != null) 'data_fim': _dateFmt.format(dataFim),
        if (dataBaixaInicio != null) 'data_baixa_inicio': _dateFmt.format(dataBaixaInicio),
        if (dataBaixaFim != null) 'data_baixa_fim': _dateFmt.format(dataBaixaFim),
        if (situacao != null) 'situacao': situacao,
        if (planoContasId != null) 'plano_contas_id': planoContasId,
      },
    );
    return (r.data as List).map((e) => GrupoFinanceiro.fromJson(e)).toList();
  }

  Future<List<GrupoFinanceiro>> receitasPorPlanoContas({
    DateTime? dataInicio,
    DateTime? dataFim,
    DateTime? dataBaixaInicio,
    DateTime? dataBaixaFim,
    String? situacao,
    int? centroCustosId,
  }) async {
    final r = await _client.dio.get(
      '/financeiro/receitas/por-plano-contas',
      queryParameters: {
        if (dataInicio != null) 'data_inicio': _dateFmt.format(dataInicio),
        if (dataFim != null) 'data_fim': _dateFmt.format(dataFim),
        if (dataBaixaInicio != null) 'data_baixa_inicio': _dateFmt.format(dataBaixaInicio),
        if (dataBaixaFim != null) 'data_baixa_fim': _dateFmt.format(dataBaixaFim),
        if (situacao != null) 'situacao': situacao,
        if (centroCustosId != null) 'centro_custos_id': centroCustosId,
      },
    );
    return (r.data as List).map((e) => GrupoFinanceiro.fromJson(e)).toList();
  }

  Future<ApuracaoResultado> getApuracaoResultado({
    DateTime? dataInicio,
    DateTime? dataFim,
    DateTime? dataBaixaInicio,
    DateTime? dataBaixaFim,
    String? situacao,
  }) async {
    final r = await _client.dio.get(
      '/financeiro/dre',
      queryParameters: {
        if (dataInicio != null) 'data_inicio': _dateFmt.format(dataInicio),
        if (dataFim != null) 'data_fim': _dateFmt.format(dataFim),
        if (dataBaixaInicio != null) 'data_baixa_inicio': _dateFmt.format(dataBaixaInicio),
        if (dataBaixaFim != null) 'data_baixa_fim': _dateFmt.format(dataBaixaFim),
        if (situacao != null) 'situacao': situacao,
      },
    );
    return ApuracaoResultado.fromJson(r.data);
  }

  Future<VendidoRecebido> getVendidoVsRecebido({
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    final r = await _client.dio.get(
      '/financeiro/vendido-vs-recebido',
      queryParameters: {
        'data_inicio': _dateFmt.format(dataInicio),
        'data_fim': _dateFmt.format(dataFim),
      },
    );
    return VendidoRecebido.fromJson(r.data);
  }
}
