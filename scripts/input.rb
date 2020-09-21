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
  dataset_classes_count[class_value] ||= 0.0
  dataset_classes_count[class_value] += 1.0
  current_measurements = measurement_names.zip measurement_values
  next if measurement_values.include?('.') || measurement_values.include?('NA')
  dataset_measurements_classes_count[measurement_values] ||= {}
  dataset_measurements_classes_count[measurement_values][class_value] ||= 0.0
  dataset_measurements_classes_count[measurement_values][class_value] += 1.0
  current_measurements.each do |measurement_name, measurement_value|
    measurements[measurement_name].add measurement_value
    dataset_measurements_count[measurement_name][measurement_value] ||= 0.0
    dataset_measurements_count[measurement_name][measurement_value] += 1.0

    dataset_classes_and_measurements_count[class_value] ||= {}
    dataset_classes_and_measurements_count[class_value][measurement_name] ||= {}
    dataset_classes_and_measurements_count[class_value][measurement_name][measurement_value] ||= 0.0
    dataset_classes_and_measurements_count[class_value][measurement_name][measurement_value] += 1.0
  end
end

input_K = classes.to_a
puts "K = {#{input_K.join(',')}}"
puts "|K| = #{input_K.size}"

input_N = measurement_names.to_a.size
puts "N = #{input_N}"

measurements.each_with_index do |(name, values), index|
  dimension = index + 1
  puts "D#{dimension} = {#{values.to_a.join(', ')}}. M#{dimension} = |D#{dimension}| = #{values.size}"
end

dataset_size = dataset_classes_count.values.inject(0.0, :+)
prior_pr = dataset_classes_count.collect do |name, amount|
  [name, amount/dataset_size]
end.to_h

prior_pr.each do |name, value|
  puts "P(C=#{name}) = #{value}"
end

def e_for(true_class_name, assigned_class_name)
  true_class_name == assigned_class_name ? 1 : -1
end

def pr_c_given_D_for(class_name, measurements, prior_pr, dataset_classes_and_measurements_count, dataset_measurements_count, dataset_measurements_classes_count, dataset_classes_count)
  dataset_c_size = dataset_classes_count.fetch(class_name)
  dataset_size = dataset_classes_count.values.inject(0.0, :+)

  # P(c)
  pr_c = dataset_c_size / dataset_size

  # P(~c)
  pr_not_c = 1.0 - pr_c

  # P(D | c)
  dataset_D_and_c_size = dataset_measurements_classes_count.fetch(measurements.values, {})
                                                           .fetch(class_name, 0.0)
  pr_D_and_c = (dataset_D_and_c_size / dataset_size)
  pr_D_given_c = pr_D_and_c / pr_c


  # P(D, ~c)
  dataset_D_and_not_c_size = dataset_measurements_classes_count.fetch(measurements.values, {})
                                                                 .select{ |c| !c.eql?(class_name)}
                                                                 .values
                                                                 .inject(0.0, :+)
  pr_D_and_not_c = dataset_D_and_not_c_size / dataset_size
  pr_D_given_not_c = pr_D_and_not_c / pr_not_c

  # P(D)
  pr_D = pr_D_given_c * pr_c + pr_D_given_not_c * pr_not_c

  # P(c | D) = P(D | c) * P(c) / P(D)
  pr_D > 0 ? ((pr_D_given_c * pr_c) / pr_D) : 0.0
end

classes.to_a.product(*measurements.values.collect(&:to_a)).each do |class_name, *measurement_values|
  current_measurements = measurement_names.zip(measurement_values).to_h
  value = pr_c_given_D_for class_name, current_measurements, prior_pr, dataset_classes_and_measurements_count, dataset_measurements_count, dataset_measurements_classes_count, dataset_classes_count
  puts "Pr(c = #{class_name} | D = { #{current_measurements.values.join(',')} }) = #{value}" if value > 0
end
