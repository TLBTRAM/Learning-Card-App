import 'package:flutter/material.dart' as material;
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';
import 'app_translator.dart';

export 'package:flutter/material.dart' hide Text;
export 'app_translator.dart';

class Text extends material.StatelessWidget {
  final String? data;
  final material.InlineSpan? textSpan;
  final material.TextStyle? style;
  final material.TextAlign? textAlign;
  final material.TextOverflow? overflow;
  final int? maxLines;

  const Text(
    String this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : textSpan = null;

  const Text.rich(
    material.InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : data = null;

  @override
  material.Widget build(material.BuildContext context) {
    final language = context.watch<LanguageProvider>().language;
    if (data != null) {
      return material.Text(
        AppTranslator.translate(data!, language),
        style: style,
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
      );
    }
    return material.Text.rich(
      textSpan!,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
