# frozen_string_literal: true

require_relative 'dimension'
require_relative 'space'

# A dataset, data and target
class DataSet
  attr_accessor :data, :target

  def initialize(size, space, labels)
    @data, @target = size.times.reduce([[], []]) do |output|
      output.first.append space.random
      output.last.append labels.random
      output
    end
  end

  def summary(tags: nil, prefix: '')
    'no tags' if tags

    puts prefix + "Dataset: #{@data.size} (rows)"
  end
end
