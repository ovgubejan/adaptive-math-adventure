import 'package:flutter/material.dart';

import '../content/consent_text.dart';
import '../widgets/family_widgets.dart';

/// Aydınlatma ve rıza metninin tamamını gösterir.
class LegalTextScreen extends StatelessWidget {
  const LegalTextScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const LegalTextScreen()));

  @override
  Widget build(BuildContext context) => FamilyPage(
    title: ConsentText.title,
    leading: IconButton(
      key: const ValueKey('legal-close'),
      tooltip: 'Kapat',
      icon: const Icon(Icons.close),
      onPressed: () => Navigator.of(context).pop(),
    ),
    maxWidth: 720,
    children: [
      if (ConsentText.isDraft)
        const FamilyCard(
          children: [
            Text(
              ConsentText.draftNotice,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      for (final section in ConsentText.sections)
        FamilyCard(
          title: section.title,
          children: [Text(section.body, style: const TextStyle(height: 1.4))],
        ),
    ],
  );
}

/// Rıza özetini, tam metne bağlantıyı ve onay kutusunu gösteren ortak parça.
/// Hem ilk kurulumda hem metin güncellendiğinde kullanılır.
class ConsentForm extends StatelessWidget {
  final bool accepted;
  final ValueChanged<bool> onAcceptedChanged;

  const ConsentForm({
    required this.accepted,
    required this.onAcceptedChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FamilyCard(
        title: 'Kısaca',
        children: [
          for (final point in ConsentText.summaryPoints)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(child: Text(point)),
                ],
              ),
            ),
          if (ConsentText.isDraft)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                ConsentText.draftNotice,
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('consent-read-full'),
              onPressed: () => LegalTextScreen.open(context),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Tam metni oku'),
            ),
          ),
        ],
      ),
      CheckboxListTile(
        key: const ValueKey('consent-checkbox'),
        value: accepted,
        onChanged: (value) => onAcceptedChanged(value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        title: const Text(ConsentText.consentStatement),
      ),
    ],
  );
}
