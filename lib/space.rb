# frozen_string_literal: true

require_relative 'dimension'

class Space
  attr_accessor :labels, :dimensions

  def random
    dimensions.map { |dimension| dimension.random }
  end

  def size
    @dimensions.map(&:size)
               .reduce(1, :*)
  end

  def address(measurement)
    jumps = @dimensions.collect(&:size)
                       .inject([1]) { |memo, size| memo << memo.last * size }
                       .take(@dimensions.size)
    jumps.zip(measurement)
         .collect { |j, dn| j * dn }
         .sum
  end
end
