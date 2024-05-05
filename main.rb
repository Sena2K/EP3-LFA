class JSONParser
  def initialize(json)
    @json = json.strip
    @index = 0
    @stack = []
  end

  def parse
    analisar_valor
  end

  private

  def analisar_valor
    pular_espaco
    case @json[@index]
    when '{' then analisar_objeto
    when '[' then analisar_array
    when '"' then analisar_string
    when 't', 'f' then analisar_booleano
    when 'n' then analisar_nulo
    when '-', '0'..'9' then analisar_numero
    else
      raise "Caractere inesperado #{@json[@index]}"
    end
  end

  def analisar_objeto
    @stack.push({})
    @index += 1  # Pula {
    pular_espaco
    unless @json[@index] == '}'
      loop do
        chave = analisar_string
        pular_espaco
        raise "Esperado ':'" unless @json[@index] == ':'
        @index += 1  # Pula :
        valor = analisar_valor
        @stack.last[chave] = valor
        pular_espaco
        break if @json[@index] == '}'
        raise "Esperado ',' ou '}'" unless @json[@index] == ','
        @index += 1  # Pula ,
        pular_espaco
      end
    end
    @index += 1  # Pula }
    @stack.pop
  end

  def analisar_array
    array = []
    @stack.push(array)
    @index += 1  # Pula [
    pular_espaco
    unless @json[@index] == ']'
      loop do
        array << analisar_valor
        pular_espaco
        break if @json[@index] == ']'
        raise "Esperado ',' ou ']'" unless @json[@index] == ','
        @index += 1  # Pula ,
        pular_espaco
      end
    end
    @index += 1  # Pula ]
    @stack.pop
  end

  def analisar_string
    raise "Esperado '\"'" unless @json[@index] == '"'
    @index += 1  # Pula "
    start = @index
    while @json[@index] != '"'
      if @json[@index] == '\\'
        @index += 1  
      end
      @index += 1
    end
    value = @json[start...@index]
    @index += 1  # Pula aspas de fechamento '"'
    value
  end

  def analisar_numero
    start = @index
    @index += 1 while @json[@index] =~ /[0-9+\-.]/
    number = @json[start...@index]
    Integer(number) rescue Float(number)
  end

  def analisar_booleano
    if @json[@index, 4] == 'true'
      @index += 4
      true
    elsif @json[@index, 5] == 'false'
      @index += 5
      false
    else
      raise "Esperado 'true' ou 'false'"
    end
  end

  def analisar_nulo
    raise "Esperado 'null'" unless @json[@index, 4] == 'null'
    @index += 4
    nil
  end

  def pular_espaco
    @index += 1 while @json[@index] =~ /\s/
  end
end

def formatar_saida(data, indent = 0)
  if data.is_a?(Hash)
    data.each do |key, value|
      puts "#{' ' * indent}#{key}:"
      formatar_saida(value, indent + 2)
    end
  elsif data.is_a?(Array)
    data.each do |item|
      formatar_saida(item, indent + 2)
    end
  else
    puts "#{' ' * indent}#{data.inspect}"
  end
end

json_teste = '{
  "nome": "Empresa Exemplo",
  "ano_fundacao": 1997,
  "ativo": true,
  "departamentos": [
    {
      "nome": "Desenvolvimento",
      "funcionarios": 25,
      "online": true
    },
    {
      "nome": "Recursos Humanos",
      "funcionarios": 10,
      "online": false
    },
    {
      "nome": "Atendimento ao Cliente",
      "funcionarios": 30,
      "online": true
    }
  ],
  "enderecos": [
    {
      "tipo": "comercial",
      "logradouro": "Rua Principal, 1000",
      "cidade": "São Paulo",
      "estado": "SP",
      "pais": "Brasil"
    },
    {
      "tipo": "industrial",
      "logradouro": "Avenida Secundária, 500",
      "cidade": "Campinas",
      "estado": "SP",
      "pais": "Brasil"
    }
  ],
  "produtos": ["Produto A", "Produto B", "Produto C"],
  "gerentes": [
    {"nome": "Carlos Silva", "idade": 42, "ativo": true},
    {"nome": "Ana Paula", "idade": 37, "ativo": false}
  ],
  "informacoes_adicionais": null
}'

begin
  parser = JSONParser.new(json_teste)
  resultado = parser.parse
  formatar_saida(resultado)
  puts resultado['ano_fundacao']
  puts "JSON válido"
rescue => e
  puts "JSON inválido: #{e.message}"
end
