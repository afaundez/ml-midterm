# frozen_string_literal: true

require 'matrix'

class Vector
  def scale
    return if self.sum == 0
    set_range (0...self.count), (self / self.sum.to_f)
    self
  end

  def to_tex_data(label, kind: :line)
    <<~TEX
    \\pgfplotstableread[row sep=\\\\,col sep=&]{
    values & P \\\\
    #{each_with_index.collect { |pr, c| [c, pr].join(' & ') }.join(" \\\\\n")} \\\\
    }\\#{label}
    TEX
  end

  def to_tex_plot(label, kind: :line)
    <<~TEX
    #{to_tex_data label}
    \\begin{figure}
      \\begin{tikzpicture}
        \\begin{axis}#{"[ybar]" if kind == :bars}
          \\addplot table[x=values,y=P]{\\#{label}};
        \\end{axis}
      \\end{tikzpicture}
      \\caption{}
      \\label{}
    \\end{figure}
    TEX
  end
end


# Add a few methods to std matrix
class Matrix
  def pretty_print(title: nil, prefix: '')
    puts prefix + title if title
    puts pp_top(prefix), pp_middle(prefix), pp_bottom(prefix)
  end

  def scale(direction = :rows, index: nil)
    if direction == :rows && index
      v = row_vectors[index]
      return set_col_range index, (0...v.size), v.scale
    elsif direction == :rows
      return row_vectors.each_with_index { |v, i| set_col_range i, (0...v.size), v.scale }
    elsif index
      v = column_vectors[index]
      return set_row_range (0...v.size), index, v.scale
    end
    column_vectors.each_with_index { |v, i| set_row_range (0...v.size), i, v.scale }
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
