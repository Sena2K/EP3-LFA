class JsonParser
  attr_reader :stack, :result

  def initialize
    @stack = []
    @result = nil
    @last_key = nil # para armazenar a última chave encontrada
  end

  def parse(json_string)
    tokens = tokenize(json_string)
    context = []

    tokens.each do |token|
      case token
      when '{', '['
        @stack.push(token)
        new_container = token == '{' ? {} : []
        if context.empty?
          @result = new_container
        else
          add_to_context(context.last, new_container)
        end
        context.push(new_container)
      when '}', ']'
        raise "Invalid JSON: Mismatched brackets or braces ;-;" unless matches?(@stack.pop, token)
        context.pop
      when ':'
        next # apenas segue para o próximo token
      when ','
        @last_key = nil # resetar a chave após um par chave-valor ser adicionado
      else
        if context.last.is_a?(Hash) && @last_key.nil?
          @last_key = parse_value(token) # armazenar a chave temporariamente
        else
          add_to_context(context.last, parse_value(token))
        end
      end
    end

    raise "Invalid JSON: Unmatched brackets or braces ;-;" unless @stack.empty?
    @result
  end

  private

  def tokenize(json_string)
    json_string.scan(/[\{\}\[\]]|"(?:\\.|[^"\\])*"|\d+\.?\d*|true|false|null|[:\,]/)
  end

  def parse_value(token)
    case token
    when /^"(.*)"$/
      $1.gsub(/\\"/, '"')
    when 'true', 'false'
      token == 'true'
    when 'null'
      nil
    else
      token.to_f % 1 == 0 ? token.to_i : token.to_f
    end
  end

  def add_to_context(context, value)
    if context.is_a?(Array)
      context.push(value)
    elsif @last_key
      context[@last_key] = value
      @last_key = nil # resetar a chave após adicionar o par chave-valor
    end
  end

  def matches?(opening, closing)
    (opening == '{' && closing == '}') || (opening == '[' && closing == ']')
  end
end

# Exemplo de uso
begin
  json_input = '{
  "nome": "Fulano de Tal",
  "idade": 30,
  "endereço": {
    "rua": "Rua Principal",
    "cidade": "São Paulo",
    "estado": "SP"
  },
  "habilidades": [
    "programação",
    "design gráfico"
  ],
  "historico_educacional": [
    {
      "tipo": "ensino médio",
      "instituição": "Escola Estadual XYZ",
      "ano_conclusão": 2010
    },
    {
      "tipo": "graduação",
      "instituição": "Universidade ABC",
      "ano_conclusão": 2015
    }
  ],
  "projetos": [
    [
      {
        "nome": "Projeto A",
        "descricao": "Desenvolvimento de uma aplicação web."
      },
      {
        "nome": "Projeto B",
        "descricao": "Criação de um app móvel."
      }
    ],
    [
      {
        "nome": "Projeto C",
        "descricao": "Análise de dados."
      },
      {
        "nome": "Projeto D",
        "descricao": "Desenvolvimento de um sistema de recomendação."
      }
    ]
  ]
}
'
  parser = JsonParser.new
  parsed_json = parser.parse(json_input)
  puts "Valid JSON"
  puts parsed_json
  puts parsed_json['habilidades']
  puts parsed_json['habilidades'][0]
rescue RuntimeError => e
  puts "Invalid JSON: #{e.message}"
end
