# a_importacoes_evolution

Imagem Docker da Evolution API usada pela Atrion Importações para o disparo de WhatsApp.

**O que é:** Evolution API **v2.3.7** + Baileys **7.0.0-rc14** + remendo de pareamento.

**Por quê:** desde ~28/07/2026 o WhatsApp acrescentou uma etapa (`companion_reg_refresh`) ao registro de aparelhos
vinculados. Nenhuma versão publicada do Baileys trata essa etapa, então vincular um número novo falha com
"não foi possível conectar novos dispositivos no momento". O remendo em `patches/baileys+7.0.0-rc14.patch` vem do
[PR #2727 da Evolution](https://github.com/evolution-foundation/evolution-api/pull/2727) (aplica
[Baileys#2765](https://github.com/WhiskeySockets/Baileys/pull/2765) e
[Baileys#2602](https://github.com/WhiskeySockets/Baileys/pull/2602)).

**Por que não a v2.4.0 / ramo `develop`:** a v2.4.0 exige ativação de licença no servidor da Evolution Foundation
(HTTP 503 até ativar). Aqui a base é a v2.3.7, sem licença.

**Imagem:** `ghcr.io/thelionrush/a_importacoes_evolution:2.3.7-pairfix`

**Quando remover o remendo:** assim que um Baileys publicado incluir o tratamento de `companion_reg_refresh`, voltar para a
imagem oficial da Evolution. **Não arquive nem apague este repositório sem antes mover o "Monitor do WhatsApp" (abaixo)** —
ele hospeda o agendamento do alerta de queda.

Sem segredos neste repositório.

## Monitor do WhatsApp — reforço pelo GitHub Actions
O alerta de queda do WhatsApp (Disparador) é agendado **pelo banco do Supabase** (pg_cron, a cada 5 min). O workflow
`.github/workflows/monitor-whatsapp.yml` chama a mesma rota (`/api/cron/evolution-health`) só como **reforço**, porque o GitHub
executa agendamentos de forma irregular (lacunas de horas). Secrets do repositório: `CRON_SECRET` e `HEALTH_URL`.
Se a rota falhar (ex.: o e-mail do alerta não saiu), o job fica vermelho e o GitHub avisa o dono do repositório.
Não apague os secrets nem o workflow sem necessidade; **não arquive/apague este repositório sem avisar** (a imagem remendada da
Evolution mora aqui).
