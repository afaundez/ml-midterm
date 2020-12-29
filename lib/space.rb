# frozen_string_literal: true

require_relative 'dimension'

class Space
  attr_accessor :dimensions, :addresses

  def initialize(dimensions)
    @dimensions = dimensions.map { |values| Dimension.new values.size }
    size = @dimensions.map { |dimension| dimension.size }.inject(:*)
    @addresses = (0...size).to_a
  end

  def address(vector)
    jumps = dimensions.collect(&:size)
                      .inject([1]) { |memo, size| memo << memo.last * size }
                      .take(@dimensions.size)
    jumps.zip(vector)
         .collect { |j, dn| j * dn }
         .sum
  end

  def size
    addresses.size
  end

  def random(x = nil)
    @dimensions.map { |dimension| dimension.random x }
  end
end
