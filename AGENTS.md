# Agents.md

Você é o engenheiro Flutter do Lumen. Entrega a feature pedida no formato do código que já existe. Navegação, texto, tema e feedback saem do aparelho, para o fluxo seguir fluido.

## Projeto

Lumen (package `noa`) é o companion e prótese executiva para pessoas com TDAH: registra humor, foco, rotina, medicação e gastos de hiperfoco, cruza dados de sono do Apple Health, centraliza o Raio-X do dia no calendário e gera resumos para o terapeuta. Offline primeiro.

O tom de voz é **100% humanizado**, livre de dialetos robóticos de IA, sermões ou clichês engessados de autoajuda. Suporta perfis de voz customizáveis (despojado, casual, não-formal, formal, feminino/mulheres, meninas e meninos), mantendo sempre proximidade, naturalidade e empatia sem culpa.

O escopo do item está em @docs/GDD.md (§6, §7, §8 e §14). @docs/PRD.md descreve o protótipo. Se os dois divergirem na stack ou no que o código já faz, vale o GDD.

## Comandos

Na pasta do app:

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter run`
- `flutter gen-l10n` — depois de editar só `lib/l10n/app_pt.arb`
- `dart run tool/doloc.dart && flutter gen-l10n` — `API_TOKEN` no ambiente, nunca no arquivo

A mudança fecha com `flutter analyze` sem issues e `flutter test` passando.

## Stack

- Dart SDK `^3.11.5`, Flutter do SDK do projeto, `flutter_localizations` (SDK)
- Estado: `flutter_riverpod ^2.6.1`
- Persistência: `shared_preferences ^2.5.5`, `path_provider ^2.1.6`, `uuid ^4.6.0`
- Saúde: `health ^13.3.2` e `ios/Runner/HealthKitBridge.swift` (channel `dev.prism.lumen/healthkit_bridge`)
- Sistema: `flutter_local_notifications ^22.3.1`, `share_plus ^13.3.0`, `printing ^5.14.3`, `pdf ^3.12.0`, `url_launcher ^6.3.2`
- UI: `fl_chart ^1.2.0`, `intl 0.20.2`, `cupertino_icons ^1.0.9`, `liquid_glass_renderer` (Impeller)
- Dev: `flutter_test` (SDK), `flutter_lints ^6.0.0`
- iOS é a plataforma primária. Android usa o mesmo domínio.

Dado persistido passa por Riverpod. `setState` fica no formulário da própria tela: seleção, flag de salvando, contagem do Des-Trava.

## Estrutura de Pastas

```
lib/features/<feature>/{domain,data,service,presentation}
lib/core/                         tema, i18n, widgets
lib/integrations/health/          HealthService facade + HealthAppConnector
lib/integrations/samsung_health_bridge/
lib/integrations/healthkit_bridge/
ios/Runner/HealthKitBridge.swift
lib/l10n/app_pt.arb
test/
```

Tela chama provider. Provider chama repositório ou serviço. Repositório fala com SharedPreferences. Saúde fala com `HealthService`. A UI não abre `MethodChannel`, `SharedPreferences` nem `Platform.isIOS`.

Domínio não importa Flutter. Modelo imutável, um tipo por conceito do GDD, com `toMap` / `fromMap`. Import interno no mesmo estilo do arquivo vizinho.

## Convenções

- Arquivo `snake_case`, tipo `PascalCase`, membro `camelCase`
- String de UI só em `lib/l10n/app_pt.arb`, chave `camelCase`. Labels de State of Mind ficam em `state_of_mind_*.dart`
- Chave de prefs: `noa_*` com sufixo de versão (`noa_mood_entries_v2`)
- Cor, espaço e raio em `AppColors`, `AppSpacing`, `AppRadii`. Superfície em `GlassSurface`. Ícone em `AppIcons`. CTA `#1FAF8A`. Fundo sólido

## Sistema

Cada gesto, texto, tema e aviso reusa a API do aparelho. A tela lê `MediaQuery` e o tema. Não desenhe de novo o que o Flutter já entrega.

- Voltar: gesto do iOS e predictive back do Android (`PopScope`). A home não consome o back.
- Check-in, forms e gavetas com teclado: **`showLumenSheet`** (+ `GlassSheet` ou `LumenKeyboardInset`, **`useRootNavigator: true`**). Sem root navigator a gaveta abre atrás da `GlassNavBar` e cobre o CTA. **Nunca** `useSafeArea: true` + `Padding(viewInsets)` + `GlassSheet` no mesmo fluxo. Sem `expandChild: true` em form longo. Rotina, medicações e hub: `MaterialPageRoute` a partir de `LumenShell`.
- Teclado, notch e Dynamic Island: `SafeArea` nas telas; sheets usam `LumenKeyboardInset` / `GlassSheet` (`lumenSheetBottomInset`). Sem altura fixa no lugar do teclado. **`LumenShell` e scaffolds de aba / `GlassScaffold`: `resizeToAvoidBottomInset: false`** — tab bar e abas não sobem com o teclado; só a gaveta redimensiona. `GlassScaffold` empura o body abaixo de `reservedTop` (texto/gráfico nunca sob a app bar).
- Hora da dose: `showTimePicker`. Data: `showDatePicker`. Formato: `intl` com o locale ativo.
- Atualizar sono: `RefreshIndicator`. Toque de confirmar: `HapticFeedback`. Tema: `ThemeMode.system`.
- Texto grande, negrito, contraste e reduzir movimento: ler o `MediaQuery` e manter o `textScaler`. Com reduzir movimento, a orb do Des-Trava fica estática.
- Leitor de tela: `Semantics` no check-in, na dose e no Des-Trava.
- Lista que cresce: `ListView.builder`. Gráfico: `RepaintBoundary`. Health no provider, no pull-to-refresh ou na sync incremental (`HKAnchoredObjectQuery` / `getChanges`, agregação no sistema). O `build` não lê HealthKit.
- Dose: canal `medication_reminders`, ações e fuso do aparelho, em `medication_reminder_service.dart`. Compartilhar: `share_plus` e `printing`. WhatsApp: `url_launcher` + `canLaunchUrl`.
- Saúde: a função existe nas duas plataformas (`docs/GDD.md` §9.0). Android escolhe `SamsungHealthConnector` quando o Samsung Health está instalado (Data SDK se o AAR estiver em `android/app/libs/`), senão `HealthConnectConnector`; gaps caem no HC. Apps OEM (Mi/Huawei/Garmin) → UX instrui sync com Health Connect. Ponte mútua só quando o connector e o par iOS têm o mesmo tipo. State of Mind, agenda de medicação, luz e áudio: espelho só no HealthKit; no Android ficam no domínio local. HRV é SDNN no iOS e RMSSD no Android.

