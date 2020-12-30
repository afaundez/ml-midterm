# frozen_string_literal: true

require 'matrix'

# Add a few methods to std matrix
class Matrix
  def pretty_print(title: nil, prefix: '')
    puts prefix + title if title
    puts pp_top(prefix), pp_middle(prefix), pp_bottom(prefix)
  end

  def shape
    [row_size, column_size]
  end

  def summary(tags: nil, prefix: '')
    raise 'No tags in summary matrix' if tags

    pretty_print prefix: prefix
  end

  private

  def pp_width
    @pp_width ||= collect(&:to_s).collect(&:size).max + 2
  end

  def pp_bottom(prefix)
    prefix + '+' + '-' * row(0).size * pp_width + '+'
  end

  def to_line(vector, prefix)
    vector.collect do |value|
      value.to_s.rjust(pp_width)
    end.prepend('|').append('|').join.prepend(prefix)
  end

  def pp_middle(prefix)
    to_a.collect { |vector| to_line vector, prefix }.join("\n")
  end

  def pp_top(prefix)
    prefix + '+' + '-' * row(0).size * pp_width + '+'
  end
end
