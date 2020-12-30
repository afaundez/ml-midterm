class Fixnum
  def values
    (0...self).to_a
  end

  def labels
    self.values
  end

  def dimension(with: 2, distributed: :uniform)
    labels = with
    Dimension.new labels
  end

  def dimensions(each, with: 1, distributed: :uniform)
    measurements = with
    self.times.collect { Dimension.new measurements }
  end

  def classifier(with)
    Classifier.new space
  end

  def samples(from:)
    space = from
    [DataSet.new(self, space), DataSet.new(self, space)]
  end
end

@block_level = -1

def current_level_prefix
  "\t" * (@block_level < 0 ? 0 : @block_level)
end

def level_puts(*args)
  print current_level_prefix
  puts *args
end

def level_print(*args)
  print current_level_prefix
  print *args
end

def space(&block)
  yield Space.new
end

def experiment(times, within:, &block)
  space = within
  times.each do |iteration|
    level_puts "Experiment #{iteration + 1}"
    block.call iteration, Classifier.new(space)
  end
end

def repeat(times, using: nil, &block)
  times.each do |iteration|
    level_puts "Iteration #{iteration}"
    if using and using.is_a?(DataSet)
      dataset = using
      block.call (iteration + 1), dataset.data, dataset.target
    else
      block.call iteration
    end
    puts ''
  end
end

def create(something, &block)
  case something
  when :measurement_space then yield Space.new
  else
    yield something
  end
end

def fit(classifier, with:, &block)
  dataset = with
  classifier.fit data: dataset.data, target: dataset.target
  yield classifier, dataset.data, dataset.target
  classifier
end

def summary(summarizable, titled: nil, including: nil)
  # @block_level += 1
  level_puts titled if titled
  tags = including.nil? ? including : [including].flatten.compact
  summarizable.summary tags: tags, prefix: current_level_prefix
end

def predict(using:, with:, &block)
  classifier, data = using, with
  predictions = classifier.predict data
  yield predictions
end

def compare(predictions, with: nil, show: nil)
  target = with
  size = predictions.uniq.sort.size

  level_print "Prediction Accuracy: "
  count_matrix = predictions.zip(target).reduce(Matrix.zero size) do |accum, (assigned_class, true_class)|
    accum[assigned_class, true_class] += 1.0 and accum
  end

  confusion_matrix = count_matrix / target.size

  puts confusion_matrix.trace
  if show == :confusion
    level_puts 'Confusion Matrix (predictions)'
    confusion_matrix.pretty_print prefix: current_level_prefix
  end
  confusion_matrix
end

def adapt(classifier, with:, based_on:)
  dataset, predictions = with, based_on
  data, target = dataset.data, dataset.target
  likelihoods = classifier.likelihoods
  level_print 'Adapting... '
  predictions.zip(target, data).reduce(likelihoods) do |accum, (assigned_class, true_class, measurement)|
    next likelihoods if assigned_class == true_class
    address = classifier.space.address measurement
    likelihoods[address, true_class] += 0.5
    next likelihoods
  end
  likelihoods = Matrix.columns likelihoods.column_vectors.map { |column| column.sum ? column / column.sum : column }
  classifier.likelihoods = likelihoods
  print 'computing... '
  classifier.compute
  puts 'done'
end

def indent_levels(*names)
  names.each do |name|
    original_method = method name
    define_method(name) do |*args, &block|
      @block_level += 1
      original_method.call *args, &block
      @block_level -= 1
    end
  end
end
