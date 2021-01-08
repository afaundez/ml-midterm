# frozen_string_literal: true
require_relative '../dsl/enumerable'

# A classification or measurement
class Dimension
  include Enumerable

  attr_accessor :values, :pmf, :cdf

  def initialize(values)
    @values = values
    @pmf = Dimension.pmf size
    @cdf = Dimension.cdf @pmf
  end

  def each(&block)
    @values.each(&block)
  end

  def size
    count
  end

  def random(pmf = nil)
    raise 'PMF size must match dimension size' if pmf && pmf.size != size
    cdf = pmf ? Dimension.cdf(pmf) : @cdf
    Dimension.random cdf
  end

  def marginal(value)
    raise 'Invalid value for dimension marginal' unless value < size
    @pmf[value]
  end

  def summary(tags: nil, prefix: '')
    'no tags' if tags

    puts prefix + "#{size} labels with prob #{@pmf}"
  end

  def self.random(cdf)
    raise 'CDF must be an enumerable' unless cdf.is_a? Enumerable
    n = rand
    return 0 if n <= cdf[0]
    return cdf.size - 1 if cdf[cdf.size - 1] <= n
    (1...cdf.size).find { |k| k if n.between?(cdf[k - 1], cdf[k]) }
  end

  def self.pmf(size)
    raise 'PMF size must be greater than zero' unless 0 < size
    random_numbers = Vector.elements (0...size).map { rand }
    random_numbers / random_numbers.sum
  end

  def self.cdf(pmf)
    raise 'PMF must be an enumerable' unless pmf.is_a? Enumerable
    Vector.elements pmf.reduce([]) { |cdf, pr| cdf << pr + (cdf.last || 0) }
  end

  def to_tex
    pmf.each_with_index.collect { |pr, c| [c, pr].join(' & ') }.join(" \\\\\n")
  end

  def to_tex_plot(label)
    <<~TEX
    \\pgfplotstableread[row sep=\\\\,col sep=&]{
    values & \P \\\\
    #{to_tex}
    }\\#{label}

    \\begin{tikzpicture}
      \\begin{axis}[
          ybar,
          symbolic x coords={#{values.collect{ |c| c }.join ','}},
          xtick=data,
        ]
        \\addplot table[x=values,y=\P]{\\#{label}};
      \\end{axis}
    \\end{tikzpicture}
    TEX
  end
end
