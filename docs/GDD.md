# Lumen — Game Design Document (GDD)

> Documento vivo de produto e desenvolvimento.  
> **App:** Lumen (package `noa`)  
> **Versão do doc:** 1.12 · **Data:** 2026-10-09  
> **Stack:** Flutter · Riverpod · SharedPreferences · Apple Health / Samsung Health / Health Connect  
> **Plataformas-alvo:** iOS (primário), Android, Web (parcial)  
> **Referências:** [PRD](PRD.md) (requisitos do protótipo) · telas em `Design/`

---

## Índice

1. [Visão do produto](#1-visão-do-produto)
2. [Identidade e posicionamento](#2-identidade-e-posicionamento)
3. [Público e personas](#3-público-e-personas)
4. [Princípios de design (UX TDAH)](#4-princípios-de-design-ux-tdah)
5. [Arquitetura técnica](#5-arquitetura-técnica)
6. [Mapa de features atuais](#6-mapa-de-features-atuais)
    - [Como ler os IDs e as siglas](#como-ler-os-ids-e-as-siglas)
7. [Modelos de dados](#7-modelos-de-dados)
8. [Fluxos de usuário](#8-fluxos-de-usuário)
9. [Integrações](#9-integrações)
10. [i18n, tema e design system](#10-i18n-tema-e-design-system)
11. [Tasks de desenvolvimento (estado atual)](#11-tasks-de-desenvolvimento-estado-atual)
12. [Roadmap](#12-roadmap)
    - [Pesquisar mais](#pesquisar-mais)
13. [Backlog / features futuras](#13-backlog--features-futuras)
14. [Critérios de aceite e qualidade](#14-critérios-de-aceite-e-qualidade)
15. [Glossário](#15-glossário)
16. [Como atualizar este GDD](#16-como-atualizar-este-gdd)

---

## 1. Visão do produto

### Elevator pitch

**Lumen** é um companion e prótese executiva offline-first para pessoas com TDAH: além de correlacionar sono, humor e medicação para a terapia, apoia ativamente o dia a dia do usuário com o Raio-X do dia no calendário, controle de gastos de hiperfoco, ferramentas visuais de ritmo e suporte anti-paralisia — tudo com múltiplos perfis de tom de voz 100% humanizados e sem culpa.

### Problema

Pessoas com TDAH enfrentam fricções centrais que o Lumen trata direto (detalhe em [PRD.md](PRD.md)):

- **Inércia e paralisia executiva:** começar uma tarefa custa mais do que a tarefa; uma lista longa piora isso.
- **Time blindness e janela do estimulante:** a queda do efeito chega sem aviso e vira crash de energia; falta percepção da linha do tempo.
- **Gastos impulsivos em hiperfoco:** novos hobbies e hiperfocos geram compras imediatas por dopamina, culminando em rombos no orçamento.
- **Culpa e rigidez de apps tradicionais:** tons professoral/robóticos, sequências quebradas e notificações agressivas levam ao abandono.
- **Amnésia de eventos e viés de recência na consulta:** a sessão resume as últimas 24 horas e perde os 15–30 dias anteriores.

### Solução

Dois pilares complementares no mesmo app:

| Pilar | Componente | O que faz |
|-------|------------|-----------|
| **Prótese Executiva (Dia a Dia)** | **Calendário & Raio-X do Dia** | Calendário do app integrado ao calendário do celular (EventKit no iOS, CalendarProvider no Android) e timeline de 24h. Entra na fase atual |
| | **Gastos de Hiperfoco** | Agora: um registro simples do gasto e do valor. Cooldown, contador de economia e gráficos ficam para depois |
| | **Ferramentas Visuais de Ritmo** | Curva contínua de energia/foco do dia (`fl_chart`) e checklist tátil de saída ("Cadê minhas coisas?"). Entram na fase atual |
| | **Central de Tarefas & Lembretes** | To-do com alarme persistente (5 min) e modo foco. Entra na fase atual |
| | **Des-Trava Anti-Paralisia** | Assistente de 3 micro-passos + timer 60s com haptic |
| **Acompanhamento Clínico** | **Check-in** | Humor + foco + energia (UI única; atalho Home a abolir) |
| | **Dia** | Check-in embutido, Foco do dia (tarefa fixada), água, pauta/fechamento |
| | **Medicação & Janela** | Agenda, estoque, tomada/snooze/pular, curva de eficácia |
| | **Sono & recuperação** | Histórico Apple Health + correlações acionáveis |
| | **Hub clínico** | PDF, WhatsApp, card visual semanal e anatomia de dias atípicos |

### Não-objetivos (por enquanto)

- Diagnóstico médico ou prescrição.
- Rede social / feed.
- Coach de produtividade genérico (Pomodoro agressivo, streaks punitivos).
- Conta obrigatória ou login na nuvem: o aplicativo é **100% local, offline-first e privacy-first**. Nenhum dado pessoal, biométrico ou de saúde é enviado para servidores/nuvem do Lumen. Qualquer integração/sincronização ocorre estritamente no aparelho (on-device). A criação de conta não é trabalhada no momento e, se algum dia existir, será sempre 100% opcional.

---

## 2. Identidade e posicionamento

| Campo | Valor |
|-------|--------|
| Nome de produto | **Lumen** |
| Package / código | `noa` |
| Tom de voz | 100% humanizado, empático, sem clichês de IA (perfis selecionáveis) |
| Metáfora visual | Apple Liquid Glass (`liquid_glass_renderer` + Impeller/Flutter GPU) — refração no chrome iOS; Android chrome/sheet com FakeGlass + blur moderado (poucas camadas); chips densos e surfaces Android em paint lite sem BackdropFilter; zero visual Material 3 / You / Google |
| Cores-chave | Teal `#1FAF8A` (primária), lavanda `#8B7BC8` (acento), coral `#FF8A5C` (Des-Trava) |
| Ícone | Arte em `lumen.ai`. iOS é o `ios/Runner/Lumen.icon` do Icon Composer, com vidro e luz, sem raster chapado por cima. Android usa essa arte no adaptive icon: fundo `#F6F1DE` no claro e `#16161A` no escuro; o L fica `#3A3A40` no claro e `#F4F1EC` no escuro |
| Locales | `pt` (fonte), `en`, `es`, `ja` |
| Versão do app | [SemVer](https://semver.org/lang/pt-BR/) em `pubspec.yaml`: `MAJOR.MINOR.PATCH`. Atual: `0.2.2` (série 0, antes do lançamento). `1.0.0` é o primeiro lançamento público. O `+N` do Flutter é só o build da loja e sobe a cada envio |

### Perfis de tom de voz (humanizados, zero dialeto de IA)

O Lumen elimina qualquer tom robótico, jargões terapêuticos engessados ou positividade tóxica. O app disponibiliza perfis de linguagem selecionáveis, todos com comunicação autêntica e humana:

1. **Despojado:** Super informal, leve, gírias naturais sem forçar (*"E aí, conseguiu ver isso ou tá na correria?", "Tranquilo, fica pra depois"*).
2. **Casual (Padrão):** Amigável, próximo, natural como conversa real de WhatsApp (*"Bora pro que dá hoje", "Sem estresse, fica pra próxima"*).
3. **Não-formal / Neutro:** Direto ao ponto, acolhedor sem intimidade forçada, sem floreios (*"Registro salvo. Siga quando puder"*).
4. **Mais formal:** Sóbrio, respeitoso, claro e sem gírias, mas sem frieza mecânica (*"Atividade remarcada. Avisaremos no próximo ciclo"*).
5. **Voltado para mulheres:** Empático, acolhedor, conectado à vivência e sobrecarga da mulher adulta com TDAH.
6. **Voltado para meninas:** Jovem feminino, leve, dinâmico e acolhedor.
7. **Voltado para meninos:** Jovem masculino, direto, prático e motivador.

> **Regra de Ouro:** Nenhuma frase do app deve parecer gerada por IA ("Seu ritmo é seguro e acolhedor") ou professoral. Comunicação humana de par.

### Nome no código vs. produto

- UI / l10n / docs de produto → **Lumen**
- `pubspec.name` → **noa**
- Identificador iOS, Android e macOS → `dev.prism.lumen`
- Channel HealthKit → `dev.prism.lumen/healthkit_bridge`

---

## 3. Público e personas

### Persona A — Marcelo (usuário primário)

Persona de produto do PRD (nome dinâmico na UI via perfil local, `H14`):

- 31 anos, designer de produto, TDAH combinado em acompanhamento.
- iPhone + Apple Watch. Exemplo de estimulante: lisdexanfetamina 30 mg, janela longa (~10 h).
- Esquece a dose, sente a queda do platô no fim da tarde e trava diante de uma lista grande.
- Terapia quinzenal. Quer um resumo objetivo, sem escrever um diário longo.
- Evita campos obrigatórios e qualquer UI que cobre sequência.

### Persona B — Terapeuta / psiquiatra (indireto)

- No protótipo Stitch, a profissional de referência é a Dra. Camila Ramos. No app, nome e telefone ainda são preferência local (`T02`), sem data de consulta.
- Recebe PDF, texto WhatsApp ou card semanal.
- Precisa de padrões (sono REM × paralisia, adesão, sobrecarga sensorial, gatilhos de impulsividade), não de um despejo bruto.

### Persona C — Usuário Android (secundário)

- Mesma UX local; saúde via `HealthAppConnector` (Samsung Health quando instalado, senão Health Connect). Apps OEM (Mi/Huawei/Garmin) → instrução para ligar no Health Connect. SoM / ambiente / meds no app de saúde = no-op ou vazio.

---

## 4. Princípios de design (UX TDAH)

1. **Baixa fricção** — ações principais em 1–2 toques; check-in cabível em bottom sheet.
2. **Sem culpa e 100% humanizado** — copy sem “você falhou”. Pular dose ou hábito cabe numa frase natural e leve (ex: *"Sem estresse, fica pra próxima"*). Sem vermelho de reprovação, sem sermão.
3. **Uma coisa por tela/seção** — home é hub; cada card leva a um job claro.
4. **Visual antes de numérico** — o cérebro com TDAH processa cores, linhas de tendência e gráficos (`fl_chart`) muito melhor do que números soltos e tabelas secas.
5. **Feedback imediato** — haptic no Des-Trava; snackbars curtos; skeletons em vez de spinners longos.
6. **Offline-first** — SharedPreferences; Health e Calendário são enriquecimento, não bloqueio.
7. **Acessibilidade cognitiva** — contraste alto, tipografia legível, ícones Material consistentes (`AppIcons`).
8. **Glass com propósito** — sheets e CTAs secundários; fundo sólido (sem auras/ruído).

---

## 5. Arquitetura técnica

```
lib/
├── main.dart                 # bootstrap + LumenApp
├── core/                     # tema, i18n providers, widgets, ícones
├── features/
│   ├── home/                 # HomeFichaScreen (Início / ficha viva)
│   ├── routine_mood/         # check-in, rotina diária, mood repo
│   ├── medications/          # meds + logs + lembretes + efficacy
│   ├── sleep_analytics/      # cards + CorrelationEngine
│   ├── state_of_mind/        # modelo/labels/editor (clone Apple)
│   ├── health_sync/          # consent + mirror → Health
│   ├── therapist_export/     # PDF / WhatsApp / share card
│   └── unstuck_assistant/    # Des-Trava
├── integrations/
│   ├── health/               # HealthService + AppleHealthService
│   └── healthkit_bridge/     # MethodChannel iOS extra
└── l10n/                     # ARB + gen-l10n
```

### Padrões

| Camada | Padrão |
|--------|--------|
| Estado | Riverpod (`Provider`, `StateNotifier`, `FutureProvider`) |
| Persistência | SharedPreferences (JSON maps) |
| Domínio | classes imutáveis + `toMap` / `fromMap` |
| Health | interface `HealthService` → `AppleHealthService` |
| UI | `CupertinoApp` + tema Material **invisível** no `builder` (só engine: forms/a11y/rotas); Apple Liquid Glass (`GlassSurface` / `GlassSheet` / `GlassNavBar` / `GlassAppBar` / `GlassChip` / `LumenFab` via `liquid_glass_renderer`); 4 abas irmãs no `PageView` + `Navigator` aninhado (`LumenShell`); Impeller + Flutter GPU. Sem `go_router` (FUT-52). Política: **zero visual** Material 3 / You / Google |

### Dependências relevantes

`flutter_riverpod`, `health`, `fl_chart`, `pdf` + `printing`, `share_plus`, `shared_preferences`, `uuid`, `url_launcher`, `flutter_local_notifications`, `intl` / `flutter_localizations`, `liquid_glass_renderer` (Impeller; `FakeGlass` no fallback).

---

## 6. Mapa de features atuais

### Como ler os IDs e as siglas

Cada linha das tabelas abaixo tem um **ID de feature**: uma ou mais letras (a área do app) + número com zero à esquerda (o item). Exemplo: **H03** = Home, item 03 → idioma pelo sistema.

Isso **não** é a mesma coisa que:

| Parece com… | Mas é… | Onde vive |
|-------------|--------|-----------|
| **H03** | Feature da Home (idioma do SO) | §6.1 |
| **H3** (sem zero) | Task do Epic H (timeline 24h) | §11 |
| **P01** | Feature de plataforma (i18n) | §6.10 |
| **P0** / **P1** / **P2** | Prioridade (ouro / prata / bronze) | §9 e §12 |
| **C01** | Feature do Check-in (valência) | §6.2 |
| **C1** (sem zero) | Task do Epic C (modelo Medication) | §11 |
| **FUT-21** | Ideia no backlog futuro | §13 |

**Regra prática:** número com dois dígitos (`H03`, `M04`) = feature da §6. Número sem zero (`H3`, `B7`, `J1`) = task de epic na §11. `FUT-*` = ainda não é fase atual. `P0`/`P1`/`P2` = prioridade, não plataforma.

#### Prefixos de feature (§6)

| Prefixo | Significa | Seção |
|---------|-----------|-------|
| **H** | **H**ome (hub principal) | §6.1 |
| **C** | **C**heck-in rápido (mood) | §6.2 |
| **R** | **R**otina do dia | §6.3 |
| **M** | **M**edicações | §6.4 |
| **S** | **S**ono & analytics | §6.5 |
| **SM** | **S**tate of **M**ind | §6.6 |
| **HS** | **H**ealth **S**ync | §6.7 |
| **T** | Hub **t**erapeuta / export | §6.8 |
| **U** | Des-Trava (**U**nstuck) | §6.9 |
| **P** | **P**lataforma / infra | §6.10 |
| **CAL** | **Cal**endário & Raio-X do dia | §6.11 |
| **EXP** | Gastos de hiperfoco (**exp**enses) | §6.12 |
| **VIS** | Ferramentas **vis**uais de apoio executivo | §6.13 |
| **TSK** | **T**a**sk**s / lembretes unificados | §6.14 |
| **FUT-** | Backlog **fut**uro (ainda não shipped) | §13 |

#### Prefixo de epic / task (§11)

Na §11 o board usa outra numeração: letra do **epic** + número sequencial sem zero (`A1`, `B7`, `H3`, `J4`). Os epics atuais:

| Epic | Tema |
|------|------|
| **A** | Fundação |
| **B** | Humor & rotina |
| **C** | Medicações |
| **D** | Health & insights |
| **E** | Export clínico |
| **F** | Des-Trava |
| **G** | Qualidade & release |
| **H** | Calendário e Raio-X |
| **I** | Prótese do dia |
| **J** | Itens desta fase (ciclo, cafeína, picos de FC, bateria mental) |

Cada task da §11 costuma apontar para uma feature da §6 (ex.: task `H3` → feature `CAL03`), mas o texto do ID é outro sistema.

#### Status nas tabelas

| Símbolo | Significado |
|---------|-------------|
| ✅ | Feito |
| 🟡 | Parcial ou nesta fase |
| ❌ | Ausente |
| 🔮 | Futuro (ver §13) |
| 🔎 | Pesquisar mais (método / limiar ainda em aberto) |

#### Outras siglas que aparecem no GDD

| Sigla | Significado |
|-------|-------------|
| **PRD** | Product Requirements Document — recorte do protótipo em `docs/PRD.md` |
| **GDD** | Este documento (produto + implementação) |
| **CTA** | Call to action — botão / atalho principal na tela |
| **CRUD** | Create, Read, Update, Delete — cadastro completo |
| **SoM** | State of Mind — modelo emocional estilo Apple Health |
| **HK** | HealthKit (Apple); ex.: `HKStateOfMind` |
| **i18n** | Internationalization — textos em vários idiomas |
| **MVP** | Minimum Viable Product — recorte mínimo usável |
| **E2E** | End-to-end — ponta a ponta (ex.: sync multi-device) |
| **REM** | Rapid Eye Movement — estágio de sono ligado a humor/foco |
| **HRV** | Heart Rate Variability — variabilidade da frequência cardíaca |
| **SDNN** | Tipo de HRV no iOS (desvio padrão dos intervalos NN) |
| **RMSSD** | Tipo de HRV no Android / Health Connect (outra fórmula; não misturar com SDNN) |
| **RHR** | Resting Heart Rate — frequência cardíaca de repouso |
| **dB** | Decibel — intensidade sonora no card de ambiente |
| **PRN** | *Pro re nata* — medicação “quando necessário” |
| **TCC** | Terapia Cognitivo-Comportamental |
| **TEA** | Transtorno do Espectro Autista |
| **TDPM** | Transtorno Disfórico Pré-Menstrual |
| **ASRS** / **PHQ-9** | Escalas clínicas opcionais no backlog (não diagnóstico) |
| **GDPR** | Regulamento europeu de privacidade / exclusão de dados |
| **PDF** / **CSV** / **JSON** | Formatos de export |
| **UI** / **UX** | Interface / experiência do usuário |
| **FC** | Frequência cardíaca (ex.: picos depois da dose no Epic J) |

Termos de produto (Check-in, Des-Trava, Mirror, Foco do dia…) estão no [§15 Glossário](#15-glossário).

### 6.1 Início (ficha viva / hub)

Shell: **Início · Dia · Remédios · Pasta clínica** (4 abas; sem quinta). O Início é a ficha pessoal (`HomeFichaScreen`). Tarefas e Meus dias abrem na pilha da aba Início (`openTasksHub` / `openRoutineCalendarScreen`). Pasta clínica é a 4ª aba (`openClinicalFolderScreen`). Troca de aba faz pop-to-root na origem e no destino. Protótipo: `Design/Stitch/new/in_cio_hub_pessoal_ficha_viva/`.

| ID | Feature | Status | Arquivo-chave |
|----|---------|--------|---------------|
| H01 | Saudação + subtítulo “sem pressão” | ✅ | `home_ficha_screen.dart` |
| H02 | Tema claro/escuro/sistema | ✅ | `SettingsScreen` (engrenagem no Início / Perfil) |
| H03 | Idioma pelo sistema | ✅ | atalho em Configurações abre o idioma do SO / do app |
| H04 | CTA Check-in | ✅ | única porta: `CheckInForm` embutido na aba **Dia** |
| H05 | CTA Des-Trava | ✅ | só na aba **Dia** (linha “Travou…? Abrir Des-Trava” → `UnstuckSheet`) |
| H06 | Atalho Rotina / Foco do dia | ✅ | card no Início → aba Dia |
| H07 | Card Medicações (resumo do dia) | ✅ | card no Início → aba Remédios |
| H08 | Card Sono | ✅ | `SleepDashboardCard` no Início |
| H09 | Card Recuperação | ✅ | `RecoveryDashboardCard` no Início |
| H10 | Pasta clínica (export) | ✅ | `ClinicalFolderScreen` — 4ª aba via `openClinicalFolderScreen`; período, notes, WhatsApp/card/PDF |
| H11 | Insights “padrões do cérebro” | ✅ | no Início |
| H12 | Lista entradas recentes (mood) | ✅ | no Início; tap abre DayDigest |
| H13 | Pull-to-refresh | ✅ | Início (sono / recuperação / mood) |
| H14 | Perfil / nome dinâmico | ✅ | bloco de identidade + ícone → `ProfileScreen` |
| H15 | Hub de configurações | ✅ | engrenagem no Início e no `ProfileScreen` |
| H16 | Contatos profissionais (múltiplos) | ✅ | `CareContact` / `noa_care_contacts_v1`; papéis terapeuta/psicólogo/psiquiatra/outro |

### 6.2 Check-in (mood)

Nome único na UI: **Check-in**. Não existe "micro check-in" como produto. A única superfície é o `CheckInForm` embutido na aba **Dia** (sem sheet paralela nem atalho na Início).

O caminho rápido grava em dois lugares, com o mesmo timestamp: o histórico (`MoodEntry`, `MoodRepository`) e o Estado Emocional do dia, via `RoutineRepository.mergeTodayStateOfMind` (acessado por `RoutineHealthMirrorNotifier`). O merge **atualiza o último snapshot do dia civil** (mesmo `id`) ou, se o dia não tem snapshot, cria **um** snapshot mínimo (sem dado de saúde inventado). Check-ins repetidos não multiplicam snapshots. O SoM do snapshot é a fonte canônica: `DayDigest.latestStateOfMind` e o feed do perfil leem só dos snapshots, nunca derivam SoM de `MoodEntry`. Health recusado não bloqueia o save local.

| ID | Feature | Status | Notas |
|----|---------|--------|-------|
| C01 | Valência 1–5 | ✅ | |
| C02 | Estado de foco (4) | ✅ | focused / hyperfocus / scattered / paralyzed |
| C03 | Energia (5) | ✅ | drained → hyper |
| C04 | Toggle medicação tomada | ✅ | |
| C05 | Toggle overload sensorial | ✅ | |
| C06 | Labels emocionais (State of Mind) | ✅ | busca + chips multilíngues |
| C07 | Nota livre opcional | ✅ | |
| C08 | Persistência local | ✅ | `MoodRepository` |
| C09 | Espelho automático no Apple SoM | ✅ | check-in e rotina espelham via `RoutineHealthMirror` (iOS 18+; Android só local); SoM canônico do dia = snapshot (ver nota acima) |
### 6.3 Rotina do dia

| ID | Feature | Status | Notas |
|----|---------|--------|-------|
| R01 | **Foco do dia** (nome de UI; “âncora” = sinônimo técnico) | ✅ | título da tarefa **fixada** no Dia → `mainFocusAnchor` (campo de domínio inalterado; sem TextField livre). Copy: “Foco do dia” com F maiúsculo, subtítulo `dayFocusSubtitle` na aba Dia, “Sem Foco do dia” no export |
| R02 | Check-in na aba Dia | ✅ | `CheckInForm` embutido (única porta na Dia); grava MoodEntry + SoM no snapshot; modal só fora da Dia (ver §6.2) |
| R03 | Checklist do dia | ✅ | aba Dia mostra só tarefas do período vigente; CRUD na Central de Tarefas (Ficha) |
| R04 | Água (copos) | ✅ | `waterGlasses` reidrata do máximo dos snapshots do dia civil e sobrevive ao salvar; zera só na virada do dia |
| R05 | Toggle medicação prescrita | ✅ | flag diária (além do módulo meds) |
| R06 | Notas para o terapeuta | ✅ | |
| R07 | Reflexão noturna | ✅ | campo na rotina; grava junto com o dia |
| R08 | Salvar + snackbar | ✅ | cada clique grava um snapshot com hora e limpa o formulário |
| R09 | Mirror Health (água, mindfulness, SoM) | ✅ | se sync habilitado; a água de cada snapshot soma no dia, sem repetir o que já foi escrito |
| R10 | Preferências de micro-hábitos default | ✅ | `micro_habits_prefs.dart` |
| R11 | Linha do tempo do dia | ✅ | cards por hora na rotina e na home |

### 6.4 Medicações

| ID | Feature | Status | Notas |
|----|---------|--------|-------|
| M01 | CRUD medicamento | ✅ | editar na lista; vários horários; dias seguem a semana toda |
| M02 | Logs do dia (gerar a partir da agenda) | ✅ | cria a dose que falta e tira o log do remédio apagado; tomada, pulada e adiada continuam após `_alignDayLogs` e resume. Fase 0.6 (multi-dose por slot): editor de `scheduledTimes` (adicionar/remover/editar com seletor do sistema, ordem cronológica, horário repetido recusado com aviso); um card e um log por ocorrência do dia; copy de pular cita o horário (“Pular a dose das {time}”) e diz que só aquela dose fica pulada; curva de eficácia por dose tomada; adesão por slot independente (tomar/pular/adiar não mexe nas outras doses do mesmo remédio), coberta por `test/medication_multi_dose_test.dart` e `test/next_dose_occurrence_test.dart` |
| M03 | Marcar tomado / pular / snooze | ✅ | |
| M04 | Janela de eficácia (pico / crash) | ✅ | pico fica dentro da janela, inclusive em 4 h |
| M05 | Alerta de refil | ✅ | threshold |
| M06 | Importar meds do Apple Health | ✅ | bridge `readMedications` |
| M07 | Sync dose events Apple ↔ Lumen | 🟡 | read + write na bridge; UX parcial |
| M08 | Notificações locais | ✅ | um aviso por horário na semana; Tomar e Adiar, inclusive com o app fechado, gravam no horário da notificação (com dois ou mais horários no dia a ação não reusa o log de outro horário); o toque abre Remédios |
| M09 | Vincular med local ↔ concept Apple | 🟡 | campos `appleConceptId` / `rxNormCode` |

### 6.5 Sono & analytics

| ID | Feature | Status | Notas |
|----|---------|--------|-------|
| S01 | Histórico sono 14 dias | ✅ | a noite que cruza a meia-noite conta no dia em que a pessoa acorda |
| S02 | Card última noite (estágios, score) | ✅ | REM/deep/light |
| S03 | Déficit sono / REM flags | ✅ | domínio `SleepRecord` |
| S04 | Recuperação (HRV, RHR, passos, exercício) | ✅ | |
| S05 | Ambiente (luz, dB ambiental/fones) | ✅ | iOS bridge |
| S06 | Gráficos (`fl_chart`) | ✅ | nos cards |
| S07 | Correlação sono × humor × recuperação | ✅ | `CorrelationEngine` |
| S08 | Insights acionáveis na home | ✅ | multilíngue |

**Insights implementados:**

- Coletando dados (estado vazio)
- Déficit REM × paralisia / esgotamento
- Fluxo mental (dias bons)
- Overload sensorial (contagem)
- HRV baixa × dias difíceis
- Poucos passos × travamento
- Pouca luz do dia × humor baixo
- Ruído alto × overload sensorial

### 6.6 State of Mind

| ID | Feature | Status | Notas |
|----|---------|--------|-------|
| SM01 | Modelo alinhado HKStateOfMind | ✅ | kind, valence −1…1, labels, associations |
| SM02 | Labels + associations localizados | ✅ | `state_of_mind_*.dart` |
| SM03 | Editor na rotina | ✅ | |
| SM04 | Leitura histórico Apple | ✅ | bridge |
| SM05 | Escrita Apple | ✅ | mirror + bridge |
| SM06 | Merge “mais recente vence” | ✅ | |

### 6.7 Health Sync

| ID | Feature | Status | Notas |
|----|---------|--------|-------|
| HS01 | Consent sheet explicativo | ✅ | |
| HS02 | Request permissions (plugin + bridge) | ✅ | |
| HS03 | Flag sync enabled (prefs) | ✅ | |
| HS04 | Mirror água / mindfulness / SoM | ✅ | |
| HS05 | Health Connect Android completo | ✅ | connector genérico + exercício/mindfulness workout + rationale |
| HS06 | Onboarding sync no primeiro uso | ✅ | intro 1ª abertura + consent Health |
| HS07 | Samsung Health Data SDK + seletor | ✅ | bridge + fallback HC; AAR opcional em `android/app/libs/` |

### 6.8 Pasta clínica (export)

4ª aba do shell: **Pasta clínica** (`ClinicalFolderScreen`, via `openClinicalFolderScreen`) — só material exportável. O prontuário pessoal vive no **Início** (`HomeFichaScreen`). Perfil biométrico completo continua em `ProfileScreen` (ícone no Início). Atalho em Configurações troca para esta aba (pop-to-root na origem).

| ID | Feature | Status | Notas |
|----|---------|--------|-------|
| T01 | Hub com preview card semanal | ✅ | `ClinicalFolderScreen` |
| T02 | Contatos profissionais (prefs) | ✅ | `CareContact` multi; migra `noa_therapist_phone_v1`; editáveis no Início |
| T03 | Enviar resumo WhatsApp | ✅ | picker de contato + fallback clipboard |
| T04 | Compartilhar card imagem | ✅ | `ShareCardExporter` |
| T05 | Relatório PDF (preview + print/share) | ✅ | `TherapistPdfGenerator` — estilos Clínico/Lumen (`noa_pdf_style_v1`); share na Pasta clínica e no preview (`Printing.sharePdf`); Noto Sans embutida |
| T06 | Incluir sono, mood, recovery, insights | ✅ | PDF, WhatsApp e card |
| T07 | Nome do paciente configurável | ✅ | `UserProfile.name` |
| T08 | Período custom (7/14/30) | ✅ | chips na Pasta clínica |

### 6.9 Des-Trava (Unstuck)

Entrada só na aba Dia (linha discreta). Protótipo: `Design/Stitch/new/des_trava_resgate_anti_paralisia/`.

| ID | Feature | Status | Notas |
|----|---------|--------|-------|
| U01 | Bottom sheet glass | ✅ | badge “Modo resgate” |
| U02 | 3 micro-passos sequenciais | ✅ | |
| U03 | Timer 60s + orb animada | ✅ | concluir só quando a contagem chega a zero |
| U04 | Haptic + snack de conclusão | ✅ | |
| U05 | Passos personalizáveis / contexto mood | 🔮 | |

### 6.10 Plataforma / infra

| ID | Feature | Status | Notas |
|----|---------|--------|-------|
| P01 | i18n pt/en/es/ja + doloc | ✅ | locale 100% do sistema; ver `docs/i18n.md` |
| P02 | Tema claro/escuro/sistema | ✅ | |
| P03 | Design system (cores, spacing, glass) | ✅ | `CupertinoApp` + `liquid_glass_renderer`; FakeGlass+blur no chrome/sheet Android; chips densos + surfaces Android em `LumenGlassLite`; zero cara M3/You |
| P04 | Skeletons / FadeSwap | ✅ | |
| P05 | Widget tests básicos | 🟡 | `test/widget_test.dart` |
| P06 | Auth / cloud backup | ❌ | |
| P07 | Analytics de produto | ❌ | |
| P08 | Perfis de tom de voz humanizados | 🔮 | sem fase nesta rodada; continua só no backlog |
| P09 | Onboarding & Perfil Local (opcional) | ✅ | Wizard de 1ª abertura + `ProfileScreen` (ícone no Início); sem tipo sanguíneo e sem aba própria no shell |
| P10 | Hub de Configurações | ✅ | engrenagem no Início / Perfil; `SystemSettings`; horário silencioso de tarefas; export `noa_*`; Sobre: “Mandar feedback” abre formulário externo (`FeedbackFormConfig`, só maintainers); sem analytics SDK |
| P11 | Navegação Início=ficha + Pasta clínica | ✅ | 4 abas inalteradas (Início · Dia · Remédios · Pasta clínica). Início = `HomeFichaScreen`. Tarefas e Meus dias: portas canônicas `openTasksHub` / `openRoutineCalendarScreen` na pilha da aba Início. Pasta clínica: `openClinicalFolderScreen`. Troca de aba: pop-to-root na origem e no destino. Sem `go_router` (FUT-52). `HomeScreen` / `PatientChartScreen` fora da narrativa. Stitch em `Design/Stitch/new/` |

### 6.11 Calendário & Raio-X do Dia (Timeline Diária)

| ID | Feature | Status | Notas |
|----|---------|--------|-------|
| CAL01 | Ponte com o calendário do celular | 🟡 | cada salvamento da rotina cria um evento (EventKit / CalendarContract) com água/hábitos/medicação do dia — sem reflexão/pauta íntimas. A agenda inteira do aparelho não entra no app |
| CAL02 | Visão de Calendário (Mês / Semana) | 🟡 | mês na Ficha e no Dia marca dias com rotina e/ou check-in; tap abre DayDigest. Semana e badges de gasto/Des-Trava ainda fora |
| CAL03 | Timeline do Raio-X do Dia (24h) | 🟡 | DayDigest local (check-in, SoM, rotina, doses, tarefas do dia). Compromissos do aparelho e gastos ainda fora |
| CAL04 | Inspeção de anatomia de dias atípicos no Hub Clínico | 🟡 | Narrativa cronológica no hub; planejado junto com a timeline |

### 6.12 Gestor de Gastos de Hiperfoco & Impulso

| ID | Feature | Status | Notas |
|----|---------|--------|-------|
| EXP01 | Registro simples de gasto de hiperfoco | 🟡 | Botão + quantia. Sem cooldown, contador ou gráfico |
| EXP02 | Timer de Cooldown de 48h | 🔮 | Fica para depois, junto com o pacote completo |
| EXP03 | Notificação casual pós-cooldown | 🔮 | |
| EXP04 | Contador de "Dinheiro Salvo do Hiperfoco" | 🔮 | |
| EXP05 | Gráficos visuais de gastos (`fl_chart`) | 🔮 | |

### 6.13 Ferramentas Visuais de Apoio Executivo

| ID | Feature | Status | Notas |
|----|---------|--------|-------|
| VIS01 | Curva Visual de Energia & Foco do Dia | 🟡 | Gráfico contínuo 24h cruzando sono, janela do estimulante e check-in |
| VIS02 | Checklist Visual de Saída ("Cadê Minhas Coisas?") | 🟡 | Grid tátil de 1 toque: chave, carteira, celular, fone, remédio, óculos |
| VIS03 | Medidor Adaptativo de Bateria Mental | 🟡 | A tela entra no planejamento; o cálculo fica em [Pesquisar mais](#pesquisar-mais), junto com a bateria biológica |

### 6.14 Central Unificada de Tarefas & Lembretes

> Entra na fase atual. O pacote é uma lista só, sem fragmentar a interface.

| ID | Feature | Status | Notas |
|----|---------|--------|-------|
| TSK01 | Pacote único integrado de tarefas | ✅ | Central de Tarefas na Ficha via `openTasksHub` (pilha da aba Início: Hoje / Recorrentes / Pontuais); Dia só checklist do período vigente, com o mesmo helper. Avisos locais do app; sem ponte com o app Lembretes nativo (`EKReminder` fora) |
| TSK02 | Alarme Persistente (Nagging) | ✅ | toca no horário; repete no intervalo escolhido (padrão 5 min) até concluir ou adiar. Estilos (`TaskAlertStyle`): notificação; `alarm` (rótulo de UI: **Em destaque** — Android: canal/volume de alarme, sem som próprio; iPhone: igual à notificação); insistente (Android: pode abrir em tela cheia; iOS: `.timeSensitive`, sem entitlement Time Sensitive nem alerta crítico). Horário silencioso (padrão 22:00–07:00) vale **só para tarefas** — remédios ficam no canal próprio. Permissão negada / exact alarm ausente: CTA via `SystemSettings` (notificações / ficha do app). App fechado: o SO entrega o aviso já agendado; Foco, DND e bateria podem segurar ou atrasar |
| TSK03 | Recorrência flexível | ✅ | pontual, diária, semanal, quinzenal ou mensal — só a janela vigente, sem empilhar períodos |
| TSK04 | Modo Foco ("Uma Coisa Só") | 🟡 | Isola a tarefa ativa na tela, ocultando a lista |
| TSK05 | Fatiador de Tarefas em micro-passos | 🟡 | Quebra em até 3 ações de 2 minutos (extensão do Des-Trava) |
| TSK06 | Gráfico visual de conclusão semanal | 🟡 | Linhas ou barras de tarefas concluídas no período |

---

## 7. Modelos de dados

### MoodEntry

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | String (uuid) | |
| timestamp | DateTime | |
| valence | int 1–5 | |
| energy | EnergyLevel | |
| focus | FocusState | |
| tookMedication | bool | |
| sensoryOverload | bool | |
| note | String? | |
| emotionLabels | Set\<String\> | IDs Apple-like |
| emotionSource | StateOfMindSource | lumen / appleHealth |

### DailyRoutineState

| Campo | Tipo | Descrição |
|-------|------|-----------|
| date | DateTime | dia civil |
| mainFocusAnchor | String | título da tarefa fixada como **Foco do dia** (evento/calendário/export); nome técnico do campo, sem migração |
| stateOfMind | StateOfMindEntry? | |
| eveningReflection | String | |
| microHabits | List\<String\> | |
| completedHabits | Set\<String\> | |
| waterGlasses | int | |
| tookPrescribedMedication | bool | |
| therapistNotes | String? | |

### Medication

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id, name, dosage | | |
| shapeIcon | capsule/tablet/liquid/drop | |
| scheduledTimes | List\<String\> | HH:mm |
| daysOfWeek | List\<int\> | 1–7 |
| totalStock / remainingStock | int | |
| refillWarningThreshold | int | default 5 |
| durationHours | int | janela eficácia |
| instructions | String | |
| active | bool | |
| appleConceptId / rxNormCode | String? | |
| source | local / appleHealth / linked | |

### MedicationLog

takenAt · skipped · skipReason · snoozedUntil · source (lumen / appleHealth)

### SleepRecord / DailyRecoverySnapshot / DailyEnvironmentSnapshot

Ver `lib/integrations/health/models/`. Thresholds de insight:

- Sono déficit: `< 6h`
- REM déficit: `< 75 min`
- HRV baixa: `< 40 ms`
- Passos baixos: `< 4000`
- Luz baixa: `< 20 min`
- Ruído alto: ambiental `≥ 70 dB` ou fones `≥ 80 dB`

### HyperfocusExpense (Gasto de Hiperfoco)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | String (uuid) | |
| title | String | Nome do item desejado |
| estimatedCost | double | Valor monetário em reais |
| hyperfocusCategory | String | Categoria do interesse (ex: "Tecnologia", "Pintura", "Ciclismo") |
| createdAt | DateTime | Momento em que o impulso bateu |
| cooldownEndsAt | DateTime | Momento em que as 48h completam |
| status | ExpenseStatus | `cooldown`, `purchased`, `dismissedSaved` |
| savedAmount | double | Valor contabilizado como poupado se descartado |

### TaskItem (Central de Tarefas)

Persistido em `noa_tasks_v1`. Horário silencioso global em `noa_task_quiet_hours_v1` (padrão 22:00–07:00); vale **só para tarefas**. Remédios usam `medication_reminder_service` e não entram na janela.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | String (uuid) | |
| title | String | Descrição da tarefa |
| timeOfDay | String? | HH:mm do aviso; sem horário = só checklist |
| recurrence | TaskRecurrence | `once`, `daily`, `weekly`, `biweekly`, `monthly` |
| naggingIntervalMinutes | int | Default 5; intervalo até marcar feito ou adiar |
| alertStyle | TaskAlertStyle | `notification`, `alarm` (rótulo de UI: “Em destaque”; valor JSON inalterado), `insistent` |
| weekdays | List\<int\> | Dias (1–7) para weekly/biweekly |
| dayOfMonth | int | Dia do mês para monthly |
| onceDate | DateTime? | Dia civil da tarefa pontual |
| completedPeriodKey | String? | Chave da janela concluída (sem dívida do período anterior) |
| snoozedUntil | DateTime? | Adiamento temporário |
| active | bool | |

### DayTimelineEvent (Raio-X do Dia no Calendário)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | String | Identificador único do evento na timeline |
| timestamp | DateTime | Hora do acontecimento no dia civil |
| eventType | TimelineEventType | `sleepWake`, `medicationDose`, `calendarEvent`, `taskCompleted`, `moodCheckin`, `unstuckTriggered`, `impulseExpense` |
| title | String | Título / resumo do evento |
| detail | String? | Metadados extras (ex: dose tomada, valor gasto, duração) |
| icon | String | Ícone temático para o feed do dia |

### VoiceToneProfile (Perfis de Voz)

Enum: `relaxed` (despojado), `casual` (padrão), `neutral` (não-formal), `formal`, `femaleAdult` (mulheres), `girlYouth` (meninas), `boyYouth` (meninos).

### UserProfile (Perfil do Usuário — 100% Local & Opcional)

Mapeamento de contexto pessoal para calibragem do app e contexto da futura LLM. Todos os campos são pertinentes e estritamente opcionais. Podem ser preenchidos manualmente ou importados em 1 toque do Apple Health / Google Health Connect. Sem conta na nuvem, sem login.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | String (uuid) | Identificador local único |
| name | String? | Nome ou apelido de preferência |
| birthDate | DateTime? | Data de nascimento (para cálculo de idade) |
| weightKg | double? | Peso corporal em kg (para calibração fisiológica) |
| heightCm | double? | Altura em cm |
| biologicalSex | String? | Sexo biológico (para correlações hormonais/fase lútea) |
| voiceToneProfile | VoiceToneProfile | Perfil de tom de voz selecionado |
| importedFromHealth | bool | Flag indicando se dados foram importados do Health |
| updatedAt | DateTime | Data da última alteração local |

> **Sem aba própria no shell:** o perfil biométrico vive em `ProfileScreen` (ícone de pessoa na Home / CTA "Ver meu perfil" na Ficha), não numa 5ª aba. Tipo sanguíneo ficou de fora da implementação — decisão de produto, não lacuna técnica. **Sem conta, sem login, sem nuvem do Lumen:** tudo grava em `noa_user_profile_v1`, só no aparelho; o import de altura/peso/nascimento/sexo via `HealthService.readDemographics()` também é 100% on-device (ver §9.1).

### Persistência (chaves conceituais)

Tudo via SharedPreferences + JSON (`noa_user_profile_v1`, `noa_hyperfocus_expenses_v1`, `noa_tasks_v1`, `noa_voice_tone_profile_v1`, etc.). Preferências extras: sync Health, sync Calendário nativo, telefone terapeuta, tema, locale, micro-hábitos. Armazenamento 100% local no aparelho, sem tráfego de dados para nuvem do Lumen. Mutações de medicação, tarefas, humor, rotina, ledger e contatos passam por `PersistenceLocks` (fila process-wide) para UI e handlers de notificação não se sobrescreverem; JSON ilegível não é trocado por lista vazia.

Uma atualização na loja mantém esse armazenamento: o identificador continua `dev.prism.lumen` e as chaves `noa_*` não são apagadas na abertura. Se um JSON antigo não puder ser lido, o app não grava uma lista vazia por cima. Sono e batimentos continuam no Apple Health ou no Health Connect, fora do arquivo do Lumen.

A mesma atualização não espelha de novo o que já foi escrito. Água, atenção plena, State of Mind e o evento da rotina no calendário ficam marcados no aparelho; a dose vinda do Saúde entra uma vez por minuto do mesmo remédio. Um segundo passe, na abertura ou num novo build, não cria outra cópia nem substitui o registro local.

---

## 8. Fluxos de usuário

### F1 — Check-in matinal (caminho feliz)

```
Aba Dia → CheckInForm → Salvar
  → MoodEntry local + SoM no snapshot + espelho HealthKit se ligado
  → Início atualiza “entradas recentes” + insights (se dados suficientes)
```

### F2 — Rotina com mirror Health

```
Aba Dia (ou Início → card Foco do dia) → editar Foco do dia / SoM / hábitos / água → Salvar
  → RoutineRepository
  → RoutineHealthMirror (se HS enabled)
      → writeWater / writeMindfulness / writeStateOfMind
```

### F3 — Tomar medicação

```
Aba Remédios (ou Início → card Remédios de hoje) → card dose pendente → Tomar
  → log.takenAt = now; estoque--; EfficacyWindowBar
  → (opcional) writeDoseEvent Apple
```

### F4 — Paralisia executiva

```
Aba Dia → Des-Trava → passo 1 → timer 60s → passo 2 → passo 3 → snack
```

### F5 — Preparar sessão clínica

```
Aba Pasta clínica (`openClinicalFolderScreen`, também a partir de Configurações)
  → período / ocultar notas → escolher contato → WhatsApp | Share card | PDF
```

### F6 — Conectar Apple Health

```
Consent sheet → permissions plugin + bridge → syncEnabled=true
  → invalidate sleep/recovery providers
```

### F6b — Onboarding na 1ª abertura

```
Primeira abertura, sem dado local ainda → FirstLaunchOnboarding
  (tela cheia, 4 passos, cada um pulável sem travar o app)
  1. Boas-vindas + nota de privacidade ("sem conta, sem login, sem nuvem do Lumen")
  2. Saúde: HealthSyncConsentSheet → readDemographics() preenche nascimento/altura/
     peso/sexo biológico quando o SDK já tem o dado (iOS: os 4; Android: altura/peso)
  3. Acessos do sistema: notificações de dose + calendário do aparelho
  4. Perfil: nome, data de nascimento, tom de voz + o que a Saúde não preencheu
  → aplica o rascunho em UserProfile (importedFromHealth quando houve import)
  → grava noa_user_profile_v1 e marca noa_onboarding_done_v1
```

### F7 — Editar o perfil depois da 1ª abertura

```
Início (ícone de pessoa / bloco identidade) → ProfileScreen
  → editar → OnboardingProfileForm → noa_user_profile_v1
```

### F7b — Configurações

```
Início (engrenagem) ou ProfileScreen → SettingsScreen
  → Tema · Idioma/SO · notificações · Saúde · calendário · horário silencioso (tarefas, não remédios) · export JSON · Pasta clínica (`openClinicalFolderScreen`)
  → Sobre → Mandar feedback → formulário externo (URL só em `FeedbackFormConfig` / dart-define; sem dado de saúde)
```

### F7c — Contatos profissionais

```
Início → Meus profissionais → adicionar/editar CareContact (papel + nome + telefone)
  → noa_care_contacts_v1 (migra telefone legado)
```

### F8 — Navegar pelo Raio-X do Dia no Calendário

```
Início (card Meus dias) ou Dia (ícone calendário) → openRoutineCalendarScreen (pilha da aba Início)
  → Selecionar data
  → DayDigest local: check-ins (palavras + nota), SoM, rotina (reflexão/pauta), doses, tarefas
  → Ainda fora: compromissos nativos (EventKit), Des-Trava e impulsos numa linha 24h
```

---

## 9. Integrações

### 9.0 Regra de paridade entre os SDKs de saúde

O Lumen é o meio-termo entre Apple HealthKit e Android Health Connect. A função existe no app nas duas plataformas. A sincronia com o app de saúde do aparelho é o extra, não a condição da função.

- **Os dois SDKs têm o tipo.** Ponte mútua: o app lê o que o SDK gravou e grava de volta o que a pessoa registrou no Lumen, com o consentimento que já existe. Sono, recuperação, água e mindfulness ainda estão de mão única; a regra pede os dois sentidos.
- **Só um SDK tem o tipo.** A função continua no outro aparelho. A única diferença é a ausência de espelho no app de saúde. Hoje isso vale para State of Mind, agenda e eventos de dose, luz do dia, áudio ambiental e áudio de fones (só no HealthKit). Se um tipo existir só no Health Connect, a mesma regra vale para o iPhone.
- **Nenhum SDK tem o tipo.** A função é só do Lumen (rotina, Des-Trava, gasto simples, calendário do produto). Fora desta regra.

Sem permissão do SDK, o app mostra o que a pessoa registrou localmente, ou vazio se não houver registro. Não inventar dado de saúde. Não amostrar microfone nem sensor de luz para imitar o Apple Watch: luz e áudio no Android, enquanto essa permissão não for pedida, são registro local. HRV continua SDNN no iOS e RMSSD no Android, com a unidade no domínio.

A matriz abaixo é o catálogo dessa regra (ponte mútua, função local com sync só de um lado, ou só do app). A paridade de função não espera a Fase 2.

### 9.1 Integrações atuais do Lumen (iOS primário)

Android: **Samsung Health** (Data SDK quando o AAR/partner estiver linkado) **ou** **Health Connect** (fallback / aparelhos sem Samsung). Outros apps OEM → UX instruindo sync com Health Connect. Contrato: `HealthAppConnector` + `FacadeHealthService`.

| Dado | Direção | Via |
|------|---------|-----|
| Sono (estágios) | ← | plugin `health` / Samsung bridge |
| HRV, RHR, passos, exercício | ← | plugin `health` (HC) / Samsung + gap HC |
| Perfil (altura, peso, nascimento, sexo) | ← | plugin / Samsung profile (`readDemographics`; iOS os 4, Android HC altura/peso) |
| Time in daylight, áudio | ← | `HealthKitBridge` |
| State of Mind | ↔ | bridge |
| Medicamentos / dose events | ↔ | bridge |
| Água / mindfulness | → | plugin / Samsung (Android mindfulness = workout meditação) |

### 9.2 Matriz completa de paridade: Apple HealthKit ↔ Android Health Connect

Mapeamento dos tipos do **Apple HealthKit** e do **Health Connect**. **Total** ou **Parcial** com equivalente nos dois lados é ponte mútua. **Inexistente** ou **Alternativa** de um lado só é função no app nas duas plataformas, com sync só onde o SDK existe.

#### 1. Sono e Repouso (Sleep Analytics)

| Função / Tipo no Apple HealthKit | Equivalente Android (Health Connect / Framework) | Paridade | Observações Técnicas & Diferenças |
| :--- | :--- | :--- | :--- |
| `HKCategoryTypeIdentifierSleepAnalysis`<br>`HKCategoryValueSleepAnalysis.asleepCore` | `SleepSessionRecord`<br>`Stage.STAGE_TYPE_LIGHT` | **Total** | Sono leve ("Core" no iOS, "Light" no Android). |
| `HKCategoryValueSleepAnalysis.asleepDeep` | `SleepSessionRecord`<br>`Stage.STAGE_TYPE_DEEP` | **Total** | Sono profundo (delta/slow-wave). |
| `HKCategoryValueSleepAnalysis.asleepREM` | `SleepSessionRecord`<br>`Stage.STAGE_TYPE_REM` | **Total** | Sono REM (crítico para foco/TDAH). |
| `HKCategoryValueSleepAnalysis.awake` | `SleepSessionRecord`<br>`Stage.STAGE_TYPE_AWAKE` | **Total** | Períodos acordados durante a janela de sono. |
| `HKCategoryValueSleepAnalysis.inBed` | `SleepSessionRecord`<br>`Stage.STAGE_TYPE_OUT_OF_BED` / Sessão | **Parcial** | O iOS separa "tempo na cama" de "tempo dormindo". O Android usa o início/fim da sessão principal. |

#### 2. Sinais Vitais e Biometria Cardíaca (Vitals & Cardiac)

| Função / Tipo no Apple HealthKit | Equivalente Android (Health Connect / Framework) | Paridade | Observações Técnicas & Diferenças |
| :--- | :--- | :--- | :--- |
| `HKQuantityTypeIdentifierHeartRate` (BPM) | `HeartRateRecord` | **Total** | Amostras pontuais de batimentos cardíacos ao longo do dia. |
| `HKQuantityTypeIdentifierRestingHeartRate` | `RestingHeartRateRecord` | **Total** | Frequência cardíaca de repouso (RHR). |
| `HKQuantityTypeIdentifierHeartRateVariabilitySDNN` | `HeartRateVariabilityRmssdRecord` | **Parcial** | ⚠️ **Diferença Matemática Crítica:** O Apple Health usa **SDNN** (desvio padrão em ms), enquanto o Health Connect usa **RMSSD** (raiz quadrada da média das diferenças). Exigem normalizações diferentes para score de recuperação. |
| `HKQuantityTypeIdentifierOxygenSaturation` (SpO2) | `OxygenSaturationRecord` | **Total** | Percentual de oxigenação no sangue. |
| `HKQuantityTypeIdentifierRespiratoryRate` | `RespiratoryRateRecord` | **Total** | Frequência respiratória (respirações por minuto). |
| `HKQuantityTypeIdentifierBloodPressure` | `BloodPressureRecord` | **Total** | Agrupamento de pressão sistólica e diastólica. |
| `HKQuantityTypeIdentifierBodyTemperature` | `BodyTemperatureRecord` | **Total** | Temperatura corporal periférica ou central. |
| `HKQuantityTypeIdentifierBasalBodyTemperature` | `BasalBodyTemperatureRecord` | **Total** | Temperatura basal ao acordar. |
| `HKElectrocardiogram` (ECG) | *Não disponível no Health Connect* | **Inexistente** | ECG bruto só é acessível via SDKs proprietários OEM (Samsung Privileged Health SDK, Fitbit, Withings). |

#### 3. Bem-Estar Mental, Humor e Mindfulness

| Função / Tipo no Apple HealthKit | Equivalente Android (Health Connect / Framework) | Paridade | Observações Técnicas & Diferenças |
| :--- | :--- | :--- | :--- |
| `HKStateOfMind` (iOS 17+)<br>• Valência (−1.0 a +1.0)<br>• Rótulos emocionais<br>• Associações de contexto | *Não disponível no Health Connect* | **Inexistente** | O Health Connect ainda não possui schema para saúde mental/humor. Deve ser armazenado **localmente** no app (SharedPreferences / SQLite / Room). |
| `HKCategoryTypeIdentifierMindfulSession` | `ExerciseSessionRecord`<br>`(EXERCISE_TYPE_MEDITATION)` | **Alternativa** | O Health Connect não tem um `MindfulnessRecord` dedicado; a convenção recomendada pela Google é registrar como uma sessão de exercício com tipo "Meditação" ou gerenciar via app. |

#### 4. Medicamentos e Adesão (Medications)

| Função / Tipo no Apple HealthKit | Equivalente Android (Health Connect / Framework) | Paridade | Observações Técnicas & Diferenças |
| :--- | :--- | :--- | :--- |
| Apple Health Medications (Agenda, doses tomadas, puladas, snoozed) | *Não disponível no Health Connect estável* | **Inexistente** | O Health Connect não possui API de rotina/dispensação de medicamentos. Android requer `AlarmManager` + banco de dados local. |
| `HKClinicalType` / FHIR Records (Prescrições, alergias, laudos) | Health Connect FHIR / Clinical Records (Android 14+ / Preview) | **Parcial** | O Google iniciou o suporte a prontuários FHIR em preview restrito, mas ainda não é uma API de consumidor ampla como no iOS. |

#### 5. Ambiente, Luz e Exposição Sonora (Environment & Audio)

| Função / Tipo no Apple HealthKit | Equivalente Android (Health Connect / Framework) | Paridade | Observações Técnicas & Diferenças |
| :--- | :--- | :--- | :--- |
| `HKQuantityTypeIdentifierTimeInDaylight` (iOS 17+) | *Não disponível no Health Connect* | **Alternativa (SensorManager)** | O iOS calcula a exposição à luz natural via Apple Watch. No Android, exige leitura do sensor físico de luz ambiente (`Sensor.TYPE_LIGHT`) no aparelho ou inferência via clima/geolocalização. |
| `HKQuantityTypeIdentifierEnvironmentalAudioExposure` (dB) | *Não disponível no Health Connect* | **Alternativa (AudioRecord)** | Decibéis do ambiente. No Android, requer amostragem manual de áudio com permissão de microfone (`RECORD_AUDIO`). |
| `HKQuantityTypeIdentifierHeadphoneAudioExposure` (dB) | *Não disponível no Health Connect* | **Alternativa (AudioManager)** | Exposição de fones. No Android, o SO gerencia alertas de volume seguro, mas não disponibiliza série histórica centralizada em API pública. |

#### 6. Atividade, Passos e Exercício (Activity & Fitness)

| Função / Tipo no Apple HealthKit | Equivalente Android (Health Connect / Framework) | Paridade | Observações Técnicas & Diferenças |
| :--- | :--- | :--- | :--- |
| `HKQuantityTypeIdentifierStepCount` | `StepsRecord` | **Total** | Contagem de passos por intervalo. |
| `HKQuantityTypeIdentifierDistanceWalkingRunning` | `DistanceRecord` | **Total** | Distância percorrida em metros. |
| `HKQuantityTypeIdentifierActiveEnergyBurned` | `ActiveCaloriesBurnedRecord` | **Total** | Calorias ativas gastas em movimento. |
| `HKQuantityTypeIdentifierBasalEnergyBurned` | `BasalMetabolicRateRecord` / `TotalCaloriesBurnedRecord` | **Total** | Gasto calórico basal em repouso. |
| `HKQuantityTypeIdentifierFlightsClimbed` | `FloorsClimbedRecord` | **Total** | Andares de escada subidos. |
| `HKWorkout` / `HKWorkoutType` | `ExerciseSessionRecord` | **Total** | Treinos estruturados com modalidade, duração e dados associados. |
| `HKQuantityTypeIdentifierVO2Max` | `Vo2MaxRecord` | **Total** | Capacidade cardiorrespiratória máxima. |
| `HKQuantityTypeIdentifierAppleExerciseTime` | `ExerciseSessionRecord.duration` | **Parcial** | No iOS existe uma métrica independente de "minutos de exercício" do anel de atividade; no Android deriva-se das sessões ativas. |
| `HKQuantityTypeIdentifierAppleStandTime` | *Não disponível diretamente* | **Inexistente** | Métrica fechada do "Anel Ficar em Pé" do Apple Watch. |

#### 7. Nutrição e Hidratação (Nutrition & Hydration)

| Função / Tipo no Apple HealthKit | Equivalente Android (Health Connect / Framework) | Paridade | Observações Técnicas & Diferenças |
| :--- | :--- | :--- | :--- |
| `HKQuantityTypeIdentifierDietaryWater` | `HydrationRecord` | **Total** | Volume de água consumido (em mililitros/litros). |
| `HKQuantityTypeIdentifierDietaryEnergyConsumed` | `NutritionRecord.energy` | **Total** | Calorias consumidas. |
| Macronutrientes (Carboidratos, Proteínas, Gorduras, Fibras) | `NutritionRecord`<br>(campos específicos: `totalCarbohydrate`, `protein`, `totalFat`, etc.) | **Total** | Ambos utilizam schemas consolidados de macronutrientes. |
| Micronutrientes (Cafeína, Vitaminas, Minerais) | `NutritionRecord`<br>(campos: `caffeine`, `dietaryFiber`, `sodium`, etc.) | **Total** | Registrados como propriedades dentro do objeto de nutrição. |

#### 8. Medições Corporais (Body Measurements)

| Função / Tipo no Apple HealthKit | Equivalente Android (Health Connect / Framework) | Paridade | Observações Técnicas & Diferenças |
| :--- | :--- | :--- | :--- |
| `HKQuantityTypeIdentifierBodyMass` (Peso) | `WeightRecord` | **Total** | Peso corporal em kg. |
| `HKQuantityTypeIdentifierHeight` (Altura) | `HeightRecord` | **Total** | Altura em metros/centímetros. |
| `HKQuantityTypeIdentifierBodyMassIndex` (IMC) | *Calculado* | **Total** | Geralmente calculado dinamicamente em ambas as plataformas. |
| `HKQuantityTypeIdentifierBodyFatPercentage` | `BodyFatRecord` | **Total** | Percentual de gordura corporal. |
| `HKQuantityTypeIdentifierLeanBodyMass` | `LeanBodyMassRecord` | **Total** | Massa magra em kg. |
| `HKQuantityTypeIdentifierWaistCircumference` | `BoneMassRecord` / Circunferências | **Parcial** | Medições antropométricas corporais. |

#### 9. Saúde Reprodutiva e Ciclo (Cycle Tracking)

| Função / Tipo no Apple HealthKit | Equivalente Android (Health Connect / Framework) | Paridade | Observações Técnicas & Diferenças |
| :--- | :--- | :--- | :--- |
| `HKCategoryTypeIdentifierMenstrualFlow` | `MenstruationPeriodRecord`<br>`MenstruationFlowRecord` | **Total** | Registro de período e intensidade do fluxo. |
| `HKCategoryTypeIdentifierOvulationTestResult` | `OvulationTestRecord` | **Total** | Resultados de testes de LH/ovulação. |
| `HKCategoryTypeIdentifierCervicalMucusQuality` | `CervicalMucusRecord` | **Total** | Qualidade do muco cervical. |
| `HKCategoryTypeIdentifierSexualActivity` | `SexualActivityRecord` | **Total** | Registro de atividade sexual e proteção. |
| `HKCategoryTypeIdentifierIntermenstrualBleeding` | `IntermenstrualBleedingRecord` | **Total** | Sangramento fora do período menstrual. |

#### 10. Mobilidade e Detecção de Incidentes

| Função / Tipo no Apple HealthKit | Equivalente Android (Health Connect / Framework) | Paridade | Observações Técnicas & Diferenças |
| :--- | :--- | :--- | :--- |
| `Apple Walking Steadiness` (Estabilidade de caminhada) | *Não disponível no Health Connect* | **Inexistente** | Métrica proprietária dos acelerômetros/giroscópios do iPhone/Watch via CoreMotion. |
| `Walking Speed` / `Step Length` / `Asymmetry` | *Não disponível no Health Connect* | **Inexistente** | Métricas exclusivas de locomoção do HealthKit. |
| `HKCategoryTypeIdentifierFallEvent` (Queda) | *APIs OEM (Wear OS Safety)* | **Inexistente no HC** | Disponível apenas via serviços de segurança do fabricante (ex: Samsung / Pixel Watch Emergency). |

#### 11. Arquitetura de Sistema, Queries e Sincronização

| Recurso / API no Apple HealthKit | Equivalente no Android Health Connect | Paridade | Observações de Engenharia |
| :--- | :--- | :--- | :--- |
| `HKHealthStore.requestAuthorization()` | `PermissionController.createRequestPermissionResultContract()` | **Total** | Fluxo declarativo padrão de permissões em tempo de execução. |
| `HKStatisticsQuery` (Soma, Média, Mín, Máx) | `HealthConnectClient.aggregate(AggregateRequest)` | **Total** | Agregação nativa de dados (ex: soma de passos, média de FC). |
| `HKAnchoredObjectQuery` (Apenas novos registros pós-âncora) | `HealthConnectClient.getChangesToken()` + `getChanges()` | **Total** | Essencial para sincronização diferencial offline-first eficiente. |
| `HKObserverQuery` + `enableBackgroundDelivery()` | Background Read Permission (`PERMISSION_READ_HEALTH_DATA_IN_BACKGROUND` - Android 14+) | **Parcial** | O iOS acorda o app silenciosamente via SO. No Android, a leitura em segundo plano exige permissão especial concedida pelo usuário nas configurações do sistema. |
| Deduplicação de Múltiplas Fontes (Apple Watch vs iPhone vs Apps) | Prioridade de Fontes e `DataOrigin` | **Total** | Ambos permitem filtrar por dispositivo de origem ou priorizar fontes confiáveis para evitar duplicidade de passos/sono. |

### 9.3 Onde a função existe e a sincronia não

1. **State of Mind:** existe nas duas plataformas. No iPhone espelha o HealthKit. No Android fica no registro local, sem Health Connect.
2. **Medicações e janela de eficácia:** a agenda, a dose e a barra existem nas duas plataformas. A escrita no app de saúde só ocorre onde o SDK tem o tipo (hoje, o HealthKit).
3. **Luz do dia e áudio:** o card existe nas duas plataformas. No iPhone a leitura vem do HealthKit. No Android o registro é local, feito pela pessoa. Sem amostrar microfone ou sensor de luz para imitar o relógio.
4. **HRV:** SDNN no iOS e RMSSD no Android. A unidade fica no domínio. Sem fundir as duas numa métrica falsa.

### 9.4 Priorização Clínica para Neurodivergência & Saúde Mental (TDAH, TEA, Transtornos de Humor)

Em contextos de neurodivergência e saúde mental, o valor dos dados de saúde não é registrar métricas passivas, mas **detectar precocemente sinais de desregulação neuroquímica, sobrecarga do sistema autônomo e fadiga executiva** para prevenir paralisia (*ADHD paralysis*), sobrecarga sensorial (*meltdown/shutdown*) e *burnout*.

Abaixo, os dados biométricos e contextuais são classificados por nível de impacto e prioridade de produto no Lumen:

| Prioridade | Métrica / Recurso | Relevância Neurobiológica & Clínica | Status no Lumen | Aplicação Prática no App |
| :---: | :--- | :--- | :---: | :--- |
| 🥇 **P0** | **Sono REM & Latência/Despertares** | Regulação afetiva e consolidação de memória. Déficit de REM gera desregulação emocional severa, impulsividade e névoa mental (*brain fog*). Despertares frequentes refletem atraso circadiano (DSPS). | ✅ Implementado (`S01`–`S03`) | Alertar quando REM < 75 min e correlacionar com dias paralisados ou esgotados. |
| 🥇 **P0** | **Variabilidade Cardíaca (HRV — SDNN / RMSSD)** | Biomarcador de ouro do tônus vagal parassimpático. Quedas abruptas sinalizam hiperexcitação simpática ("luta ou fuga"), esgotamento pré-burnout ou crise de pânico iminente. | ✅ Implementado (`S04`, `S07`) | Indicador matinal de resiliência ao estresse ("bateria biológica"). |
| 🥇 **P0** | **Valência Rápida & State of Mind** | Combate à alexitimia (dificuldade de nomear emoções, comum em ~50% dos neurodivergentes). Micro-registro em ~5s remove a fricção do diário longo. | ✅ Implementado (`C01`–`C06`, `SM01`) | Cruzamento direto de estados emocionais com fatores ambientais e sono. |
| 🥈 **P1** | **Medicação & Janela de Eficácia (Crash)** | Estimulantes têm janela terapêutica estreita. O término da ação gera um "crash dopaminérgico" transitório com disforia e irritabilidade. | ✅ Barra / 🔎 aviso (`M04` ✅, `FUT-21`) | A barra existe. O aviso ~1h antes fica em Pesquisar mais. |
| 🥈 **P1** | **Exposição Sonora (dB Ambiental & Fones)** | Hipersensibilidade a processamento sensorial em TEA/TDAH. Estímulos sonoros acumulados (>70 dB) drenam energia executiva sem percepção consciente. | ✅ Card / 🔮 alerta (`S05` ✅, `FUT-37`) | O card existe. O alerta proativo fica para depois e não é prioridade. |
| 🥈 **P1** | **Tempo em Luz Natural (Daylight)** | Luz solar matinal ativa o núcleo supraquiasmático, disparando dopamina e sincronizando o ritmo circadiano. Pessoas com TDAH em hiperfoco tendem ao isolamento escuro. | ✅ Implementado (`S05`, `S07`) | Insight: correlaciona pouca luz solar com humor deprimido e insônia à noite. |
| 🥈 **P1** | **Ciclo Menstrual & Modulação Hormonal** | O estrogênio potencializa a dopamina; na fase lútea tardia (queda de estrogênio), estimulantes perdem eficácia e sintomas de TDAH/TDPM disparam. | 🟡 nesta fase (`J1`) | Rastreamento opt-in correlacionando fase do ciclo com perda de foco. |
| 🥉 **P2** | **Frequência Cardíaca de Repouso (RHR)** | Monitoramento de efeitos colaterais de psicoestimulantes e somatização de ansiedade (distinguir procrastinação por falta de dopamina vs. paralisia por ansiedade). | ✅ RHR / 🟡 picos (`S04` ✅, `J3`) | RHR diário nos cards; picos depois da dose entram no planejamento. |
| 🥉 **P2** | **Passos & Inércia Motora** | O movimento aeróbico estimula a liberação de dopamina e BDNF, atuando como "resgate" da inércia. Dias com <2.000 passos coincidem com paralisia executiva. | ✅ Passos / 🟡 aviso (`S04` ✅, `I6`) | Passos diários hoje; poucos passos abrem o Des-Trava nesta fase. |
| 🥉 **P2** | **Hidratação & Cafeína** | Estimulantes inibem a sede e aumentam diurese. Cafeína excessiva combinada a estimulantes dispara taquicardia e ataques de pânico. | ✅ Água / 🟡 tags (`R04` ✅, `J2`) | Água na rotina hoje; cafeína e álcool no check-in entram no planejamento. |

### 9.5 WhatsApp

`url_launcher` com deep link; fallback clipboard.

### 9.6 Notificações

`flutter_local_notifications` com init única (`LocalNotificationsHost`). Sem `Timer` periódico. Permissão negada não inventa aviso: a UI mostra o estado real e o CTA abre `SystemSettings` (sem WebView, sem `MethodChannel` na tela).

**Remédios** — canal `medication_reminders`: cada horário ativo vira um aviso semanal no fuso do aparelho; Tomar grava a dose, Adiar empurra 15 minutos, toque no corpo abre Remédios. Fora do horário silencioso de tarefas.

**Tarefas** — canais `task_reminders` / `task_reminders_alarm`: aviso no horário, nagging no intervalo escolhido, Concluir/Adiar, toque abre Rotina. Estilos (`TaskAlertStyle`; o enum/JSON não muda):

- `notification` (UI: Notificação) — aviso comum do sistema. Foco ou Não Perturbe do aparelho mandam.
- `alarm` (UI: **Em destaque**) — Android: canal de alarme, importância máxima, volume de alarme (sem asset de som próprio). iPhone: igual à notificação (`.active`).
- `insistent` (UI: Bem chamativo) — Android: pode abrir em tela cheia com o aparelho bloqueado. iPhone: `.timeSensitive` (pede para passar pelo Foco; quem decide é o sistema). Sem entitlement Time Sensitive e sem alerta crítico.

Horário silencioso (`noa_task_quiet_hours_v1`, padrão 22:00–07:00) empurra só o aviso de **tarefa** para depois da janela. Remédio continua no horário.

Permissão de notificação desligada: CTA `SystemSettingsTarget.notifications`. Exact alarm ausente no Android: CTA `SystemSettingsTarget.app` (ficha do app; o bridge não tem destino dedicado à tela “Alarmes e lembretes”).

Com o app fechado, o aviso já está agendado no SO (`AlarmManager` / `UNUserNotificationCenter`) e não depende do processo do Lumen. Isso **não** promete furar Foco, Não Perturbe, economia de bateria nem horário exato sem a permissão de alarmes do Android.

### 9.7 Tradução

doloc.io a partir de `app_pt.arb` → en/es/ja. Ver [i18n.md](./i18n.md).

---

## 10. i18n, tema e design system

### i18n

- Fonte: `lib/l10n/app_pt.arb`
- Acesso: `AppLocalizations.of(context)` ou `appLocalizationsProvider`
- Locale: preferência do **sistema** (sem seletor no app; atalho em Configurações abre o SO)
- Labels SoM: mapas por `languageCode` (não ARB)

### Tema

- `CupertinoApp` + `AppTheme.lightTheme` / `darkTheme` (Material só no `builder`, transparente)
- Tokens: `AppColors`, `AppSpacing`, `AppRadii`, `lumenGlassSettings` / `LumenGlass`, `GlassSurface` / `GlassSheet` / `showLumenSheet` / `LumenKeyboardInset`, `GlassNavBar` (cápsula + lente), `GlassAppBar` / `GlassScaffold` (`reservedTop`), `GlassIconButton`, `GlassChip`, `LumenFab`, `showGlassToast`
- Liquid glass via `liquid_glass_renderer` (`LiquidGlass` / `FakeGlass` / `GlassGlow` / `LiquidGlassBlendGroup`) + `LumenGlassLite` em chips densos / surfaces Android; FakeGlass+blur no chrome/sheet Android; Impeller + `EnableFlutterGPU` / `FLTEnableFlutterGPU`
- Zero visual Material 3 / You / Google (sem FAB/SnackBar/Chip/Card M3 na pele); transitions Cupertino
- Responsive: `responsive.dart` (`kMinBodySecondary`, etc.)

### Linha-base de hardware (glass + utilidades)

Referência de QA — não é listing de loja. `minSdk` 26 / iOS deploy 17; glass pleno exige Impeller/Vulkan (API 29+ no Android).

| Faixa | Aparelhos | Glass |
|-------|-----------|-------|
| Alvo confortável | iPhone 13+ / SE 3ª; Pixel 7+ ou S22+ (≥6 GB, Android 12+) | Vidro pleno na nav/app bar/sheets, 60 fps |
| Mínimo usável | iPhone XS–11 (iOS 17); mid-range API 29+ (A54 / ~4–6 GB) | `FakeGlass` no chrome se GPU não aguentar |
| Fora do foco | Emulador sem GPU, Web, Windows/Linux | Só FakeGlass / sem refração |

Smoke: iPhone 14/15, Pixel 7/8 (ou S23), um mid-range Android. O que mais puxa chip é o glass (~335 mW GPU no Pixel 10 na doc do pacote); Health, alarmes, calendário e PDF são leves ao lado disso.

### Navegação atual

Quatro abas no `LumenShell` (`PageView` full-bleed + `GlassNavBar` dock flutuante com indicador de vidro neutro), cada uma com `Navigator` aninhado. Sem `go_router` (FUT-52). Sem quinta aba. O inset inferior entra só em `MediaQuery.padding` — o conteúdo pinta atrás da cápsula para a refração aparecer. O shell e as abas usam `resizeToAvoidBottomInset: false`: teclado **não** sobe a tab bar nem as páginas; só gavetas via `showLumenSheet` / `LumenKeyboardInset` redimensionam. Telas empilhadas usam `GlassScaffold` + `GlassAppBar`: body abaixo de `reservedTop` (texto/gráfico nunca sob a cápsula). As raízes das abas **não** usam `GlassAppBar` (o rótulo mora na tab bar); ações ficam no cabeçalho do corpo via `GlassIconButton`. Bottom sheets abrem via `showLumenSheet` com `useRootNavigator: true` (acima da `GlassNavBar`) + `GlassSheet` (teclado único, FakeGlass legível, campo focado com `ensureVisible`).

| Aba | Raiz |
|-----|------|
| Início | `HomeFichaScreen` (ficha viva) |
| Dia | `DailyRoutineScreen` |
| Remédios | `MedicationsScreen` |
| Pasta clínica | `ClinicalFolderScreen` |

Troca de aba (`_showTab`, toque na tab bar ou atalho que muda de aba): pop-to-root na aba de origem **e** na de destino. Toque na aba já selecionada também volta à raiz. A aba Início não consome o back do aparelho (`PopScope` / gesto iOS).

Portas canônicas (helpers em `lumen_shell.dart`):

- **Tarefas** — `openTasksHub`: aba Início → raiz → `TasksHubScreen` empilhada. Mesma pilha a partir do card na Início e de “Ver todas as tarefas” no Dia.
- **Meus dias** — `openRoutineCalendarScreen`: mesma política (pilha da Início). Reusada pelo card na Início e pelo ícone de calendário no Dia.
- **Pasta clínica** — `openClinicalFolderScreen`: 4ª aba na raiz (também a partir de Configurações).
- **Dia / Remédios** — `openRoutineScreen` / `openMedicationsScreen`: só trocam de aba.

Check-in e Des-Trava moram só na aba Dia. Perfil e Configurações empilham na aba ativa (`openProfileScreen` / `openSettingsScreen`). `HomeScreen` e `PatientChartScreen` saíram da narrativa de produto.

### Protótipo visual (Stitch, 2026-09-24)

Requisitos em [PRD.md](PRD.md). Arquivos em `Design/`:

| Pasta | Tela |
|-------|------|
| `lumen_in_cio_home_hub` | Home |
| `lumen_check_in_r_pido` | Check-in |
| `lumen_rotina_foco` | Rotina |
| `lumen_medica_es_janela` | Medicação |
| `lumen_des_trava_anti_paralisia` | Des-Trava |
| `lumen_hub_cl_nico` | Hub clínico |
| `lumen_minimalist_mark` | Marca (SVG) |
| `soft_liquid_glass/DESIGN.md` | Tokens exportados |

O YAML do Stitch marca `primary` como `#006c53` e `#1FAF8A` como `primary-container`. No app, o preenchimento dos CTAs continua `#1FAF8A`. Fundo do app permanece sólido, sem orbes. O protótipo mede água em mililitros; a rotina atual conta copos (`R04`). O título “Sessão Descongelar” do HTML não substitui o nome de produto Des-Trava.

---

## 11. Tasks de desenvolvimento (estado atual)

Use esta lista como board. Tasks usam letra do epic + número sem zero (`H3`, `B7`). Features da §6 usam prefixo + dois dígitos (`CAL03`, `H03`). Não confundir os dois sistemas — ver [Como ler os IDs e as siglas](#como-ler-os-ids-e-as-siglas).

### Epic A — Fundação (concluído)

- [x] A1 Bootstrap Flutter + Riverpod + SharedPreferences
- [x] A2 Design system Soft Liquid Glass
- [x] A3 Home hub com CTAs principais
- [x] A4 i18n 4 locales + pipeline doloc
- [x] A5 Tema claro/escuro/sistema

### Epic B — Humor & rotina (concluído / polish)

- [x] B1 MoodEntry + repository
- [x] B2 Quick check-in modal completo
- [x] B3 Daily routine screen + save
- [x] B4 State of Mind editor + labels
- [ ] B5 Unificar flag “med tomada” (check-in × rotina × MedicationLog) — segue aberta. A Fase 0.6 (multi-dose, M02) deixou a adesão real por slot em `MedicationLog`, mas o toggle “Tomei medicação” do check-in (`MoodEntry.tookMedication`) continua um resumo subjetivo solto, sem `medicationId`/`logId`
- [ ] B6 Nome do usuário dinâmico (remover hardcode)
- [x] B7 Check-in grava State of Mind sozinho (espelho HealthKit iOS 18+; cópia local sempre). Fase 0.4: nome único Check-in; o caminho rápido grava `MoodEntry` e funde o SoM no snapshot do dia (`mergeTodayStateOfMind`, sem N snapshots); `DayDigest` lê SoM só dos snapshots

### Epic C — Medicações

- [x] C1 Modelo Medication + MedicationLog
- [x] C2 UI lista + add sheet + card ações
- [x] C3 Efficacy window
- [x] C4 Import Apple meds
- [x] C5 Agendar notificações recorrentes por horário
- [x] C6 Deep link notificação → tela meds / ação tomada
- [ ] C7 Escrita consistente de dose events no Health
- [ ] C8 UI de vincular med local ↔ Apple concept
- [ ] C9 Histórico multi-dia de adesão (gráficos)
- [ ] C10 Aviso gentil de rebote perto do fim da janela (lanche leve e água)
- [ ] C11 Atalho de mensagem para renovar a receita quando o estoque está baixo

### Epic D — Health & insights

- [x] D1 HealthService abstrato + AppleHealthService
- [x] D2 Sleep + recovery cards
- [x] D3 CorrelationEngine (vários insights)
- [x] D4 Consent + mirror rotina
- [x] D5 Bridge luz/áudio/SoM/meds
- [x] D6 Implementação sólida Health Connect (Android)
- [ ] D7 Cache local de snapshots Health (offline resiliente)
- [x] D8 Onboarding guiado na 1ª abertura (intro + permissões já usadas; FUT-01 narrativo continua no backlog)
- [ ] D9 Insights com período configurável e confiança estatística

### Epic E — Export clínico

- [x] E1 Hub + WhatsApp formatter
- [x] E2 Share card PNG
- [x] E3 PDF generator rico
- [x] E4 Perfil paciente (nome) — idade/diagnóstico ainda abertos
- [ ] E5 Seletor de período 7/14/30 na UI
- [ ] E6 Export mais completo no primeiro teste: PDF, WhatsApp e card já levam os salvamentos da rotina (hora, Foco do dia, água, hábitos, medicação, reflexão e notas; o toggle esconde reflexão e pauta). Ainda falta a adesão real de dose (tomou / pulou) e a tabela de sono no período inteiro, sem cortar em 7 noites. Fase 0.3 (feedback) entregou o resto do item:

  | Ponto | Estado |
  |-------|--------|
  | Pauta e fechamento (`therapistNotes` / `eveningReflection`) | ✅ WhatsApp e PDF levam quando `hideIntimateNotes` está desligado |
  | Tarefas do período | ✅ bloco "Lista de tarefas" (feita / aberta) em WhatsApp e PDF, via `taskExportLines` |
  | Humor / SoM | ✅ `MoodEntry` e/ou labels SoM do snapshot contam no estado emocional; legível com uma fonte só |
  | Card visual | ✅ nunca leva pauta nem fechamento, mesmo com o toggle desligado |
  | Adesão real de dose, sono do período inteiro | ⏳ aberto
- [x] E7 Export JSON das chaves locais (`noa_*`) em Configurações; CSV clínico ainda fora
- [x] E8 Toggle para ocultar notas íntimas na exportação (PRD §4.6)

  | Ponto | Estado |
  |-------|--------|
  | Onde | `ClinicalFolderScreen` (4ª aba), `SwitchListTile` "Ocultar notas íntimas" com `Semantics` e ajuda |
  | Padrão | `hideIntimateNotes` ligado (seguro); estado local da tela, sem chave de prefs nova |
  | Desligado | WhatsApp, PDF e `TherapistReportScreen` incluem pauta e fechamento; a seção "Para a terapia" mostra o período na pasta |
  | Ligado | pauta e fechamento ficam fora de todos os formatos |
  | Card | sempre sem notas íntimas, independente do toggle |
- [ ] E9 Data da próxima consulta no perfil do profissional

### Epic F — Des-Trava

- [x] F1 Fluxo 3 passos + timer
- [ ] F2 Variantes por contexto (paralisia vs scattered vs overload)
- [ ] F3 Histórico “quantas vezes usei esta semana”
- [ ] F4 Integração opcional: criar micro-hábito a partir do passo

### Epic G — Qualidade & release

- [ ] G1 Cobertura de testes unitários (domínio + engine)
- [ ] G2 Testes de widget por feature crítica
- [ ] G3 CI (analyze + test + gen-l10n check)
- [ ] G4 Privacy Nutrition Labels / política de privacidade
- [ ] G5 Screenshots App Store / Play
- [ ] G6 Primeiro TestFlight (primeiro teste prático, depois de B7 e de G4)

### Epic H — Calendário e Raio-X (agora)

- [x] H1 Calendário do app (mês) com badges de rotina/check-in + DayDigest (semana ainda fora)
- [ ] H2 Ponte com o calendário do celular, nos dois sentidos
- [ ] H3 Timeline de 24h com EventKit / compromissos nativos
- [ ] H4 Anatomia do dia no hub clínico

### Epic I — Prótese do dia (agora)

- [ ] I1 Curva de energia e foco
- [ ] I2 Checklist de saída
- [x] I3 Perfil local: `FirstLaunchOnboarding` + `ProfileScreen` (idade, peso, altura, sexo biológico, tom de voz, importar do app de saúde); sem tipo sanguíneo, sem aba própria no shell
- [x] I4 Central de tarefas na Ficha (Hoje / Recorrentes / Pontuais); Dia só checklist. Modo foco e fatiador continuam de fora. Fase 0.7: estilos de alerta honestos na UI (`alarm` = “Em destaque”); horário silencioso só de tarefas; permissão negada com CTA `SystemSettings`; app fechado = entrega agendada no SO, sem prometer Foco/DND
- [ ] I5 Gasto de hiperfoco: botão e valor, sem gráfico
- [ ] I6 Aviso de inércia: poucos passos abrem o Des-Trava
- [x] I7 Hub de configurações no Perfil (tema, idioma/SO, acessos, export local)
- [x] I8 Início = ficha viva + Pasta clínica + contatos múltiplos (Stitch `Design/Stitch/new/`). Fase 0.8: 4 abas; Tarefas/Meus dias na pilha da Início; Pasta via `openClinicalFolderScreen`; pop-to-root na troca de aba; sem `go_router`

### Epic J — Saúde que saiu do futuro (planejado)

- [ ] J1 Ciclo menstrual, opt-in
- [ ] J2 Cafeína e álcool no check-in
- [ ] J3 Picos de FC depois da dose
- [ ] J4 Medidor de bateria mental na tela; o cálculo espera a seção Pesquisar mais

---

## 12. Roadmap

### Fase 0 — MVP interno (atual) ✅

App usável localmente no iPhone do usuário-alvo: check-in, rotina, meds, sono, insights, export. O protótipo visual desta fase está em `Design/` e o recorte de requisitos em [PRD.md](PRD.md).

**Critério de saída:** uso diário real por ≥1 semana sem crash bloqueante.

### Fase Feedback (subfase da Fase 0)

Correções e melhorias da análise de uso real (confiança do dia, export clínico, check-in, navegação), com canal de feedback primeiro. Plano detalhado por etapas **0.1–0.8:** [FASE_0_FEEDBACK.md](FASE_0_FEEDBACK.md). Princípio: ferramentas de funcionamento pessoal locais antes de trabalho novo de SDK.

**Status (2026-10-08):** 0.1–0.8 **feitas**. Em seguida: ~1 semana de uso diário real coletando feedback (Sobre → Mandar feedback). Só depois disso decide-se se abre uma **Feedback 2**, se vai direto à **Fase 1**, ou um híbrido (hotfixes + Fase 1). Detalhe do gate: [FASE_0_FEEDBACK.md](FASE_0_FEEDBACK.md) § “Semana de uso”.

### Primeiro teste — TestFlight

O primeiro uso prático é um TestFlight. O build sobe depois do check-in espelhar o State of Mind sozinho, do material exportado ficar mais completo do que o de hoje, do texto de privacidade dizer o que o app lê e grava, e do lembrete de dose funcionar com o app fechado.

| Item | Prioridade | Epic |
|------|------------|------|
| Check-in grava State of Mind sozinho | P0 | B7 |
| Export mais completo (PDF, WhatsApp e card) | P0 | E6, E8 |
| Texto de privacidade alinhado ao que o app lê e grava | P0 | G4 |
| Escrita consistente do evento de dose | P0 | C7 |
| Vincular medicamento local ao conceito da Apple | P0 | C8 |
| Upload do TestFlight | P0 | G6 |
| Notificações recorrentes de dose | P0 | C5–C6 |

O export cobre sono, humor, recuperação, insights e os salvamentos da rotina (hora, Foco do dia, água, hábitos, medicação do toggle, reflexão e notas). Com "Ocultar notas íntimas", reflexão e pauta ficam de fora. A medicação de dose (tomou ou pulou) ainda entra só como a contagem do check-in, e a tabela de sono continua cortando em 7 noites.

C7 e C8 entram nesse build porque a ponte e os campos já existem. Subir o teste com a dose pela metade é o tipo de furo que aparece no primeiro uso. O lembrete também entra: um aviso por horário, Tomar e Adiar, inclusive com o app fechado, e o toque no corpo abre Remédios.

**No mesmo período, sem travar o upload:** histórico semanal do Des-Trava (F3), micro-hábito criado a partir de um passo (F4), teste só do que esse build toca (G1, G2) e CI quando o upload for repetível (G3).

**Depois do primeiro uso real:** gráfico de adesão em vários dias (C9), período e confiança dos insights (D9), exportação CSV/JSON (E7) e screenshots de loja (G5), quando as telas novas existirem.

### Fase 1 — Polish clínico & meds

**Objetivo:** adesão e export “prontos para sessão”. Continua em aberto. Não bloqueia a prótese da fase 1.5.

| Item | Prioridade | Epic |
|------|------------|------|
| Perfil paciente (nome) | P0 | B6, E4 |
| Período no export | P1 | E5 |
| Próxima consulta no perfil do profissional | P2 | E9 |
| Aviso de rebote + mensagem de renovação | P2 | C10–C11 |
| Onboarding Health + permissões | P1 | D8 |
| Unificar medicação tomada | P2 | B5 |

### Fase 1.5 — Prótese executiva (agora)

**Objetivo:** calendário do app ligado ao calendário do celular, timeline do dia e as ferramentas que saíram do futuro.

| Item | Prioridade | Epic |
|------|------------|------|
| Calendário do app (mês e semana) | P0 | H1, CAL02 |
| Ponte com o calendário do celular, nos dois sentidos | P0 | H2, CAL01 |
| Timeline de 24h | P0 | H3, CAL03 |
| Anatomia do dia no hub clínico | P1 | H4, CAL04 |
| Checklist de saída | P0 | I2, VIS02 |
| Curva de energia e foco | P0 | I1, VIS01 |
| Perfil local opcional | P0 | I3, P09 |
| Configurações no Perfil | P0 | I7, H15, P10 |
| Central de tarefas | P0 | I4, TSK01–TSK06 |
| Gasto de hiperfoco: botão e valor | P1 | I5, EXP01 |
| Aviso de inércia (Des-Trava) | P0 | I6 |
| Ciclo menstrual, opt-in | P1 | J1 |
| Cafeína e álcool no check-in | P1 | J2 |
| Picos de FC depois da dose | P1 | J3 |
| Medidor de bateria mental na tela | P1 | J4 |

O cálculo da bateria mental e o aviso de crash não entram nesta tabela. Estão em [Pesquisar mais](#pesquisar-mais). Cooldown, contador de dinheiro salvo e gráficos de hiperfoco continuam no §13. Tom de voz (P08 / FUT-76) também: nesta rodada não teve decisão.

**Meta:** companion diário com calendário, timeline e tarefas.

### Fase 2 — Ponte de saúde e resiliência

A função já existe nas duas plataformas (§9.0). Esta fase é a sincronia onde os dois SDKs têm o tipo, mais cache e notificações no Android. Não é “a tela espera o SDK”.

| Item | Prioridade |
|------|------------|
| Ponte mútua onde os dois SDKs têm o tipo (sono, recuperação, água, mindfulness) | P0 |
| Cache Health offline | P1 |
| Notificações Android estáveis | P0 |
| Testes engine + repos | P1 |

**Meta:** v1.2 dual-platform.

### Fase 3 — Inteligência & personalização

| Item | Prioridade |
|------|------------|
| Des-Trava contextual | P1 |
| Mais regras de correlação + transparência (“com base em N dias”) | P1 |
| Lembretes suaves de check-in (não spam) | P2 |

Crash predictor e bateria biológica foram para Pesquisar mais. O alerta sonoro ficou no backlog, sem pressa. A inércia foi para a fase 1.5. Os gráficos de adesão ficam para depois do primeiro uso.

**Meta:** v1.3 “padrões confiáveis”.

### Fase 4 — Conta opcional & sync (futuro)

Ver §13. Só após validar retenção local.

```
TestFlight (B7 + E6 + G4 + C7 + C8)
        │
        ▼
Fase 1 (meds+export) ──► Fase 1.5 (calendário, timeline, tarefas)
        │
        ▼
Fase 2 (ponte de saúde) ──► Fase 3 (insights) ──► Fase 4 (conta)
```

### Pesquisar mais

Ideias que ficam fora da implementação até a pergunta ter resposta. Não são backlog solto e não são fase.

| Tema | O que já existe | O que falta decidir |
|------|-----------------|---------------------|
| Crash predictor (FUT-21) | Horário da dose, duração da janela e a barra de eficácia | Se o aviso é só o fim da duração cadastrada, cerca de 1h antes, ou se espera um modelo. Sem inventar farmacocinética. |
| Bateria biológica (FUT-36) | REM da noite e HRV do dia, já nos cards | Pré-implementação: um bloco que junta esses dois números, sem nota única e sem recalibrar a lista de tarefas. Estudar como cruzar SDNN e RMSSD sem métrica falsa, qual limiar vira dia curto, e se o resultado muda a carga do dia ou só informa. O medidor VIS03 / J4 usa este estudo. |

---

## 13. Backlog / features futuras

> Área reservada para ideias **não comprometidas**. Mova para o roadmap (§12) só com prioridade e epic.

### 13.1 Produto / UX

| ID | Ideia | Notas |
|----|-------|-------|
| FUT-01 | Onboarding narrativo opcional | Boas-vindas, valores Lumen e consentimento local (100% pulável) |
| FUT-03 | Widgets iOS (check-in / próxima dose) | |
| FUT-04 | Shortcuts / App Intents “check-in” | |
| FUT-05 | Modo “dia difícil” (UI reduzida) | menos estímulos |
| FUT-06 | Rotina com templates (dias úteis / fds) | |
| FUT-07 | Reflexão noturna com prompt guiado | |
| FUT-08 | Streaks **não punitivos** (opcional, off by default) | |
| FUT-09 | Dark mode automático por horário de sono | |
| FUT-10 | Acessibilidade: Dynamic Type + Reduce Motion | |
| FUT-11 | Nota de voz no check-in e nas notas de terapia | PRD pede; hoje só texto |
| FUT-12 | Bloqueio biométrico (Face ID / Touch ID) | fora do MVP local |

### 13.2 Medicação

| ID | Ideia | Notas |
|----|-------|-------|
| FUT-20 | Protocolo multi-dose complexo | PRN, efervescente |
| FUT-22 | Interação med × sono no insight | |
| FUT-23 | Inventário / foto da caixa | |
| FUT-24 | Compartilhar plano de meds com prescritor (PDF dedicado) | |

### 13.3 Saúde & dados

| ID | Ideia | Notas |
|----|-------|-------|
| FUT-32 | Localização aproximada / clima (opt-in) | Correlacionar luz solar/pressão com humor |
| FUT-33 | Import CSV histórico | |
| FUT-34 | Export GDPR / exclusão total com 1 toque | |
| FUT-35 | Watch complication / app watchOS | Ações rápidas de check-in / tomar dose |
| FUT-37 | Alerta proativo de sobrecarga sensorial acústica | Adiado, sem prioridade. O card de ambiente continua |

### 13.4 Clínico / B2B

| ID | Ideia | Notas |
|----|-------|-------|
| FUT-40 | Portal web somente-leitura para terapeuta | auth + consent |
| FUT-41 | Código de vínculo paciente↔clínica | |
| FUT-42 | Templates de relatório por especialidade | psiq / TCC |
| FUT-43 | Escalas validadas (ASRS, PHQ-9) opcionais | não diagnóstico |

### 13.5 Plataforma

| ID | Ideia | Notas |
|----|-------|-------|
| FUT-50 | Conta Apple/Google opcional + backup iCloud/Drive | |
| FUT-51 | Sync multi-device E2E | |
| FUT-52 | go_router + deep links | |
| FUT-53 | Feature flags remotas | |
| FUT-54 | Crashlytics / analytics privacy-first | |
| FUT-55 | Monetização: freemium clínico / família | TBD ética |
| FUT-56 | Criptografia em repouso e backup E2E | o PRD cita AES-256 e nuvem; o MVP segue SharedPreferences local |
| ~~FUT-57~~ | ~~Migrar wrappers glass para `liquid_glass_renderer`~~ | ✅ Feito — `liquid_glass_renderer` + Impeller/FakeGlass |
| ~~FUT-58~~ | ~~Migrar para `CupertinoApp`~~ | ✅ Feito — `CupertinoApp` + Material invisível no builder |

### 13.6 Des-Trava & bem-estar

| ID | Ideia | Notas |
|----|-------|-------|
| FUT-60 | Biblioteca de protocolos (body double, body scan, 5-4-3-2-1) | |
| FUT-61 | Áudio guiado curto (local) | |
| FUT-62 | Modo “body doubling” timer com check silencioso | |
| FUT-63 | Integração Focus modes iOS | |

### 13.7 Prótese Executiva, Calendário & Vida Real TDAH

| ID | Ideia | Notas |
|----|-------|-------|
| FUT-72 | Gestor completo de gastos de hiperfoco | O botão com valor está na fase 1.5 (I5). Aqui ficam cooldown de 48h, aviso depois do cooldown, contador de dinheiro salvo e gráficos |
| FUT-76 | Seletor de Perfis de Tom de Voz Humanizado | Sem fase nesta rodada. Despojado, casual, não-formal, formal, feminino, meninas, meninos |

### 13.8 Caixa livre (rascunhos)

_Use esta lista em brainstorms. Não priorizar aqui._

- [ ] …
- [ ] …
- [ ] …

---

## 14. Critérios de aceite e qualidade

### Aceite por feature (checklist genérico)

1. Funciona offline (exceto dados Health).
2. Strings em `app_pt.arb` + doloc rodado se novas chaves.
3. Light + dark sem overflow / contraste ilegível.
4. Empty / loading / error states cobertos.
5. Não bloqueia UX se Health negar permissão.
6. Sem emojis decorativos novos (preferir `AppIcons`); exceção legado efficacy ⚡ — migrar quando possível.

### Definition of Done (release)

- [ ] `flutter analyze` limpo
- [ ] Testes críticos passando
- [ ] Privacy copy alinhada ao que o app realmente lê/escreve
- [ ] README + este GDD atualizados se mudou escopo

### Métricas de produto (sugeridas — ainda não instrumentadas)

| Métrica | Meta inicial |
|---------|--------------|
| Check-ins / semana | ≥ 5 |
| Tempo médio de check-in | < 12 s |
| Sessões de Des-Trava que completam os 60 s | > 65% |
| Retenção no dia 30 | > 45% |
| Export usado antes de consulta | ≥ 1× / 2 semanas |
| Crash-free sessions | ≥ 99% |

---

## 15. Glossário

IDs de feature (`H03`, `M04`), epics (`H3`, `B7`), prioridades (`P0`) e siglas técnicas (HRV, SoM, i18n…) estão detalhados em [§6 — Como ler os IDs e as siglas](#como-ler-os-ids-e-as-siglas).

| Termo | Significado |
|-------|-------------|
| Check-in | Registro rápido de humor/foco/energia |
| Des-Trava | Assistente anti-paralisia (Unstuck) |
| Janela de eficácia | Período estimado pós-dose (pico → crash) |
| Insight | Correlação textual acionável |
| Mirror | Escrita de dados locais no Apple Health |
| State of Mind (SoM) | Modelo emocional estilo Apple Health |
| Foco do dia | Nome de UI da tarefa principal do dia (fixada no checklist da aba Dia); grava o título em `mainFocusAnchor`. Escrito sempre com F maiúsculo para não confundir com o foco do Check-in |
| Âncora | Sinônimo técnico de Foco do dia (campo `mainFocusAnchor`, ícone `AppIcons.anchor`, chaves arb `*Anchor*`). Não aparece como nome na UI. Não confundir com a âncora do HealthKit (`HKAnchoredObjectQuery`) |
| Check-in | Formulário único de humor/foco/energia (`CheckInForm`); Home CTA a abolir |
| Hub clínico | Tela de export para terapeuta |
| Raio-X do dia | Timeline / anatomia do dia no calendário e no hub |
| Soft Liquid Glass | Linguagem visual anterior (histórico Stitch); app atual = Apple Liquid Glass |
| Apple Liquid Glass | Design system atual (`liquid_glass_renderer` + Impeller + tokens Lumen; `FakeGlass` no fallback) |

---

## 16. Como atualizar este GDD

1. **Nova feature shipped** → marque ✅ na §6 e `[x]` na §11; se era FUT-*, remova do §13.
2. **Mudança de escopo** → atualize §1 e §12; bump versão do doc no topo.
3. **Nova ideia** → só §13 (caixa livre ou tabela); não misture com “atual”. Dúvida de método vai para [Pesquisar mais](#pesquisar-mais), não para a fase.
4. **Task em andamento** → pode linkar issue/PR ao lado do ID (`C5`).
5. Mantenha este arquivo como **fonte de verdade de produto e de implementação**; o [PRD](PRD.md) guarda o recorte do protótipo. Se os dois divergirem na stack ou no que já existe no código, vale este GDD.

---

## Apêndice A — Mapa rápido tela → arquivo

| Tela / sheet | Path |
|--------------|------|
| Início (ficha viva) | `lib/features/home/presentation/home_ficha_screen.dart` |
| Check-in | `lib/features/routine_mood/presentation/check_in_form.dart` |
| Dia / Rotina | `lib/features/routine_mood/presentation/daily_routine_screen.dart` |
| Meus dias | `lib/features/calendar/presentation/routine_calendar_screen.dart` |
| Medicações | `lib/features/medications/presentation/medications_screen.dart` |
| Des-Trava | `lib/features/unstuck_assistant/presentation/unstuck_sheet.dart` |
| Pasta clínica | `lib/features/therapist_export/presentation/clinical_folder_screen.dart` |
| Contato profissional (sheet) | `lib/features/therapist_export/presentation/care_contact_editor_sheet.dart` |
| DayDigest | `lib/features/calendar/domain/day_digest.dart` |
| Central de Tarefas | `lib/features/tasks/presentation/tasks_hub_screen.dart` |
| Perfil completo (feed + biométrico) | `lib/features/profile/presentation/profile_screen.dart` |
| Configurações | `lib/features/settings/presentation/settings_screen.dart` |
| Onboarding 1ª abertura | `lib/features/onboarding/presentation/first_launch_onboarding.dart` |

## Apêndice A2 — Referência visual

| Tela | Protótipo |
|------|-----------|
| Início (ficha viva) | `Design/Stitch/new/in_cio_hub_pessoal_ficha_viva/` |
| Dia | `Design/Stitch/new/dia_execu_o_rotina/` |
| Remédios | `Design/Stitch/new/rem_dios_posologia_alarmes/` |
| Pasta clínica | `Design/Stitch/new/pasta_cl_nica_exporta_o_consulta/` |
| Des-Trava | `Design/Stitch/new/des_trava_resgate_anti_paralisia/` |
| Tokens Soft Liquid Glass | `Design/Stitch/new/lumen_soft_liquid_glass/DESIGN.md` |
| Legado (frames antigos) | `Design/Stitch/lumen_*` |
| Requisitos | `docs/PRD.md` |
| PDF | `lib/features/therapist_export/service/therapist_pdf_generator.dart` (+ `pdf_report_style`, `therapist_pdf_share`, fontes `assets/fonts/NotoSans-*.ttf`) |
| Consent Health | `lib/features/health_sync/presentation/health_sync_consent_sheet.dart` |
| Bridge iOS | `ios/Runner/HealthKitBridge.swift` |

## Apêndice B — Comandos úteis

```bash
flutter pub get
flutter run
flutter gen-l10n
export API_TOKEN=… && dart run tool/doloc.dart && flutter gen-l10n
flutter test
flutter analyze
```

---

*Fim do GDD v1.11 — Lumen*
