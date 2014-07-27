# compile

Parser = require './parser'
Compiler = require './compiler'
Tokenizer = require './tokenizer'

module.exports = (input, cwd) ->
  p = new Parser new Tokenizer input
  c = new Compiler {cwd}
  c.compile p.parse()
