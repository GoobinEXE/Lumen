---
name: Fase 0.8 — Navegação mais intuitiva
overview: "Sprint F: clareza do shell (P11) depois que as ferramentas do Dia, export, check-in, remédios e alarmes já estão estáveis. Uma porta principal por job; sem go_router até FUT-52."
todos:
  - id: status-md
    content: Status / subtabela 0.8 em docs/FASE_0_FEEDBACK.md (Docs, Grok 4.6 High — Cursor Models)
    status: completed
  - id: audit
    content: "Audit: CTAs, abas, Home legado vs ficha, hub órfão, pilhas de tarefas (Sonnet 5 Thinking High)"
    status: completed
  - id: copy
    content: "Copy humana: labels de abas, hierarquia, uma porta por job (Opus 5.5 Medium)"
    status: completed
  - id: i18n
    content: Chaves arb + doloc + gen-l10n (GPT-5.6 Sol)
    status: completed
  - id: flutter
    content: "Flutter: shell, destinos canônicos, atalhos duplicados alinhados (Sonnet 5 Thinking High)"
    status: completed
  - id: tests
    content: "Testes: lumen_shell_navigation_test + destino canônico de tarefas (Sonnet 5 Thinking High)"
    status: completed
  - id: docs-gate
    content: GDD P11 + flutter analyze + flutter test -j 1 + fechar MD (Grok 4.6 High — Cursor Models)
    status: completed
isProject: false
---

# Fase 0.8 — Navegação mais intuitiva

Sprint F. Detalhe da fase em [docs/FASE_0_FEEDBACK.md](../../docs/FASE_0_FEEDBACK.md) (seção “Fase 0.8”). Nota de origem: tópico #14, “navegação confusa / pouco intuitiva”.

## Visão geral

O shell já tem 4 abas (Início/ficha, Dia, Remédios, Pasta clínica). As ferramentas de uso diário (0.2–0.7) já fecharam. O que falta é a pessoa **entender onde cada job mora**: uma porta principal, atalhos que não empilham destinos diferentes, e nenhum hub órfão na narrativa.

Decisão de produto: **clareza no `Navigator` + `LumenShell` que já existe**. `go_router` continua em FUT-52.

## Princípio

Segue o princípio da Fase Feedback: ferramentas de funcionamento pessoal, sem priorizar SDK. Não criar rota nomeada nova, campo salvo nem chave `noa_*` nova sem pedir antes. A fase é mapa mental + IA do shell, não redesign liquid glass.

## Dependências

- Fases 0.2–0.7 não bloqueiam código, mas **justificam a ordem**: mexer na IA cedo demais redesenha em cima de bugs de confiança. Esta fase é a última da Feedback.
- P11 já está ✅ no GDD (shell 4 abas + Stitch). A 0.8 refina a hierarquia e as portas, não inventa uma quinta aba.

## Passos

1. **Status MD** — subtabela de etapas da 0.8 no doc de feedback; fase → `em implementação` quando o audit começar.
2. **Audit** — inventário de CTAs (Início, Dia, Remédios, Pasta, Perfil, Config, Tarefas, Des-Trava). Registrar: `HomeScreen` legado vs `HomeFichaScreen` no shell; `PatientChartScreen` / hub rico órfão vs `ClinicalFolderScreen`; tarefas empilhadas a partir da Home vs Dia; labels das abas que ainda geram dúvida.
3. **Copy** — labels de abas, tooltips e hierarquia (“uma porta principal por job”). Tom humano, sem jargão clínico demais na tab bar.
4. **i18n** — chaves só em `lib/l10n/app_pt.arb`; `dart run tool/doloc.dart && flutter gen-l10n` (`API_TOKEN` só no ambiente) ou sincronizar EN/ES/JA à mão se faltar token.
5. **Flutter** — destino canônico de Tarefas e Pasta; podar ou alinhar atalhos duplicados (mesmo destino, mesma pilha); remover ou redirecionar `HomeScreen` / hub órfão; `Semantics` nos controles novos; respeitar `textScaler`. Sem `go_router`.
6. **Testes** — `test/lumen_shell_navigation_test.dart` (abas, double-tap limpa pilha, back); widget do destino canônico de tarefas. A home não consome o back.
7. **Docs gate** — GDD P11 (e §10 navegação se a IA mudar), `flutter analyze` sem issues, `flutter test -j 1` verde, fechar MD.

## Arquivos prováveis

- `lib/core/widgets/lumen_shell.dart`
- `lib/features/home/presentation/home_ficha_screen.dart`
- `lib/features/home/presentation/home_screen.dart`
- `lib/features/therapist_export/presentation/clinical_folder_screen.dart`
- `lib/features/therapist_export/presentation/therapist_export_hub_screen.dart`
- `lib/features/tasks/presentation/tasks_hub_screen.dart`
- `lib/l10n/app_pt.arb`
- `docs/GDD.md` — P11 / § navegação
- `Design/Stitch/new/` — referência visual, não ditadura de IA copy

## Critério de pronto

- Mapa mental documentado e refletido na UI: **uma porta principal por job**.
- Atalhos duplicados podados ou alinhados (mesmo destino, mesma pilha).
- Hub órfão: incorporar o que falta na Pasta clínica **ou** remover entrada morta da narrativa de produto.
- Testes de shell atualizados (`test/lumen_shell_navigation_test.dart`).
- Sem `go_router` (FUT-52).

## Fora de escopo

- **`go_router` / rotas nomeadas / deep links** até FUT-52
- Redesign liquid glass completo só por estética
- Novas abas além das 4 sem decisão de produto
- Widget / App Intent / Focus (FUT-*)
- Reabrir alarmes de tarefa, multi-dose ou export clínico (já fechados em 0.3–0.7)

## Risco

Cortar atalho que a pessoa já usa no dia a dia (Tarefas a partir do Dia, Pasta a partir do Início). O audit precisa listar cada porta antes de podar. Labels da tab bar em tom humano, sem jargão clínico. A home continua sem consumir o back (`PopScope` / gesto iOS).

## Modelos por etapa

Docs usam **Cursor Models** (pool first-party: Grok / Composer), não terceiros.

| Etapa | Modelo |
|-------|--------|
| Docs (status MD, gate) | Grok 4.6 High (`cursor-grok-4.6-high`) |
| Audit | Sonnet 5 Thinking High |
| Copy | Opus 5.5 Medium |
| i18n | GPT-5.6 Sol |
| Flutter / testes | Sonnet 5 Thinking High |
