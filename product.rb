require 'open-uri'
require 'nokogiri'

url = 'https://xapostore.com.br/produtos/corta-vento-italia/?variant=512769707'
puts url

doc = Nokogiri::HTML(URI.open(url, {'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36'}))

product = {
  category: doc.xpath('//a[@class="crumb"]')[1..].map { |el| el.text }.join(' > '),
  title: doc.xpath('//h1').text,
  price: doc.xpath('//h2[contains(@class, "js-price-display")]').text.tr('R$', '').tr(',', '.').to_f,
  sizes: doc.xpath('//form[@id="product_form"]/div/div[contains(@class, "js-product-variants-group")]').find { |el| el.text =~ /tamanho/i }.xpath('.//option').map(&:text),
  images: doc.xpath('//a[contains(@class, "js-product-thumb")]/img[@data-srcset]').map { |el| el.attribute('data-srcset').value.split(',').last.strip.split(' ').first }
}

puts product
