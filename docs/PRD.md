# Product Requirements Document (PRD) — Lumen

**Versão:** 1.0.0  
**Status:** Referência de produto, importada do protótipo Stitch em 2026-09-24  
**Plataforma:** iOS (iPhone 15 Pro e Dynamic Island, com suporte offline-first)  
**Público-alvo:** Adultos neurodivergentes diagnosticados ou em investigação de TDAH  
**Design system associado:** Soft Liquid Glass (`#1FAF8A` teal menta, `#8B7BC8` lavanda calmo, `#FF8A5C` coral suave)

> A implementação vigente está no [GDD](GDD.md): Flutter, Riverpod e SharedPreferences. Onde este PRD fala em SQLite ou SwiftData, vale a stack do GDD. Telas de referência: pasta `Design/`.

---

## 1. Visão geral e proposta de valor

### 1.1 Declaração do problema

Pessoas com TDAH enfrentam desafios agudos de função executiva:

1. **Inércia e paralisia executiva.** Dificuldade física e emocional em iniciar tarefas, agravada por interfaces complexas.
2. **Time blindness e farmacocinética.** Dificuldade em perceber a duração e o declínio da eficácia de estimulantes e estabilizadores, com quedas abruptas de energia (crashes dopaminérgicos).
3. **Culpa crônica e gamificação agressiva.** Aplicativos de produtividade usam sequências punitivas, notificações intrusivas e indicadores vermelhos de falha, o que gera ansiedade e abandono.
4. **Desconexão com o terapeuta ou psiquiatra.** Dificuldade em sintetizar os últimos 15 a 30 dias na consulta, com relatos presos ao humor das últimas 24 horas (viés de recência).

### 1.2 Proposta de valor

O Lumen é um companion neurodivergente, centrado em zero culpa e baixa fricção, projetado para:

- fazer check-ins de humor, energia e sintomas em menos de 10 segundos;
- mostrar a janela de eficácia das medicações;
- resgatar a paralisia executiva com o protocolo Des-Trava;
- correlacionar Apple Health (sono REM, repouso, HRV) com estados mentais;
- exportar um resumo clínico em um toque (WhatsApp e PDF).

---

## 2. Princípios de produto e UX

| Princípio | Implementação prática |
| :--- | :--- |
| Zero culpa | Sem sequências quebráveis. Pular uma dose ou um hábito usa mensagem neutra (“Tudo bem, seu ritmo é seguro”). Sem alerta vermelho de falha. |
| Microfricção (≤ 10 s) | Interações críticas em 1 ou 2 toques. Campos abertos são opcionais. |
| Anti-paralisia | Um único foco inegociável no dia. Des-Trava em destaque, com timer de 60 s. |
| Offline-first e privacidade | Registro, timer e janela de medicação funcionam sem internet. Dados de saúde não são monetizados. Persistência atual: ver GDD. |
| Soft Liquid Glass | Superfícies translúcidas, cantos de 16–24 px, contraste alto, sem ruído decorativo. |

---

## 3. Personas

### Persona primária: Marcelo, 31 anos, designer de produto

- **Diagnóstico:** TDAH combinado há 2 anos, em uso de lisdexanfetamina 30 mg.
- **Dores:** esquece se tomou o remédio; sente a queda do platô no fim da tarde; paralisa diante de uma lista longa; não lembra o que dizer na terapia quinzenal.
- **Necessidade:** um espaço sem julgamento, um aviso sereno antes do cansaço e um resumo para a consulta.

### Persona indireta: profissional de saúde

No protótipo visual, a profissional de referência é a Dra. Camila Ramos. Recebe PDF, texto de WhatsApp ou card semanal, com padrões (sono, adesão, sobrecarga), não um despejo de dados brutos.

---

## 4. Requisitos funcionais

### 4.1 Hub principal

- Saudação do período do dia e microcópia “Sem pressa, um passo de cada vez”.
- Atalhos: Check-in rápido e Des-Trava (coral `#FF8A5C`).
- Card de medicação com a janela ativa, tempo restante e próxima dose.
- Card da âncora do dia: um foco e o status dos micro-hábitos, com mensagem anti-culpa.
- Apple Health: sono total, minutos de REM e indicativo de recuperação.
- Card de padrões: correlação entre sono/recuperação e foco.
- Histórico compacto dos check-ins recentes.

