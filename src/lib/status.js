// Tempo na etapa atual a partir do histórico de mudanças de status.
// O backend registra mudanças como "Status: X → Y" (inclui atualizações sem mudança).
// O fallback é criado_em quando não existe histórico de mudança confiável.

export function statusSince(registro, entidade, historico = []) {
  if (!registro) return null
  const transitions = historico
    .filter(h => h.entidade === entidade && h.registro_id === registro.id)
    .map(h => {
      const match = /^Status:\s*(.*?)\s*→\s*(.*?)\s*$/.exec(h.descricao || '')
      return match && match[1] !== match[2] && match[2] === registro.status
        ? h.criado_em : null
    })
    .filter(Boolean)
    .map(v => new Date(v).getTime())
    .filter(Number.isFinite)
  const since = transitions.length ? new Date(Math.max(...transitions)) : new Date(registro.criado_em)
  return Number.isFinite(since.getTime()) ? since : null
}

export function statusAge(registro, entidade, historico = [], now = new Date()) {
  const since = statusSince(registro, entidade, historico)
  if (!since) return { since: null, hours: 0, days: 0, label: 'Sem data' }
  const hours = Math.max(0, (new Date(now).getTime() - since.getTime()) / 3600000)
  const days = hours / 24
  let label = hours < 1 ? 'menos de 1h' : hours < 24
    ? `${Math.floor(hours)}h` : `${Math.floor(days)}d ${Math.floor(hours % 24)}h`
  return { since, hours, days, label }
}

export function statusAgeChart(registros, entidade, historico = [], now = new Date()) {
  return registros.map(registro => {
    const age = statusAge(registro, entidade, historico, now)
    return {
      id: registro.id,
      nome: registro.numero ? `${registro.numero} · ${registro.titulo}` : registro.titulo,
      status: registro.status,
      horas: Math.round(age.hours * 10) / 10,
      tempo: age.label,
      desde: age.since ? age.since.toLocaleString('pt-BR') : 'Sem data'
    }
  }).sort((a,b) => b.horas - a.horas)
}
