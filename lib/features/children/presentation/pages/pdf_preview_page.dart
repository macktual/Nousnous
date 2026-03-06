import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Arguments pour afficher l’aperçu d’un PDF (impression / enregistrement).
class PdfPreviewArgs {
  const PdfPreviewArgs({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

/// Page qui affiche un PDF avec les boutons Imprimer et Partager/Enregistrer.
/// Pour les PDF multi-pages : titre et numérotation « Page n / total » au-dessus de chaque page.
class PdfPreviewPage extends StatelessWidget {
  const PdfPreviewPage({super.key, required this.args});

  final PdfPreviewArgs args;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(args.filename),
      ),
      body: SafeArea(
        child: LayoutBuilder(
        builder: (context, constraints) {
          // Estimation hauteur page A4 (ratio 297/210) pour centrer en hauteur
          final pageWidth = (constraints.maxWidth - 40).clamp(200.0, 600.0);
          final pageHeight = pageWidth * (297 / 210);
          final verticalMargin = ((constraints.maxHeight - pageHeight) / 2).clamp(0.0, double.infinity);
          return PdfPreview.builder(
            build: (PdfPageFormat format) => Future<Uint8List>.value(args.bytes),
            allowPrinting: true,
            allowSharing: true,
            canDebug: false,
            pdfFileName: args.filename,
            padding: EdgeInsets.symmetric(vertical: verticalMargin),
            scrollViewDecoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
            pdfPreviewPageDecoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
            pagesBuilder: (context, pages) {
              final total = pages.length;
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                panEnabled: true,
                scaleEnabled: true,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: verticalMargin),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < pages.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Text(
                            total > 1
                                ? '${args.filename} — Page ${i + 1} / $total'
                                : args.filename,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 20, top: 4, right: 20, bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor.withValues(alpha: 0.2),
                                offset: const Offset(0, 3),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: AspectRatio(
                            aspectRatio: pages[i].aspectRatio,
                            child: Image(
                              image: pages[i].image,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
            onError: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erreur : $error'),
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}
