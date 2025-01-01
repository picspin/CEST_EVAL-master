CEST_EVAL_branch code adapted for internal research use from M. Zaiss et al. at https://github.com/cest-sources/CEST_EVAL   

The analysis works conventionally on 2-D CEST data. 
Current updates support 3D CEST data but need to modify the run section step by step. 

============

- unzip all files in the package
- load the whole folder into the matlab path
- run sections step by step

## Analysis pipeline 

For a complete CEST evaluation, the general pipeline is the following: 1. process the WASABI series to obtain simultaneous B0- and B1-maps if needed. 2.run B1-correction using multiple B0-corrected Mz series acquired at different B1 values. 3. The corrected Z-spectra are stored in the variable `Z_corrExt`. 4. performing pixel-wise Multi-Lorentzian fitting of the corrected Z-spectra. This allows us to evaluate separate CEST peaks (amide, amine, etc.) and calculate CEST contrast images using different metrics.      

Create a `P` structure containing parameters for the fitting functions. Parameters are extracted automatically from Simens dicom metadata files, for Philips rec  file seperately run batch's Philip section as well; for other vendor  run ini section for `.ini` file loaded or manual input should be needed.   

Define an image ROI mask (consisting of 1s and NaNs) called `Segment` that selects pixels for all following analyses. Create it manually with the `make_Segment` UI tool, or load a predefined one.     

### Computing Z-spectra
The Z-spectrum for each pixel is obtained by normalizing the `Mz_stack` image by `M0_stack`. This is the most basic operation to visualize and quantify CEST effects.
```matlab
Z_uncorr = NORM_ZSTACK(Mz_stack, M0_stack, P, Segment);
```     
#### B0-correction using internal map 

(1) Calculate an internal dB0 map. This is given by the x-axis offset of the minimum of the interpolated Z-spectrum from the nominal 0 ppm.
```matlab
dB0_stack_int = MINFIND_SPLINE_3D(Mz_stack, Segment, P);
```
(2)  Then do pixel-wise B0 correction. This simply centers each pixel’s Z-spectrum by shifting it by the calculated x-offset dB0 map):
```matlab
Mz_CORR = B0_CORRECTION(Mz_stack, dB0_stack_int, P, Segment);
```
(3) Finally, compute B0-corrected Z-spectra using `NORM_ZSTACK`.    

#### Multi-Lorentzian fitting of Z-spectra 

To model CEST effects of interest we fit a sum of Lorentzian line shapes to each pixel’s Z-spectrum. The fit is performed pixel-wise by calling `FIT_3D` with fitting parameters specified in the `P`structure (default is 5-pool model: water, amine, amide, NOE, MT). The function `get_FIT_LABREF` then calculates Zlab and Zref (used for CEST contrasts).

For pH-weighted Ultravist-CEST, use the function:
```matlab
[Zlab, Zref, P, popt] = lorentzianfit_main(Z_corrExt, P, Segment, 'invivo');
```
The ‘invivo’ argument specifies a 6-pool Lorentzian model that includes Ultravist peaks (water, amine, amide, NOE, 5.6ppm, 4.2ppm). For phantom scans, set the argument to ‘ultravist’. This fits a 3-pool model corresponding to Ultravist peaks only (Chen et al., 2014).

`Zlab` is the full n-pool fit (the 'label' image). `Zref` is a structure containing reference images for each pool i (i.e. for each pixel, the sum of all Lorentzians _excluding_ pool i).

#### CEST contrasts calculation 

The CEST effect can be quantified using different metrics:

 - **MTR_asym** _(not implemented)_: Magnetization Transfer Ratio asymmetry. It is simply computed as the difference between each Z-value and the value at the symmetrically opposite spectral location.
 - **MTR_LD**: Magnetization Transfer Ratio, where the asymmetry is calculated as linear difference between Zref and Zlab at each frequency offset. This measure is confounded by water saturation spillover effects (‘dilution’ of the Z-spectrum), especially at higher B1 strengths (Zaiss et al., 2014).
 - **MTR_Rex**: Magnetization Transfer Ratio, where the asymmetry is calculated as the difference of the reciprocal terms. Does spillover- and MT-correction.
 - **AREX** (Apparent Exchange-Dependent Relaxation): MTR_Rex normalized by T1 map. Relaxation-compensated measure.

### Exporting CEST images 
CEST contrast images can be written to DICOM format. However, DICOM stores data in uint16 type. This means that CEST contrast values (encoded as double-precision floating point, typically smaller than 1) will be automatically re-scaled to unsigned integers. To be able to recover the original values, together with the DICOM file we also save a .mat file ('[filename]_ScalingFactorMap') with the pixel-wise scaling factors. This way, if you load into MATLAB a DICOM CEST image (e.g. after ROI analysis in PMOD) you can convert the pixel values back to the original scale and then do statistics and further analyses on them.

Additional acquisitions that are used for field inhomogeneity corrections and for T1 mapping, by Morit Zaiss, [Magn Reson Med. 2017 Feb;77(2):571-580.](https://doi.org/10.1002/mrm.26133):

 - **Mz** image series at different B1 strengths: e.g. with B1 = 0.5-3.0 muT. At least two such series are needed for B1-inhomogeneity correction with the 'Z-B1-correction' method (see Windschuh et al., 2015). Note that B1 correction also requires a B1 map obtained with a WASABI sequence.
 - **WASABI**: image series for simultaneous B0- ("WAter Shift") and B1- ("BI") mapping. These maps are used for field inhomogeneity correction (see Schuenke et al., 2016).
 - **T1 mapping sequence**: a series of scans with different
inversion recovery times for T1 mapping. A T1 map is needed for calculating the relaxation-compensated CEST contrast, AREX (see 'Contrasts' below).


CEST sources - Copyright (C) 2014  Moritz Zaiss
**********************************
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or(at your option) any later version.
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **********************************

