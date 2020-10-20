# frozen_string_literal: true

require_relative 'dimension'

# Space
class Space
  attr_accessor :class_dimension, :measurements_dimensions, :likelihoods

  def initialize(class_dimension, measurements_dimensions)
    @class_dimension = class_dimension
    @measurements_dimensions = measurements_dimensions
    rows = classes.collect { Dimension.build_pdf addresses.size }
    @likelihoods = Matrix.rows rows
  end

  def classes
    @class_dimension.values
  end

  def dimensions
    @measurements_dimensions
  end

  def update_likelihoods(klass, address, delta = 0.025)
    matrix = likelihoods.to_a
    pdf = matrix[klass]
    pdf[address] += delta
    matrix[klass] = Dimension.normalize Vector.elements(pdf)
    @likelihoods = Matrix.rows matrix
  end

  def dimensions_product
    @dimensions_product ||= dimensionsfirst.product(*dimensions[1..-1])
  end

  def address_book
    @address_book ||= dimensions_product.collect do |coordinates|
      measurement = Measurement.new coordinates
      [measurement.linear_address, measurement]
    end.to_h
  end

  def addresses
    (0...dimensions.collect(&:size).inject(:*)).to_a
  end

  def address(measurement)
    jumps = dimensions.collect(&:size)
                      .inject([1]) { |memo, size| memo << memo.last * size }
                      .take(dimensions.size)
    jumps.zip(measurement)
         .collect { |j, dn| j * dn }
         .sum
  end

  def measurement(address)
    address_book(dimensions)[address]
  end
end
