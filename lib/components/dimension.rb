# frozen_string_literal: true

require_relative '../dsl/enumerable'

# A classification or measurement
class Dimension
  include Enumerable

  attr_accessor :values

  def initialize(values)
    @values = values
  end

  def each(&block)
    @values.each(&block)
  end

  def random
    rand 0...size
  end

  def size
    count
  end

  def summary(tags: nil, prefix: '')
    'no tags' if tags

    puts prefix + "#{size} labels"
  end
end
