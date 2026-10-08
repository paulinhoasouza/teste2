import { supabase, assertConfigured } from './supabase'

const req = async (promise) => { const { data, error } = await promise; if (error) throw error; return data }
export const fetchAll = async () => {
  assertConfigured()
  // Paginação evita limite padrão de 1.000 linhas imposto pelo PostgREST.
  const all = async (table, order='criado_em') => {
    let result=[]; let offset=0
    for(;;) {
      const chunk=await req(supabase.from(table).select('*').order(order, {ascending:false}).range(offset,offset+999))
      result.push(...chunk)
      if(chunk.length<1000) return result
      offset += 1000
    }
  }
  const [clientes, solicitacoes, propostas, itens, historico, revisoes, equipe, anexos] = await Promise.all([
    all('clientes', 'nome'), all('solicitacoes'), all('propostas'), all('itens_proposta', 'descricao'),
    all('historico'), all('revisoes_proposta'), all('equipe', 'nome'), all('anexos')
  ])
  return { clientes, solicitacoes, propostas, itens, historico, revisoes, equipe, anexos }
}
export const persistClient = async (data, id) => req(id
  ? supabase.from('clientes').update(data).eq('id',id).select().single()
  : supabase.from('clientes').insert(data).select().single())
export const removeClient = async id => req(supabase.from('clientes').delete().eq('id',id).select())
export const persistRequest = async (data,id) => req(id
  ? supabase.from('solicitacoes').update({...data, atualizado_em:new Date().toISOString()}).eq('id',id).select().single()
  : supabase.from('solicitacoes').insert(data).select().single())
export const persistProposal = async p => req(supabase.rpc('salvar_proposta', {
  p_id:p.id || null,
  p_solicitacao_id:p.solicitacao_id,
  p_titulo:p.titulo,
  p_escopo:p.escopo || null,
  p_status:p.status,
  p_desconto:Number(p.desconto) || 0,
  p_validade:p.validade || null,
  p_condicoes:p.condicoes_pagamento || null,
  p_observacoes:p.observacoes || null,
  p_itens:p.itens.map(x=>({ descricao:x.descricao, quantidade:Number(x.quantidade), valor_unitario:Number(x.valor_unitario) }))
}))
export const saveMember = async (data,id) => req(id
  ? supabase.from('equipe').update(data).eq('id',id).select().single()
  : supabase.from('equipe').insert(data).select().single())
export async function uploadAttachment(file, entity, recordId, userId) {
  if (!['solicitacoes','propostas'].includes(entity)) throw new Error('Entidade inválida')
  if (!file || file.size > 10*1024*1024) throw new Error('Arquivo deve ter até 10 MB')
  const safeName=file.name.replace(/[^a-zA-Z0-9._-]/g,'_')
  const path=`${entity}/${recordId}/${crypto.randomUUID()}-${safeName}`
  await req(supabase.storage.from('zetta-anexos').upload(path,file,{upsert:false}))
  try {
    return await req(supabase.from('anexos').insert({entidade:entity,registro_id:recordId,nome:file.name,caminho:path,tamanho:file.size,criado_por:userId}).select().single())
  } catch(err) { await supabase.storage.from('zetta-anexos').remove([path]); throw err }
}
export async function downloadAttachment(file) {
  const tab=window.open('about:blank','_blank')
  const {data,error}=await supabase.storage.from('zetta-anexos').createSignedUrl(file.caminho,60)
  if(error){tab?.close();throw error}
  if(tab){tab.opener=null;tab.location.href=data.signedUrl}
  else window.location.assign(data.signedUrl)
}
export const removeAttachment = async file => {
  await req(supabase.storage.from('zetta-anexos').remove([file.caminho]))
  await req(supabase.from('anexos').delete().eq('id',file.id))
}
