# compiler

fs = require 'fs'
path = require 'path'

Scope = require './scope'
Parser = require './parser'
Tokenizer = require './tokenizer'

MAX_INSTRUCTION_COUNT = 1048576

argv = (d) ->
  "LD 0 #{d}"

checkCell = (d) ->
  """
    LDC #{d}
    LD 0 0
    CEQ
    RTN
  """.split '\n'

class Compiler
  constructor: (opts={}) ->
    @subroutines = []
    @cwd = opts.cwd or __dirname

  addSubroutine: (subroutine) ->
    @subroutines.push subroutine
    @subroutines.length - 1

  compile: (program) ->
    instructions = @_compile program
    instructions.push 'RTN'
    counter = instructions.length
    obj = instructions.join '\n'

    refs = {}
    subs = for index, instructions of @subroutines
      refs["sub#{index}"] = counter
      counter += instructions.length
      instructions.join '\n'

    for name, location of refs
      console.log "relocating", name, "to", location
      obj = obj.replace new RegExp("<%#{name}%>", 'g'), location
      subs = for sub in subs
        sub = sub.replace new RegExp("<%#{name}%>", 'g'), location

    if counter > MAX_INSTRUCTION_COUNT
      throw new Error 'Exceeded max instruction count'

    obj + '\n' + subs.join('\n')

  _compile: (node, scope) ->
    console.log "compiling", node, "in scope", scope

    instructions = []

    unless scope?
      scope = new Scope()

    switch on
      when Array.isArray node
        for n in node
          instructions = instructions.concat @_compile n, scope

      when node.fn?
        switch node.fn.symbol
          when '+'
            if node.params.length isnt 2
              throw new Error 'airity mismatch, expecting 2, got '+ node.params.length
            for param in node.params[0..1]
              instructions = instructions.concat @_compile param, scope
            instructions.push "ADD"
          when '-'
            if node.params.length isnt 2
              throw new Error 'airity mismatch, expecting 2, got '+ node.params.length
            for param in node.params[0..1]
              instructions = instructions.concat @_compile param, scope
            instructions.push "SUB"
          when '*'
            if node.params.length isnt 2
              throw new Error 'airity mismatch, expecting 2, got '+ node.params.length
            for param in node.params[0..1]
              instructions = instructions.concat @_compile param, scope
            instructions.push "MUL"
          when '/'
            if node.params.length isnt 2
              throw new Error 'airity mismatch, expecting 2, got '+ node.params.length
            for param in node.params[0..1]
              instructions = instructions.concat @_compile param, scope
            instructions.push "DIV"
          when '='
            if node.params.length isnt 2
              throw new Error 'airity mismatch, expecting 2, got '+ node.params.length
            for param in node.params[0..1]
              instructions = instructions.concat @_compile param, scope
            instructions.push "CEQ"
          when '>'
            if node.params.length isnt 2
              throw new Error 'airity mismatch, expecting 2, got '+ node.params.length
            for param in node.params[0..1]
              instructions = instructions.concat @_compile param, scope
            instructions.push "CGT"
          when '>='
            if node.params.length isnt 2
              throw new Error 'airity mismatch, expecting 2, got '+ node.params.length
            for param in node.params[0..1]
              instructions = instructions.concat @_compile param, scope
            instructions.push "CGTE"
          when 'cons'
            if node.params.length isnt 2
              throw new Error 'airity mismatch, expecting 2, got '+ node.params.length
            for param in node.params[0..1]
              instructions = instructions.concat @_compile param, scope
            instructions.push "CONS"
          when 'car'
            if node.params.length isnt 1
              throw new Error 'airity mismatch, expecting 1, got '+ node.params.length
            instructions = instructions.concat @_compile node.params[0], scope
            instructions.push "CAR"
          when 'cdr'
            if node.params.length isnt 1
              throw new Error 'airity mismatch, expecting 1, got '+ node.params.length
            instructions = instructions.concat @_compile node.params[0], scope
            instructions.push "CDR"
          when 'atom'
            if node.params.length isnt 1
              throw new Error 'airity mismatch, expecting 1, got '+ node.params.length
            instructions = instructions.concat @_compile node.params[0], scope
            instructions.push "ATOM"
          when 'list'
            for param in node.params
              instructions = instructions.concat @_compile param, scope
            instructions.push "LDC 0"
            instructions.push "CONS" for [0...node.params.length]
          when 'require'
            console.log 'require', node
            name = node.params[0].string
            name += '.lmb' unless /\.lmb$/.test name
            f = path.join @cwd, name
            unless fs.existsSync f
              throw new Error 'unable to locate require ' + f
            fc = fs.readFileSync f
            parser = new Parser new Tokenizer fc.toString()
            body = @_compile parser.parse()
            guid = @addSubroutine body.concat ['RTN']
            instructions.push "LDF <%sub#{guid}%>"
          when 'let'
            console.log 'entering let', scope, node
            child = scope.child()
            for pair in node.params[0].list
              console.log 'compiling child', pair
              instructions = instructions.concat @_compile pair.tuple[1], child
              child.add pair.tuple[0]
            body = @_compile node.params[1], child
            guid = @addSubroutine body.concat ['RTN']
            instructions.push "LDF <%sub#{guid}%>"
            instructions.push "AP #{node.params[0].list.length}"
            console.log 'let', child, body, @subroutines, guid, instructions
          when 'letrec'
            console.log 'entering letrec', scope, node
            child = scope.child()
            instructions.push "DUM #{node.params[0].list.length}"
            for pair in node.params[0].list
              console.log 'compiling child', pair
              child.add pair.tuple[0]
              instructions = instructions.concat @_compile pair.tuple[1], child
            body = @_compile node.params[1], child
            guid = @addSubroutine body.concat ['RTN']
            instructions.push "LDF <%sub#{guid}%>"
            instructions.push "RAP #{node.params[0].list.length}"
            console.log 'letrec', child, body, @subroutines, guid, instructions
          when 'if'
            consequentBody = @_compile node.params[1], scope
            alternateBody = @_compile node.params[2], scope
            consequent = @addSubroutine consequentBody.concat ['JOIN']
            alternate = @addSubroutine alternateBody.concat ['JOIN']
            instructions = instructions.concat @_compile node.params[0], scope
            instructions.push "SEL <%sub#{consequent}%> <%sub#{alternate}%>"
          when 'argv'
            instructions.push argv node.params[0].integer
          when 'debug'
            if node.params.length isnt 1
              throw new Error 'airity mismatch, expecting 1, got '+ node.params.length
            instructions = instructions.concat @_compile node.params[0], scope
            instructions.push "DBUG"

          else
            index = scope.indexOf node.fn.symbol
            console.log node.fn.symbol, scope

            if index is -1
              throw new Error "Unknown function " + node.fn.symbol
            else
              console.log 'found', node.fn.symbol, index
              for param in node.params
                instructions = instructions.concat @_compile param, scope
              instructions.push "LD #{index[0]} #{index[1]}"
              instructions.push "AP #{node.params.length}"

      when node.closure?
        child = scope.child()
        for param in node.parameters
          console.log 'considering param', param
          child.add param
        console.log 'child scope', child
        body = @_compile node.closure, child
        guid = @addSubroutine body.concat ['RTN']
        instructions.push "LDF <%sub#{guid}%>"

      when node.list?
        for elem in node.list
          instructions = instructions.concat @_compile elem, scope
        instructions.push "LDC 0"
        instructions.push "CONS" for [0...node.list.length]

      when node.tuple?
        for elem in node.tuple
          instructions = instructions.concat @_compile elem, scope
        instructions.push "CONS" for [0...node.tuple.length - 1]

      when node.integer?
        instructions.push "LDC #{node.integer}"

      when node.symbol?
        index = scope.indexOf node.symbol
        console.log node.symbol, scope
        if index is -1
          throw new Error 'unknown symbol: ' + node.symbol
        else
          instructions.push "LD #{index[0]} #{index[1]}"

      else
        console.log node, @stack, scope, node.integer
        throw new Error 'unknown node type ' + JSON.stringify node

    instructions

module.exports = Compiler
