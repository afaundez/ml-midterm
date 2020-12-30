# frozen_string_literal: true

# Add dsl to std Enumerable
module Enumerable
  def argmax
    each_with_index.max.last
  end
end
