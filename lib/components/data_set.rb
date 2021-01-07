# frozen_string_literal: true

require_relative 'dimension'
require_relative 'space'

# A dataset, data and target
class DataSet
  attr_accessor :data, :target

  def initialize(size = nil, space = nil, labels = nil, conditionals: nil, conditional_direction: :column, datasets: nil)
    if size && space && labels
      @data = []
      @target = []
      size.times do
        measurement = space.random
        @data << measurement
        address = space.address measurement
        pmf = conditionals ? conditionals.send(conditional_direction, address) : nil
        label = labels.random pmf
        @target << label
      end
    elsif datasets
      @data = datasets.collect(&:data).flatten 1
      @target = datasets.collect(&:target).flatten 1
    end
  end

  def size
    @data.size
  end

  def summary(tags: nil, prefix: '')
    'no tags' if tags

    puts prefix + "Dataset: #{@data.size} (rows)"
  end

  def to_s
    "<DataSet data.size: #{@data.size} target.size: #{@target.size}>"
  end
end
