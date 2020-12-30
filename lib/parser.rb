# frozen_string_literal: true

require 'optparse'

DEFAULTS = {
  seed: nil,
  class_cardinality: 2,
  measurements_cardinality: 3,
  measurement_cardinality: 4,
  measurement_min_cardinality: 2,
  measurement_max_cardinality: 4,
  experiments: 1,
  delta: 0.01,
  sample_size: nil,
  overlap: true,
  distribution: :random,
  k_folds: 10,
  repetitions: 1
}

Options = Struct.new(*DEFAULTS.keys)

class Parser
  def self.parse(args)
    options = Options.new(*DEFAULTS.values)

    opt_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: midterm [options]'

      opts.on('-s', '--seed [INT]', 'Pseudo-random seed, an integer. Default: nil') do |value|
        options.seed = value.to_i
      end

      opts.on('-c', '--classes [INT]', 'Class cardinality. Default 2') do |value|
        options.class_cardinality = value.to_i
      end

      opts.on('-m', '--measurements-cardinality [INT]', 'Measurements Cardinality. Default 3') do |value|
        options.measurements_cardinality = value.to_i
      end

      opts.on('-l', '--measurement-cardinality [INT]', 'Cardinality for all measurements. Default 4') do |value|
        options.measurement_cardinality = value.to_i
      end

      opts.on('--measurement-min-cardinality [INT]', 'Min Cardinality for all measurements. Default 2') do |value|
        options.measurement_min_cardinality = value.to_i
      end

      opts.on('--measurement-max-cardinality [INT]', 'Max Cardinality for all measurements. Default 4') do |value|
        options.measurement_max_cardinality = value.to_i
      end

      opts.on('--sample-size [INT]', 'Sample size. Default space.addresses.size * 10') do |value|
        options.sample_size = value.to_i
      end

      opts.on('-e', '--experiments [INT]', 'Experiments. Each experiment create a new classifier. Default 1') do |value|
        options.experiments = value.to_i
      end

      opts.on('-r', '--repetitions [INT]', 'Repetitions. Default 1') do |value|
        options.repetitions = value.to_i
      end

      opts.on('-d', '--delta [FLOAT]', 'Delta. Default: 0.01') do |value|
        options.delta = value.to_f
      end

      opts.on('--no-overlap', 'Generate classes based on measurements') do |value|
        options.overlap = false
      end

      opts.on('--uniform', 'Use uniform distribution on all dimensions') do |value|
        options.distribution = :uniform
      end

      opts.on('-h', '--help', 'Prints this help') do
        puts opts
        exit
      end
    end

    opt_parser.parse!(args)
    return options
  end
end