Widget, App Intent, relógio e Focus entram só quando o GDD promove o `FUT-*`. Até lá, a fluidez mora nas APIs desta seção.

## Padrões de Código

```dart
class MoodEntry {
  const MoodEntry({
    required this.id,
    required this.timestamp,
    required this.valence,
  });

  final String id;
  final DateTime timestamp;
  final int valence;

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'valence': valence,
      };
}
```

```dart
Future<void> openFormSheet(BuildContext context) {
  return showLumenSheet<void>(
    context: context,
    builder: (context) => const GlassSheet(
      child: /* form — scroll do GlassSheet; sem NestedScroll / expandChild */,
    ),
  );
}
```

Código que não entra no app: frase de culpa na tela, cópia robótica/engessada de IA, lembrete de dose com `Timer`, e sheet com teclado via `showModalBottomSheet`+`useSafeArea: true`+`Padding(viewInsets)` (use `showLumenSheet`). O countdown de 60 segundos do Des-Trava permanece na sheet.

```dart
Text('Você falhou o hábito de hoje');
Text('Tudo bem, seu ritmo é seguro e acolhedor'); // Robótico / IA cliché proibido
Timer.periodic(const Duration(minutes: 15), (_) => notifyDose());
```

A cópia de pular dose ou hábito é humana, casual e direta conforme o perfil ativo (ex: *"Sem estresse, fica pra próxima"* ou *"Tranquilo, bora pro que dá hoje"*).

## Testes

Regra nova de domínio ganha teste em `test/`. A suíte que falha permanece até o código passar.

```dart
test('SleepRecord marca déficit de sono e de REM', () {
  final night = SleepRecord(
    date: DateTime(2026, 9, 20),
    bedtime: DateTime(2026, 9, 20, 1),
    wakeTime: DateTime(2026, 9, 20, 6, 15),
    totalSleep: const Duration(hours: 5, minutes: 15),
    remSleep: const Duration(minutes: 40),
    deepSleep: const Duration(minutes: 35),
  );

  expect(night.hasSleepDeficit, isTrue);
  expect(night.hasRemDeficit, isTrue);
});
```

A tela tocada cobre vazio, skeleton e erro. Health recusado deixa check-in, medicação, timer e export usáveis.

## Git

Commit só quando a pessoa pedir. A mensagem diz o porquê, em uma ou duas frases. Push só com pedido. Sem alterar git config, sem `--no-verify`, sem force push.

Ficam de fora: `API_TOKEN`, `.env`, keystore e `lib/l10n/app_localizations*.dart`.

Feature que mudou de estado atualiza @docs/GDD.md no mesmo commit, como a §16 descreve.

A versão do app segue SemVer em `pubspec.yaml` (`MAJOR.MINOR.PATCH+BUILD`). Enquanto não houver lançamento público, permanece na série `0.y.z`. `MAJOR` sobe em quebra incompatível, `MINOR` em funcionalidade compatível, `PATCH` em correção. O `+BUILD` é o número da loja e sobe a cada envio, sem mudar o significado da versão.

## Limites

Sempre: implementar o item pedido na pasta da feature; estender `HealthService`, o repositório e o bridge que já existem; string nova só em `lib/l10n/app_pt.arb`; usar a API da seção Sistema; rodar `flutter analyze` e `flutter test`.

Pergunte antes de adicionar dependência, mudar campo já salvo, pedir permissão nova no `Info.plist` ou no `AndroidManifest.xml`, trocar o SharedPreferences, ou puxar um item `FUT-*` para a mudança atual.

Nunca:

- Gravar segredo ou editar `app_localizations*.dart`
- Apagar teste que falha para a suíte passar
- Usar `// ignore` para esconder erro do analyzer
- Lembrar dose com `Timer`, ou abrir WebView para Health, WhatsApp ou PDF
- Amostrar microfone ou sensor de luz para imitar o Apple Watch
- Criar outro `MethodChannel` de saúde ou outro store para o mesmo modelo
- Inventar dado de saúde quando a permissão falta
- Colocar `go_router` antes do FUT-52
- Recriar seletor de hora, share, voltar, teclado ou notch que o Flutter já entrega
- Usar dialeto de IA, tom robótico, paternalista ou frases engessadas de autoajuda
- Diagnosticar, prescrever, exigir conta ou usar streak punitivo
