---
name: Fase 0.7 — Clareza dos alarmes de tarefas
overview: "Sprint E: deixar claro como funcionam lembrete, alarme, insistente, quiet hours e app fechado nas tarefas, e o que fazer quando a permissão falta. Tudo local, sem app Lembretes nativo (EKReminder fora de escopo)."
todos:
  - id: status-md
    content: Status / subtabela 0.7 em docs/FASE_0_FEEDBACK.md (Docs, Grok 4.6 High — Cursor Models)
    status: completed
  - id: audit
    content: "Audit: estilos de alerta no editor, quiet hours, permissão negada / exact alarm, comportamento com app fechado (Sonnet 5 Thinking High)"
    status: completed
  - id: domain
    content: Domínio de alarmes de tarefa só se o audit achar gap (Opus 4.8 Thinking High)
    status: completed
  - id: copy
    content: "Copy humana: notificação × alarme × insistente, quiet hours, remédio fora do quiet hours, app fechado, permissão negada (Opus 5.5 Medium)"
    status: completed
  - id: i18n
    content: Chaves arb + doloc + gen-l10n (GPT-5.6 Sol)
    status: completed
  - id: flutter
    content: "Flutter: ajuda no editor e/ou Configurações + CTA para ajustes do sistema via SystemSettings (Sonnet 5 Thinking High)"
    status: completed
  - id: tests
    content: "Testes: regressão quiet hours / schedule se tocar domínio; widget do editor com texto de ajuda (Sonnet 5 Thinking High)"
    status: completed
  - id: docs-gate
    content: GDD (TSK + notificações) + flutter analyze + flutter test -j 1 + fechar MD (Grok 4.6 High — Cursor Models)
    status: completed
isProject: false
---

# Fase 0.7 — Clareza dos alarmes de tarefas

Sprint E. Detalhe da fase em [docs/FASE_0_FEEDBACK.md](../../docs/FASE_0_FEEDBACK.md) (seção “Fase 0.7”). Nota de origem: tópico #6, “tarefas × lembretes do celular / clareza dos alarmes”.

## Visão geral

Já existem `TaskReminderService`, os canais `task_reminders` e `task_reminders_alarm`, `TaskAlertStyle { notification, alarm, insistent }` e quiet hours de tarefas. O que falta é a pessoa **entender e prever**: o que cada estilo faz, o que são as quiet hours, se vai tocar com o app fechado e o que fazer quando o sistema bloqueia o aviso.

Decisão de produto: **clareza e confiabilidade local primeiro**. O app **não** vira ponte para o app Lembretes do celular.

## Princípio

Segue o princípio da Fase Feedback: ferramentas de funcionamento pessoal, sem priorizar SDK. Não criar modelo novo, campo novo salvo nem chave `noa_*` nova sem pedir antes. Remédio continua em `medication_reminder_service.dart`, com canal próprio; a ajuda precisa dizer que remédios **não** entram nas quiet hours de tarefas.

## Dependências

- Fase 0.2 / 0.6 não bloqueiam. Esta fase não mexe em `_alignDayLogs` nem no repositório de doses.
- `SystemSettings` (`lib/integrations/system/system_settings.dart`) já existe e abre os ajustes do sistema. Reusar, sem `MethodChannel` novo e sem WebView.

## Passos

