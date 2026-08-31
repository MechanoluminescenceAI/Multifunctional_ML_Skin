# Interactive 3D Mechanoluminescence Reconstruction

This repository contains MATLAB code for interactive visualization of three-dimensional (3D) mechanoluminescence (ML) reconstruction and 3D digital image correlation (DIC) results.

The interactive viewer provides four visualization modes:

- 3D point cloud
- Triangular mesh
- Reconstructed 3D ML
- 3D effective strain

## Repository Structure

```text
3D_ML_reconstruction/
├── data/
│   └── ML_images_camera_1/
├── reconstruct_3D_ML_interactive.m
└── README.md
```

`DIC3DPPresults.mat` contains the reconstructed 3D geometry, DIC-tracked image coordinates, triangular faces, and effective strain data. Owing to its large file size, the file is distributed separately from the GitHub repository as part of the complete reproducibility dataset.

The `ML_images_camera_1` folder contains the corresponding ML images used for 3D ML reconstruction.

## 3D ML Reconstruction

For each frame, ML image information is sampled at the DIC-tracked image coordinates and assigned to the corresponding vertices of the reconstructed 3D surface. The mapped ML values are interpolated over the triangular surface mesh to visualize ML emission on the reconstructed deforming surface.

The effective strain visualization uses the corresponding effective strain values obtained from the 3D DIC analysis.

## Software Requirements

The code was tested using:

- MATLAB R2019a (9.6.0.1174912, Update 5)
- Image Processing Toolbox
- Statistics and Machine Learning Toolbox
- Microsoft Windows 10

The code may also run with later MATLAB releases, although these were not specifically tested.

## Running the Code

For complete reproduction, place `DIC3DPPresults.mat` in the `data` directory:

```text
3D_ML_reconstruction/
├── data/
│   ├── DIC3DPPresults.mat
│   └── ML_images_camera_1/
├── reconstruct_3D_ML_interactive.m
└── README.md
```

Then:

1. Open MATLAB.
2. Set the MATLAB **Current Folder** to the `3D_ML_reconstruction` directory.
3. Open `reconstruct_3D_ML_interactive.m`.
4. Click **Run**.

The code automatically loads the required data and opens the interactive 3D viewer.

## Interactive Visualization

The viewer allows the user to:

- switch between the 3D point cloud, triangular mesh, reconstructed 3D ML, and effective strain;
- navigate through individual frames;
- rotate the reconstructed surface;
- zoom and pan;
- switch between top and oblique views;
- show or hide the coordinate axes;
- show or hide the effective-strain colorbar.

## Optional Export

The viewer provides optional controls to export:

- the currently displayed visualization as a PNG image;
- the selected visualization mode as an MP4 video.

The `results` folder is created automatically when an image or video is exported.
