import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'cliente_tema.dart';

final brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

/// Bloco cinza que "respira" enquanto o conteúdo carrega.
class Esqueleto extends StatefulWidget {
  final double? altura;
  final double radius;
  const Esqueleto({super.key, this.altura, this.radius = 16});
  @override
  State<Esqueleto> createState() => _EsqueletoState();
}

class _EsqueletoState extends State<Esqueleto> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          height: widget.altura,
          decoration: BoxDecoration(
            color: Color.lerp(const Color(0xFFE9E9EE), const Color(0xFFF5F5F8), _c.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      );
}

/// Foto do produto: esqueleto enquanto baixa, aparece com fade, ícone se falhar.
class FotoProduto extends StatelessWidget {
  final String url;
  final BoxFit fit;
  const FotoProduto({super.key, required this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) => Image.network(
        url,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        frameBuilder: (_, child, frame, sync) => sync
            ? child
            : AnimatedOpacity(
                opacity: frame == null ? 0 : 1, duration: const Duration(milliseconds: 350), child: child),
        loadingBuilder: (_, child, p) => p == null ? child : const Esqueleto(radius: 0),
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFEFEFF3),
          child: const Center(child: Icon(Icons.image_not_supported_outlined, color: ClienteTema.suave)),
        ),
      );
}

/// Faixa de estado vazio / erro, com ação opcional.
class EstadoVazio extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String? texto;
  final String? acao;
  final VoidCallback? onAcao;
  const EstadoVazio(
      {super.key, required this.icone, required this.titulo, this.texto, this.acao, this.onAcao});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: ClienteTema.marca.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(icone, size: 44, color: ClienteTema.marca),
            ),
            const SizedBox(height: 18),
            Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            if (texto != null) ...[
              const SizedBox(height: 6),
              Text(texto!, textAlign: TextAlign.center, style: const TextStyle(color: ClienteTema.suave)),
            ],
            if (acao != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: 220,
                child: ElevatedButton(onPressed: onAcao, child: Text(acao!)),
              ),
            ],
          ]),
        ),
      );
}
