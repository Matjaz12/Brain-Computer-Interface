# Brain Computer Interface

Implementation of a brain computer interface to
classify between two motor activities.

## Usage
In order to evaluate the classifier we have to first compute
the features, this can be done using the following command:

`computeFeatures(<subject>, <task>, <nFeatures>, <arFeatures>)`

`computeFeatures('S001', 'Task2', 4, true)`

Once we computed the features we can evaluate the classifier
using:

`doClassification("featureVectors.txt", "referenceClass.txt", {1, 1}, 10, 30, 0)`