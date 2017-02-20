# frozen_string_literal: true
class Corrasable
  attr_reader :text, :response

  ENDPOINT = 'https://api.corrasable.com/phonemes'

  class << self
    def cast(text, response)
      response
        .flatten(1) # Flatten outer array since we have no concept of lines
        .map { |word| word.split(' ') } # Split each word into an array of phonemes
        .zip(text.split(' '))
        .map do |phonemes, word|
          # Cast the word/phonemes, include a pause
          [Word.new(word, phonemes), Word.new(' ', [' '])]
        end
        .flatten
    end

    def sanitize(string)
      string.to_s
        .gsub(/[^a-z ]/i, '') # Avoid punctuation and numbers for the time being
    end
  end

  def initialize(text)
    @text = self.class.sanitize(text)
  end

  def request
    Typhoeus::Request.new(ENDPOINT,
      method: :post,
      params: {
        text: text
      }
    )
  end

  def get
    @response ||= Cached.get(CGI.escape request.url) do
      request.run.body
    end

    Oj.load response
  end

  def to_words
    self.class.cast(text, get)
  end
end
