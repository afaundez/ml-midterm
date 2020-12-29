require 'matrix'
require_relative 'matrix'
require_relative 'dimension'
require_relative 'space'

class Classifier
  attr_accessor :space

  def initialize(space)
    @space = space
    @priors = Vector.zero @space.labels.size
    @likelihoods = Matrix.zero @priors.size, @space.size
  end

  def fit(data:, target:)
    @data, @target = data, target
    @priors = process_priors
    @likelihoods = process_likelihoods
    @posteriors = compute_posteriors
    @economic_gain_matrix = Matrix.identity @space.labels.size
    @bayes_rules = compute_bayes_rules
    @confusion_matrix = compute_confusion_matrix
    @expected_gain_matrix = compute_expected_gain_matrix
  end

  def predict(measurement_or_measurements)
    if measurement_or_measurements.is_a? Enumerable
      measurements = measurement_or_measurements
      return measurements.map { |measurement| predict measurement }
    end
    measurement = measurement_or_measurements
    @space.labels
          .values
          .map { |label| posterior label, given: measurement }
          .each_with_index
          .max
          .last
  end

  def accuracy
    @confusion_matrix.trace
  end

  def expected_gain
    @expected_gain_matrix.trace
  end

  def summary
    p @priors
    @likelihoods.pretty_print
    @posteriors.pretty_print
    @economic_gain_matrix.pretty_print
    @bayes_rules.pretty_print
    @confusion_matrix.pretty_print
    @expected_gain_matrix.pretty_print
    puts "Expected Gain: #{expected_gain}.\tConfusion: #{accuracy}"
  end

  private

  def prior(label)
    @priors[label]
  end

  def posterior(label, given:)
    address = given.is_a?(Enumerable) ? @space.address(given) : given
    @posteriors[label, address]
  end

  def likelihood(address_or_measurement, given:)
    address = address_or_measurement.is_a?(Enumerable) ? @space.address(address_or_measurement) : address_or_measurement
    label = given
    @likelihoods[address, label]
  end

  def compute_expected_gain_matrix
    Matrix.combine @confusion_matrix, @economic_gain_matrix do |confusion, gain|
      confusion * gain
    end
  end

  def compute_confusion_matrix
    Matrix.build @space.labels.size do |true_class, assigned_class|
      @bayes_rules.row(assigned_class).dot @posteriors.row(true_class)
    end
  end

  def compute_bayes_rules
    bayes_rules = (0...@space.size).map do |address|
      gains = @space.labels.values.map do |label|
        @posteriors.column(address).dot @economic_gain_matrix.column(label)
      end
      Vector.basis size: @space.labels.size, index: gains.each_with_index.max.last
    end
    Matrix.columns bayes_rules
  end

  def compute_posteriors
    Matrix.build(*@likelihoods.shape.reverse) do |label, address|
      likelihood(address, given: label) * prior(label)
    end
  end

  def process_priors
    @target.each { |label| @priors[label] += 1.0 }
    @priors /= @priors.sum
  end

  def process_likelihoods
    counts = Matrix.zero @space.size, @space.labels.size
    @target.zip(@data).reduce(counts) do |accum, (label, measurement)|
      address = @space.address measurement
      accum[address, label] += 1.0 and accum
    end
    Matrix.columns counts.column_vectors.map { |column| column.sum ? column / column.sum : column }
  end
end
