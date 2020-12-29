# frozen_string_literal: true

require_relative 'matrix'

class Dimension
  attr_accessor :values

  def initialize(values)
    @values = values
  end

  def random
    rand 0...values.size
  end

  def size
    @values.size
  end
end
