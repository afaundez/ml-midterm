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

  def dimensions(each_with: (0..1))
    values = each_with
    times.collect { Dimension.new values }
  end

  def folds
    self
  end

  def samples(**keywords)
    size = self
    space = keywords[:from]
    labels = keywords[:to]
    conditionals = keywords[:with]
    folds = keywords[:in] || 1
    if folds == 1
      return 2.times.collect { DataSet.new size / 2, space, labels, conditionals: conditionals }
    end
    folds.times.collect { DataSet.new size / folds, space, labels, conditionals: conditionals }
  end
end
