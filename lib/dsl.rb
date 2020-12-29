class Fixnum
  def measurements
    (0...self).to_a
  end

  def labels
    self.measurements
  end

  def dimension(with: 2)
    labels = with
    Dimension.new labels
  end

  def dimensions(each, with: 1)
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

def space(&block)
  yield Space.new
end

def experiment(using:, &block)
  space = using
  yield Classifier.new space
end

def iterate(times, &block)
  times.each(&block)
end

def create(something, &block)
  case something
  when :space then yield Space.new
  else
    yield something
  end
end

def fit(classifier, with:)
  dataset = with
  classifier.fit data: dataset.data, target: dataset.target
end

def summary(classifier, extra, only: nil)
  puts extra
  tags = only.nil? ? only : [only].flatten.compact
  classifier.summary tags

end

def predict(using:, with:, &block)
  classifier, data = using, with
  predictions = classifier.predict data
  yield predictions
end

def compare(predictions, with: nil)
  raise 'cannot compare nil to anything' unless predictions
  raise 'cannot compare to nil' unless with
  target = with
  matches = predictions.zip(target).count { |a, b| a == b }
  accuracy = matches / target.size.to_f
  puts "Prediction Accuracy: #{accuracy}"
end

def adapt(classifier, with:, based_on:)
  dataset, predictions = with, based_on
  p 'do the adapt'
end
