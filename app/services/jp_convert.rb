require 'natto'
require 'shellwords'

class JpConvert
  def self.to_hiragana(text)
    nm = Natto::MeCab.new
    normalized_text = normalize_text(text)
    result = []

    normalized_text.split(' ').each do |word|
      word_result = ''
      nm.parse(word) do |n|
        next if n.surface == "*" || n.is_eos?
  
        features = n.feature.split(',')
        reading = features[7] || n.surface
        word_result += katakana_to_hiragana(reading)
      end
      result << word_result
    end
  
    result.join(' ')
  end

  def self.normalize_text(text)
    `echo #{Shellwords.escape(text)} | nkf -w -W`.strip
  end

  def self.katakana_to_hiragana(text)
    text.tr('ァ-ン', 'ぁ-ん')
  end
end