# frozen_string_literal: true

require_relative '../dsl/enumerable'

# A maeasurement space
class Space
  include Enumerable

  attr_accessor :dimensions

  def initialize(dimensions)
    @dimensions = dimensions
  end

  def each(&block)
    @dimensions.each(&block)
  end

  def random
    map(&:random)
  end

  def sizes
    collect(&:size)
  end

  def size
    sizes.reduce :*
  end

  def cardinality
    @dimensions.size
  end

  def address(measurement)
    sizes.inject([1]) { |jumps, size| jumps << size * jumps.last }
         .take(cardinality)
         .zip(measurement)
         .sum { |jump, measurement_value| jump * measurement_value }
  end

  def summary(tags: nil, prefix: '')
    'no tags' if tags

    puts prefix + "#{@dimensions.size} measurements with cardinalities #{@dimensions.collect(&:size)} each"
  end
end
