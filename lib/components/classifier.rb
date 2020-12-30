# frozen_string_literal: true

require_relative '../dsl/enumerable'
require_relative '../dsl/matrix'
require_relative 'dimension'
require_relative 'space'

# A discrete bayes classifier
class Classifier
  attr_accessor :space, :labels, :priors, :likelihoods, :posteriors,
                :confusion_matrix

  def initialize(space, labels, priors: nil, likelihoods: nil)
    @space = space
    @labels = labels
    @economic_gain_matrix = Matrix.identity @labels.size
    @priors = priors || Vector.zero(@labels.size)
    @likelihoods = likelihoods || Matrix.zero(@priors.size, @space.size)
  end

  def fit(data:, target:, priors: nil, likelihoods: nil)
    @priors = priors || process_priors(target)
    @likelihoods = likelihoods || process_likelihoods(data, target)
    compute
  end

  def predict(input)
    if input.is_a?(Enumerable) && !input.empty? && input.first.is_a?(Enumerable)
      return input.map { |measurement| predict measurement }
    end

    @labels.map { |label| posterior label, given: input }.argmax
  end

  def adapt(predictions, target, data, delta: 0.05)
    likelihoods = @likelihoods.clone
    predictions.zip(target, data).reduce(likelihoods) do |accum, (assigned_class, true_class, measurement)|
      next accum if assigned_class == true_class

      address = @space.address measurement
      accum[address, true_class] += delta and accum
    end
    @likelihoods = normalize(likelihoods, :columns)
    compute
  end

  def normalize(matrix, rows_or_columns)
    return unless rows_or_columns == :columns

    columns = matrix.clone.column_vectors.map { |column| column.sum ? column / column.sum : column }
    Matrix.columns columns
  end

  def summary(tags: %i[input output values], prefix: '')
    if tags.include? :input
      puts prefix + @priors.inspect
      [@likelihoods, @posteriors, @economic_gain_matrix].each { |matrix| matrix.pretty_print prefix: prefix }
    end
    if tags.include? :output
      [@bayes_rules, @confusion_matrix, @expected_gain_matrix].each { |matrix| matrix.pretty_print prefix: prefix }
    end
    return unless tags.include? :values

    puts prefix + "Expected Gain: #{@expected_gain_matrix.trace}."
  end

  def compute
    @posteriors = compute_posteriors
    @bayes_rules = compute_bayes_rules
    @confusion_matrix = compute_confusion_matrix
    @expected_gain_matrix = compute_expected_gain_matrix
  end

  private

  def prior(label)
    @priors[label]
  end

  def posterior(label, given:)
    address = given.is_a?(Enumerable) ? @space.address(given) : given
    @posteriors[label, address]
  end

  def likelihood(event, given:)
    address = event.is_a?(Enumerable) ? @space.address(event) : event
    @likelihoods[address, given]
  end

  def compute_expected_gain_matrix
    Matrix.combine @confusion_matrix, @economic_gain_matrix do |confusion, gain|
      confusion * gain
    end
  end

  def compute_confusion_matrix
    Matrix.build @labels.size do |true_class, assigned_class|
      @bayes_rules.row(assigned_class).dot @posteriors.row(true_class)
    end
  end

  def compute_bayes_rules
    bayes_rules = (0...@space.size).map do |address|
      gains = @labels.values.map do |label|
        @posteriors.column(address).dot @economic_gain_matrix.column(label)
      end
      Vector.basis size: @labels.size, index: gains.argmax
    end
    Matrix.columns bayes_rules
  end

  def compute_posteriors
    Matrix.build(*@likelihoods.shape.reverse) do |label, address|
      likelihood(address, given: label) * prior(label)
    end
  end

  def process_priors(target)
    target.each { |label| @priors[label] += 1.0 }
    @priors /= @priors.sum
  end

  def process_likelihoods(data, target)
    counts = Matrix.zero @space.size, @labels.size
    target.zip(data).reduce(counts) do |accum, (label, measurement)|
      address = @space.address measurement
      accum[address, label] += 1.0 and accum
    end
    normalize(counts, :columns)
  end
end
