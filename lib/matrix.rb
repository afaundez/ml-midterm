# frozen_string_literal: true

require 'matrix'

class Matrix
  def pretty_print(title = nil)
    puts title if title
    width = self.collect(&:to_s).collect(&:size).max + 2
    puts '+' + '-' * self.row(0).size * width + '+'
    puts self.to_a.collect { |vector| vector.collect { |value| value.to_s.rjust(width) }.prepend('|').append('|').join  }
    puts '+' + '-' * self.row(0).size * width + '+'
  end

  def shape
    [self.row_size, self.column_size]
  end
end
