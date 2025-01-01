%%
addpath(genpath(cd('.')))
%%
clear all; close all; clc

%% manual load of converted nii (only in newer Matlab version):
%use mricron etc. to turn yoru dicoms into a 4D nii
M_stack=niftiread(uigetfile('*.*'));
M0_stack=M_stack(:,:,:,1);  %unsaturated M0
Mz_stack=M_stack(:,:,:,2:end);  % saturated Mz by scale
P.SEQ.w= [-5:0.25:5];   % delta frequencies and offset
P.EVAL.w_interp=P.SEQ.w;
P.SEQ.stack_dim=size(Mz_stack);

%% LOAD Siemens CEST-DATA
[M0_stack, Mz_stack, P] = LOAD('USER'); % thats quite automized, good luck


%% LOAD philips CEST-DATA (rec par)

clear Z Mz_stack M0_stack Mz_CORR

% Set the path to the folder containing the .rec and .par files
[filename, dataFolder] = uigetfile({'*.REC','Philips REC files (*.REC)'; '*.*', 'All Files (*.*)'}, 'Select a Philips REC file');

% Check if the user selected a file
if isequal(filename,0)
    disp('User selected Cancel')
    return  % Exit the script if no file is selected
else
    disp(['User selected ', fullfile(dataFolder, filename)])
end

% Read the .rec file
[imagesOut, ParsOut, meta] = read_par_rec_file(fullfile(dataFolder, filename));

% Display the size of the output images
disp(size(imagesOut));

% Initialize the S matrix
S = imagesOut;

% Extract the M0 image (unsaturated)
M0_stack = S(:, :, :, 1);  % First dynamic is unsaturated M0 image, adjust if necessary

% Extract the Mz images (saturated)
Mz_stack = S(:, :, :, 2:end);  % All the others are the saturated images

% Define the offsets manually
P.SEQ.w = linspace(-5, 5, size(Mz_stack, 4))';

% Define some parameters needed later
P.EVAL.w_fit = (-10:0.01:10)';
P.EVAL.w_interp = P.SEQ.w;
P.SEQ.stack_dim = size(Mz_stack);
P.EVAL.lowerlim_slices = 1;
P.EVAL.upperlim_slices = size(M0_stack, 3);

% Update P.SEQ with essential parameters
P.SEQ.Matrix = ParsOut.Matrix;
P.SEQ.Res_XYZ = ParsOut.Res_XYZ;
P.SEQ.N_slices = ParsOut.N_slices;
P.SEQ.N_dynamics = ParsOut.N_dynamics;
P.SEQ.N_card = ParsOut.N_card;
P.SEQ.Orientation = ParsOut.Orientation;
P.SEQ.offcenter_XYZ = ParsOut.offcenter_XYZ;
P.SEQ.TE = ParsOut.TE;
P.SEQ.N_averages = ParsOut.N_averages;

% Store the header information in meta
metaInfo = meta;

% Clear unnecessary variables
clearvars -except P Mz_stack M0_stack image_z x X ROI_def Segment dB0_stack_ext dB0_stack_int metaInfo

 
%% LOAD GE CEST-DATA (On developing)

clear Z Mz_stack M0_stack Mz_CORR






