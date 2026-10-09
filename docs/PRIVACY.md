# Política de Privacidade — Lumen

**Última atualização:** 2026-10-08  
**App:** Lumen (`dev.prism.lumen`)  
**URL pública:** https://goobinexe.github.io/lumen-privacy/  
**Contato:** pelo app, em Configurações → Mandar feedback (e-mail de suporte dedicado entra nesta página quando existir)

Este texto descreve o que o Lumen faz com dados no aparelho. Vale para iOS e Android. É a base da Nutrition Label (Apple) e do Data safety (Google Play). A página HTML em `site/index.html` espelha este documento para o GitHub Pages.

---

## Resumo

O Lumen é **offline-first e privacy-first**.

- Sem conta obrigatória.
- Sem login.
- Sem nuvem do Lumen.
- Nenhum dado pessoal, de saúde ou biométrico é enviado a servidores do Lumen.
- Integrações (Health Connect / Apple Health, calendário do aparelho, compartilhar PDF/WhatsApp) acontecem **no aparelho** ou só quando **você** escolhe compartilhar.

---

## Quem controla os dados

Os dados que você registra no Lumen ficam **no seu aparelho**, sob o identificador `dev.prism.lumen`. Você controla o que fica, o que apaga e o que compartilha.

O Lumen **não** opera um backend de conta nem um serviço de sincronização em nuvem nesta versão.

---

## Quais dados o app guarda no aparelho

Dependendo do que você usa:

| Tipo | Exemplos | Onde fica |
|------|----------|-----------|
| Perfil local | Nome/apelido, nascimento, altura, peso, sexo biológico, tom de voz | Preferências locais do app |
| Humor e rotina | Check-in (humor, foco, energia), âncora do dia, água, hábitos, reflexão, pauta | Preferências locais do app |
| Medicação | Nome, posologia, horários, tomadas/puladas, estoque | Preferências locais do app |
| Tarefas | Itens, períodos, lembretes, quiet hours | Preferências locais do app |
| Contatos de cuidado | Nome, papel, telefone do profissional (você digita) | Preferências locais do app |
| Preferências | Tema, idioma, sync de saúde/calendário | Preferências locais do app |
| Export / backup | PDF, texto, JSON compartilhados por você | Só quando você exporta ou compartilha |

Chaves locais usam o prefixo `noa_*` (ex.: `noa_mood_entries_v2`). Uma atualização da loja **não** apaga esse armazenamento de propósito.

---

## Saúde do aparelho (Health Connect / Apple Health)

Com o seu consentimento no sistema:

**Leitura (quando disponível e autorizada):** sono, frequência cardíaca, HRV, FC em repouso, passos, exercício, altura, peso, hidratação; no iOS também estado emocional, luz, áudio e agenda de medicação quando o tipo existe.

**Escrita (quando o tipo existe nos dois lados e você autorizou):** o que o Lumen puder espelhar de volta (ex.: hidratação). Tipos só de um SDK ficam no domínio local do app na outra plataforma.

Sem permissão, o app continua usável com o que você registrou localmente — ou vazio, se não houver registro. O Lumen **não inventa** dado de saúde.

HRV: SDNN no iOS e RMSSD no Android; unidades ficam no domínio, sem métrica misturada.

---

## Calendário, notificações e alarmes

- **Calendário:** leitura/escrita do calendário do aparelho só com permissão, para enriquecer o Raio-X do dia. O evento espelhado inclui água, hábitos e medicação do dia — **não** inclui reflexão noturna nem pauta íntima (essas só saem no export clínico quando você libera o toggle).
- **Notificações locais:** lembretes de dose e de tarefas no próprio aparelho (canais locais). Não passam por servidor do Lumen.
- **Alarmes exatos (Android):** usados para lembretes no horário certo; você pode gerenciar isso nos Ajustes do sistema.

---

## Compartilhamento e terceiros

O Lumen **não vende** dados e **não envia** registros pessoais ou de saúde a servidores próprios.

- **Compartilhamento iniciado por você:** PDF clínico, texto para WhatsApp, card semanal e backup local usam a folha de compartilhar do sistema. O destino (terapeuta, WhatsApp, e-mail, arquivo) é **sua escolha**. Arquivos temporários usados só para abrir o share são apagados em seguida no aparelho.
- **Health Connect / Apple Health e calendário:** ficam no aparelho / apps de saúde e agenda do sistema, com as permissões que você concedeu.
- **Lojas de apps (Google Play / App Store):** processam instalação, atualização e, quando aplicável, dados de diagnóstico da própria loja. Isso **não** inclui o conteúdo clínico que você registra no Lumen.
- **Formulário de feedback:** se você abrir “Mandar feedback” nas Configurações, o que você digitar no formulário externo segue a política desse provedor — o Lumen não anexa automaticamente humor, sono, doses ou export clínico.

---

## O que o Lumen não faz

- O Lumen **não é um dispositivo médico** e **não diagnostica, trata, cura ou previne** nenhuma condição médica. É um companion de rotina e organização para o dia a dia (incluindo apoio a quem vive com TDAH). Para aconselhamento, diagnóstico ou tratamento, consulte um profissional de saúde.
- Não exige conta nem rede social.
- Não vende dados.
- Não usa seus dados de saúde para anúncio.
- Não amostra microfone nem sensor de luz para imitar relógio; luz/áudio no Android, enquanto não houver permissão pedida, são registro local se existirem.

---

## Crianças

O Lumen não é dirigido a crianças menores de 13 anos. Há perfis de tom de voz (incluindo linguagem voltada a meninas/meninos) para quem já usa o app com acompanhamento; isso **não** muda a regra de privacidade local.

---

## Seus controles

- Revogar Health Connect / Apple Health e calendário nos Ajustes do sistema.
- Apagar dados do app (limpar armazenamento / desinstalar).
- Exportar backup local quando quiser levar os dados consigo.
- Escolher o que entra no material clínico (ex.: ocultar notas íntimas).

---

## Alterações desta política

Mudanças relevantes aparecem neste documento com nova data. Em builds de teste (TestFlight / Play Internal), a cópia no app e esta política devem dizer a mesma coisa sobre o que o app lê e grava.

---

## Contato

Dúvidas de privacidade: abra o Lumen → Configurações → **Mandar feedback**. Quando houver e-mail de suporte dedicado, ele passa a constar nesta política e na URL pública.
