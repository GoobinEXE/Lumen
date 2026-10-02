# Lumen — Game Design Document (GDD)

> Documento vivo de produto e desenvolvimento.  
> **App:** Lumen (package `noa`)  
> **Versão do doc:** 1.5 · **Data:** 2026-10-01  
> **Stack:** Flutter · Riverpod · SharedPreferences · Apple Health / Health Connect  
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
| **Acompanhamento Clínico** | **Check-in micro** | Humor + foco + energia em ~10s |
| | **Rotina do dia** | Âncora, tarefas, água, State of Mind |
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
| Metáfora visual | Soft Liquid Glass — superfícies leves, CTAs vivos, fundo creme/preto suave |
| Cores-chave | Teal `#1FAF8A` (primária), lavanda `#8B7BC8` (acento), coral `#FF8A5C` (Des-Trava) |
| Ícone | Arte em `lumen.ai`. iOS é o `ios/Runner/Lumen.icon` do Icon Composer, com vidro e luz, sem raster chapado por cima. Android usa essa arte no adaptive icon: fundo `#F6F1DE` no claro e `#16161A` no escuro; o L fica `#3A3A40` no claro e `#F4F1EC` no escuro |
| Locales | `pt` (fonte), `en`, `es`, `ja` |
| Versão do app | [SemVer](https://semver.org/lang/pt-BR/) em `pubspec.yaml`: `MAJOR.MINOR.PATCH`. Atual: `0.1.0` (série 0, antes do lançamento). `1.0.0` é o primeiro lançamento público. O `+N` do Flutter é só o build da loja e sobe a cada envio |

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

Persona de produto do PRD, também usada como nome fixo na UI hoje (`H14`):

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

- Mesma UX local; Health Connect parcial; bridge State of Mind / ambiente = no-op ou vazio.

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
│   ├── home/                 # HomeScreen (hub)
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
| UI | Material 3 + glass surfaces; navegação `MaterialPageRoute` |

### Dependências relevantes

`flutter_riverpod`, `health`, `fl_chart`, `pdf` + `printing`, `share_plus`, `shared_preferences`, `uuid`, `url_launcher`, `flutter_local_notifications`, `intl` / `flutter_localizations`.

---

## 6. Mapa de features atuais

Legenda de status: ✅ feito · 🟡 parcial ou nesta fase · ❌ ausente · 🔮 futuro (ver §13) · 🔎 pesquisar mais

### 6.1 Home (hub)

| ID | Feature | Status | Arquivo-chave |
|----|---------|--------|---------------|
| H01 | Saudação + subtítulo “sem pressão” | ✅ | `home_screen.dart` |
| H02 | Toggle tema claro/escuro/sistema | ✅ | `theme_mode_provider.dart` |
| H03 | Seletor de idioma | ✅ | `language_selector_dialog.dart` |
| H04 | CTA Check-in rápido | ✅ | → `QuickCheckinModal` |
| H05 | CTA Des-Trava | ✅ | → `UnstuckSheet` |
| H06 | Atalho Rotina do dia | ✅ | → `DailyRoutineScreen` |
| H07 | Card Medicações (resumo do dia) | ✅ | logs pending/taken |
| H08 | Card Sono | ✅ | `SleepDashboardCard` na home, com o botão de sincronizar |
| H09 | Card Recuperação | ✅ | `RecoveryDashboardCard` na home; exercício e luz em minutos |
| H10 | Hub terapeuta | ✅ | `TherapistExportHubScreen` |
| H11 | Insights “padrões do cérebro” | ✅ | `correlationInsightsProvider` |
| H12 | Lista entradas recentes (mood) | ✅ | últimos 4 |
| H13 | Pull-to-refresh (sono + recuperação + mood) | ✅ | |
| H14 | Perfil / nome dinâmico | 🟡 | nome fixo “Marcelo” |

### 6.2 Check-in rápido (mood)

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
| C09 | Espelho automático no Apple SoM | 🟡 | prioridade: o check-in grava o State of Mind sozinho; hoje só a rotina espelha |

### 6.3 Rotina do dia

| ID | Feature | Status | Notas |
|----|---------|--------|-------|
| R01 | Âncora / foco principal do dia | ✅ | texto livre |
| R02 | Editor State of Mind | ✅ | valence + labels + associations |
| R03 | Tarefas (lista única) | ✅ | a seção da rotina junta o do dia, o pontual e a to-do; o nome na tela é Tarefas |
| R04 | Água (copos) | ✅ | |
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
| M02 | Logs do dia (gerar a partir da agenda) | ✅ | cria a dose que falta e tira o log do remédio apagado |
| M03 | Marcar tomado / pular / snooze | ✅ | |
| M04 | Janela de eficácia (pico / crash) | ✅ | pico fica dentro da janela, inclusive em 4 h |
| M05 | Alerta de refil | ✅ | threshold |
| M06 | Importar meds do Apple Health | ✅ | bridge `readMedications` |
| M07 | Sync dose events Apple ↔ Lumen | 🟡 | read + write na bridge; UX parcial |
| M08 | Notificações locais | ✅ | um aviso por horário na semana; Tomar e Adiar, inclusive com o app fechado; o toque abre Remédios |
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
| HS05 | Health Connect Android completo | 🟡 | contrato existe; cobertura parcial |
| HS06 | Onboarding sync no primeiro uso | 🟡 | sheet existe; trigger pontual |

### 6.8 Hub terapeuta / export

| ID | Feature | Status | Notas |
|----|---------|--------|-------|
| T01 | Hub com preview card semanal | ✅ | |
| T02 | Telefone do terapeuta (prefs) | ✅ | |
| T03 | Enviar resumo WhatsApp | ✅ | fallback clipboard |
| T04 | Compartilhar card imagem | ✅ | `ShareCardExporter` |
| T05 | Relatório PDF (preview + print/share) | ✅ | `TherapistPdfGenerator` |
| T06 | Incluir sono, mood, recovery, insights | ✅ | PDF, WhatsApp e card. Rotina e logs de dose ainda ficam de fora; entram no primeiro teste |
| T07 | Nome do paciente configurável | 🟡 | hardcoded “Marcelo P.” |
| T08 | Período custom (7/14/30) | 🟡 | PDF usa `periodDays`; UI limitada |

### 6.9 Des-Trava (Unstuck)

| ID | Feature | Status | Notas |
|----|---------|--------|-------|
| U01 | Bottom sheet glass | ✅ | |
| U02 | 3 micro-passos sequenciais | ✅ | |
| U03 | Timer 60s + orb animada | ✅ | concluir só quando a contagem chega a zero |
| U04 | Haptic + snack de conclusão | ✅ | |
| U05 | Passos personalizáveis / contexto mood | 🔮 | |

### 6.10 Plataforma / infra

| ID | Feature | Status | Notas |
|----|---------|--------|-------|
| P01 | i18n pt/en/es/ja + doloc | ✅ | ver `docs/i18n.md` |
| P02 | Tema claro/escuro/sistema | ✅ | |
| P03 | Design system (cores, spacing, glass) | ✅ | |
| P04 | Skeletons / FadeSwap | ✅ | |
| P05 | Widget tests básicos | 🟡 | `test/widget_test.dart` |
| P06 | Auth / cloud backup | ❌ | |
| P07 | Analytics de produto | ❌ | |
| P08 | Perfis de tom de voz humanizados | 🔮 | sem fase nesta rodada; continua só no backlog |
| P09 | Onboarding & Perfil Local (opcional) | 🟡 | entra agora: idade, peso, altura, importação do app de saúde; sem login |

### 6.11 Calendário & Raio-X do Dia (Timeline Diária)

| ID | Feature | Status | Notas |
|----|---------|--------|-------|
| CAL01 | Ponte com o calendário do celular | 🟡 | cada salvamento da rotina cria um evento (EventKit / CalendarContract). A agenda inteira do aparelho não entra no app |
| CAL02 | Visão de Calendário (Mês / Semana) | 🟡 | mês no app marca o dia com rotina salva e abre os horários. Semana, remédio, humor, des-trava e gasto continuam de fora |
| CAL03 | Timeline do Raio-X do Dia (24h) | 🟡 | linha do tempo de hoje com a hora de cada salvamento da rotina. Sono, doses, compromissos e gastos continuam de fora |
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
| TSK01 | Pacote único integrado de tarefas | ✅ | a lista única está na rotina, com o nome Tarefas. Sem tela separada |
| TSK02 | Alarme Persistente (Nagging de 5 min) | 🟡 | Toca no horário; repete a cada 5 min até marcar concluído ou adiar |
| TSK03 | Recorrência flexível | 🟡 | Diária, semanal, quinzenal ou data única |
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
| mainFocusAnchor | String | âncora |
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

### TaskItem (Central de Tarefas — Em Maturação)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | String (uuid) | |
| title | String | Descrição da tarefa |
| scheduledAt | DateTime? | Horário definido para alarme |
| recurrence | TaskRecurrence | `none`, `daily`, `weekly`, `biweekly` |
| naggingIntervalMinutes | int | Default 5 minutos para repetir até marcar feito |
| completedAt | DateTime? | Data/hora de conclusão |
| snoozedUntil | DateTime? | Adiamento temporário consciente |
| subSteps | List\<String\> | Micro-passos de até 2 min |

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

### Persistência (chaves conceituais)

Tudo via SharedPreferences + JSON (`noa_user_profile_v1`, `noa_hyperfocus_expenses_v1`, `noa_tasks_v1`, `noa_voice_tone_profile_v1`, etc.). Preferências extras: sync Health, sync Calendário nativo, telefone terapeuta, tema, locale, micro-hábitos. Armazenamento 100% local no aparelho, sem tráfego de dados para nuvem do Lumen.

---

## 8. Fluxos de usuário

### F1 — Check-in matinal (caminho feliz)

```
Home → Check-in → valência/foco/energia/[labels] → Salvar
  → MoodRepository
  → Home atualiza “entradas recentes” + insights (se dados suficientes)
```

### F2 — Rotina com mirror Health

```
Home → Rotina → editar âncora / SoM / hábitos / água → Salvar
  → RoutineRepository
  → RoutineHealthMirror (se HS enabled)
      → writeWater / writeMindfulness / writeStateOfMind
```

### F3 — Tomar medicação

```
Home → Medicações → card dose pendente → Tomar
  → log.takenAt = now; estoque--; EfficacyWindowBar
  → (opcional) writeDoseEvent Apple
```

### F4 — Paralisia executiva

```
Home → Des-Trava → passo 1 → timer 60s → passo 2 → passo 3 → snack
```

### F5 — Preparar sessão clínica

```
Home → Hub terapeuta → (config telefone) → WhatsApp | Share card | PDF
```

### F6 — Conectar Apple Health

```
Consent sheet → permissions plugin + bridge → syncEnabled=true
  → invalidate sleep/recovery providers
```

### F7 — Onboarding de Perfil Local & Importação Health (Opcional)

```
Primeiro uso / Ajustes → Perfil Local (100% opcional, sem login)
  → Perguntas pertinentes: nome/apelido, idade, peso, altura, estilo de rotina
  → Botão [Importar do Apple Health / Google Health Connect] (preenche idade/peso/altura em 1 toque)
  → Botão [Pular / Deixar pra depois] (livre, sem travar o app)
  → Grava localmente em SharedPreferences (sem envio para nuvem)
```

### F8 — Navegar pelo Raio-X do Dia no Calendário

```
Home → Card Calendário → Selecionar data (passada ou presente)
  → Timeline diária unificada de 24h
  → Exibe: despertar, doses, compromissos nativos (EventKit), tarefas, des-trava e impulsos
  → Terapeuta / usuário identificam padrões e gatilhos de sobrecarga com precisão
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

| Dado | Direção | Via |
|------|---------|-----|
| Sono (estágios) | ← | plugin `health` |
| HRV, RHR, passos, exercício | ← | plugin `health` |
| Time in daylight, áudio | ← | `HealthKitBridge` |
| State of Mind | ↔ | bridge |
| Medicamentos / dose events | ↔ | bridge |
| Água / mindfulness | → | plugin / serviço |

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

`flutter_local_notifications` — canal `medication_reminders`. Cada horário ativo vira um aviso semanal no fuso do aparelho. Tomar grava a dose, Adiar empurra 15 minutos, e o toque no corpo abre Remédios. As três saídas valem com o app fechado.

### 9.7 Tradução

doloc.io a partir de `app_pt.arb` → en/es/ja. Ver [i18n.md](./i18n.md).

---

## 10. i18n, tema e design system

### i18n

- Fonte: `lib/l10n/app_pt.arb`
- Acesso: `AppLocalizations.of(context)` ou `appLocalizationsProvider`
- Labels SoM: mapas por `languageCode` (não ARB)

### Tema

- `AppTheme.lightTheme` / `darkTheme`
- Tokens: `AppColors`, `AppSpacing`, `AppRadii`, `GlassSurface` / `GlassSheet`
- Responsive: `responsive.dart` (`kMinBodySecondary`, etc.)

### Navegação atual

Sem router nomeado: `Navigator.push` + modals. Home = root.

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

Use esta lista como board. IDs batem com features da §6.

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
- [ ] B5 Unificar flag “med tomada” (check-in × rotina × MedicationLog)
- [ ] B6 Nome do usuário dinâmico (remover hardcode)
- [ ] B7 Check-in grava State of Mind sozinho (prioridade do primeiro teste)

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
- [ ] D6 Implementação sólida Health Connect (Android)
- [ ] D7 Cache local de snapshots Health (offline resiliente)
- [ ] D8 Onboarding guiado na 1ª abertura
- [ ] D9 Insights com período configurável e confiança estatística

### Epic E — Export clínico

- [x] E1 Hub + WhatsApp formatter
- [x] E2 Share card PNG
- [x] E3 PDF generator rico
- [ ] E4 Perfil paciente (nome, idade, diagnóstico opcional)
- [ ] E5 Seletor de período 7/14/30 na UI
- [ ] E6 Export mais completo no primeiro teste: PDF, WhatsApp e card já levam os salvamentos da rotina (hora, âncora, água, hábitos, medicação, reflexão e notas; o toggle esconde reflexão e pauta). Ainda falta a adesão real de dose (tomou / pulou) e a tabela de sono no período inteiro, sem cortar em 7 noites.
- [ ] E7 Export CSV / JSON para o próprio usuário
- [ ] E8 Toggle para ocultar notas íntimas na exportação (PRD §4.6)
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

- [ ] H1 Calendário do app (mês e semana) com badges
- [ ] H2 Ponte com o calendário do celular, nos dois sentidos
- [ ] H3 Timeline de 24h
- [ ] H4 Anatomia do dia no hub clínico

### Epic I — Prótese do dia (agora)

- [ ] I1 Curva de energia e foco
- [ ] I2 Checklist de saída
- [ ] I3 Perfil local (idade, peso, altura, importar do app de saúde)
- [ ] I4 Central de tarefas: a lista única já está na rotina, com o nome Tarefas. Recorrência, alarme de 5 min, modo foco e fatiador continuam de fora
- [ ] I5 Gasto de hiperfoco: botão e valor, sem gráfico
- [ ] I6 Aviso de inércia: poucos passos abrem o Des-Trava

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

O export cobre sono, humor, recuperação, insights e os salvamentos da rotina (hora, âncora, água, hábitos, medicação do toggle, reflexão e notas). Com "Ocultar notas íntimas", reflexão e pauta ficam de fora. A medicação de dose (tomou ou pulou) ainda entra só como a contagem do check-in, e a tabela de sono continua cortando em 7 noites.

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

| Termo | Significado |
|-------|-------------|
| Check-in | Registro rápido de humor/foco/energia |
| Des-Trava | Assistente anti-paralisia (Unstuck) |
| Janela de eficácia | Período estimado pós-dose (pico → crash) |
| Insight | Correlação textual acionável |
| Mirror | Escrita de dados locais no Apple Health |
| State of Mind (SoM) | Modelo emocional estilo Apple Health |
| Âncora | Único foco principal do dia |
| Hub clínico | Tela de export para terapeuta |

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
| Home | `lib/features/home/presentation/home_screen.dart` |
| Check-in | `lib/features/routine_mood/presentation/quick_checkin_modal.dart` |
| Rotina | `lib/features/routine_mood/presentation/daily_routine_screen.dart` |
| Medicações | `lib/features/medications/presentation/medications_screen.dart` |
| Des-Trava | `lib/features/unstuck_assistant/presentation/unstuck_sheet.dart` |
| Hub terapeuta | `lib/features/therapist_export/presentation/therapist_export_hub_screen.dart` |

## Apêndice A2 — Referência visual

| Tela | Protótipo |
|------|-----------|
| Home | `Design/lumen_in_cio_home_hub/code.html` |
| Check-in | `Design/lumen_check_in_r_pido/code.html` |
| Rotina | `Design/lumen_rotina_foco/code.html` |
| Medicações | `Design/lumen_medica_es_janela/code.html` |
| Des-Trava | `Design/lumen_des_trava_anti_paralisia/code.html` |
| Hub terapeuta | `Design/lumen_hub_cl_nico/code.html` |
| Marca | `Design/lumen_minimalist_mark/code.html` |
| Tokens Stitch | `Design/soft_liquid_glass/DESIGN.md` |
| Requisitos | `docs/PRD.md` |
| PDF | `lib/features/therapist_export/service/therapist_pdf_generator.dart` |
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

*Fim do GDD v1.1 — Lumen*
