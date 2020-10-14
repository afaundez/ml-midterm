srand 1236
_Z = 1000 # sample size
_K = rand 2..4 # number of classes
_N = rand 2..7 # measurement dimensions
_Mn_max = 10

_C = (0..(_K - 1)).to_a # classes
_L = _N.times.collect { (0..rand(1..(_Mn_max - 2))).to_a } # measurement values
_M = _L.first.product(*_L[1..-1]) # all measument combinations

def f(_L, d) # linear address
  jumps = _L.collect(&:size)
            .inject([1]) { |memo, size| memo << memo.last * size }
            .take(_L.size)
  jumps.zip(d)
       .collect { |j, dn| j * dn }
       .sum
end

def build_dist(size)
  numbers = size.times.collect { rand }
  sum = numbers.sum
  numbers.collect { |number| number / sum }
         .inject([0]) { |memo, pr| memo << memo.last + pr }
         .slice(1..-1)
end

def h(dist) # class assignement
  x = rand
  return 0 if x < dist.first
  (dist.size - 1).times do |i|
    return i + 1 if dist[i] <= x && x < dist[i + 1]
  end
end

_S = _L.collect(&:size).inject(:*)

p_d_given_c = _C.collect { |c| [c, build_dist(_S)] }.to_h

c_dist = build_dist _K

_L_dists = _L.collect do |_l|
  build_dist _l.size
end

_h = _M.inject([]) do |acum, d|
  _f = f _L, d
  acum[_f] = h c_dist
  acum
end

_Z.times do
  x = _L_dists.collect { |l_dist| h l_dist }
  c = _h[f(_L, x)]
  puts [c, x].flatten.join(',')
end
