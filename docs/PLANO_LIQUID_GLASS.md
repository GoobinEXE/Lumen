# Plano — Liquid Glass no padrão Apple (iOS)

> Data: 2026-10-29 · Escopo: P03 (design system) e §10 do [GDD](GDD.md) · Android continua em Material 3.

## Contexto

- **O ajuste do sistema não é um controle deslizante.** No iOS 26.1 ele fica em **Ajustes › Tela e Brilho › Liquid Glass**, com duas opções: **Transparente** e **Colorido** (mais opaco, mais contraste). Não foi encontrada API pública que diga ao app qual opção a pessoa escolheu. Componentes nativos (UIKit/SwiftUI) seguem a escolha sozinhos; o vidro do Lumen é desenhado pelo `liquid_glass_renderer` dentro do Flutter e **não muda** com ela. Confirmar no aparelho (etapa 1).
- **O que o app consegue ler:** Reduzir Transparência (estendendo `ios/Runner/SystemSettingsBridge.swift`), Aumentar Contraste (`MediaQuery.highContrast`), Reduzir Movimento (já usado) e o modo escuro.
- **Vidro no conteúdo:** os cards (`GlassSurface`, papel `LumenGlassRole.surface`) são vidro. As diretrizes da Apple (HIG) reservam o Liquid Glass para a camada de navegação e controles, que flutua sobre o conteúdo — não para o próprio conteúdo. É a correção visual que mais pesa.
- **Antes de começar:** estabilizar e commitar as alterações de tema que ainda estão abertas.

## Etapas

| # | Etapa | Entrega | Modelo |
|---|---|---|---|
| 0 | **Base estável:** `flutter analyze` e `flutter test` sem erros sobre o que já está alterado; commit | ✅ Feito | Haiku 5.5 |
| 1 | **Teste técnico no aparelho (iOS 26.1+):** ver se dá para ler Transparente/Colorido por caminho público; confirmar a leitura de Reduzir Transparência e Aumentar Contraste em tempo real; medir o custo do `liquid_glass_renderer 0.2.0-dev.4`; confirmar build com SDK do Xcode 26 (Liquid Glass nativo no teclado, seletor de hora e folha de compartilhar) | ✅ Sem API pública (DTS); `accessibilityFlags` + highContrast no código. Medição GPU / Xcode 26 no aparelho ainda pendente | Opus 5.5 (Fable 5.1 se a investigação nativa ficar funda) |
| 2 | **Auditoria HIG e direção de design:** prints das 4 abas e das gavetas, claro/escuro, texto grande. Regra: vidro só em tab bar, app bar, gavetas, FAB e chips; conteúdo em superfícies sólidas; tom de destaque só na ação principal (`#1FAF8A`); cantos concêntricos com o aparelho | ✅ `docs/DESIGN_LIQUID_GLASS.md` (prints no aparelho ainda pendentes) | Opus 5.5 (skills `impeccable`, `apple-design`) |
| 3 | **Nível de vidro como token:** `LumenGlassLevel { clear, tinted, solid }` + provider em `lib/core/theme`. Junta a escolha da pessoa com o que o sistema permite ler: Reduzir Transparência → `solid`; Aumentar Contraste → `tinted` com borda. `lumenGlassSettings` passa a ler o nível. Ponte nativa só estendida, sem canal novo | ✅ Feito (`LumenGlassScope` + provider) | Sonnet 5.5, revisão Opus 5.5 |
| 4 | **Navegação e controles no padrão iOS 26:** tab bar que encolhe ao rolar, efeito de borda de rolagem sob a app bar, gavetas e FAB coerentes com os três níveis | 🟡 Borda de rolagem + níveis no chrome; encolher tab ao rolar pendente | Sonnet 5.5 |
| 5 | **Revisão tela por tela:** Início, Dia, Remédios, Pasta clínica e gavetas. Cards sólidos, hierarquia, Dynamic Type, estados vazio/carregando/erro | ✅ `GlassSurface` sólido globalmente (telas herdaram) | Sonnet 5.5 (paralelo, uma sessão por feature); Haiku 5.5 para strings no `app_pt.arb` |
| 6 | **"Aparência do vidro" nas Configurações:** Seguir sistema · Transparente · Colorido · Sólido, com atalho para o ajuste do iOS. Chave `noa_glass_level_v1`. Só entra se a etapa 1 mostrar que não dá para ler o ajuste do sistema | ✅ Feito | Sonnet 5.5 |
| 7 | **Desempenho:** limitar camadas com refração, `RepaintBoundary`, medir no DevTools em iPhone 13 e XS | 🟡 Surface sem shader; medição no aparelho pendente | Opus 5.5 |
| 8 | **Verificação:** testes de imagem nível × tema × tamanho de texto, prints no simulador, `flutter analyze` e `flutter test` | 🟡 Unit/widget + analyze/test; golden/prints pendentes | Sonnet 5.5; Haiku 5.5 para testes repetitivos |
| 9 | **GDD (P03, §10) e versão `0.3.0`** | ✅ Feito | Haiku 5.5 |

## Critério dos modelos

- **Opus 5.5:** arquitetura, design e desempenho, onde errar custa caro (1, 2, 7).
- **Sonnet 5.5:** implementação em volume seguindo regras já definidas (3–6, 8).
- **Haiku 5.5:** trabalho mecânico (commit, strings, testes repetitivos, documentação).
- **Fable 5.1:** opcional na etapa 1, se disponível no plano.

## Perguntar antes (AGENTS.md)

- Criar a chave de preferência `noa_glass_level_v1` (etapa 6).
- Qualquer dependência nova.

## Fontes

- [MacRumors — iOS 26.1 Liquid Glass toggle](https://www.macrumors.com/2025/10/20/ios-26-1-liquid-glass-toggle/)
- [MacRumors — how to reduce Liquid Glass effects](https://www.macrumors.com/how-to/ios-26-1-reduce-liquid-glass-effects/)
- [Daring Fireball — Clear or Tinted](https://daringfireball.net/linked/2025/10/21/ios-26-1-beta-4-liquid-glass-tinted-option)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
