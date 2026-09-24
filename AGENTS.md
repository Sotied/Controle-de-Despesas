# Controle de Despesas

App de finanças pessoais em **Flutter**:

- **Riverpod** para gerenciamento de estado
- **Drift** (SQLite) para persistência local no dispositivo

O diretório do projeto Flutter é `flutter_application_1/`. O fluxo de navegação/telas documentado está em `FluxoSistema.svg` (mermaid flowchart).

## Fluxo do sistema (FluxoSistema.svg)

### Navegação principal (a partir de Home / Visão geral)
A Home (`B`) é o hub central e dá acesso a todas as áreas:

- **Saldo consolidado** (B1) — exibido na Home
- **Resumo do mês: receitas, gastos e saldo** (B2) — exibido na Home
- **Próximos vencimentos** (B3) — exibido na Home
- **Últimos lançamentos** (B4) — exibido na Home
- **+ Novo lançamento** (C)
- **Lançamentos** (E)
- **Contas** (F)
- **Planejamento** (G)
- **Relatórios** (H)
- **Configurações** (I)

### 1. Novo lançamento (C)
Fluxo: `C (Novo lançamento) → C1 (Tipo, decisão) → formulário → D (Confirmar) → volta para Home`

Escolha do tipo (C1) leva a três formulários:
- **Despesa** → C2: valor, categoria, conta, data
- **Receita** → C3: valor, origem, conta, data
- **Transferência** → C4: conta de origem, conta de destino e valor

### 2. Lançamentos (E)
Fluxo: `E → E1 (lista com busca e filtros) → E2 (detalhe do lançamento) → E3 (editar ou excluir)`

- Da tela de Lançamentos também se acessa `+ Novo lançamento` (E → C).

### 3. Contas (F)
- F1: tipos de conta — **carteira, banco, cartão, poupança**
- F2: saldo e histórico da conta
- F3: adicionar / editar conta
- Atalho: da tela de contas pode-se iniciar uma **Transferência** (F1 → C4)

### 4. Planejamento (G)
- G1: orçamento mensal por categoria → G4: comparar **previsto x realizado**
- G2: contas recorrentes (atalho para criar despesa: G2 → C2)
- G3: metas financeiras

### 5. Relatórios (H)
- H1: gastos por categoria
- H2: evolução mensal
- H3: receitas x despesas

### 6. Configurações (I)
- I1: categorias
- I2: exportar / importar backup
- I3: moeda e preferências

## Convenções de código
- **Gerenciamento de estado**: sempre priorizar **Riverpod** (Notifiers/providers) — não usar `setState` para estado de tela (filtros, seleções, salvamento, erros). Controllers de texto podem ficar no widget, mas o estado relevante da tela vai em providers; assim a validação do gerenciamento de estado é consistente.

## Observações para implementação
- Entidades centrais no banco (Drift): lançamentos (despesa/receita/transferência), contas (carteira/banco/cartão/poupança), categorias, orçamentos, contas recorrentes, metas.
- Transferência envolve duas contas (débito na origem, crédito no destino).
- Confirmar lançamento sempre retorna à Home, que deve refletir saldo consolidado, resumo do mês, próximos vencimentos e últimos lançamentos.

## Plano de trabalho (roadmap T01–T16)

Plano definido junto ao usuário; as tarefas serão executadas sob demanda (uma por vez, conforme pedido).

### Fase 1 — Fundação
- **T01 — Organizar a arquitetura** ✅ (concluída): separar features, database, repositories, providers e componentes compartilhados; centralizar injeção do AppDatabase via Riverpod; remover código experimental e substituir o teste padrão do contador.
- **T02 — Modelar o banco Drift** ✅ (concluída): tabelas de contas, categorias, lançamentos e preferências; valores monetários em **centavos** (int, nunca texto); modelar despesa, receita e transferência; migrations e relacionamentos.
- **T03 — Criar repositórios e providers** ✅ (concluída): CRUD reativo com streams do Drift; providers para contas, categorias, lançamentos e resumos; tratamento padronizado de carregamento e erros.

### Fase 2 — Funcionalidades essenciais
- **T04 — Categorias** ✅ (concluída): listar, adicionar, editar, arquivar e excluir; diferenciar categorias de receita e despesa; criar categorias iniciais.
- **T05 — Contas** ✅ (concluída): carteira, banco, cartão e poupança; adicionar/editar; exibir saldo e histórico; calcular saldo a partir dos lançamentos.
- **T06 — Novo lançamento** ✅ (concluída): escolher despesa/receita/transferência; validar valor, categoria, conta e data; seleção de origem/destino em transferências; confirmar e persistir no Drift.
- **T07 — Lista de lançamentos** ✅ (concluída): ordenação por data; busca textual; filtros por período, tipo, conta e categoria; estados vazio, carregando e erro.
- **T08 — Detalhe, edição e exclusão** ✅ (concluída): detalhes do lançamento; edição mantendo consistência dos saldos; exclusão com confirmação; tratamento correto de transferências.
- **T09 — Home / visão geral** ✅ (concluída): saldo consolidado; receitas, despesas e saldo do mês; próximos vencimentos; últimos lançamentos; atalho para novo lançamento.
- **T10 — Navegação principal** ✅ (concluída): Home, Lançamentos, Contas, Planejamento, Relatórios e Configurações; preservar estado de cada seção; adaptar a diferentes tamanhos de tela.

### Fase 3 — Planejamento financeiro
- **T11 — Contas recorrentes** ✅ (concluída): criar regras de recorrência; identificar próximos vencimentos; gerar/confirmar lançamentos sem duplicidade.
- **T12 — Orçamento mensal** ✅ (concluída): limite mensal por categoria; comparar previsto x realizado; alerta visual quando limite próximo ou ultrapassado.
- **T13 — Metas financeiras** ✅ (concluída): metas com valor e prazo; registrar progresso; exibir percentual e valor restante.

### Fase 4 — Análises e manutenção
- **T14 — Relatórios**: gastos por categoria; evolução mensal; receitas x despesas; filtros por período e conta.
- **T15 — Configurações locais**: moeda e preferências; gerenciamento de categorias; exportação/importação de backup; validar backup antes de substituir dados.
- **T16 — Qualidade e finalização**: testes de banco, repositórios, providers e widgets críticos; testes de migrations e cálculos financeiros; estados vazios, acessibilidade e responsividade; revisão geral contra o fluxo do SVG.
