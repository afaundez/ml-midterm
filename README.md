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
    -s, --seed [INT]                 Pseudo-random seed, an integer. Default: nil
    -K, --classes [INT]              Class cardinality. Default 2
    -N [INT],                        Measurements Cardinality. Default 3
        --measurements-cardinality
    -M [INT],                        Cardinality for all measurements. Default 4
        --measurement-cardinality
        --measurement-min-cardinality [INT]
                                     Min Cardinality for all measurements. Default 2
        --measurement-max-cardinality [INT]
                                     Max Cardinality for all measurements. Default 4
    -Z, --sample-size [INT]          Sample size. Default space.addresses.size * 10
    -R, --repetitions [INT]          Repetitions. Default 1
    -D, --delta [FLOAT]              Delta. Default: 0.01
    -V, --folds [FLOAT]              Number of Folds. Default: 3
    -h, --help                       Prints this help
```
