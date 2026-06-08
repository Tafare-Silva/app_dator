import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/vendas_models.dart';

class PreVendaPdfService {
  static final _fmtMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _fmtDataHora = DateFormat('dd/MM/yyyy HH:mm:ss');

  // Largura de 80 mm (papel térmico padrão)
  static final _formato = PdfPageFormat(
    80 * PdfPageFormat.mm,
    297 * PdfPageFormat.mm, // A4 height — será cortado pelo conteúdo
    marginTop: 4 * PdfPageFormat.mm,
    marginBottom: 4 * PdfPageFormat.mm,
    marginLeft: 3 * PdfPageFormat.mm,
    marginRight: 3 * PdfPageFormat.mm,
  );

  static Future<void> compartilhar(PreVendaDetalhe pv, {String nomeEmpresa = ''}) async {
    final bytes = await _gerar(pv, nomeEmpresa: nomeEmpresa);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/pre_venda_${pv.pkChave}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Pré-Venda #${pv.pkChave}',
    );
  }

  static Future<void> visualizar(PreVendaDetalhe pv, {String nomeEmpresa = ''}) async {
    await Printing.layoutPdf(onLayout: (_) => _gerar(pv, nomeEmpresa: nomeEmpresa));
  }

  static Future<Uint8List> _gerar(PreVendaDetalhe pv, {String nomeEmpresa = ''}) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontMono = await PdfGoogleFonts.robotoMonoRegular();

    final totalItens = pv.itens.fold<double>(0, (s, i) => s + i.quantidade);

    doc.addPage(pw.Page(
      pageFormat: _formato,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── Nome da empresa ──────────────────────────────────────────────
          if (nomeEmpresa.isNotEmpty) ...[
            pw.Center(
              child: pw.Text(
                nomeEmpresa.toUpperCase(),
                style: pw.TextStyle(font: fontBold, fontSize: 11),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 3),
          ],

          // ── Número e data ────────────────────────────────────────────────
          pw.Text('CONDICIONAL: ${pv.pkChave}', style: pw.TextStyle(font: fontBold, fontSize: 9)),
          pw.Text(_fmtDataHora.format(pv.data), style: pw.TextStyle(font: font, fontSize: 8)),

          pw.SizedBox(height: 6),
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 4),

          // ── Dados do cliente ─────────────────────────────────────────────
          if (pv.clienteNome != null) ...[
            _linha(fontBold, font, 'Cliente:', pv.clienteNome!),
            pw.SizedBox(height: 2),
          ],
          pw.SizedBox(height: 2),
          if (pv.vendedorNome != null)
            _linha(fontBold, font, 'Vendedor:', pv.vendedorNome!),

          pw.SizedBox(height: 6),
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 4),

          // ── Cabeçalho da tabela de itens ─────────────────────────────────
          pw.Row(children: [
            pw.Expanded(child: pw.Text('COD  Descrição', style: pw.TextStyle(font: fontBold, fontSize: 8))),
          ]),
          pw.Row(children: [
            pw.SizedBox(width: 16),
            pw.Expanded(child: pw.Text('QTD', style: pw.TextStyle(font: fontBold, fontSize: 8))),
            pw.Text('Vl.Unit', style: pw.TextStyle(font: fontBold, fontSize: 8)),
            pw.SizedBox(width: 4),
            pw.SizedBox(
              width: 50,
              child: pw.Text('Vl.Total', style: pw.TextStyle(font: fontBold, fontSize: 8), textAlign: pw.TextAlign.right),
            ),
          ]),
          pw.Divider(thickness: 0.3),

          // ── Itens ────────────────────────────────────────────────────────
          ...pv.itens.map((item) {
            final qtdStr = item.quantidade == item.quantidade.truncateToDouble()
                ? item.quantidade.toStringAsFixed(0)
                : item.quantidade.toStringAsFixed(2);
            final nome = item.produtoNome ?? 'Produto #${item.produtoId}';
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${item.produtoId} - $nome',
                  style: pw.TextStyle(font: fontMono, fontSize: 7),
                ),
                pw.Row(children: [
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: pw.Text(qtdStr, style: pw.TextStyle(font: fontMono, fontSize: 7))),
                  pw.Text(_fmtMoeda.format(item.vrUnitarioBruto), style: pw.TextStyle(font: fontMono, fontSize: 7)),
                  pw.SizedBox(width: 4),
                  pw.SizedBox(
                    width: 50,
                    child: pw.Text(_fmtMoeda.format(item.vrTotalLiquido), style: pw.TextStyle(font: fontMono, fontSize: 7), textAlign: pw.TextAlign.right),
                  ),
                ]),
                if (item.vrDescontoTotal > 0)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 8),
                    child: pw.Text('Desconto: ${_fmtMoeda.format(item.vrDescontoTotal)}', style: pw.TextStyle(font: font, fontSize: 7)),
                  ),
                pw.SizedBox(height: 3),
              ],
            );
          }),

          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 4),

          // ── Totais ───────────────────────────────────────────────────────
          pw.Row(children: [
            pw.Expanded(child: pw.Text('TOTAL DE ITENS: ${totalItens.toStringAsFixed(0)}', style: pw.TextStyle(font: fontBold, fontSize: 9))),
          ]),
          pw.SizedBox(height: 3),
          pw.Row(children: [
            pw.Expanded(child: pw.Text('TOTAL:', style: pw.TextStyle(font: fontBold, fontSize: 10))),
            pw.Text(_fmtMoeda.format(pv.vrTotal), style: pw.TextStyle(font: fontBold, fontSize: 10)),
          ]),

          pw.SizedBox(height: 20),
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 30),
          pw.Center(child: pw.SizedBox(width: 120, child: pw.Divider(thickness: 0.5))),
          pw.SizedBox(height: 2),
          pw.Center(child: pw.Text('ASSINATURA', style: pw.TextStyle(font: font, fontSize: 8))),
        ],
      ),
    ));

    return doc.save();
  }

  static pw.Widget _linha(pw.Font bold, pw.Font regular, String label, String valor) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(font: bold, fontSize: 8)),
        pw.SizedBox(width: 4),
        pw.Expanded(child: pw.Text(valor, style: pw.TextStyle(font: regular, fontSize: 8))),
      ],
    );
  }
}
