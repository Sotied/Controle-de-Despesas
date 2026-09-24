# Fluxo de telas — gestão financeira pessoal

Este documento registra o fluxo inicial do aplicativo, sem autenticação e com
os dados mantidos localmente no dispositivo.

```mermaid
flowchart TD
    A[Abrir app] --> B[Home / Visão geral]

    B --> B1[Saldo consolidado]
    B --> B2[Resumo do mês: receitas, gastos e saldo]
    B --> B3[Próximos vencimentos]
    B --> B4[Últimos lançamentos]
    B --> C[+ Novo lançamento]

    C --> C1{Tipo}
    C1 -->|Despesa| C2[Valor, categoria, conta, data]
    C1 -->|Receita| C3[Valor, origem, conta, data]
    C1 -->|Transferência| C4[Conta de origem, destino e valor]
    C2 --> D[Confirmar lançamento]
    C3 --> D
    C4 --> D
    D --> B

    B --> E[Lançamentos]
    E --> E1[Lista com busca e filtros]
    E1 --> E2[Detalhe do lançamento]
    E2 --> E3[Editar ou excluir]
    E --> C

    B --> F[Contas]
    F --> F1[Carteira, banco, cartão, poupança]
    F1 --> F2[Saldo e histórico da conta]
    F --> F3[Adicionar / editar conta]
    F1 --> C4

    B --> G[Planejamento]
    G --> G1[Orçamento mensal por categoria]
    G --> G2[Contas recorrentes]
    G --> G3[Metas financeiras]
    G1 --> G4[Comparar previsto x realizado]
    G2 --> C2

    B --> H[Relatórios]
    H --> H1[Gastos por categoria]
    H --> H2[Evolução mensal]
    H --> H3[Receitas x despesas]

    B --> I[Configurações]
    I --> I1[Categorias]
    I --> I2[Exportar / importar backup]
    I --> I3[Moeda e preferências]
```

## Escopo inicial sugerido

1. Home com saldo, resumo mensal, vencimentos e acesso ao lançamento rápido.
2. Lançamentos de receita, despesa e transferência.
3. Contas e categorias.
4. Contas recorrentes.
5. Relatórios e metas como evolução posterior.
