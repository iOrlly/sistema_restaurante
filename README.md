# 🍽️ Controle Restaurante - Gestão Inteligente e Lucrativa

O **Controle Restaurante** é uma solução completa em Flutter desenvolvida para transformar a operação caótica de um restaurante em uma gestão baseada em dados. O app foca em quatro pilares: **Redução de Desperdício**, **Eficiência de Equipe**, **Visão Financeira Real** e **Controle de Obrigações**.

---

## 🚀 Funcionalidades Principais

### 🧾 Gestão de Boletos (Novo!)
- **Compensação Automática:** Boletos que vencem no final de semana são automaticamente agrupados na segunda-feira para uma visão real de fluxo de caixa.
- **Categorização:** Organização por Fornecedores, Impostos, Insumos e Outros.
- **Dashboard Financeiro:** Visualização imediata do total pendente hoje e do total da semana.
- **Exportação Excel:** Gere relatórios de vencimentos com status de pagamento em segundos.

### 📦 Almoxerifado Inteligente
- **Gestão de Estoque:** Controle total de insumos com suporte a unidades (KG, Litro, Unidade, Caixa).
- **Alertas de Reposição:** Notificações automáticas quando um item atinge o nível crítico.
- **Rastreio de Avarias:** Registro específico para perdas e desperdícios no estoque.

### 💰 Ecossistema Financeiro Integrado
- **Conexão Inteligente:** Sincronização automática entre Vendas, Boletos e Frequência de Equipe.
- **Cálculo de Lucro Líquido:** O sistema cruza as entradas (Vendas/Faturamento) com as saídas (Boletos pagos e Diárias) para entregar o saldo real.
- **Filtros por Período:** Visualize a saúde financeira de um dia, uma semana ou do mês completo.
- **Relatórios Consolidados:** Exportação para Excel com detalhamento de cada centavo que saiu do caixa.

### 🍳 Produção & Combate ao Desperdício
- **Planejamento de Produção:** Registro do que foi produzido vs. o que sobrou.
- **Indicador "Fire":** Alertas visuais na Home quando o desperdício ultrapassa 20%, sugerindo ajustes imediatos na produção do dia seguinte.
- **Eficiência por Funcionário:** Monitoramento de quantos itens cada colaborador produz/vende por hora.

---

### 👥 Gestão de Pessoas & Pagamentos (Atualizado!)
- **Equipe Fixa:** Controle de férias, faltas e novo botão de **"Registrar Pagamento de Salário"**.
- **Terceirizados:** Ao clicar em "Quitar/Zerar", o sistema agora gera um registro histórico permanente do pagamento.
- **Integração Financeira:** Todos os pagamentos (salários e diárias) são enviados automaticamente para a tela de Fechamento de Caixa.
- **Histórico:** Mantenha o registro de tudo o que foi pago para cada colaborador com data e hora.

---

## ❓ Dúvidas Frequentes (FAQ)

**1. O aplicativo funciona sem internet?**
> Sim! O app utiliza o banco de dados local **SQLite**. Seus dados ficam salvos no seu dispositivo, garantindo velocidade e privacidade. A internet é necessária apenas para exportar relatórios por e-mail ou abrir o WhatsApp.

**2. Como a regra de boletos de segunda-feira funciona?**
> Para facilitar a gestão bancária, o app soma todos os boletos que vencem no Sábado, Domingo e Segunda-feira em um único bloco de "Total Hoje" quando visualizado na segunda, refletindo o impacto real no seu caixa no primeiro dia útil.

**3. Onde vejo o que já paguei para os funcionários?**
> Na tela de **Terceirizados**, existe um novo ícone de **Relógio (Histórico)** no topo. Lá você vê a lista de todos os acertos realizados. Para os mensalistas, os valores aparecem consolidados no **Fechamento de Caixa** dentro do período filtrado.

**4. Posso levar meus dados para o computador?**
> Com certeza. O app possui integração com **Microsoft Excel**. Você pode exportar boletos, folhas de pagamento e relatórios de faturamento com um clique.

---

## 🛠️ Tecnologias Utilizadas

- **Flutter & Dart:** Para uma interface fluida e moderna.
- **SQLite (sqflite):** Banco de dados robusto e local.
- **Excel Service:** Geração dinâmica de planilhas .xlsx.
- **Intl:** Padronização de moeda (Real R$) e datas brasileiras.

---

## 💻 Como Rodar o Projeto

1.  **Clone o repositório:**
    ```bash
    git clone https://github.com/iOrlly/sistema_restaurante.git
    ```
2.  **Entre na pasta do projeto:**
    ```bash
    cd app_restaurante
    ```
3.  **Instale as dependências:**
    ```bash
    flutter pub get
    ```
4.  **Execute o aplicativo:**
    ```bash
    flutter run
    ```

---

## 📈 Próximos Passos
- [ ] Integração com impressoras térmicas via Bluetooth.
- [ ] Backup automático na nuvem (Firebase).
- [ ] Módulo de gestão de mesas e comandas via QR Code.

---
**Desenvolvido com ❤️ para facilitar a vida do empreendedor gastronômico.**
