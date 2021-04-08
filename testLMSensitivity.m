% ************************************************************************
% Script: testLMSensitivity
% Purpose: Test landmark position sensitivity to smoothing parameters
%
% ************************************************************************

clear;

% ************************************************************************
%     MASTER OPTION
% ************************************************************************

dataset = 'Training';


% ************************************************************************
%     Setup file paths
% ************************************************************************

if ismac
    rootpath = '/Users/markgewhite/Google Drive/PhD/Studies/Jumps';
else
    rootpath = 'C:\Users\markg\Google Drive\PhD\Studies\Jumps';
end

switch dataset 
    case 'Training'
        datapath = [ rootpath '\Data\Processed\Training' ];
    case 'Testing'
        datapath = [ rootpath '\Data\Processed\Testing' ];
    case 'All'
        datapath = [ rootpath '\Data\Processed\All' ];
end

if ismac
    datapath = strrep( datapath, '\', '/') ;
end


% ************************************************************************
%   Read data
% ************************************************************************

load( fullfile(datapath, 'AccelerometerSignals') );
load( fullfile(datapath, 'GRFFeatures') );

% ************************************************************************
%   Options
% ************************************************************************

options.nBasis = 50; % number of bases for landmark search
options.lambda = 1E7; % heavily smoothed for landmark search
options.basisOrder = 4;
options.penaltyOrder = 2;
options.doCurvePlots = false; % display plots for checks
options.set.pwrMax1 = true;
options.set.takeoff = false;
options.set.landing = true;
options.set.accd1Max = true;
options.set.pwrMax2 = true;

accRaw = signal.norm{1};
tSpan = -2000:4:2000;
tLanding = curveFTSet{1};

n = size( accRaw, 2 );


l = -5:1:7; % lambda values
m = length(l); 

pwr1 = zeros( n, m );
land = zeros( n, m );
accD1 = zeros( n, m );
pwr2 = zeros( n, m );

for i = 1:m
    options.lambda = 10^l(i);
    landmarks = findACClandmarks( accRaw, tSpan, tLanding, options );
    pwr1( :, i ) = landmarks.case( :, 1 );
    land( : , i ) = landmarks.case( :, 2 );
    accD1( :, i ) = landmarks.case( :, 3 );
    pwr2( :, i ) = landmarks.case( :, 4 );
end

pwr1Diff = pwr1-land;
pwr2Diff = pwr2-land;
accD1Diff = accD1-land;

pwr1RMSE = sqrt(sum( pwr1Diff.^2, 1 )/n );
accD1RMSE = sqrt(sum( accD1Diff.^2, 1 )/n );
pwr2RMSE = sqrt(sum( pwr2Diff.^2, 1 )/n );

pwr1TORMSE = sqrt(sum( pwr1.^2, 1 )/n );






