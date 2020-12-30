# frozen_string_literal: true

require_relative 'dsl/enumerable'
require_relative 'dsl/integer'
require_relative 'dsl/matrix'
require_relative 'components/data_set'
require_relative 'components/dimension'
require_relative 'components/space'
require_relative 'components/classifier'

@block_level = -1

def current_level_prefix
  "\t" * (@block_level.negative? ? 0 : @block_level)
end

def level_puts(*args)
  print current_level_prefix
  puts(*args)
end

def level_print(*args)
  print current_level_prefix
  print(*args)
end

def experiment(times, within:, assigning:, &block)
  space = within
  labels = assigning
  times.each do |iteration|
    level_puts "Experiment #{iteration + 1}"
    block.call iteration, Classifier.new(space, labels)
  end
end

def repeat(times, using: nil, &block)
  times.each do |iteration|
    level_puts "Iteration #{iteration}"
    if using&.is_a?(DataSet)
      dataset = using
      block.call (iteration + 1), dataset.data, dataset.target
    else
      block.call iteration
    end
    level_puts ''
  end
end

def create(thing)
  if thing.is_a?(Enumerable) && thing.all? { |obj| obj.is_a?(Dimension) }
    dimensions = thing
    yield Space.new dimensions
    return
  end
  yield thing
end

def fit(classifier, with:)
  dataset = with
  classifier.fit data: dataset.data, target: dataset.target
  yield classifier, dataset.data, dataset.target
  classifier
end

def report(*summarizables, titled: nil, including: nil)
  level_puts titled if titled
  tags = including.nil? ? including : [including].flatten.compact
  summarizables.each do |summarizable|
    summarizable.summary tags: tags, prefix: current_level_prefix
  end
  puts
end

def predict(using:, with:)
  classifier = using
  data = with
  predictions = classifier.predict data
  yield predictions
end

def compare(predictions, with: nil, show: nil)
  target = with
  size = target.uniq.sort.size
  level_print 'Prediction Accuracy: '
  count_matrix = Matrix.zero size
  predictions.zip(target).reduce(count_matrix) do |accum, (predicted, targeted)|
    accum[predicted, targeted] += 1.0 and accum
  end
  confusion_matrix = count_matrix / target.size
  puts confusion_matrix.trace
  report confusion_matrix, titled: 'Confusion Matrix' if show == :confusion
end

def adapt(classifier, with: nil, based_on: nil)
  dataset = with
  predictions = based_on
  data = dataset.data
  target = dataset.target
  level_print 'Adapting... '
  classifier.adapt predictions, target, data, delta: 0.05
  puts 'done'
end

def indent_levels(*names)
  names.each do |name|
    original_method = method name
    define_method(name) do |*args, **keywords, &block|
      @block_level += 1
      original_method.call(*args, **keywords, &block)
      @block_level -= 1
    end
  end
end
