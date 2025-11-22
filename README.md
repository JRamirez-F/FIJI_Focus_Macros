# Detecting unfocus in images using FIJI macros 

This repository contains two FIJI macros designed to evaluate image focus in microscopy or natural images. The macros are intended to classify regions of interest (ROIs) as **focused** or **unfocused** and provide a global focus status.

For a detailed explanation, tests, etc visit the Image.sc [topic](https://forum.image.sc/t/script-to-list-unsharp-pictures/114841/8?u=j_ramirez) where this macro was generated. 

---

## Features

* Works with 8-bit grayscale and RGB images.
* Supports image stacks or single images.
* ROI-based analysis with customizable size and number of ROIs.
* Generates focus scores based on Gaussian blur, sharpening, and edge detection.
* Provides a global status: **GLOBALLY FOCUSED** or **GLOBALLY UNFOCUSED**.
* Empirical and robust for a variety of sample images.
* Includes optional ROI visualization for inspection.

---

## Usage

### Macro 1: Standard Focus Assessment for large microscopy images that do not cover the whole FOV

* Place ROIs randomly over the image.
* Threshold the image to define the sample area.
* Morphologically clean the mask (dilate/erode cycles).
* Calculates focus scores for each ROI and classifies them.
* Outputs ROI summary and global focus status.

### Macro 2: Simplified for Microscopy/Natural Images where tthe sample covers the whole FOV

* Works similarly to previous macro
* Works on natural images or microscopy images where the sample covers the full field.
* Avoids thresholding for ROI placement.
* Evaluates focus for each ROI and outputs global status.

---

## User Settings

Adjust the following parameters at the top of each macro:

```javascript
roiWidth = 500;          // Width of each ROI
roiHeight = 500;         // Height of each ROI
numberOfROIs = 20;       // Number of ROIs to evaluate
```

Optional: For simplified images, you may reduce ROI size for better sampling.

---

## Example

Tested over various images:

* Microscopy images (brightfield, fluorescence)
* Natural images (flowers from the Alps)
* Gaussian blur applied for testing sensitivity

The macros detect focus/unfocus reliably and allow visual inspection of individual ROIs.

---

## How it Works

1. ROIs are placed randomly within the sample area.
2. Each ROI is duplicated and processed to create a **focus stack**:

   * Blurred versions (slices 1–6)
   * Original slice (slice 7)
   * Sharpened versions (slices 8–13)
3. Focus scores are calculated using edge detection and standard deviation metrics.
4. Each ROI is classified as focused or unfocused based on:

   * Comparison to the original and best focus slice
   * Trend in sharpening slices
   * Ratio of original score to worst score
5. Global focus status is determined based on the majority of ROIs.

---

## Requirements

* FIJI / ImageJ with macro scripting enabled
* 8-bit or RGB images (stacks or single images)

---

## Notes

* The macros are **experimental** and meant for evaluation purposes.
* Results may vary depending on sample type and image quality.
* Users can modify thresholding, ROI size, number, and morphological cycles to adapt to specific datasets.

---

## License

This repository does **not include a license**. Usage is at your own risk.

---

## Author

Jorge Ramirez-F
