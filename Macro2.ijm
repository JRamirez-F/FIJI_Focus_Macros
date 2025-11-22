// === USER SETTINGS ===
roiWidth = 250;
roiHeight = 250;
numberOfROIs = 20;

// === Duplicate and convert image for masking ===
origTitle = getTitle();
// === Return to Main Image ===
selectWindow(origTitle);
getDimensions(width, height, channels, slices, frames);

roiManager("reset");
run("Clear Results");

setBatchMode(true);
setBatchMode("hide");

// === Overlap Check Function ===
function rectanglesOverlapWithBuffer(x1, y1, w1, h1, x2, y2, w2, h2) {
    buffer = 1;
    if (x1 + w1 + buffer <= x2) return false;
    if (x2 + w2 + buffer <= x1) return false;
    if (y1 + h1 + buffer <= y2) return false;
    if (y2 + h2 + buffer <= y1) return false;
    return true;
}

// === Focus Classification Function ===
function classifyFocusROI(x, y, w, h) {
    selectWindow(origTitle);
    makeRectangle(x, y, w, h);
    run("Duplicate...", "title=tempROI");

    selectWindow("tempROI");
    run("8-bit");

    newImage("FocusStack", "8-bit black stack", getWidth(), getHeight(), 13);
    stackTitle = getTitle();

    // Blurred slices (1–6)
    for (i = 1; i <= 6; i++) {
        selectWindow("tempROI");
        run("Duplicate...", "title=tempBlur");
        run("Gaussian Blur...", "sigma=" + ((7 - i) * 1.5));
        run("Copy");
        close("tempBlur");

        selectWindow(stackTitle);
        setSlice(i);
        run("Paste");
    }

    // Original slice (7)
    selectWindow("tempROI");
    run("Copy");
    selectWindow(stackTitle);
    setSlice(7);
    run("Paste");

    // Sharpened slices (8–13)
    for (i = 1; i <= 6; i++) {
        selectWindow("tempROI");
        run("Duplicate...", "title=tempSharp");
        for (j = 1; j <= i; j++) run("Sharpen", "slice");
        run("Copy");
        close("tempSharp");

        selectWindow(stackTitle);
        setSlice(i + 7);
        run("Paste");
    }

    // Evaluate focus scores
    focusScores = newArray(13);
    maxScore = -1; bestSlice = -1;

    for (i = 1; i <= 13; i++) {
        setSlice(i);
        run("Find Edges", "slice");
        getStatistics(area, mean, min, max, stdDev);
        focusScores[i - 1] = stdDev;
        run("Undo");

        if (stdDev > maxScore) {
            maxScore = stdDev;
            bestSlice = i;
        }
    }

    origScore = focusScores[6]; // Original slice
    sliceDistance = abs(bestSlice - 7);

    // Rank calculation
    rank = 1;
    for (i = 0; i < 13; i++) if (focusScores[i] > origScore) rank++;

    // Sharpness trend check
    brokenSharpTrend = false;
    for (i = 7; i < 12; i++) {
        if (focusScores[i + 1] < focusScores[i]) {
            brokenSharpTrend = true;
            break;
        }
    }

    isTop3 = rank <= 3;
    isCloseScore = (origScore / maxScore) >= 0.7;
    isNearBest = sliceDistance <= 3;
    isGoodScore = origScore >= 60;

    worstScore = focusScores[0];
    scoreRatio = origScore / worstScore;
    isMuchBetterThanWorst = scoreRatio >= 10;

    // Final Focus Decision
    focused = (isMuchBetterThanWorst || 
               (isGoodScore && (isTop3 || isCloseScore || isNearBest)) || 
               brokenSharpTrend);

    close("tempROI");
    close(stackTitle);

    return focused;
}

// === ROI Placement Loop ===
success = 0; attempts = 0;
maxAttempts = 10000;

xList = newArray();
yList = newArray();

focusedCount = 0;
unfocusedCount = 0;

while (success < numberOfROIs && attempts < maxAttempts) {
    selectWindow(origTitle);

    x = floor(random() * (width - roiWidth));
    y = floor(random() * (height - roiHeight));
    makeRectangle(x, y, roiWidth, roiHeight);

    overlaps = false;
    for (i = 0; i < success; i++) {
        if (rectanglesOverlapWithBuffer(x, y, roiWidth, roiHeight, xList[i], yList[i], roiWidth, roiHeight)) {
            overlaps = true;
            break;
        }
    }

    if (!overlaps) {
        selectWindow(origTitle);
        makeRectangle(x, y, roiWidth, roiHeight);
        roiManager("Add");

        isFocused = classifyFocusROI(x, y, roiWidth, roiHeight);
        if (isFocused) {
            focusedCount++;
            print("ROI " + (success + 1) + " is FOCUSED");
        } else {
            unfocusedCount++;
            print("ROI " + (success + 1) + " is UNFOCUSED");
        }

        xList = Array.concat(xList, newArray(x));
        yList = Array.concat(yList, newArray(y));
        success++;
    }
    attempts++;
}

setBatchMode("exit and display");

// === Final Output ===
selectWindow(origTitle);
roiManager("Show All");

// Rename ROIs 1, 2, ..., N
nROIs = roiManager("count");
for (k = 0; k < nROIs; k++) {
    roiManager("select", k);
    roiManager("rename", (k + 1));
}

print("\nTotal ROIs placed: " + success);
print("Focused ROIs: " + focusedCount);
print("Unfocused ROIs: " + unfocusedCount);
if (unfocusedCount > (success / 2)) {
    print("=> GLOBAL STATUS: GLOBALLY UNFOCUSED");
} else {
    print("=> GLOBAL STATUS: GLOBALLY FOCUSED");
}
