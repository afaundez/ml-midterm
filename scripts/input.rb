require 'set'

class DataSet
  attr_accessor :dimensions, :classes, :measurements, :measurement_count_by_category,
    :measurement_count, :measurement_count_by_measurement_dimension_and_category,
    :category_count_by_measurement
  def initialize(header)
    header_list = header.split(',')
    @dimensions = Set.new header_list[1..-1]
    @categories = Set.new
    @measurements_by_dimension = @dimensions.collect { |name| [name, Set.new] }.to_h
    @measurement_count_by_category = {}
    @measurement_count_by_dimension = @dimensions.collect { |name| [name, {}] }.to_h
    @measurement_count_by_measurement_dimension_and_category = {}
    @category_count_by_measurement = {}
  end

  def d_and_not_c_size(measurement, category)
    @category_count_by_measurement.fetch(measurement, {})
                                  .select{ |c| !c.eql?(category)}
                                  .values
                                  .inject(0.0, :+)
  end

  def d_and_c_size(measurement, category)
    @category_count_by_measurement.fetch(measurement, {})
                                  .fetch(category, 0.0)
  end

  def c_size(category)
    @measurement_count_by_category.fetch(category)
  end

  def size
    measurement_count_by_category.values.inject(0.0, :+)
  end

  def K
    @categories.to_a
  end

  def M_names
    @M_names ||= @measurements_by_dimension.collect { |name, values|  values.to_a }
  end

  def M
    @M ||= @measurements_by_dimension.each_with_index.collect do |(name, values), index|
      dimension = index + 1
      values.size
    end
  end

  def N
    @N ||= self.M.size
  end

  def L
    @L ||= self.M.collect { |m| (0..(m - 1)).to_a }
  end

  def linear_address(d)
    accumulate_gaps = @M.inject([1]) { |acc, m_i| acc << acc.last * m_i }.take @M.size
    return accumulate_gaps.zip(d).map { |k, v| k*v }.inject(:+)
  end

  def add_category(category)
    @categories.add category
    @measurement_count_by_category[category] ||= 0.0
    @measurement_count_by_category[category] += 1.0
    @measurement_count_by_measurement_dimension_and_category[category] ||= {}
  end

  def add_class_and_measurement(category, measurements)
    count_measurement_by_class category, measurements
    measurments_by_dimension = @dimensions.zip measurements
    measurments_by_dimension.each do |dimension, measurement|
      @measurements_by_dimension[dimension].add measurement
      @measurement_count_by_measurement_dimension_and_category[category][dimension] ||= {}
      count_measurement_by_dimension dimension, measurement
      count_measurement_by_dimension_and_class category, dimension, measurement
    end
  end

  private

  def count_measurement_by_dimension_and_class(category, dimension, measurement)
    @measurement_count_by_measurement_dimension_and_category[category][dimension][measurement] ||= 0.0
    @measurement_count_by_measurement_dimension_and_category[category][dimension][measurement] += 1.0
  end

  def count_measurement_by_dimension(dimension, measurement)
    @measurement_count_by_dimension[dimension][measurement] ||= 0.0
    @measurement_count_by_dimension[dimension][measurement] += 1.0
  end

  def count_measurement_by_class(category, measurement)
    @category_count_by_measurement[measurement] ||= {}
    @category_count_by_measurement[measurement][category] ||= 0.0
    @category_count_by_measurement[measurement][category] += 1.0
  end
end

header = STDIN.readline.chomp
dataset = DataSet.new header

STDIN.each_line do |line|
  category, *measurements = line.chomp.split(',')
  dataset.add_category category
  next if measurements.include?('.') || measurements.include?('NA')
  dataset.add_class_and_measurement category, measurements
end

puts "K = categories = { #{dataset.K.join(', ')} }"
puts "|K| = #{dataset.K.size}"
puts "L = { #{dataset.L.collect{|x| "{ #{x.join(', ')} }" }.join(',  ')} }"
puts "N = |L| = #{dataset.N}"
puts "M = { |L_0|, ..., |L_(N-1)| }= { #{dataset.M.join(', ')} }"

def e_for(true_category, assigned_category)
  true_category == assigned_category ? 1 : -1
end

def pr_c_given_D_for(category, measurement, dataset)
  pr_c = dataset.c_size(category) / dataset.size
  pr_d_and_c = dataset.d_and_c_size(measurement, category) / dataset.size
  pr_d_given_c = pr_d_and_c / pr_c
  pr_d_and_not_c = dataset.d_and_not_c_size(measurement, category) / dataset.size
  pr_not_c = 1.0 - pr_c
  pr_d_given_not_c = pr_d_and_not_c / pr_not_c
  pr_d = (pr_d_given_c * pr_c) + (pr_d_given_not_c * pr_not_c)
  return 0.0 if pr_d <= 0
  (pr_d_given_c * pr_c) / pr_d
end

def d_as_measurements_by_dimension(d, d_names, d_values_names)
  d_value = d.each_with_index.collect { |dn, n| d_values_names[n][dn] }
  d_names.zip(d_value).to_h
end

p_c_given_D = dataset.K.each_with_index.collect { |c, i| [i, []] }.to_h
p_c_given_D.keys.to_a.product(*(dataset.L)).each do |c, *d|
  category = dataset.K[c]
  measurements = d_as_measurements_by_dimension d, dataset.dimensions.to_a, dataset.M_names
  p_c_given_D[c][dataset.linear_address(d)] = pr_c_given_D_for category, measurements.values, dataset
  value = p_c_given_D[c][dataset.linear_address(d)]
  puts "Pr(c = #{category} | D = { #{measurements.values.join(',')} }) = #{value}" if value > 0
end

p p_c_given_D
