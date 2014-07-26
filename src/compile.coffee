# compile

Parser = require './parser'
Compiler = require './compiler'
Tokenizer = require './tokenizer'

module.exports = (input) ->
  p = new Parser new Tokenizer input
  c = new Compiler()
  c.compile p.parse()
