# Design — Liquid Glass no Lumen (iOS)

> Data: 2026-10-29 · Par do [PLANO_LIQUID_GLASS.md](PLANO_LIQUID_GLASS.md) · Android permanece Material 3.

## Decisão da etapa 1

| Sinal do sistema | API pública | Uso no Lumen |
|---|---|---|
| Liquid Glass Transparente / Colorido (iOS 26.1) | **Não** (Apple DTS) | Não dá para espelhar sozinho; seletor no app fica na etapa 6 |
| Reduzir Transparência | `UIAccessibility.isReduceTransparencyEnabled` via `SystemSettings.accessibilityFlags` | Nível `solid` |
| Aumentar Contraste | `MediaQuery.highContrast` | Nível `tinted` + borda |
| Reduzir Movimento | `MediaQuery.disableAnimations` | FakeGlass / motion off (já existia) |
| Modo escuro | tema | Tint / fill |

## Regra HIG

Vidro só na camada que flutua sobre o conteúdo:

- tab bar (`GlassNavBar`)
- app bar (`GlassAppBar`)
- gavetas (`GlassSheet`)
- FAB (`LumenFab`)
- chips (`GlassChip`)

Cards e painéis de conteúdo (`GlassSurface`) são **sólidos** (`AppColors.cardLight` / `cardDark`), com borda leve e sombra de contato.

## Níveis (`LumenGlassLevel`)

| Nível | Opacidade | Refração | Borda |
|---|---|---|---|
| `clear` | baixa | sim (chrome) | sutil |
| `tinted` | média-alta | reduzida | reforçada |
| `solid` | quase opaca | não | reforçada |

Resolução automática (sem preferência do app): Reduzir Transparência → `solid`; senão Aumentar Contraste → `tinted`; senão `clear`.

## Tipografia e espaço

- Tipografia do sistema; manter `textScaler`.
- Tokens: `AppSpacing`, `AppRadii` (card 24, sheet 36, nav cápsula).
- Cantos concêntricos: cápsula da nav e app bar acompanham o raio do aparelho via `LiquidRoundedSuperellipse`.

## Cor

- Fundo sage-stone / carvão (`#F2F5F3` / `#141816`).
- Destaque só na ação principal `#1FAF8A`.
- Sem acento de vidro em cards de conteúdo.

## Estados

- Vazio / carregando / erro: mesmo envelope sólido (`GlassSurface` / placeholders).
- Health recusado: chrome e conteúdo usáveis sem inventar dado.

## Navegação (etapa 4)

- Chrome responde ao nível (tint, FakeGlass em `solid`, borda em `tinted`/`solid`).
- `GlassScaffold`: gradiente curto sob a app bar (borda de rolagem).
- Encolher tab bar ao rolar: ainda fora deste corte — depende de listener de scroll por aba.

## Aparência do vidro (etapa 6)

Chave `noa_glass_level_v1` · só iOS em Configurações › Aparência:

- Seguir sistema · Transparente · Colorido · Sólido
- Atalho “Abrir Ajustes do iPhone” (`SystemSettingsTarget.app`) com hint para Tela e Brilho › Liquid Glass e Reduzir Transparência

Preferência explícita sobrescreve a resolução por acessibilidade.
