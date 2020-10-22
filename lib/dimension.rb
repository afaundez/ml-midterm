# frozen_string_literal: true

require 'matrix'

# Dimension
class Dimension
  attr_accessor :size, :pdf, :cdf, :distribution

  def initialize(size, distribution: :random)
    @size = size
    @distribution = distribution
    @pdf = self.class.build_pdf @size, distribution: @distribution
    @cdf = self.class.build_cdf @pdf
  end

  def values
    @values ||= Vector.elements((0...@size).to_a).to_a
  end

  def random
    self.class.random @cdf
  end

  def self.normalize(vector)
    return vector if vector.zero?

    sum = vector.sum
    return vector if sum == 1
    
    vector / sum
  end

  def self.build_pdf(size, distribution: :random)
    numbers = size.times.collect do
      case distribution
      when :uniform then 1 / size.to_f
      else rand
      end
    end
    vector = Vector.elements numbers
    normalize vector
  end

  def self.build_cdf(pdf)
    Vector.elements pdf.inject([0]) { |cdf, pr| cdf << cdf.last + pr }
                       .slice(1..-1)
  end

  def self.random(cdf)
    x = rand
    return 0 if x < cdf.first

    (cdf.size - 1).times do |i|
      return i + 1 if (cdf[i]..cdf[i + 1]).cover? x
    end
  end
end
