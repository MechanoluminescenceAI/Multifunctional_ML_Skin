# Multifunctional ML Skin

This repository contains the code and associated data supporting the computational analyses of the multifunctional mechanoluminescent (ML) skin.

The repository contains two analysis workflows.

## 1. 3D ML Reconstruction

`3D_ML_reconstruction/`

MATLAB-based interactive reconstruction and visualization of:

- 3D point cloud
- Triangular surface mesh
- Reconstructed 3D mechanoluminescence (ML)
- 3D effective strain

The interactive viewer allows frame-by-frame inspection, rotation, zooming, panning, and optional image or video export.

The large `DIC3DPPresults.mat` file required for reconstruction is distributed separately from the GitHub repository as part of the complete reproducibility dataset.

See `3D_ML_reconstruction/README.md` for the required data, software environment, and instructions.

## 2. Multimodal AI Fusion

`Multimodal_AI_fusion/`

Python/TensorFlow-based multimodal analysis using ML, 3D digital image correlation (DIC), and piezoresistive (PR) sensing for simultaneous prediction of bending angle (BA) and angular rate (AR).

The analysis evaluates the sensing modalities individually and in selected multimodal combinations using MobileNetV2, EfficientNetB0, and ResNet50 backbones.

See `Multimodal_AI_fusion/README.md` for environment setup, data organization, and reproducibility instructions.

## Repository Structure

The complete structure required to run the analyses is:

```text
Multifunctional_ML_Skin/
├── README.md
│
├── 3D_ML_reconstruction/
│   ├── README.md
│   ├── reconstruct_3D_ML_interactive.m
│   └── data/
│       ├── DIC3DPPresults.mat    [distributed separately]
│       └── ML_images_camera_1/
│
└── Multimodal_AI_fusion/
    ├── README.md
    ├── multimodal_motion_prediction.ipynb
    ├── environment.yml
    ├── requirements.txt
    └── data/
```

Before running the 3D ML reconstruction code, place the separately distributed `DIC3DPPresults.mat` file in the `3D_ML_reconstruction/data/` directory.

Each analysis folder contains its own README with the instructions required to reproduce or interactively inspect the corresponding results.
