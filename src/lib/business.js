/** Cálculos de apresentação. O PostgreSQL realiza as validações definitivas. */
export const proposalSubtotal = items => items.reduce((sum,item) =>
  sum + Number(item.quantidade || 0) * Number(item.valor_unitario || 0), 0)

export const proposalTotal = (items, desconto=0) =>
  Math.max(0, proposalSubtotal(items) - Number(desconto || 0))

export const conversionRate = (approved, decided) =>
  decided > 0 ? (approved / decided) * 100 : 0
