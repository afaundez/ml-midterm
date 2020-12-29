require_relative 'dimension'
require_relative 'space'

class Classifier
  attr_accessor :space, :klass, :economic_gain_matrix,
                :priors, :likelihoods, :posteriors,
                :bayes_rules, :confusion_matrix, :expected_gain_matrix

  def accuracy
    @confusion_matrix.trace
  end

  def expected_gain
    @expected_gain_matrix.trace
  end

  def prior(label)
    @priors[label]
  end

  def likelihood(address, given:)
    label = given
    @likelihoods[label, address]
  end

  def posterior(label, given:)
    address = given
    @posteriors[label, address]
  end

  def fit(data: nil, target: nil, space: nil, klass: nil, economic_gain_matrix: nil, likelihoods: nil, priors: nil)
    raise 'space and klass must be present' unless space || klass
    @space = space
    @klass = klass
    if data && target
      @priors = priors || compute_priors(target)
      @likelihoods = likelihoods || compute_likelihoods(target, data)
    else
      @priors = priors || @klass.pdf
      @likelihoods = likelihoods || generate_likelihoods
    end
    @economic_gain_matrix = economic_gain_matrix || Matrix.identity(@klass.size)
    compute_posteriors
    compute_bayes_rules
    compute_confusion_matrix
    compute_expected_gain_matrix
  end

  def predict(measurement)
    address = space.address measurement
    @klass.values
          .map { |label| posterior label, given: address }
          .each_with_index
          .max[1]
  end

  def adapt(data, target, predictions, delta: 0.05, after: :each)
    likelihoods = @likelihoods.clone
    changes = data.zip(target, predictions).reduce(0) do |sum, (measurement, true_class, assigned_class)|
      address = space.address measurement
      next sum if true_class.eql? assigned_class
      @likelihoods[true_class, address] += delta
      renormalize_likelihoods if after == :each
      next sum += 1
    end
    renormalize_likelihoods if after == :all
    compute_posteriors
    compute_bayes_rules
    compute_confusion_matrix
    compute_expected_gain_matrix
  end

  # private

  def compute_priors(target)
    priors = target.inject(Vector.zero @klass.size) do |count, c|
      count[c] += 1.0 and count
    end
    priors / priors.sum
  end

  def compute_likelihoods(target, data)
    likelihoods = target.zip(data).inject(Matrix.zero @klass.size, @space.size) do |count, (c, measurement)|
      address = space.address measurement
      count[c, address] += 1.0 and count
    end
    Matrix.rows likelihoods.row_vectors.map { |row| row / row.sum }
  end

  def renormalize_likelihoods
    @likelihoods = Matrix.rows @likelihoods.row_vectors.collect { |row| row / row.sum }
  end

  def compute_expected_gain_matrix
    @expected_gain_matrix = Matrix.combine @confusion_matrix, @economic_gain_matrix do |confusion, gain|
      confusion * gain
    end
    # expected_gain_matrix = @economic_gain_matrix.row_vectors.zip(@confusion_matrix.row_vectors).collect do |row1, row2|
    #   row1.collect2(row2) { |v1, v2| v1 * v2 }
    # end
    # @expected_gain_matrix = Matrix.rows expected_gain_matrix
  end

  def compute_confusion_matrix
    @confusion_matrix = Matrix.build @klass.size do |true_class, assigned_class|
      @bayes_rules.row(assigned_class).dot @posteriors.row(true_class)
    end
    # confusion_matrix = @klass.values.collect do |true_class|
    #   @klass.values.collect do |assigned_class|
    #     @bayes_rules.row(assigned_class).dot @posteriors.row(true_class)
    #   end
    # end
    # @confusion_matrix = Matrix.rows confusion_matrix
  end

  def compute_bayes_rules
    bayes_rules = @space.addresses.collect do |address|
      gains = @klass.values.collect do |assigned_class|
        @posteriors.column(address).dot @economic_gain_matrix.column(assigned_class)
      end
      Vector.basis size: @klass.size, index: gains.each_with_index.max.last
    end
    @bayes_rules = Matrix.columns bayes_rules
  end

  def compute_posteriors
    @posteriors = Matrix.build(*@likelihoods.shape) do |label, likelihood|
      @likelihoods[label, likelihood] * prior(label)
    end
    # @posteriors = @likelihoods.collect { |label, likelihood| p [label, likelihood]; label * prior(label) }
    # posteriors = @likelihoods.row_vectors.each_with_index.collect do |row, label|
    #   row * prior(label)
    # end
    # @posteriors = Matrix.rows posteriors
  end

  def generate_likelihoods
    Matrix.rows @klass.values.map { Dimension.build_pdf @space.size }
  end

  def summary(kind = :full)
    if kind == :full
      puts 'INPUTS'
      puts 'Priors'
      puts @priors.to_a.inspect
      # @likelihoods.pretty_print 'Likelihoods'
      # @posteriors.pretty_print 'Posteriors'
      @economic_gain_matrix.pretty_print 'Economic Gain Matrix'
    end
    puts 'OUTPUTS'
    if kind == :full
      # @bayes_rules.pretty_print 'Bayes Rules'
    end
    @confusion_matrix.pretty_print 'Confusion Matrix'
    @expected_gain_matrix.pretty_print 'Expected Gain Matrix'
    puts "Accuracy: #{@confusion_matrix.trace}"
    puts "Expected Gain: #{@expected_gain_matrix.trace}"
  end
end
