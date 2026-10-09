---
name: Fase 0.6 — Multi-dose (slots por horário)
overview: "Sprint E: remédios com mais de um horário no dia viram slots independentes na UX (tomar / pular / adiar por dose), com edição clara da agenda. O modelo já suporta; a fase é editor + lista do dia + copy + testes."
todos:
  - id: status-md
    content: "Status / subtabela 0.6 em docs/FASE_0_FEEDBACK.md (Docs, Sonnet 5.5 High)"
    status: completed
  - id: audit
    content: "Audit UX/domain: editor de horários, lista do dia 1:1 com logs, notificações por horário (Sonnet 5 Thinking High)"
    status: completed
  - id: domain
    content: "Domínio multi-dose só se o audit achar gap (Opus 4.8 Thinking High)"
    status: completed
  - id: copy
    content: "Copy humana: adicionar horário, esta dose, pular esta dose vs não tomei hoje (Opus 5.5 Medium)"
    status: completed
  - id: i18n
    content: "Chaves arb + doloc + gen-l10n (GPT-5.6 Sol)"
    status: completed
  - id: flutter
    content: "Flutter: editor de horários (showTimePicker) + card por ocorrência no dia (Sonnet 5 Thinking High)"
    status: completed
  - id: tests
    content: "Testes: schedule com 2+ horários no mesmo dia; repositório com dois logs do mesmo medicationId (Sonnet 5 Thinking High)"
    status: completed
  - id: docs-gate
    content: "GDD M02 + flutter analyze + flutter test -j 1 + fechar MD (Sonnet 5.5 High)"
    status: completed
isProject: false
---

# Fase 0.6 — Modularidade multi-dose

Sprint E. Detalhe da fase em [docs/FASE_0_FEEDBACK.md](../../docs/FASE_0_FEEDBACK.md) (seção “Fase 0.6”).

## Visão geral

Remédios com vários horários no dia aparecem e se comportam como **slots independentes**: tomar, pular e adiar por dose. A dor é de UX/modularidade percebida (manhã / tarde / noite como unidades, não um único interruptor do dia).

## Princípio

`Medication.scheduledTimes` (`List<String>`) **já existe**, e os logs do dia já alinham por slot. Não criar modelo novo, campo novo salvo nem chave `noa_*` nova sem pedir antes. A fase completa gaps de UX em cima do que existe.

## Dependência

Depende da **Fase 0.2**: `_alignDayLogs` preserva `status` / `takenAt` / `skipReason` / `snoozedUntil` ao realocar horário, e o repositório serializa as transações de logs. Realinhar horários não pode resetar status. Se 0.2 e 0.6 tocarem `_alignDayLogs`, coordenar o merge.

## Passos

1. **Status MD** — subtabela de etapas da 0.6 no doc de feedback; fase → `em implementação`.
2. **Audit** — o editor já permite vários horários? A lista do dia é 1:1 com os logs por `scheduledTime`? Notificações já saem por horário ativo? Registrar gaps antes de mexer.
3. **Domínio** (só se o audit pedir) — ajustes em `medication.dart` / `medication_repository.dart` / `reminder_schedule.dart`, mantendo `toMap`/`fromMap` compatíveis.
4. **Copy** — textos de adicionar/remover horário, “esta dose”, e diferença entre pular **esta** dose e “não tomei hoje”. Tom humano, sem culpa, conforme o perfil de voz.
5. **i18n** — chaves só em `lib/l10n/app_pt.arb`; `dart run tool/doloc.dart && flutter gen-l10n` (`API_TOKEN` só no ambiente) ou sincronizar EN/ES/JA à mão se faltar token.
6. **Flutter** — editor com adicionar/remover/editar horário via `showTimePicker`; lista do dia com um card/linha por ocorrência e status independente; `Semantics` por dose.
7. **Testes** — `upcomingDoseOccurrences` e ids de notificação estáveis por `med|time|weekday` com 2+ horários; repositório com dois logs no mesmo `medicationId` e statuses distintos; regressão de realign.
8. **Docs gate** — GDD M02 (e B5 se tocar o mesmo código), `flutter analyze` sem issues, `flutter test -j 1` verde, fechar MD.

## Arquivos prováveis

- `lib/features/medications/domain/medication.dart`
- `lib/features/medications/presentation/widgets/medication_card.dart`
- `lib/features/medications/data/medication_repository.dart`
- `lib/features/medications/service/medication_reminder_service.dart`
- `lib/features/medications/service/reminder_schedule.dart`
- telas de editor de medicação (presentation)

## Fora de escopo

- Apple Medications (C8) como bloqueio ou requisito desta fase
- `Timer` periódico para lembrar dose (proibido no AGENTS.md)
- Ponte mútua nova de saúde / `MethodChannel` novo
- Alarmes de tarefas (Fase 0.7)

## Risco

Realinhar horários não pode zerar status de dose (contrato da 0.2). Toggle “med tomada” do check-in não substitui adesão real por slot. Não criar `Timer`; notificações seguem em `medication_reminder_service.dart`.

## Modelos por etapa

| Etapa | Modelo |
|-------|--------|
| Docs (status MD, gate) | Sonnet 5.5 High |
| Audit | Sonnet 5 Thinking High |
| Domínio, se precisar | Opus 4.8 Thinking High |
| Copy | Opus 5.5 Medium |
| i18n | GPT-5.6 Sol |
| Flutter / testes | Sonnet 5 Thinking High |
