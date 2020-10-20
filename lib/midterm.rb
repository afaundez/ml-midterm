# frozen_string_literal: true

require 'matrix'
require_relative 'dimension'
require_relative 'space'
require_relative 'data_set'

class_min_cardinality = 2
class_max_cardinality = 2
class_cardinality = rand class_min_cardinality..class_max_cardinality
class_dimension = Dimension.new class_cardinality

measurements_size = rand 5..5
measurements_min_cardinality = 5
measurements_max_cardinality = 5
measurements_dimensions = (0...measurements_size).collect do
  measurement_cardinality = rand measurements_min_cardinality..measurements_max_cardinality
  Dimension.new measurement_cardinality
end

space = Space.new class_dimension, measurements_dimensions

puts "classes:\t#{space.classes}"
puts "dimensions:\t#{space.dimensions.collect(&:values)}"
puts "addresses:\t#{space.addresses.size}"

sample_size = space.addresses.size / 100
iterations = 200
delta = 0.025
puts "samples:\t#{sample_size}"
puts "iterations:\t#{iterations}"
puts "delta:\t\t#{delta}"

economic_gain_matrix = Matrix.identity space.classes.size
iterations.times do |iteration|
  data_set = DataSet.new sample_size, space
  _, expected_gain, confusion_matrix = data_set.train economic_gain_matrix
  space, accuracy = data_set.improve delta
  print "#{iteration}.\tExpected Gain: #{expected_gain}\t"
  puts "Confusion Matrix Trace: #{confusion_matrix.trace}\tAccuracy: #{accuracy}"
end
