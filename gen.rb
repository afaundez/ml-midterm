# TODO: refactor helpers
def normalize(vector)
  sum = vector.sum.to_f
  vector.collect { sum <= 0 ? 0.0 : _1 / sum }
end

def linear_address_for(measurement, dimensions:) # linear address
  dimensions_sizes = dimensions.collect(&:size)
  jumps = dimensions_sizes.inject([1]) { |memo, size| memo << memo.last * size }
                          .take(dimensions.size)
  jumps.zip(measurement)
       .collect { |j, dn| j * dn }
       .sum
end

def address_book(dimensions)
  @address_book ||= dimensions.first.to_a.product(*dimensions[1..-1].collect(&:to_a)).collect do |m|
    [linear_address_for(m, dimensions: dimensions), m]
  end.to_h
end

def measurement_for(linear_address, dimensions:)
  address_book(dimensions)[linear_address]
end

def build_pdf(size)
  normalize size.times.collect { rand }
end

def build_cdf(pdf)
  pdf.inject([0]) { |memo, pr| memo << memo.last + pr }
     .slice(1..-1)
end

def random_value(cdf)
  x = rand
  return 0 if x < cdf.first
  (cdf.size - 1).times do |i|
    return i + 1 if (cdf[i]..cdf[i + 1]).cover? x
  end
end

def matrix_trace(matrix)
  (0...matrix.size).collect { |i| matrix[i][i] }.sum
end

# TODO: refactor steps
def generate_samples(size, class_cdf, dimensions_cdfs, dimensions)
  size.times.collect do
    klass = random_value class_cdf
    measurement = dimensions_cdfs.collect { |cdf| random_value cdf }
    address = linear_address_for measurement, dimensions: dimensions
    [klass, address]
  end
end

def build_measurement_conditionals_pdfs(samples, measurements_addresses, classes, class_conditional_pdfs, class_pdf)
  count_by_class = classes.collect { 0.0 }
  count_by_measurement_address_and_class = measurements_addresses.collect { classes.collect { 0.0 } }
  samples.each do |true_class, measurement_address|
    count_by_class[true_class] += 1.0
    count_by_measurement_address_and_class[measurement_address][true_class] += 1.0
  end
  pr_by_class = normalize count_by_class
  pr_by_measurement_address_and_class = count_by_measurement_address_and_class.collect { normalize _1 }
  measurements_addresses.collect do |measurement_address|
    pr_d = pr_by_class.each_with_index.collect { |pr_c, klass| class_conditional_pdfs[klass][measurement_address] * pr_c }.sum
    classes.collect do |true_class|
      pr_d_given_c = class_conditional_pdfs[true_class][measurement_address]
      pr_c = pr_by_class[true_class]
      pr_d_given_c * pr_c / pr_d
    end
  end
end

def build_bayes_rules_decisions(measurements_addresses, classes, measurement_conditionals_pdfs, economic_gain_matrix)
  measurements_addresses.collect do |measurement_address|
   classes.inject([nil, -Float::INFINITY]) do |(maximizing_class, maximized_expected_gain), assigned_class|
     assigned_class_expected_gain = classes.inject(0.0) do |memo, true_class|
       pr_true_class_given_measurement = measurement_conditionals_pdfs[measurement_address][true_class]
       economic_gain = economic_gain_matrix[true_class][assigned_class]
       memo + economic_gain * pr_true_class_given_measurement
     end
     if maximized_expected_gain < assigned_class_expected_gain
       maximized_expected_gain = assigned_class_expected_gain
       maximizing_class = assigned_class
     end
     [maximizing_class, maximized_expected_gain]
   end.first
 end
end

def build_confusion_matrix(classes, bayes_rules_decisions, measurement_conditionals_pdfs)
  classes.collect do |true_class|
    classes.collect do |assigned_class|
      measurement_conditionals_pdfs.each_with_index.collect do |measurement_conditionals_pdf, address|
         bayes_rules_decisions[address] == assigned_class ? measurement_conditionals_pdf[true_class] : 0.0
      end.sum
    end
  end
end

def calculate_expected_gain(classes, economic_gain_matrix, confusion_matrix)
  classes.collect do |true_class|
    classes.collect do |assigned_class|
      economic_gain_matrix[true_class][assigned_class] * confusion_matrix[true_class][assigned_class]
    end.sum
  end.sum
end

def improve_class_conditionals(delta, samples, bayes_rules_decisions, class_conditional_pdfs)
  samples.each do |true_class, measurement_address|
    assigned_class = bayes_rules_decisions[measurement_address]
    next if true_class == assigned_class

    true_class_conditional_pdf = class_conditional_pdfs[true_class]
    true_class_conditional_pdf[measurement_address] += delta
    class_conditional_pdfs[true_class] = normalize class_conditional_pdfs[true_class]
  end
  class_conditional_pdfs
end

# TODO: refactor singletons
srand 1234
classes_space_size = rand 2..3
classes = 0...classes_space_size
class_pdf = build_pdf classes_space_size
class_cdf = build_cdf class_pdf

dimensions_size = rand 5..6
dimension_min_size = 3
dimension_max_size = 5
dimensions = (0...dimensions_size).collect { (0...(rand dimension_min_size..dimension_max_size)).to_a }
dimensions_pdfs = dimensions.collect { |dimension| build_pdf dimension.size }
dimensions_cdfs = dimensions_pdfs.collect { |pdf| build_cdf pdf }

measurement_space_size = dimensions.collect(&:size).inject(:*)
measurements_addresses = 0...measurement_space_size

class_conditional_pdfs = classes.collect { build_pdf measurement_space_size }

economic_gain_matrix = classes.collect do |true_class|
  classes.collect { |assigned_class| true_class == assigned_class ? 1.0 : 0.0 }
end

sample_size = measurement_space_size / 10
iterations = 200
delta = 0.025

puts "classes: #{classes.to_a}"
puts "dimensions sizes: #{dimensions.collect(&:size)}"
puts "sample_size: #{sample_size}"

iterations.times do |iteration|
  samples = generate_samples sample_size, class_cdf, dimensions_cdfs, dimensions
  measurement_conditionals_pdfs = build_measurement_conditionals_pdfs samples, measurements_addresses, classes, class_conditional_pdfs, class_pdf
  bayes_rules_decisions = build_bayes_rules_decisions measurements_addresses, classes, measurement_conditionals_pdfs, economic_gain_matrix
  confusion_matrix = build_confusion_matrix classes, bayes_rules_decisions, measurement_conditionals_pdfs
  expected_gain = calculate_expected_gain classes, economic_gain_matrix, confusion_matrix
  class_conditional_pdfs = improve_class_conditionals delta, samples, bayes_rules_decisions, class_conditional_pdfs

  trace = matrix_trace confusion_matrix
  puts "#{iteration}.\tConfusion Matrix Trace: #{trace / sample_size.to_f / 10.0}\tExpected Gain: #{expected_gain / 10.0}"
end
