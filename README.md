# Brain Computer Interface


## About
In this work we implement a brain computer interface
(BCI), capable of classifying between two imaginary motor
activities, namely opening and closing of the left and right fist. We
extracted two types of features from raw electroencephalogram
(EEG) signals using common spatial patterns (CSP) and the
autoregressive method (AR). We trained two classifiers Linear
discriminant analysis (LDA) and Quadratic Discriminant Analy-
sis (QDA). We evaluated models performance on a single subject
from the EEG MMIDB database. We were able to overfit the
dataset and achieve AUC of 100%, the best AUC using 10 fold
cross validation with 30 repetitions was 66.68%.

For further detail please read [BCI](BCI.pdf)

## Usage
In order to evaluate the classifier we have to first compute
the features, this can be done using the following command:

`computeFeatures(<subject>, <task>, <nFeatures>, <arFeatures>)`

`computeFeatures('S001', 'Task2', 4, true)`

Once we computed the features we can evaluate the classifier
using:

`doClassification("featureVectors.txt", "referenceClass.txt", {1, 1}, 10, 30, 0)`
