import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/financeiro_model.dart';
import '../models/cliente_model.dart';

class FinanceiroPdfService {
  static final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _fmtData = DateFormat('dd/MM/yyyy');

  static Future<void> gerarRelatorioAberto(String clienteNome, List<ContaPagar> titulos, {Cliente? cliente}) async {
    final pdf = pw.Document();

    final vencidos = titulos.where((t) => !t.pago && t.vencido).toList();
    final aVencer = titulos.where((t) => !t.pago && !t.vencido).toList();

    double totalVencido = vencidos.fold(0, (acc, t) => acc + t.valorOriginal);
    double totalAVencer = aVencer.fold(0, (acc, t) => acc + t.valorOriginal);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Extrato de Titulos em Aberto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                pw.Text(_fmtData.format(DateTime.now())),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          
          // Dados do Cliente
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.TableBorder.all(color: PdfColors.grey),
              color: PdfColors.grey50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Cliente: $clienteNome', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                if (cliente != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text('CPF/CNPJ: ${cliente.cnpjCpf ?? "—"}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Contato: ${cliente.celular ?? cliente.fone ?? "—"}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          if (vencidos.isNotEmpty) ...[
            pw.Text('TITULOS VENCIDOS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
            pw.Divider(color: PdfColors.red),
            _buildTable(vencidos),
            pw.SizedBox(height: 10),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Subtotal Vencido: ${_fmt.format(totalVencido)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
          ],

          if (aVencer.isNotEmpty) ...[
            pw.Text('TITULOS A VENCER', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
            pw.Divider(color: PdfColors.blue),
            _buildTable(aVencer),
            pw.SizedBox(height: 10),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Subtotal a Vencer: ${_fmt.format(totalAVencer)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
          ],

          pw.Divider(),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL EM ABERTO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.Text(_fmt.format(totalVencido + totalAVencer), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.red)),
              ],
            ),
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/extrato_${clienteNome.replaceAll(' ', '_')}.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'Extrato de títulos em aberto - $clienteNome');
  }

  static pw.Widget _buildTable(List<ContaPagar> titulos) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _cell('Emissao', bold: true),
            _cell('Vencimento', bold: true),
            _cell('Documento', bold: true),
            _cell('Parcela', bold: true),
            _cell('Valor', bold: true),
          ],
        ),
        ...titulos.map((t) => pw.TableRow(
          children: [
            _cell(_fmtData.format(t.dataOperacao)),
            _cell(_fmtData.format(t.dataVencimento)),
            _cell(t.documento ?? '—'),
            _cell(t.parcela),
            _cell(_fmt.format(t.valorOriginal)),
          ],
        )),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : null)),
    );
  }
}
