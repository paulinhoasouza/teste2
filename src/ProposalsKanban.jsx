import React,{useState} from 'react'
import {Clock3, Pencil, Building2, CalendarDays, Plus, Search} from 'lucide-react'
import {statusAge} from './lib/status'
import {persistProposal} from './lib/data'
const stages=['Rascunho','Enviada','Em negociacao','Aprovada','Recusada','Cancelada']
const colors=['#66718b','#1853e5','#7528c4','#13926c','#e02755','#9d547d']
const brl=v=>new Intl.NumberFormat('pt-BR',{style:'currency',currency:'BRL'}).format(v||0)
export default function ProposalsKanban({data,onEdit,onNew,onRefresh,onError}) {
 const [search,setSearch]=useState('')
 const [working,setWorking]=useState(null)
 const [dragging,setDragging]=useState(null)
 const client=p=>{const r=data.solicitacoes.find(s=>s.id===p.solicitacao_id);return data.clientes.find(c=>c.id===r?.cliente_id)?.nome||'Cliente não informado'}
 const total=p=>data.itens.filter(i=>i.proposta_id===p.id).reduce((n,i)=>n+Number(i.quantidade)*Number(i.valor_unitario),0)-Number(p.desconto||0)
 const filtered=data.propostas.filter(p=>[p.titulo,p.numero,client(p)].some(v=>(v||'').toLowerCase().includes(search.toLowerCase())))
 async function change(p,status){
   if(status===p.status||working)return
   setWorking(p.id)
   try{await persistProposal({...p,status,itens:data.itens.filter(i=>i.proposta_id===p.id)});await onRefresh()}
   catch(e){onError(e?.message||'Erro ao alterar status')}
   finally{setWorking(null)}
 }
 return <><div className="page-heading"><div><div className="eyebrow">PIPELINE COMERCIAL</div><h1>Kanban de propostas</h1><p>Arraste os cartões para mudar o status ou use o seletor em cada proposta.</p></div><button className="btn btn-primary" onClick={onNew}><Plus size={16}/> Nova proposta</button></div>
 <div className="kanban-toolbar"><Search size={17}/><input aria-label="Buscar propostas" value={search} placeholder="Buscar proposta, número ou cliente" onChange={e=>setSearch(e.target.value)}/><small>{filtered.length} propostas</small></div>
 <div className="kanban-board">{stages.map((stage,idx)=>{const cards=filtered.filter(p=>p.status===stage);return <section className="kanban-column" key={stage} onDragOver={e=>e.preventDefault()} onDrop={e=>{e.preventDefault();const id=e.dataTransfer.getData('text/plain')||dragging;const p=data.propostas.find(x=>x.id===id);setDragging(null);if(p)change(p,stage)}}>
 <header><i style={{background:colors[idx]}}/><strong>{stage==='Em negociacao'?'Em negociação':stage}</strong><span>{cards.length}</span></header>
 <div className="kanban-stack">{cards.map(p=>{const age=statusAge(p,'propostas',data.historico);return <article className="kanban-card" key={p.id} draggable onDragStart={e=>{e.dataTransfer.setData('text/plain',p.id);setDragging(p.id)}} onDragEnd={()=>setDragging(null)}>
 <div className="kanban-top"><span>{p.numero||'Sem número'}</span><button aria-label="Editar proposta" onClick={()=>onEdit(p)}><Pencil size={16}/></button></div>
 <button className="kanban-name" onClick={()=>onEdit(p)}>{p.titulo}</button><div className="kanban-client"><Building2 size={13}/>{client(p)}</div>
 <div className="kanban-money">{brl(total(p))}</div><div className="kanban-meta"><span><Clock3 size={13}/>{age.label} no status</span>{p.validade&&<span><CalendarDays size={13}/>{p.validade.split('-').reverse().join('/')}</span>}</div>
 <select aria-label={'Mudar status de '+p.titulo} disabled={!!working} value={p.status} onChange={e=>change(p,e.target.value)}>{stages.map(v=><option key={v} value={v}>{v==='Em negociacao'?'Em negociação':v}</option>)}</select>
 </article>})}{!cards.length&&<div className="kanban-empty">Arraste uma proposta para cá</div>}</div></section>})}</div><p className="kanban-note">No celular, use o seletor do cartão. Mudanças atualizam o banco e o histórico; propostas em etapas finais precisam ter valor positivo.</p></>
}