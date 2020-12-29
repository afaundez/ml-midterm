# frozen_string_literal: true

require_relative 'matrix'

class Dimension
  attr_accessor :values, :pdf

  def initialize(size, pdf: nil)
    @values = (0...size).collect { |v| v }
    @pdf = pdf.nil? ? Dimension.build_pdf(size) : pdf
  end

  def size
    @values.size
  end

  def cdf
    Vector.elements @pdf.inject([0]) { |cdf, pr| cdf << cdf.last + pr }
                        .slice(1..-1)
  end

  def random(x_ = nil)
    x = x_ || rand
    return 0 if x < cdf.first

    (cdf.size - 1).times do |i|
      return i + 1 if (cdf[i]..cdf[i + 1]).cover? x
    end
  end

  def self.build_pdf(size)
    numbers = size.times.collect { rand }
    # numbers = size.times.collect { 1.0 / size }
    vector = Vector.elements numbers
    vector / vector.sum
  end
end
