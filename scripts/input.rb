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

c_space = dataset.K.each_with_index.collect { |_, i| i }
d_spaces = dataset.L

puts "K = categories = #{c_space}"
puts "|K| = #{c_space.size}"
puts "L = #{d_spaces}"
puts "N = |L| = #{d_spaces.size}"
puts "M = #{dataset.M}"

pr_c_given_d = c_space.collect { |_| [] }

c_space.product(*d_spaces).each do |c, *d|
  pr_c_given_d[c][dataset.linear_address(d)] = dataset.pr_c_given_D c, d
  # pr = pr_c_given_d[c][dataset.linear_address(d)]
  # puts "Pr(c = #{c} | D = [ #{d.join(', ')} ]) = #{pr}" if pr > 0
  # category = dataset.c_to_category c
  # measurements = dataset.d_to_measurement d
  # puts "Pr(c = #{category} | D = { #{measurements.join(',')} }) = #{value}" if value > 0
end

e = c_space.collect{ |_| c_space.collect { |_| 0.0 }}
c_space.product(c_space) do |cj, ck|
  e[cj][ck] = (cj == ck) ? 1.0 : -1.0
end

dimensions = d_spaces[0].product(*d_spaces[1..-1])
                        .map { |d| dataset.linear_address d }
bayes_rule = dimensions.collect { |_| c_space.collect { |_| 0.0 } }
dimensions.each do |d|
  max_sum_ck = nil
  d_ck_cj_max_sum = nil
  c_space.each do |ck|
    d_ck_cj_sum = c_space.inject(0.0) do |sum, cj|
      sum + pr_c_given_d[cj][d] * e[cj][ck]
    end
    if !d_ck_cj_max_sum || d_ck_cj_max_sum < d_ck_cj_sum
      d_ck_cj_max_sum = d_ck_cj_sum
      max_sum_ck = ck
    end
  end
  bayes_rule[d][max_sum_ck] = 1.0
end

# bayes_rule.each { |br| p br}

confusion_matrix = c_space.collect{ |_| c_space.collect { |_| 0.0 } }
c_space.product(c_space) do |cj, ck|
  prods = dimensions.collect do |d|
    bayes_rule[d][ck] * pr_c_given_d[cj][d]
  end
  confusion_matrix[cj][ck] = prods.inject(:+)
end

puts "Confusion Matrix"
confusion_matrix.each {|c| p c}

puts "Expected Gain"
e_g = c_space.collect do |ck|
  dimensions.collect do |d|
    e_prod_pr = c_space.collect do |cj|
      e[cj][ck] * pr_c_given_d[cj][d]
    end.inject(:+)
    bayes_rule[d][ck] * e_prod_pr
  end.inject(:+)
end.inject(:+)
p e_g







# def e(true_class_name, assigned_class_name)
#   true_class_name == assigned_class_name ? 1 : -1
# end
