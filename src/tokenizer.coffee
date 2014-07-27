# tokenizer

class Tokenizer
  constructor: (str) ->
    @value = str

  isDone: ->
    @value.length is 0

  getToken: ->
    token = @value.replace /^[ \t]+/, ''
    @value = ''

    index = -1
    for i, char of token when /[\n#(){}|\[\],.]/.test char
      index = +i
      break

    if 0 is index
      @value = token[1..]
      token = token[0]
      return token if token is '\n'
      if token is '#'
        @value = @value.replace /^[^\n]+/, ''
        return @getToken()
    else unless -1 is index
      @value = token[index..]
      token = token[...index]

    console.log "1 '#{token}'"
    token = token.replace /^[ \t]+/, ''
    console.log "2 '#{token}'"
    token = token.replace /[ \t]+$/, ''
    console.log "3 '#{token}'"
    token

module.exports = Tokenizer
