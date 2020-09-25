require 'set'



class DataSet
  attr_accessor :dimensions, :classes, :measurements, :measurement_count_by_category,
    :measurement_count, :category_count_by_measurement

  CATEGORIES = ['Adelie', 'Chinstrap', 'Gentoo']
  DIMENSIONS = [
    ['Biscoe', 'Dream', 'Torgersen'],
    ['large', 'small'],
    ['large', 'small'],
    ['large', 'small'],
    ['large', 'small'],
    ['FEMALE', 'MALE']
  ]

  def initialize(header)
    header_list = header.split(',')
    @measurements_by_dimension = DIMENSIONS.collect { |_| 0.0 }
    @measurement_count_by_category = CATEGORIES.collect { |_| 0.0 }
    @measurement_count_by_dimension = DIMENSIONS.collect { |l| l.collect{ |_| 0.0} }
    @category_count_by_measurement = []
  end

  def category_to_c(category)
    CATEGORIES.index category
  end

  def c_to_category(c)
    CATEGORIES[c]
  end

  def add_category(category)
    @measurement_count_by_category[category] += 1.0
  end

  def add_class_and_measurement(category, measurements)
    @category_count_by_measurement[linear_address(measurements)] ||= []
    @category_count_by_measurement[linear_address(measurements)][category] ||= 0.0
    @category_count_by_measurement[linear_address(measurements)][category] += 1.0
    measurements.each_with_index do |measurement, dimension|
      @measurement_count_by_dimension[dimension][measurement] += 1.0
    end
  end

  def d_to_measurement(d)
    DIMENSIONS.zip(d).collect { |values, index| values[index] }
  end

  def measurement_to_d(measurement)
    measurement.each_with_index.collect { |value, n| DIMENSIONS[n].index value  }
  end

  def K
    CATEGORIES.to_a
  end

  def M_names
    @M_names ||= @measurements_by_dimension.collect { |name, values|  values.to_a }
  end

  def M
    @M ||= DIMENSIONS.collect(&:size)
  end

  def N
    @N ||= self.M.size
  end

  def L
    @L ||= self.M.collect { |m| (0..(m - 1)).to_a }
  end

  def d_and_not_c_size(d, c)
    return 0.0 unless @category_count_by_measurement[linear_address(d)]
    @category_count_by_measurement[linear_address(d)].each_with_index
                                               .select{ |_, i| i != c}
                                               .collect { |_, v| v}
                                               .inject(0.0, :+)
  end

  def d_and_c_size(d, c)
    index = linear_address d
    categories = @category_count_by_measurement.fetch index, nil
    return 0.0 unless categories
    categories.fetch(c, nil) || 0.0
  end

  def c_size(c)
    @measurement_count_by_category[c]
  end

  def size
    @measurement_count_by_category.inject(0.0, :+)
  end

  def pr_c_given_D(c, d)
    pr_c = c_size(c) / size
    pr_d_and_not_c = d_and_not_c_size(d, c) / size
    pr_not_c = 1.0 - pr_c
    pr_d_given_not_c = pr_not_c > 0 ? (pr_d_and_not_c / pr_not_c) : 0.0
    pr_d_and_c = d_and_c_size(d, c) / size
    pr_d_given_c = pr_d_and_c / pr_c
    pr_d = (pr_d_given_c * pr_c) + (pr_d_given_not_c * pr_not_c)
    return 0.0 if pr_d <= 0
    (pr_d_given_c * pr_c) / pr_d
  end

  def linear_address(d)
    jumps = self.M.inject([1]) { |prod, m| prod << prod.last * m }
                  .take(self.M.size)
    return jumps.zip(d)
                .collect { |j, dn| j * dn }
                .inject(:+)
  end
end

header = STDIN.readline.chomp
dataset = DataSet.new header

STDIN.each_line do |line|
  category, *measurement = line.chomp.split(',')
  next if measurement.include?('.') || measurement.include?('NA')
  c = dataset.category_to_c category
  d = dataset.measurement_to_d measurement
  dataset.add_category c
  dataset.add_class_and_measurement c, d
end

puts "K = categories = { #{dataset.K.join(', ')} }"
puts "|K| = #{dataset.K.size}"
puts "L = { #{dataset.L.collect{|x| "{ #{x.join(', ')} }" }.join(',  ')} }"
puts "N = |L| = #{dataset.N}"
puts "M = { |L_0|, ..., |L_(N-1)| }= { #{dataset.M.join(', ')} }"

c_space = dataset.K.each_with_index.collect { |_, i| i }
pr_c_given_d = c_space.collect { |_| [] }
d_spaces = dataset.L
c_space.product(*d_spaces).each do |c, *d|
  pr_c_given_d[c][dataset.linear_address(d)] = dataset.pr_c_given_D c, d

  value = pr_c_given_d[c][dataset.linear_address(d)]
  category = dataset.c_to_category c
  measurements = dataset.d_to_measurement d
  puts "Pr(c = #{category} | D = { #{measurements.join(',')} }) = #{value}" if value > 0
end

p pr_c_given_d
