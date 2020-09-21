require 'set'

header = STDIN.readline.chomp
header_list = header.split(',')
classification_name = header_list[0]
measurement_names = header_list[1..-1]

classifications = Set.new()
indexes_measurements = measurement_names.each_with_index.collect { |k, v| [v, k] }.to_h
measurements = measurement_names.collect { |name| [name, Set.new()] }.to_h
dataset_classifications_count = {}
dataset_dimensions_count = measurement_names.collect { |name| [name, {}] }.to_h

dataset_classifications_and_measurements_count = {}

STDIN.each_line do |line|
  values = line.chomp.split(',')
  classification_value = values[0]
  classifications.add classification_value
  dataset_classifications_count[classification_value] ||= 0
  dataset_classifications_count[classification_value] += 1
  measurements_values = values[1..-1]
  measurements_values.each_with_index do |measurement_value, index|
    measurement_name = indexes_measurements[index]
    measurements[measurement_name].add measurement_value
    dataset_dimensions_count[measurement_name][measurement_value] ||= 0
    dataset_dimensions_count[measurement_name][measurement_value] += 1

    dataset_classifications_and_measurements_count[classification_value] ||= {}
    dataset_classifications_and_measurements_count[classification_value][measurement_name] ||= {}
    dataset_classifications_and_measurements_count[classification_value][measurement_name][measurement_value] ||= 0
    dataset_classifications_and_measurements_count[classification_value][measurement_name][measurement_value] += 1
  end
end



puts "K = {#{classifications.to_a.join(', ')}}"
puts "|K| = #{classifications.size}"

puts "N = #{measurements.size}"

measurements.each_with_index do |(name, values), index|
  dimension = index + 1
  puts "D#{dimension} = {#{values.to_a.join(', ')}}. M#{dimension} = |D#{dimension}| = #{values.size}"
end

dataset_total_count = dataset_classifications_count.values.inject(:+)
prior_probabilities = dataset_classifications_count.collect do |name, amount|
  [name, 1.0 * amount/dataset_total_count]
end.to_h

prior_probabilities.each do |name, value|
  puts "P(C=#{name}) = #{value}"
end

def p_classification_given_measurement(classification_name, measurement_name, measurement_value, dataset_classifications_and_measurements_count)
  positive_cases = dataset_classifications_and_measurements_count[classification_name][measurement_name][measurement_value]
  # p positive_cases
  total_cases = dataset_classifications_and_measurements_count[classification_name][measurement_name].values.inject(:+)
  # p total_cases
  1.0 * positive_cases / total_cases
end

def p_measurement(measurement_name, measurement_value, dataset_dimensions_count)
  positive_cases = dataset_dimensions_count[measurement_name][measurement_value]
  # p positive_cases
  total_cases = dataset_dimensions_count[measurement_name].values.inject(:+)
  # p total_cases
  1.0 * positive_cases / total_cases
end

def p_measurement_given_classification(measurement_name, measurement_value, classification_name, dataset_classifications_and_measurements_count, dataset_dimensions_count)
  p_classification_given_measurement = p_classification_given_measurement(classification_name, measurement_name, measurement_value, dataset_classifications_and_measurements_count)
  p_measurement = p_measurement(measurement_name, measurement_value, dataset_dimensions_count)
  p_classification_given_not_measurement = 1.0 - p_classification_given_measurement
  p_not_measurement = 1.0 - p_measurement
  (p_classification_given_measurement * p_measurement) / (p_classification_given_measurement * p_measurement + p_classification_given_not_measurement + p_not_measurement)
end

dataset_classifications_and_measurements_count.each do |classification_name, measurements_count|
  measurements_count.each do |measurement_name, measurement_values_count|
    measurement_values_count.each do |measurement_value, _|
      value = p_measurement_given_classification(measurement_name, measurement_value, classification_name, dataset_classifications_and_measurements_count, dataset_dimensions_count)
      puts "P(#{measurement_name}=#{measurement_value} | C=#{classification_name}) = #{value}"
    end
  end
end
