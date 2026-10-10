import test from 'node:test'
import assert from 'node:assert/strict'
import {statusAge, statusAgeChart} from '../src/lib/status.js'

const created = {id:'a', titulo:'Proposta A', status:'Enviada', criado_em:'2026-10-01T12:00:00Z'}

test('sem mudanças usa data de criação',()=>{
  assert.equal(statusAge(created,'propostas',[],new Date('2026-10-02T12:00:00Z')).hours,24)
})

test('considera última mudança real para o status atual',()=>{
  const history=[
    {entidade:'propostas',registro_id:'a',descricao:'Status: Rascunho → Enviada',criado_em:'2026-10-03T00:00:00Z'},
    {entidade:'propostas',registro_id:'a',descricao:'Status: Enviada → Enviada',criado_em:'2026-10-04T00:00:00Z'},
    {entidade:'clientes',registro_id:'a',descricao:'Status: x → Enviada',criado_em:'2026-10-04T00:00:00Z'}
  ]
  assert.equal(statusAge(created,'propostas',history,new Date('2026-10-04T00:00:00Z')).hours,24)
})

test('retorno ao status anterior usa última entrada',()=>{
  const history=[
    {entidade:'propostas',registro_id:'a',descricao:'Status: Rascunho → Enviada',criado_em:'2026-10-01T15:00:00Z'},
    {entidade:'propostas',registro_id:'a',descricao:'Status: Enviada → Rascunho',criado_em:'2026-10-01T17:00:00Z'},
    {entidade:'propostas',registro_id:'a',descricao:'Status: Rascunho → Enviada',criado_em:'2026-10-02T00:00:00Z'}
  ]
  assert.equal(statusAge(created,'propostas',history,new Date('2026-10-02T03:00:00Z')).hours,3)
})

test('gráfico ordena por maior tempo na etapa',()=>{
  const list=[created,{id:'b',titulo:'Proposta B',status:'Enviada',criado_em:'2026-09-30T12:00:00Z'}]
  assert.equal(statusAgeChart(list,'propostas',[],new Date('2026-10-02T12:00:00Z'))[0].id,'b')
})
