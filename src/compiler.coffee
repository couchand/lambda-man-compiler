# compiler

class Compiler
  constructor: ->

  compile: (node) ->
    scope = {}
    instructions = []

    switch on
      when Array.isArray node
        for n in node
          instructions = instructions.concat @compile n

      when not not node.fn
        switch node.fn.symbol
          when '+'
            for param in node.params[0..1]
              instructions = instructions.concat @compile param
            instructions.push "ADD"
          when '-'
            for param in node.params[0..1]
              instructions = instructions.concat @compile param
            instructions.push "SUB"
          when '*'
            for param in node.params[0..1]
              instructions = instructions.concat @compile param
            instructions.push "MUL"
          when '/'
            for param in node.params[0..1]
              instructions = instructions.concat @compile param
            instructions.push "DIV"
          when '='
            for param in node.params[0..1]
              instructions = instructions.concat @compile param
            instructions.push "CEQ"
          when '>'
            for param in node.params[0..1]
              instructions = instructions.concat @compile param
            instructions.push "CGT"
          when '>='
            for param in node.params[0..1]
              instructions = instructions.concat @compile param
            instructions.push "CGTE"
          when 'cons'
            for param in node.params[0..1]
              instructions = instructions.concat @compile param
            instructions.push "CONS"
          when 'car'
            instructions = instructions.concat @compile node.params[0]
            instructions.push "CAR"
          when 'cdr'
            instructions = instructions.concat @compile node.params[0]
            instructions.push "CDR"
          when 'list'
            for param in node.params
              instructions = instructions.concat @compile param
            instructions.push "LDC 0"
            instructions.push "CONS" for [0...node.params.length]
          else
            throw new Error "Unknown function " + node.fn.symbol

      when not not node.list
        for elem in node.list
          instructions = instructions.concat @compile elem
        instructions.push "LDC 0"
        instructions.push "CONS" for [0...node.list.length]

      when not not node.tuple
        for elem in node.tuple
          instructions = instructions.concat @compile elem
        instructions.push "CONS" for [0...node.tuple.length - 1]

      when not not node.integer
        instructions.push "LDC #{node.integer}"

      when not not node.symbol
        unless node.symbol of scope
          throw new Error 'unknown symbol: ' + node.symbol

      else
        throw new Error 'unknown node type ' + JSON.stringify node

    instructions.join '\n'

module.exports = Compiler
