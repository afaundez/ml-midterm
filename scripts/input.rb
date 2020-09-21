require 'set'

header = STDIN.readline.chomp
header_list = header.split(',')
class_name = header_list[0]
measurement_names = Set.new header_list[1..-1]

classes = Set.new
measurements = measurement_names.collect { |name| [name, Set.new] }.to_h
dataset_classes_count = {}
dataset_measurements_count = measurement_names.collect { |name| [name, {}] }.to_h

dataset_classes_and_measurements_count = {}

dataset_measurements_classes_count = {}

STDIN.each_line do |line|
  values = line.chomp.split(',')
  class_value, *measurement_values = values
  classes.add class_value
  dataset_classes_count[class_value] ||= 0
  dataset_classes_count[class_value] += 1
  current_measurements = measurement_names.zip measurement_values
  next if measurement_values.include?('.') || measurement_values.include?('NA')
  dataset_measurements_classes_count[measurement_values] ||= {}
  dataset_measurements_classes_count[measurement_values][class_value] ||= 0
  dataset_measurements_classes_count[measurement_values][class_value] += 1
  current_measurements.each do |measurement_name, measurement_value|
    measurements[measurement_name].add measurement_value
    dataset_measurements_count[measurement_name][measurement_value] ||= 0
    dataset_measurements_count[measurement_name][measurement_value] += 1

    dataset_classes_and_measurements_count[class_value] ||= {}
    dataset_classes_and_measurements_count[class_value][measurement_name] ||= {}
    dataset_classes_and_measurements_count[class_value][measurement_name][measurement_value] ||= 0
    dataset_classes_and_measurements_count[class_value][measurement_name][measurement_value] += 1
  end
end

puts "K = {#{classes.to_a.join(', ')}}"
puts "|K| = #{classes.size}"

puts "N = #{measurements.size}"

measurements.each_with_index do |(name, values), index|
  dimension = index + 1
  puts "D#{dimension} = {#{values.to_a.join(', ')}}. M#{dimension} = |D#{dimension}| = #{values.size}"
end

dataset_total_count = dataset_classes_count.values.inject(:+)
prior_pr = dataset_classes_count.collect do |name, amount|
  [name, 1.0 * amount/dataset_total_count]
end.to_h

prior_pr.each do |name, value|
  puts "P(C=#{name}) = #{value}"
end

def pr_yx_for(class_name, measurement_name, measurement_value, dataset_classes_and_measurements_count)
  positive_cases = dataset_classes_and_measurements_count[class_name][measurement_name][measurement_value]
  return 0.0 unless positive_cases
  total_cases = dataset_classes_and_measurements_count[class_name][measurement_name].values.inject(:+)
  1.0 * positive_cases / total_cases
end

def pr_x_for(measurement_name, measurement_value, dataset_measurements_count)
  positive_cases = dataset_measurements_count[measurement_name][measurement_value]
  return 0.0 unless positive_cases
  total_cases = dataset_measurements_count[measurement_name].values.inject(:+)
  1.0 * positive_cases / total_cases
end

def pr_xy_for(measurement_name, measurement_value, class_name, dataset_classes_and_measurements_count, dataset_measurements_count)
  pr_yx = pr_yx_for(class_name, measurement_name, measurement_value, dataset_classes_and_measurements_count)
  pr_x = pr_x_for(measurement_name, measurement_value, dataset_measurements_count)
  pr_y_nx = 1.0 - pr_yx
  pr_nx = 1.0 - pr_x
  (pr_yx * pr_x) / (pr_yx * pr_x + pr_y_nx + pr_nx)
end

def e_for(true_class_name, assigned_class_name)
  true_class_name == assigned_class_name ? 1 : -1
end

def pr_yX_for(class_name, measurements, prior_pr, dataset_classes_and_measurements_count, dataset_measurements_count, dataset_measurements_classes_count)
  # P(d | c)
  # pr_Xy = measurements.collect do |measurement_name, measurement_value|
  #   # p [measurement_name, measurement_value, class_name, pr_xy_for(measurement_name, measurement_value, class_name, dataset_classes_and_measurements_count, dataset_measurements_count)]
  #   pr_xy_for measurement_name, measurement_value, class_name, dataset_classes_and_measurements_count, dataset_measurements_count
  #
  # end.inject(:*)

  pr_Xy = if dataset_measurements_classes_count.dig measurements.values, class_name
    1.0 * dataset_measurements_classes_count.dig(measurements.values, class_name) / dataset_measurements_classes_count.dig(measurements.values).values.inject(:+)
  else
    0.0
  end

  # P(c)
  pr_y = prior_pr[class_name]

  # pr_X_ny = measurements.keys.collect do |measurement_name, measurement_value|
  #   1.0 - pr_xy_for(measurement_name, measurement_value, class_name, dataset_classes_and_measurements_count, dataset_measurements_count)
  # end.inject(:*)

  pr_X_ny = 1 - pr_Xy

  pr_X = pr_Xy * pr_y + pr_X_ny * (1.0 - pr_y)

  pr_Xy * pr_y / pr_X
end

classes.to_a.product(*measurements.values.collect(&:to_a)).each do |class_name, *measurement_values|
  current_measurements = measurement_names.zip(measurement_values).to_h
  value = pr_yX_for class_name, current_measurements, prior_pr, dataset_classes_and_measurements_count, dataset_measurements_count, dataset_measurements_classes_count
  puts "Pr(c = #{class_name} | x = { #{current_measurements.values.join(', ')} }) = #{value}"
end
