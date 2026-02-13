# EEG Sleep Stage Detection using MATLAB

## 📌 Project Overview
This project implements automated sleep stage classification using EEG data from the Sleep-EDF dataset.

The system:
- Loads EEG data from EDF file
- Applies signal preprocessing and detrending
- Extracts Delta, Theta, Alpha, Beta frequency bands
- Performs sliding window band power analysis
- Classifies sleep stages (Wake, REM, N1, N2, N3)
- Visualizes sleep statistics and transitions

---

## 🧠 EEG Data
Dataset: Sleep-EDF  
Channel used: EEGFpz-Cz  
Sampling Frequency: 100 Hz  
Epoch Length: 30 seconds  
Overlap: 50%

---

## 🔍 Processing Steps

### 1️⃣ Preprocessing
- EDF file reading
- Signal detrending
- Conversion to numeric format

### 2️⃣ Bandpass Filtering
4th-order Butterworth filters applied for:
- Delta (0.5–4 Hz)
- Theta (4–8 Hz)
- Alpha (8–12 Hz)
- Beta (12–30 Hz)

### 3️⃣ Sleep Stage Detection
Rule-based classification using band power thresholds.

Stages:
- Wake
- REM
- N1
- N2
- N3

### 4️⃣ Visualization
- Hypnogram
- Sleep stage distribution pie chart
- Power Spectral Density (PSD)
- Stage transition matrix heatmap
- Statistical summary

---

## 📊 Output
- Sleep statistics
- Transition matrix
- PSD plots
- Saved results (.mat file)

---

## 🛠 Requirements
- MATLAB
- Signal Processing Toolbox

---

## 🎯 Learning Outcomes
- EEG signal preprocessing
- Digital filtering
- Spectral analysis
- Sliding window segmentation
- Rule-based sleep classification
- Data visualization in MATLAB

---

## 👨‍💻 Author
Ahmed Basil  
Machine Learning & AI Enthusiast
