import test from 'node:test'
import assert from 'node:assert/strict'
import {proposalSubtotal,proposalTotal,conversionRate} from '../src/lib/business.js'

test('soma itens por quantidade e valor unitário',()=>{
 assert.equal(proposalSubtotal([{quantidade:2,valor_unitario:125},{quantidade:3,valor_unitario:100}]),550)
})
test('descontos diminuem o total',()=>{
 assert.equal(proposalTotal([{quantidade:2,valor_unitario:125}],50),200)
})
test('total de apresentação nunca é negativo',()=>{
 assert.equal(proposalTotal([{quantidade:1,valor_unitario:10}],20),0)
})
test('taxa de conversão conta propostas decididas',()=>{
 assert.equal(conversionRate(3,4),75)
 assert.equal(conversionRate(0,0),0)
})
