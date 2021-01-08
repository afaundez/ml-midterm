# frozen_string_literal: true
require_relative '../dsl/enumerable'
require_relative '../dsl/matrix'
require_relative 'dimension'
require_relative 'space'

# A discrete bayes classifier
class Classifier
  attr_accessor :space, :labels, :economic_gain_matrix,
                :priors, :likelihoods,
                :joints, :marginals, :posteriors,
                :bayes_rules, :confusion_matrix, :expected_gain_matrix

  def initialize(space, labels)
    @space = space
    @labels = labels
  end

  def fit(data: nil, target: nil, economic_gain_matrix: nil, priors: nil,
                                                             likelihoods: nil,
                                                             marginals: nil)
    user_economic_gain_matrix = economic_gain_matrix
    user_priors = priors
    user_likelihoods = likelihoods
    user_marginals = marginals

    @economic_gain_matrix = user_economic_gain_matrix || compute_economic_gain_matrix
    @priors = user_priors || sample_priors(target) || compute_priors
    @likelihoods = user_likelihoods || sample_likelihoods(data, target) || compute_likelihoods
    compute
  end

  def predict(input)
    return [] if input.empty?
    return input.map { |i| predict i } if input.first.is_a? Enumerable

    address = @space.address input
    @bayes_rules.column(address).argmax
  end

  def adapt(assigned_classes:, dataset:, delta: 0.01, normalize: :after_all)
    raise 'Predictions and Target sizes must match' unless dataset && dataset.target.size == assigned_classes.size
    true_classes = dataset.target
    measurements = dataset.data
    measurements.zip(true_classes, assigned_classes).each do |measurement, true_class, assigned_class|
      address = @space.address measurement
      next unless assigned_class != true_class
      @likelihoods[address, assigned_class] += delta
      @likelihoods.scale :columns, index: assigned_class if normalize == :after_each
    end

    @likelihoods.scale :columns if normalize == :after_all
    compute
  end

  def expected_gain
    @expected_gain_matrix.trace
  end

  def compute
    @joints = compute_joints
    @marginals = compute_marginals
    @posteriors = compute_posteriors
    @bayes_rules = compute_bayes_rules
    @confusion_matrix = compute_confusion_matrix
    @expected_gain_matrix = compute_expected_gain_matrix
  end

  def summary(tags: nil, prefix: '')
    tags ||= %i[values]
    if tags.include? :input
      puts prefix + @priors.inspect
      [@likelihoods, @posteriors, @economic_gain_matrix].each { |matrix| matrix.pretty_print prefix: prefix }
    end
    if tags.include? :output
      [@bayes_rules, @confusion_matrix, @expected_gain_matrix].each { |matrix| matrix.pretty_print prefix: prefix }
    end
    return unless tags.include? :values

    puts prefix + "Expected Gain: #{@expected_gain_matrix.trace}"
  end

  private

  def compute_expected_gain_matrix
    Matrix.combine @confusion_matrix, @economic_gain_matrix do |confusion, gain|
      confusion * gain
    end
  end

  def compute_confusion_matrix
    Matrix.build @labels.size do |true_class, assigned_class|
      (0...space.size).sum do |address|
        @bayes_rules[assigned_class, address] * @joints[true_class, address]
      end
    end
  end

  def compute_bayes_rules
    bayes_rules = (0...@space.size).map do |address|
      gains = @labels.values.map do |label|
        @joints.column(address).dot @economic_gain_matrix.column(label)
      end
      Vector.basis size: @labels.size, index: gains.argmax
    end
    Matrix.columns bayes_rules
  end

  def compute_posteriors
    Matrix.build(*@joints.shape) do |label, address|
      @joints[label, address] / @marginals[address]
    end
  end

  def compute_joints
    Matrix.build(*@likelihoods.transpose.shape) do |label, address|
      @likelihoods[address, label] * @priors[label]
    end
  end

  def compute_marginals
    marginals = (0...@space.size).map do |address|
      @labels.sum { |label| @likelihoods[address, label] *  @priors[label] }
    end
    Vector.elements marginals
  end

  # def compute_marginals
  #   marginals = (0...@space.size).map do |address|
  #     @space.marginal address
  #   end
  #   Vector.elements marginals
  # end

  def compute_priors
    Vector.elements @labels.pmf
  end

  def compute_likelihoods
    columns = (0...@labels.size).collect do
      conditional = Dimension.new (0...@space.size).to_a
      conditional.pmf
    end
    Matrix.columns columns
  end

  def compute_economic_gain_matrix
    Matrix.identity @labels.size
  end

  def sample_priors(target)
    return unless target
    tally = Vector.zero @labels.size
    target.each { |label| tally[label] += 1.0 }
    tally.scale
  end

  def sample_marginals(data)
    return unless data
    tally = Vector.zero @space.size
    data.map { |measurement| @space.address measurement }
        .each { |address| tally[address] += 1.0 }
    tally.scale
  end

  def sample_likelihoods(data, target)
    return unless data && target
    tally = Matrix.zero @labels.size, @space.size
    data.map { |measurement| @space.address measurement }
        .zip(target)
        .each  { |address, label| tally[label, address] += 1.0 }
    tally.scale :columns
  end
end
