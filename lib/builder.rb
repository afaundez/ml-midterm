# frozen_string_literal: true

require 'matrix'
require_relative 'dimension'
require_relative 'space'
require_relative 'matrix'
require_relative 'data_set'

def build_space_from_options(options)
  class_min_cardinality = options.class_cardinality
  class_max_cardinality = options.class_cardinality
  class_cardinality = rand class_min_cardinality..class_max_cardinality
  class_dimension = Dimension.new class_cardinality, distribution: options.distribution

  measurements_size = options.measurements_size
  measurement_min_cardinality = options.measurement_min_cardinality
  measurement_max_cardinality = options.measurement_max_cardinality
  measurements_dimensions = (0...measurements_size).collect do
    measurement_cardinality = rand measurement_min_cardinality..measurement_max_cardinality
    Dimension.new measurement_cardinality, distribution: options.distribution
  end

  space = Space.new class_dimension, measurements_dimensions
  puts "classes:\t#{space.classes}"
  puts "dimensions:\t#{space.dimensions.collect(&:values)}"
  puts "addresses:\t#{space.addresses.size}"
  space
end

def build_data_sets_from_options_and_space(options, space)
  sample_size = options.sample_size || (space.addresses.size * 10)
  iterations = options.iterations
  puts "samples:\t#{sample_size}"
  puts "iterations:\t#{iterations}"

  train_sets = (0...iterations).collect { DataSet.new sample_size, space, overlap: options.overlap }
  test_set = DataSet.new sample_size, space, overlap: options.overlap
  [train_sets, test_set]
end

def build_economic_gain_matrix(type, size)
  matrix = Matrix.identity size
  puts 'Economic Gain Matrix'
  matrix.pretty_print
  matrix
end
