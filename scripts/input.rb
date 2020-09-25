require_relative 'data_set'

header = STDIN.readline.chomp
dataset = DataSet.new header

STDIN.each_line do |line|
  category, *measurement = line.chomp.split(',')
  next if measurement.include?('.') || measurement.include?('NA')
  c = dataset.category_to_c category
  d = dataset.measurement_to_d measurement
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
