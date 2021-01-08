# frozen_string_literal: true

require_relative '../dsl/matrix'
require_relative '../dsl/enumerable'
require_relative 'dimension'

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

  def marginal(measurement_or_address)
    measurement = if measurement_or_address.is_a? Enumerable
      measurement_or_address
    else
      measurement measurement_or_address
    end
    @dimensions.zip(measurement)
               .map { |dimension, value| dimension.marginal value }
               .reduce(:*)
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

  def measurement(address)
    sizes.inject([1]) { |jumps, size| jumps << size * jumps.last }
         .take(cardinality)
         .reverse
         .inject([[], address]) do |(measurement, remainder), jump|
            measurement.insert(0, remainder / jump)
            remainder %= jump
            [measurement, remainder]
          end.first
  end

  def summary(tags: nil, prefix: '')
    'no tags' if tags

    puts prefix + "#{@dimensions.size} measurements with cardinalities #{@dimensions.collect(&:size)} each"
  end
end
