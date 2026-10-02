# Lumen

App Flutter para acompanhamento de TDAH, sono, rotina e compartilhamento clínico.

## Documentação

- **[GDD completo](docs/GDD.md)** — visão, features atuais, tasks, roadmap e backlog futuro

## Internacionalização

Strings em ARB (`lib/l10n/`), fonte em português. Traduções `en` / `ja` / `es` via [doloc](https://doloc.io/getting-started/frameworks/flutter/):

```bash
export API_TOKEN=seu_token
dart run tool/doloc.dart
flutter gen-l10n
```

Detalhes: [docs/i18n.md](docs/i18n.md).

## Getting Started

```bash
flutter pub get
flutter run
```

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
