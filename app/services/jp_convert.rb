require 'natto'

class JpConvert
  def self.to_hiragana(text)
    nm = Natto::MeCab.new
    result = ''

    nm.parse(text) do |n|
      next if n.surface == "*" || n.is_eos?
      
      features = n.feature.split(',')
      reading = features[7] || n.surface
      result += reading.tr('ァ-ン', 'ぁ-ん')
    end

    result
  end
end