### 4.2 Check-in rápido

- Meta de execução abaixo de 10 segundos, em bottom sheet.
- Valência emocional em 5 níveis.
- Matriz de foco: focado, hiperfoco, disperso, paralisado.
- Energia em 5 níveis.
- Toggles: medicação prescrita tomada e sobrecarga sensorial.
- Nuvem State of Mind.
- Linha opcional de nota. Voz é requisito de produto ainda não implementado.
- Salvar sem modal intermediário.

### 4.3 Rotina e foco do dia

- Uma âncora inegociável.
- Hidratação visual, sem notificação agressiva. O protótipo usa mililitros; o app atual conta copos.
- Micro-hábitos com folga emocional quando o dia fica incompleto.
- Slider de humor e contexto (trabalho, família, saúde, hobbies ou sono).
- Espaço de notas para a próxima consulta.

### 4.4 Medicação e janela de eficácia

- Barra da janela: início, platô e término, com tempo restante.
- Aviso gentil de rebote (lanche leve e água) ainda não implementado.
- Timeline do dia com formato, dose e ações: tomar, adiar 15 minutos, pular sem culpa.
- Aviso quando restarem 5 doses ou menos, com atalho de mensagem de renovação ainda não implementado.

### 4.5 Des-Trava

- Superfície com poucos estímulos e acento coral.
- Três passos: microação física, uma palavra da tarefa, timer de 60 segundos.
- Pacto explícito: depois do minuto, parar também é um resultado válido.

### 4.6 Hub clínico

- Nome e telefone do profissional. Data da próxima consulta ainda não implementada.
- Janela de 7, 14 ou 30 dias na interface: parcial (o PDF já aceita período).
- Toggle para ocultar notas íntimas na exportação: ainda não implementado.
- Resumo: adesão, sono, distribuição de foco e sobrecarga, usos do Des-Trava e correlações.
- WhatsApp e PDF.

---

## 5. Requisitos não funcionais

1. Abertura rápida e check-in fluido. Números-alvo do protótipo: abertura em menos de 400 ms e bottom sheet a 60 fps. Ainda sem medição no app.
2. Registro, timer e janela de medicação funcionam offline. Dados do Apple Health dependem de permissão e de leitura prévia.
3. HealthKit só depois de consentimento explícito.
4. Criptografia em repouso, Face ID e nuvem com criptografia de ponta a ponta estão fora do MVP. O app é local-first, sem conta obrigatória.

---

## 6. Métricas de sucesso

Ainda não instrumentadas. Metas do protótipo:

- Retenção no dia 30 acima de 45%.
- Tempo médio de check-in abaixo de 12 segundos.
- Mais de 65% das sessões de Des-Trava concluem os 60 segundos.
- Mais de 70% dos usuários ativos enviam o resumo clínico na janela semanal.

---

## 7. Protótipo visual

Telas em `Design/`, cada uma com `code.html`:

| Pasta | Tela |
| --- | --- |
| `lumen_in_cio_home_hub` | Home |
| `lumen_check_in_r_pido` | Check-in |
| `lumen_rotina_foco` | Rotina |
| `lumen_medica_es_janela` | Medicação |
| `lumen_des_trava_anti_paralisia` | Des-Trava |
| `lumen_hub_cl_nico` | Hub clínico |
| `lumen_minimalist_mark` | Marca |
| `soft_liquid_glass/DESIGN.md` | Design system exportado |

O YAML do `DESIGN.md` do Stitch gera um `primary` Material `#006c53` e usa `#1FAF8A` como `primary-container`. No produto, o teal preenchido dos CTAs continua `#1FAF8A`.

O app mantém fundo sólido, sem orbes decorativos. O protótipo sugere luz ambiente atrás dos cards; isso não entra na implementação enquanto o princípio de fundo sólido do GDD valer.
