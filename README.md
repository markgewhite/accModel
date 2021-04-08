# accModel
FPCA-based model for predicting peak power in the countermovement jump from accelerometer data  
This project supports my PhD thesis, "Generalised FPCA-based model for predicting peak power in the countermovement jump using accelerometer data".
My thesis is in final draft form prior to submission. I will provide a link to it once it is submitted.

The code takes raw data from triaxial accelerometers worn by participants who performed the countermovement jump (CMJ) with or without arm swing. 
The data files are annoymised and were prepared separately, grouped by sensor anatomical location and jump type.
The peak power output was calculated from the vertical ground reaction force data using standard methods.
Functional Principal Component Analysis (FPCA) extracts the features from the smoothed acceleration curves. The FPC scores serve as inputs to the machine learning models.
See https://www.psych.mcgill.ca/misc/fda/

Nested cross validation is employed to select the models (parameters) and estimate their generalised predictive error on unseen data drawn from the same distribution.
For model selection, a novel optimisation procedure is implemented based on a constrainted random search of parameter values generating observations from the model. The procedure finds the global optimum of a surrogate model using Particle Swarm Optimisation. The surrogate model is based on a Gaussian Process.
The estimate of a selected model is based on Monte Carlo cross validation.
The modelling procedure is highly flexible with around 40 different parameters. The parameters govern the choice of sensor data set, model type, hyperparameter values, time windows, functional smoothing, feature selection and data augmentation methods. The whole modelling procedure, including all these elements, is subject to optimisation and nested cross validation, not just the model itself.

**Prerequisites**
Latest version of MATLAB:
 - Communications Toolbox
 - Deep Learning Toolbox
 - Global Optimization Toolbox
 - Optimization Toolbox
 - Signal Processing Toolbox
 - Statistics and Machine Learning Toolbox

Functional Principal Component Analysis Library for MATLAB:
 - https://www.psych.mcgill.ca/misc/fda/downloads/FDAfuns/Matlab/

**Key Files**

*Top level:*
- accAnalysis3.m: main script that reads data files, sets parameters, prepares data structures, calls the functions to perform the analysis
- gridSearch.m: performs a grid search for one or two specified parameters
- randomSearch.m: performs the novel optimisation procedure based on a random search at its heart (used extensively in the thesis)
- modelContourPlot.m: produces the surrogate model plots

*Accelerometer Function* 
- accModelRun.m: accelerometer model (AM) function which performs all data preprocessing, augmentation, registration, partitioning prior to an inner cross validation loop in which the models are fitted

*Partitioning*
- partitionData.m: partitions the data set according to the specified method: K-Fold CV, Monte Carlo CV, Bootstrap, Leave One Out (by trial or by participant)

*Data Preprocessing*
- signalTransforms.m: pads out the variable-length time series to a standard specified length, including calculating the resultant if 1D or rotational transformations if 3D
- signalFDA.m: converts time series into smooth functions using FDA library routines
- deriveAccCurves.m: generate transformed curves, either through time derivatives or integrals, including the pseudo power curves

*Curve Registration*
- findACClandmarks.m: locates the landmarks for each accelerometer curve (two pseudo power maxima)
- registerCurves.m: performs landmark curve registration using the FDA library routines

*Model Selection*
- assemblePredictors.m: constructs a superset of predictors made up of FPC scores from one or multiple curves (with or without FPCA partitioning), including timewarp FPCs, if appropriate
- filterPredictors.m: selects predictors based on a specified method

*Augmentation*
- resampleData.m: utility-based data augmentation (oversampling and undersampling) targetting sparse regions of the outcome distribution and optionally some of the predictors' distributions (includes option to use SMOTER or Signal Rotations methods)
- augCaseSMOTER.m: implmentation of SMOTER algorithm for augmentation (Chawla, 2006) based on linear algebra for more efficient execution
- augCaseRotation.m: implementation of novel Signal Rotations algorithm which rotates the triaxial accelerometer signals


