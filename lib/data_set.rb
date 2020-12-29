# frozen_string_literal: true

require_relative 'dimension'
require_relative 'space'

class DataSet
  attr_accessor :data, :target

  def initialize(size, space)
    @data, @target = size.times.reduce([[], []]) do |output|
      output[0].append space.random
      output[1].append space.labels.random
      output
    end
  end
end
