require 'matrix'

class Dimension
  attr_accessor :values, :pdf

  def initialize(size)
    @values = (0...size).collect { |v| v }
    @pdf = Dimension.build_pdf size
  end

  def size
    @values.size
  end

  def self.build_pdf(size)
    pdf = (0...size).collect { 1.0 / size }
    Vector.elements pdf
  end
end

class Space
  attr_accessor :dimensions, :addresses

  def initialize(dimensions)
    @dimensions = dimensions
    @addresses = []
  end

  def address(vector)
  end

  def size
    addresses.size
  end
end

class Classifier
  attr_accessor :space, :klass, :economic_gain_matrix,
                :priors, :likelihoods, :posteriors,
                :bayes_rules, :confusion_matrix, :expected_gain_matrix

  def prior(label)
    @klass.pdf[label]
  end

  def likelihood(address, given:)
    klass = given
    @likelihoods[label, address]
  end

  def posterior(label, given:)
    address = given
    @posteriors[address, label]
  end

  def fit(data: nil, target: nil, space: nil, klass: nil, expected_gain_matrix: nil)
    raise 'data/target not supported' if data || target
    raise 'space and klass must be present' unless space || klass
    @space = space
    @klass = klass
    @economic_gain_matrix = Matrix.rows [[1, 0], [0, 2]]  #expected_gain_matrix || Matrix.identity(@klass.size)
    generate_likelihoods
    compute_posteriors
    compute_bayes_rules
    compute_confusion_matrix
    compute_expected_gain_matrix
  end

  def predict(address)
    @klass.values
          .map { |label| posterior address, label }
          .each_with_index
          .max[1]
  end

  def optimize(data, target, predictions, delta: 0.05)
    data.zip(target, predictions).each do |true_class, assigned_class, vector|
      address = space.address vector
      next if true_class.eql? assigned_class
      @likelihoods[true_class, address] += delta
    end
    renormalize_likelihoods
    compute_posteriors
    compute_bayes_rules
    compute_confusion_matrix
    compute_expected_gain_matrix
  end

  # private

  def renormalize_likelihoods
  end

  def compute_expected_gain_matrix
    expected_gain_matrix = @economic_gain_matrix.row_vectors.zip(@confusion_matrix.row_vectors).collect do |row1, row2|
      row1.collect2(row2) { |v1, v2| v1 * v2 }
    end
    @expected_gain_matrix = Matrix.rows expected_gain_matrix
  end

  def compute_confusion_matrix
    confusion_matrix = @klass.values.collect do |true_class|
      @klass.values.collect do |assigned_class|
        @bayes_rules.row(assigned_class).dot @posteriors.row(true_class)
      end
    end
    @confusion_matrix = Matrix.rows confusion_matrix
  end

  def compute_bayes_rules
    rules = @space.addresses.collect do |address|
      gains = @klass.values.collect do |assigned_class|
        @posteriors.column(address).dot @economic_gain_matrix.column(assigned_class)
      end
      Vector.basis size: @klass.size, index: gains.each_with_index.max.last
    end
    @bayes_rules = Matrix.columns rules
  end

  def compute_posteriors
    posteriors = @likelihoods.row_vectors.each_with_index do |row, label|
      row * prior(label)
    end
    @posteriors = Matrix.rows posteriors
  end

  def generate_likelihoods
    likelihoods = @klass.values.map { Dimension.build_pdf @space.size }
    @likelihoods = Matrix.rows likelihoods
  end
end


dimensions = [[0, 1, 2]]
klass = Dimension.new 2
space = Space.new dimensions
space.addresses = [0, 1, 2]
classifier = Classifier.new

classifier.fit space: space, klass: klass

classifier.posteriors = Matrix.rows [[0.12, 0.18, 0.3], [0.2, 0.16, 0.04]]
classifier.compute_bayes_rules
classifier.compute_confusion_matrix
classifier.compute_expected_gain_matrix

puts classifier.bayes_rules
puts classifier.confusion_matrix
puts classifier.expected_gain_matrix



data = space.sample size
target = klass.sample size
shuffled_data, shuffled_target = shuffle data, target
train_data, train_target, test_data, test_target = split shuffled_data, shuffled_target

iterations.times do |iteration|
  data = space.sample size
  target = klass.sample size
  shuffled_data, shuffled_target = shuffle data, target
  train_data, train_target, test_data, test_target = split shuffled_data, shuffled_target

  classifier.fit train_data, train_target
  predict_target = data.map { |measurement| classifier.predict measurement }
  classifier.optimize test_data, test_target, predict_target, delta
end
