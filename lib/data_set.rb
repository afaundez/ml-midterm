# frozen_string_literal: true

require 'matrix'
require_relative 'dimension'

# DataSet
class DataSet
  attr_accessor :size, :space, :samples, :class_outcomes, :overlap

  def initialize(size, space, overlap: true)
    @size = size
    @space = space
    @overlap = overlap
    @class_outcomes = space.classes.collect { 0.0 }
    @samples = build_samples
  end

  def train(economic_gain_matrix)
    bayes, expected_gain = build_bayes_rules_decisions economic_gain_matrix
    confusion_matrix = build_confusion_matrix bayes
    expected_gain_matrix = economic_gain_matrix * confusion_matrix
    [bayes, expected_gain, confusion_matrix, expected_gain_matrix]
  end

  def improve(delta)
    likelihoods = @space.likelihoods
    matches = @samples.inject(0) do |count, sample|
      true_class, *measurement = sample
      address = space.address measurement
      assigned_class = posteriors.row(address).each_with_index.max[1]
      next count += 1 if true_class == assigned_class
      likelihoods[true_class, address] += delta
      count
    end
    @space.likelihoods = Matrix.rows likelihoods.row_vectors.collect { |row| Dimension.normalize row }
    @posteriors = build_posteriors
    accuracy = matches.to_f / samples.size
    [@space, accuracy]
  end

  def class_prioris
    @class_prioris ||= Dimension.normalize Vector.elements(class_outcomes)
  end

  def posteriors
    @posteriors ||= build_posteriors
  end

  private

  def build_bayes_rules_decisions(economic_gain_matrix)
    bayes_rows, gains = @space.addresses.collect do |address|
      max_class, max_gain = @space.classes.inject([nil, -Float::INFINITY]) do |(klass, max), assigned_class|
        assigned_class_gain_row = economic_gain_matrix.row assigned_class
        gain = posteriors.row(address).dot assigned_class_gain_row
        max < gain ? [assigned_class, gain] : [klass, max]
      end
      [build_bayes_row(max_class), max_gain]
    end.transpose
    [Matrix.rows(bayes_rows), gains.sum]
  end

  def build_confusion_matrix(bayes)
    confusion_matrix = @space.classes.collect do |true_class|
      @space.classes.collect do |assigned_class|
        @space.addresses.collect do |address|
          bayes[address, assigned_class] * 1.0
        end.sum
      end
    end
    Matrix.rows(confusion_matrix) / space.addresses.size
  end

  def build_bayes_row(klass)
    Vector.basis size: @space.classes.size, index: klass
  end

  def build_posteriors
    rows = @space.addresses.collect do |address|
      @space.classes.collect do |true_class|
        priori = @space.prioris[true_class]
        likelihood = @space.likelihoods[true_class, address]
        # evidence = 1.0 / @space.addresses.size
        evidence = @space.evidence(address)
        likelihood * priori / evidence
      end
    end
    Matrix.rows rows
  end

  def build_samples
    @size.times.collect do
      measurement = @space.dimensions.collect(&:random)
      address = @space.address measurement
      klass = @space.class_dimension.random (@overlap ? nil : measurement)
      @class_outcomes[klass] += 1.0
      [klass, measurement].flatten
    end
  end
end
