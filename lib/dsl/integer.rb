# frozen_string_literal: true

# Add dsl to std integer
class Integer
  def values
    (0...self).to_a
  end

  def dimension(with: 2)
    labels = with
    Dimension.new labels
  end

  def dimensions(each_with: 1)
    measurements = each_with
    times.collect { Dimension.new measurements }
  end

  def samples(from:, to:)
    size = self
    space = from
    labels = to
    2.times.collect { DataSet.new size, space, labels }
  end
end
