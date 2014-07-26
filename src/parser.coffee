# parser

class Parser
  constructor: (input) ->
    @input = input
    @stack = []

  parse: ->
    statements = []

    until @input.isDone()
      token = @input.getToken()
      console.log 'next token', token

      switch token
        when ')'
          params = []
          console.log 'rewinding', @stack

          until @stack.length is 0
            param = @stack.pop()

            console.log 'rexamining', param

            break if param is '('
            continue if param is ','

            unless /[(,]/.test @stack[-1..][0]
              throw new Error 'Too much input found: missing comma? missing paren?'

            params.unshift param

          unless param is '('
            throw new Error 'Unmatched paren'

          fn = @stack.pop()

          @stack.push {fn, params}

        when ']'
          elements = []
          type = no

          until @stack.length is 0
            elem = @stack.pop()

            break if elem is '['
            if /[,.]/.test elem
              type = elem
              continue

            unless /[\[,.]/.test @stack[-1..][0]
              throw new Error 'Too much input found: missing comma? missing bracket?'

            elements.unshift elem

          unless elem is '['
            throw new error 'Unmatched bracket'

          switch type
            when ','
              @stack.push list: elements
            when '.'
              @stack.push tuple: elements
            else
              throw new Error 'Unknown delimiter'

        when '\n'
          console.log 'new', @stack.length
          if @stack.length is 1 and not /^[\[(,.]$/.test @stack[0]
            console.log 'push'
            statements.push @stack.pop()
          console.log 'newline', @stack, token, statements

        else
          console.log token
          switch on
            when /^[0-9]+$/.test token
              @stack.push integer: parseInt token, 10
            when /^[a-z+*/=>-]+$/.test token
              @stack.push symbol: token
            else
              console.log 'pushing plain', token
              @stack.push token

    console.log @stack

    unless @stack.length <= 1
      throw new Error 'Too much input found: missing comma? missing paren?'

    if @stack.length
      statements.push @stack.pop()

    unless statements.length
      throw new Error 'no input found'

    statements

module.exports = Parser
