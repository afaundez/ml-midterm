# TODO: check if it is ok discretize float values
positions_averages = {
  2 => 43,
  3 => 17,
  4 => 200,
  5 => 4200
}

puts STDIN.readline.chomp

STDIN.each_line do |line|
  non_discrete_values = line.chomp.split(',')
  discrete_values = non_discrete_values.each_with_index.collect do |measurement, position|
    next measurement unless positions_averages.key? position
    measurement_value = measurement.to_f
    measurement_average = positions_averages[position]
    measurement_value < measurement_average ? :small : :large
  end
  puts discrete_values.to_a.join(',')
end
