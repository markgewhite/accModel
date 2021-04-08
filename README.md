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

**Data Files**
- GRFFeatures.mat: https://drive.google.com/file/d/1_ik9_cN0nwWBxHgB78vL0O3amHARC9tQ/view?usp=sharing (Ground Reaction Force Features)
- AccelerometerSignals.mat: https://drive.google.com/file/d/1IZOu5ecLt_TrdKJg8Ez6rcwXw-ZfhdhN/view?usp=sharing
These files contain annoymised, processed data.

**GRFFeatures.mat**

*stdResults*: Table listing the jump performance measures and the FPC scores computed from the VGRF data
- Measure: data subset identifier, grouping by jump type (WOA=Without Arms; WA=With Arms) and by FPC type (unrotated; varimax)
- Variable: performance measure identifier (now redundant)
- SubjectID: annoyimised participant identifier
- Trial: trial number (by participant) 1-16 (or higher if jumps were discarded)
- JumpType: legacy field identifying vertical (V) or horizontal (H) jumps (only vertical jumps included) - NB The term jump type in thesis distinguished between jumps with and without arms
- Arms: whether the jump involved arm swing or not (WOA=Without Arms; WA=With Arms) - NB This is jump type in the sense used by the thesis
- Height: jump height attained based on the work done definition
- HeightRecalc: legacy field (ignore)
- TakeOffHeight: gain in height achieved upon take-off
- CMD: countermovement depth - the minimum negative displacement reached during the jump action
- PeakPower: maximum positive relative external power achieved
- PeakNegPower: maximum negative relative external power achieved
- Time0: period in milliseconds from the start of recording to jump initiation
- Time1: duration in milliseconds of the unweighting phase
- Time2: duration in milliseconds of the braking phase
- Time3: duration in milliseconds of the propulsion phase
- Bodyweight: body weight in Newtons
- PCA1-PCA30: FPC scores obtained from FPCA

*curveSet:* Table of 3 cells to lists of resultant acceleration time series in the same three categories as above for (1) all vertical jumps (2) jumps without arms (3) jumps with arms
*curveIDSet:* Table of 3 cells with lists of subject index (not ID) and trial number for same three categories above
*curveFTSet:* Table of 3 cells with lists of flight times for same three categories above
*curveTOSet:* Table of 3 cells with lists of take-off times for same three categories above

*grfFd:* Functional Principal Components for the Vertical Ground Reaction Forces
*grfFdParams:* Parameters defining the smoothing functions
*grfPCA:* Functional Principal Component scores split into unrotated and varimax types

**AccelerometerSignals.mat**

*signal:* structure holding (rows=sensors; cols=jump categories above)
 - raw: resultant acceleration time series (full length)
 - jump: resultant acceleration time series (truncated at jump take-off)
 - norm: padded resultant acceleration time series to standard length of 1001 points
 - takeoff: take-off times in terms of array indices (time series points where one point = 4ms)
NB: row 1 = Lower Back sensor; row 2 = Upper Back sensor; row 3 = Left Shank sensor; row 4 = Right Shank sensor

*signalFd:* multi-level structure categorising the smooth functions describing the acceleration curves
 - <level 1>: all, noarms, arms (jump categorisations)
 - <level 2>: lb, ub, ls, rs (sensor identifiers)
 - <level 3>: acc, d1Acc, d2Acc, vel, pos, pwr (resultant acceleration curves, first derivative curves, second derivative curves, pseudo velocity curves, pseudo position [displacement] curves, pseudo power curves)

*fdParams*: smooth function parameters for the above curves


**NOTE: Although these datafiles contain the processed raw data (generated by another program not included in this repository) it should be understood that the accModel functions do not use this preprocessed data. AccModelRun.m and its subroutines generates a new version of the data each time it is called.** These datafiles are included as a convenience to allow the user to readily see the data that is produced. In an earlier version of the code, the modelling procedures simply took the preprocessed curves generated by the other program.



 





