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

def create(thing, showing: false)
  created = if thing.is_a?(Enumerable) && thing.all? { |obj| obj.is_a?(Dimension) }
    dimensions = thing
    Space.new dimensions
  else
    thing
  end
  summary created if showing
  yield created
end

def experiment(times, within:, assigning:, showing: false, &block)
  space = within
  labels = assigning
  times.each do |iteration|
    level_puts "Experiment #{iteration + 1}" if showing
    block.call iteration, Classifier.new(space, labels)
  end
end

def fit(classifier, with: nil, showing: false)
  dataset = with
  args = if dataset
    classifier.fit data: dataset.data, target: dataset.target
    [classifier, dataset.data, dataset.target]
  else
    classifier.fit
    [classifier]
  end
  summary classifier, titled: 'Fitted classifier' if showing
  yield(*args)
end

def repeat(times, using: nil, showing: false, &block)
  times.collect do |repetition|
    results = if using&.is_a?(DataSet)
      dataset = using
      block.call (repetition + 1), dataset.data, dataset.target
    else
      block.call repetition
    end
    results
  end
end

def round_robin(folds, showing: false, &block)
  mean = (0...folds.size).collect do |v|
    *group, validation = folds.rotate v
    test = DataSet.new datasets: group
    classifier = block.call test, validation
    classifier.expected_gain
  end.sum(0.0) / folds.size
  report "Round Robin mean average: #{mean}" if showing
end

def report(message)
  level_puts message
end

def summary(*summarizables, titled: nil, including: nil)
  level_puts titled if titled
  tags = including.nil? ? including : [including].flatten.compact
  summarizables.each do |summarizable|
    summarizable.summary tags: tags, prefix: current_level_prefix
  end
end

def predict(using:, with:, showing: false, &block)
  classifier = using
  data = with
  predictions = classifier.predict data
  block.call predictions if block_given?
  summary classifier if showing
  classifier
end

def compare(predictions, to: nil, with: nil, showing: nil)
  target = to
  labels = with
  level_print 'Prediction Accuracy: ' if showing
  count_matrix = Matrix.zero labels.size
  predictions.zip(target).reduce(count_matrix) do |accum, (predicted, targeted)|
    accum[predicted, targeted] += 1.0 and accum
  end
  confusion_matrix = count_matrix / predictions.size
  puts confusion_matrix.trace if showing
end

def adapt(classifier, with: nil, based_on: nil, increasing: 0.05)
  dataset = with
  predictions = based_on
  classifier.adapt assigned_classes: predictions, dataset: dataset,
                                                  delta: increasing
  classifier
end

def write_into(filename)
  File.open(filename, 'w') { |file| yield file }
end

def indent_levels(*names)
  names.each do |name|
    original_method = method name
    define_method(name) do |*args, **keywords, &block|
      if block
        original_method.call(*args, **keywords) do |*block_args|
          @block_level += 1
          block_result = block.call *block_args
          @block_level -= 1
          block_result
        end
      else
        original_method.call(*args, **keywords)
      end
    end
  end
end