1. **Status MD** — subtabela de etapas da 0.7 no doc de feedback; fase → `em implementação` quando o audit começar.
2. **Audit** — ler `task_editor_sheet.dart`, `task_reminder_service.dart`, `task_quiet_hours.dart` / prefs, `settings_screen.dart` e `local_notifications_host.dart`. Registrar: como cada `TaskAlertStyle` aparece hoje na UI; o que o código faz de fato por estilo e plataforma (canal, som, insistência, `AndroidScheduleMode`); onde as quiet hours são editadas e aplicadas; o que acontece com permissão negada e com exact alarm ausente no Android; o que o `flutter_local_notifications` garante com o app fechado (agendado no SO) e o que não garante (DND, Focus, economia de bateria, fabricante).
3. **Domínio** (só se o audit pedir) — ajustes em `task_reminder_schedule.dart` / `task_quiet_hours.dart`, mantendo `toMap`/`fromMap` compatíveis.
4. **Copy** — textos curtos de: notificação vs alarme vs insistente; quiet hours (janela em que a tarefa não toca; remédio não entra); app fechado (o aviso fica agendado no aparelho); permissão negada com CTA; sem prometer o que o SO não garante. Tom humano, sem culpa, conforme o perfil de voz.
5. **i18n** — chaves só em `lib/l10n/app_pt.arb`; `dart run tool/doloc.dart && flutter gen-l10n` (`API_TOKEN` só no ambiente) ou sincronizar EN/ES/JA à mão se faltar token.
6. **Flutter** — ajuda curta no editor de tarefa (subtítulo ou sheet de ajuda, `showModalBottomSheet` com `useSafeArea: true`); revisar labels de `TaskAlertStyle`; texto de quiet hours onde elas são editadas; estado de permissão negada / exact alarm ausente com CTA que chama `SystemSettings.open(...)`. `Semantics` nos controles novos; respeitar `textScaler`.
7. **Testes** — regressão de quiet hours / schedule se o domínio mudar; widget do editor mostrando o texto de ajuda; widget do estado de permissão negada com CTA (ação do sistema fakeada, sem abrir ajustes reais). Permissão negada deixa tarefa, check-in, medicação e export usáveis.
8. **Docs gate** — GDD (TSK e linha de notificações, §sistema), `flutter analyze` sem issues, `flutter test -j 1` verde, fechar MD.

## Arquivos prováveis

- `lib/features/tasks/presentation/task_editor_sheet.dart`
- `lib/features/tasks/service/task_reminder_service.dart`
- `lib/features/tasks/domain/task_item.dart` (`TaskAlertStyle`)
- `lib/features/tasks/domain/task_quiet_hours.dart` e `lib/features/tasks/data/task_quiet_hours_prefs.dart`
- `lib/features/tasks/domain/task_reminder_schedule.dart`
- `lib/features/settings/presentation/settings_screen.dart`
- `lib/integrations/system/system_settings.dart`
- `lib/core/notifications/local_notifications_host.dart`
- `lib/l10n/app_pt.arb`

## Critério de pronto

- No editor de tarefa e/ou Configurações: texto curto do que cada estilo faz, das quiet hours, e de que remédios não entram nas quiet hours de tarefas.
- Permissão negada ou exact alarm ausente: estado claro com CTA para os ajustes do sistema (`SystemSettings`), sem WebView.
- A pessoa consegue prever se o aviso toca com o app fechado; a copy bate com o comportamento real do `flutter_local_notifications`.
- Nenhuma promessa de DND, Focus ou bateria que o SO não garante.
- Strings só em `app_pt.arb`; EN/ES/JA sincronizados.

## Fora de escopo

- **`EKReminder` / EventKit Reminders / app Lembretes nativo (iOS e Android)**, incluindo sync bidirecional e deep link para criar lembrete nativo
- Qualquer permissão nova no `Info.plist` ou no `AndroidManifest.xml` (perguntar antes, se o audit achar necessidade)
- `Timer` periódico para avisar tarefa ou dose
- Widget / App Intent / Focus (FUT-*)
- Mexer em lembrete de remédio além de citar na copy que ele é separado
- Mudar semântica das quiet hours já salvas

## Risco

Copy que promete mais do que o SO entrega (DND, Focus, economia de bateria, fabricantes Android agressivos). Revisar cada frase contra o comportamento real. Tom humano e sem culpa; nada de “você vai perder” ou sermão. Mudar o rótulo de `TaskAlertStyle` na UI sem mexer no valor salvo (`enum` e JSON ficam).

## Modelos por etapa

Docs usam **Cursor Models** (pool first-party: Grok / Composer), não terceiros.

| Etapa | Modelo |
|-------|--------|
| Docs (status MD, gate) | Grok 4.6 High (`cursor-grok-4.6-high`) |
| Audit | Sonnet 5 Thinking High |
| Domínio, se precisar | Opus 4.8 Thinking High |
| Copy | Opus 5.5 Medium |
| i18n | GPT-5.6 Sol |
| Flutter / testes | Sonnet 5 Thinking High |
