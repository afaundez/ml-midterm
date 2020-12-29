# ml-midterm

```sh
bin/midterm
```

## Documentation

### Probabilities

```tex
P(c \mid d) = P(d \mid c) * P(c) / P(d)
P(c \mid d) = P(c \mid d) * P(d) = P(d \mid c) * P(c)
```

### slides case

```ruby
priors = Vector[0.6, 0.4]
likelihoods = Matrix[
  Vector[0.12, 0.18, 0.3] / 0.6 ,
  Vector[0.2, 0.16, 0.04] / 0.4
]
economic_gain_matrix = Matrix[[1, 0], [0, 2]]
dimensions = [[0, 1, 2]]
klass = Dimension.new 2, pdf: priors
space = Space.new dimensions
classifier = Classifier.new
classifier.fit space: space, klass: klass,
                             economic_gain_matrix: economic_gain_matrix,
                             likelihoods: likelihoods
classifier.summary
```

## Help

```sh
Usage: midterm [options]
        --seed [INT]                 Pseudo-random seed, an integer. Default: 1234
    -c, --classes [INT]              Class cardinality. Default 2
    -m, --measurements [INT]         Measurements size. Default 5
        --measurement-min-cardinality [INT]
                                     Measurement Min Cardinality. Default 3
        --measurement-max-cardinality [INT]
                                     Measurement Max Cardinality. Default 6
    -s, --sample-size [INT]          Sample size. Default space.addresses.size * 10
    -i, --iterations [INT]           Iterations. Default 2
    -d, --delta [FLOAT]              Delta. Default: 0.01
    -h, --help                       Prints this help
```
