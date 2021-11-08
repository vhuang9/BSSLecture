% Independent component analysis using classical methods
%
% BMI500 Course
% Lecture:  An Introduction to Blind Source Separation and Independent Component Analysis
%           By: R. Sameni
%           Department of Biomedical Informatics, Emory University, Atlanta, GA, USA
%           Fall 2020
%
% Dependency: The open-source electrophysiological toolbox (OSET):
%       https://github.com/alphanumericslab/OSET.git
%   OR
%       https://gitlab.com/rsameni/OSET.git
%

clc
clear
close all

example = 1;  % test the case on EEGdata2 rather than the synthetically generated data
% example = 3;
switch example
    case 1 % A sample EEG from the OSET package
        load EEGdata2 textdata data % Load a sample EEG signal
        fs = 250;
        x = data'; % make the data in (channels x samples) format
        % Check the channel names
        disp(textdata)
    case 2 % A sample ECG from the OSET package
        load SampleECG2 data % Load a sample ECG signal
        fs = 1000;
        x = data(:, 2:end)'; % make the data in (channels x samples) format
        x = x - LPFilter(x, 1.0/fs); % remove the lowpass baseline
    case 3 % A synthetic signal
        fs = 500;
        len = round(3.0*fs);   % generating signal of length 3 seconds
        % 3 signals (s1, s2, s3) with phase lag in between them; the third
        % signal is a rectangular pulse signal with a period of 76 samples
        % (this is random can play around with this); A is the matrix that
        % is unknown to algorithm (random 3x3) mixing up the sources and
        % adding a small portion of noise to the algorithm
        % N channels and T samples
        s1 = sin(2*pi*7.0/fs * (1 : len));
        s2 = 2*sin(2*pi*1.3/fs * (1 : len) + pi/7);
        period = 76.0;
        s3 = (mod(1:len, 76.0) - period/2)/(period/2);
        A = rand(3);
        noise = 0.01*randn(3, len);
        x = A * [s1 ; s2 ; s3] + noise;
    otherwise
        error('unknown example');
end

N = size(x, 1); % The number of channels
T = size(x, 2); % The number of samples per channel

% Plot the channels
PlotECG(x, 4, 'b', fs, 'Raw data channels');

% Run fastica
approach = 'symm'; % 'symm' symmetric: want to come up with whole matrix A 
%at the same time instead of extracting 1 at a time or 'defl' deflation
g = 'tanh'; % 'pow3', 'tanh', 'gauss', 'skew'; nonlinear transformation
lastEigfastica = N; % PCA stage
numOfIC = N; % ICA stage
interactivePCA = 'off';   % not applying PCA for dimensionality reduction like in ex. 1
[s_fastica, A_fatsica, W_fatsica] = fastica (x, 'approach', approach, 'g', g, 'lastEig', lastEigfastica, 'numOfIC', numOfIC, 'interactivePCA', interactivePCA, 'verbose', 'off', 'displayMode', 'off');

% Check the covariance matrix
Cs = cov(s_fastica');

% Run JADE (JADE algorithm)
lastEigJADE = N; % PCA stage
% selecting number of eigenvalues to preserve
W_JADE = jadeR(x, lastEigJADE);   % using real value of JADE algorithm for separating signals
s_jade = W_JADE * x;

% Run SOBI  (linear method)
lastEigSOBI = N; % PCA stage
num_cov_matrices = 100;
[W_SOBI, s_sobi] = sobi(x, lastEigSOBI, num_cov_matrices);

% Plot the sources
PlotECG(s_fastica, 4, 'r', fs, 'Sources extracted by fatsica');

% Plot the sources
PlotECG(s_jade, 4, 'k', fs, 'Sources extracted by JADE');

% Plot the sources
PlotECG(s_sobi, 4, 'm', fs, 'Sources extracted by SOBI');