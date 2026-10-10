import React,{useState} from 'react'
import {ResponsiveContainer,CartesianGrid,XAxis,YAxis,Tooltip,BarChart,Bar,Cell} from 'recharts'
import {statusAgeChart} from './lib/status'
const colors={'Rascunho':'#6c7690','Enviada':'#1853e5','Em negociacao':'#7528c4','Aprovada':'#12946d','Recusada':'#d92d56','Cancelada':'#ab507b','Aberta':'#1853e5','Em analise':'#7250c4','Em proposta':'#bb318d','Concluida':'#12946d'}
export default function StatusDashboard({data}){
 const [type,setType]=useState('propostas')
 const records=type==='propostas'?data.propostas:data.solicitacoes
 const chart=statusAgeChart(records,type,data.historico).slice(0,15)
 const statuses=[...new Set(chart.map(x=>x.status))]
 const average=status=>{const values=chart.filter(r=>r.status===status);return (values.reduce((n,r)=>n+r.horas,0)/values.length).toFixed(1)}
 return <section className="panel time-dashboard"><div className="panel-title"><div><h2>Tempo de permanência por status</h2><p>Identifique propostas e solicitações paradas em cada etapa.</p></div><div className="time-tabs"><button className={type==='propostas'?'selected':''} onClick={()=>setType('propostas')}>Propostas</button><button className={type==='solicitacoes'?'selected':''} onClick={()=>setType('solicitacoes')}>Solicitações</button></div></div>
 {chart.length?<><div className="time-legend">{statuses.map(s=><span key={s}><i style={{background:colors[s]||'#7143bf'}}/>{s}: <b>{average(s)}h</b> em média</span>)}</div><div className="time-chart"><ResponsiveContainer width="100%" height="100%"><BarChart layout="vertical" data={chart} margin={{top:8,bottom:8,left:8,right:28}}><CartesianGrid strokeDasharray="3 3" horizontal={false}/><XAxis type="number" unit="h" tick={{fontSize:11}}/><YAxis type="category" dataKey="nome" width={125} tick={{fontSize:11}} tickFormatter={x=>x.length>20?x.slice(0,19)+'…':x}/><Tooltip formatter={(v,n,p)=>[p.payload.tempo,'Tempo no status']} /><Bar dataKey="horas" maxBarSize={22} radius={[0,5,5,0]}>{chart.map(x=><Cell key={x.id} fill={colors[x.status]||'#7143bf'}/>)}</Bar></BarChart></ResponsiveContainer></div><p className="kanban-note">Base: última mudança registrada no histórico. Quando não há mudança registrada, o cálculo parte da criação do registro (estimativa).</p></>:<p className="kanban-empty">Nenhum registro para analisar.</p>}</section>
}