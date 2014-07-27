# parser

class Parser
  constructor: (input) ->
    @input = input
    @stack = []

  parse: ->
    statements = []
    awaiting = no

    addStatement = (statement) ->
      console.log 'adding statement', statement

      unless awaiting
        statements.push statement
      else
        statements.push args: awaiting, body: statement
        awaiting = no

    until @input.isDone()
      token = @input.getToken()
      console.log 'next token', token

      switch token
        when ')'
          params = []
          console.log 'rewinding', @stack

          until @stack.length is 0
            param = @stack.pop()

            console.log 'reexamining', param

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
          type = ','

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

        when '}'
          inBody = yes
          params = []
          expressions = []
          console.log 'rewinding block', @stack

          until @stack.length is 0
            expr = @stack.pop()

            console.log 'reexamining', expr

            break if expr is '{'
            continue if expr is ','
            if expr is '|'
              unless inBody
                expr = {params}
              else
                inBody = no
              continue

            unless /[{|,]/.test @stack[-1..][0]
              throw new Error 'Too much input found: missing comma? missing brace?'

            if inBody
              expressions.unshift expr
            else
              params.unshift expr

          unless expr is '{'
            throw new Error 'Unmatched brace'

          @stack.push parameters: params, closure: expressions

        when '=>'
          if awaiting
            throw new Error 'no recursive function defines yet'

          if @stack.length isnt 0 and @stack[-1..][0]?.list
            awaiting = @stack.pop()
          else
            awaiting = list: []

        when '\n'
          console.log 'new', @stack.length
          if @stack.length is 1 and not /^[\[(,.]$/.test @stack[0]
            addStatement @stack.pop()
          console.log 'newline', @stack, token, statements

        else
          console.log token
          switch on
            when /^[0-9]+$/.test token
              @stack.push integer: parseInt token, 10
            when /^[a-zA-Z+*/=>-]+$/.test token
              @stack.push symbol: token
            when /^['"]/.test token
              @stack.push string: token[1...-1]
            else
              console.log 'pushing plain', token
              @stack.push token

    console.log @stack

    unless @stack.length <= 1
      throw new Error 'Too much input found: missing comma? missing paren?'

    if @stack.length
      addStatement @stack.pop()

    unless statements.length
      throw new Error 'no input found'

    statements

module.exports = Parser
