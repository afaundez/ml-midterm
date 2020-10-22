# frozen_string_literal: true

require 'matrix'
require_relative 'dimension'
require_relative 'space'
require_relative 'data_set'

class_min_cardinality = 2
class_max_cardinality = 2
class_cardinality = rand class_min_cardinality..class_max_cardinality
class_dimension = Dimension.new class_cardinality, distribution: :random

measurements_size = rand 5..5
measurements_min_cardinality = 5
measurements_max_cardinality = 5
measurements_dimensions = (0...measurements_size).collect do
  measurement_cardinality = rand measurements_min_cardinality..measurements_max_cardinality
  Dimension.new measurement_cardinality, distribution: :random
end

space = Space.new class_dimension, measurements_dimensions

puts "classes:\t#{space.classes}"
puts "dimensions:\t#{space.dimensions.collect(&:values)}"
puts "addresses:\t#{space.addresses.size}"

sample_size = space.addresses.size * 10
iterations = 2
delta = 0.025
puts "samples:\t#{sample_size}"
puts "iterations:\t#{iterations}"
puts "delta:\t\t#{delta}"

economic_gain_matrix = Matrix.identity space.classes.size

class Matrix
  def pretty_print
    width = self.collect(&:to_s).collect(&:size).max + 2
    puts '+' + '-' * self.row(0).size * width + '+'
    puts self.to_a.collect { |vector| vector.collect { |value| value.to_s.rjust(width) }.prepend('|').append('|').join  }
    puts '+' + '-' * self.row(0).size * width + '+'
  end
end
puts 'Economic Gain Matrix'
economic_gain_matrix.pretty_print

train_sets = (0...iterations).collect { DataSet.new sample_size, space }
test_set = DataSet.new sample_size, space

train_sets.each_with_index do |train_set, iteration|
  train_set.space = space
  _, expected_gain, confusion_matrix = train_set.train economic_gain_matrix
  space, accuracy = train_set.improve delta
  print "Train\t#{iteration}.\tExpected Gain: #{expected_gain}\t"
  puts "Confusion Matrix Trace: #{confusion_matrix.trace}\tAccuracy: #{accuracy}"
end

test_set.space = space
_, expected_gain, confusion_matrix = test_set.train economic_gain_matrix
puts 'Confusion Matrix'
puts confusion_matrix.pretty_print
space, accuracy = test_set.improve delta
print "Test\t\t\tExpected Gain: #{expected_gain}\t"
puts "Confusion Matrix Trace: #{confusion_matrix.trace}\tAccuracy: #{accuracy}"
