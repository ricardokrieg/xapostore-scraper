require 'open-uri'
require 'nokogiri'
require 'csv'

def parse_product(url)
  doc = Nokogiri::HTML(URI.open(url, {'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36'}))

  {
    id: doc.text[/product_id":(\d+),/, 1],
    title: doc.xpath('//h1').text,
    category: doc.xpath('//a[@class="crumb"]')[1..].map { |el| el.text }.join(' > '),
    price: doc.xpath('//h2[contains(@class, "js-price-display")]').text.tr('R$.', '').tr(',', '.').to_f,
    sizes: doc.xpath('//form[@id="product_form"]/div/div[contains(@class, "js-product-variants-group")]').find { |el| el.text =~ /tamanho/i }.xpath('.//option').map(&:text),
    images: doc.xpath('//a[contains(@class, "js-product-thumb")]/img[@data-srcset]').map { |el| 'https:' + el.attribute('data-srcset').value.split(',').last.strip.split(' ').first }
  }
end

def product_to_csv(product)
  rows  = []

  categories = [
    product[:category].split(' > ')[0],
    product[:category].split(' > ')[1],
    product[:category].split(' > ')[2],
    product[:category].split(' > ')[3],
    product[:category].split(' > ')[4]
  ]
  images = [
    product[:images][0],
    product[:images][1],
    product[:images][2],
    product[:images][3],
    product[:images][4]
  ]
  description = product[:category].start_with?('Camisas Masculina') ? "#{product[:title]} Masculina Versão Torcedor" : product[:title]

  if product[:sizes].empty?
    rows = [
      nil,
      'sem-variacao',
      nil,
      "XP#{product[:id]}",
      'S',
      'N',
      nil,
      nil,
      product[:title],
      description,
      nil,
      'S',
      0,
      'imediata',
      '30 dias',
      'N',
      nil,
      product[:price] > 100 ? product[:price] - 20 : product[:price],
      nil,
      nil,
      nil,
      nil,
      nil,
      nil
    ] + categories + images + [nil] * 13
  else
    rows << [
      nil,
      'com-variacao',
      nil,
      "XP#{product[:id]}",
      'S',
      'N',
      nil,
      nil,
      product[:title],
      description,
      nil,
      nil,
      nil,
      nil,
      nil,
      'N',
      nil,
      nil,
      nil,
      nil,
      nil,
      nil,
      nil,
      nil
    ] + categories + images + [nil] * 13

    product[:sizes].each do |size|
      size = 'XGG' if size == 'XXG'
      grade = product[:category] =~ /infantil/i ? [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, size, nil, nil] : [nil, nil, nil, size, nil, nil, nil, nil, nil, nil, nil, nil, nil]

      rows << [
        nil,
        'variacao',
        "XP#{product[:id]}",
        "XP#{product[:id]}-#{size}",
        'S',
        'N',
        nil,
        nil,
        nil,
        nil,
        nil,
        'S',
        0,
        'imediata',
        '30 dias',
        'N',
        nil,
        product[:price] > 100 ? product[:price] - 20 : product[:price],
        nil,
        nil,
        nil,
        nil,
        nil,
        nil
      ] + [nil] * 10 + grade
    end
  end

  rows
end

(1..20).each do |page|
  url = "https://xapostore.com.br/produtos/page/#{page}/?limit=100&theme=amazonas"
  puts "Page ##{page} (#{url})"

  doc = Nokogiri::HTML(URI.open(url, {'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36'}))

  if doc.text =~ /Não temos produtos com estas variações. Por favor, tente com outros filtros/
    puts "No more products"
    break
  end

  CSV.open("page#{page}.csv", 'w') do |csv|
    csv << [
      'id',
      'tipo',
      'sku-pai',
      'sku',
      'ativo',
      'usado',
      'ncm',
      'gtin',
      'nome',
      'descricao-completa',
      'url-video-youtube',
      'estoque-gerenciado',
      'estoque-quantidade',
      'estoque-situacao-em-estoque',
      'estoque-situacao-sem-estoque',
      'preco-sob-consulta',
      'preco-custo',
      'preco-cheio',
      'preco-promocional',
      'marca',
      'peso-em-kg',
      'altura-em-cm',
      'largura-em-cm',
      'comprimento-em-cm',
      'categoria-nome-nivel-1',
      'categoria-nome-nivel-2',
      'categoria-nome-nivel-3',
      'categoria-nome-nivel-4',
      'categoria-nome-nivel-5',
      'imagem-1',
      'imagem-2',
      'imagem-3',
      'imagem-4',
      'imagem-5',
      'grade-genero',
      'grade-tamanho-de-anelalianca',
      'grade-tamanho-de-calca',
      'grade-tamanho-de-camisacamiseta',
      'grade-tamanho-de-capacete',
      'grade-tamanho-de-tenis',
      'grade-voltagem',
      'grade-tamanho-juvenil-infantil',
      'grade-produto-com-uma-cor',
      'grade-produto-com-duas-cores',
      'grade-tamanho-infantil',
      '',
      'url-antiga'
    ]

    doc.xpath('//div[@data-product-id]').each_with_index do |product, i|
      puts "Product ##{i + 1} of 100"
      product_url = product.xpath('.//a').first.attribute('href').value

      begin
        product = parse_product(product_url)

        puts product
        product_to_csv(product).each do |row|
          csv << row
        end
      rescue => e
        puts "Error: #{e.message}"
      end
    end
  end
end
