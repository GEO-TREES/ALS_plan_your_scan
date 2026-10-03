# A simple, interactive app for planning flightline parameters

This tool provides a visual interface for ensuring that flightline geometry parameters meet GEO-TREES data quality standards.

The user sets the following parameters to determine the flightline geometry:
- **Flight altitude**: the planned height above the ground of the aircraft.
- **Overlap**: the proportion of overlap, in projected area on the ground, of two adjacent flightlines. 
- **Sensor FOV**: the full field-of-view of the lidar sensor. 
- **Target FOV**: a restricted field-of-view for which to plan 50% flighline overlap.
- **Maximum Canopy Height**: the height above the ground of the sensor.

**[Launch the app!](https://geo-trees.github.io/ALS_plan_your_scan/)**


## Using the app

The app may be slow to load on the first launch. Please wait up to a few minutes. 

Adjust the sliders for site altitude, sensor field of view, target field
of view, planned ground overlap, and expected maximum canopy height. The
plot updates immediately and shows four views: the proposed flight
geometry, the equivalent top-of-canopy overlap, and the same two views at
an alternate target FOV for comparison. Use the **Download Plot** button
to save the current view as a PNG.


# GEO-TREES flightline geometry standards

## GEO-TREES acquisition standards

The specific GEO-TREES acquisition standards:

### <ins>(1) Complete scan overlap</ins>

**Details:** The overlap between flightlines should be ≥ 50% to ensure that all areas are scanned from multiple directions.

**Rationale:** [Dayal et al. (2022)](https://www.sciencedirect.com/science/article/pii/S0924271622002222?via%3Dihub) investigated the impacts of scan angle and flight line overlap on model predictions of basal area and volume. Narrower scan angles did not result in systematically better model fits or lower error. But high flightline overlap, ensuring information from multiple flight lines from all plots, resulted in more robust models with lower distributions of goodness-of-fit criteria. [Van Lier et al. (2022)](https://academic.oup.com/forestry/article/95/1/49/6303362) found significant but small differences in metrics and predictions with scan angle in boreal forests, and higher accuracy when multiple flightlines were included.

**Assessment criteria:** Within the ROI, the range in scan angles (maximum absolute scan angle - minimum absolute scan angle) should be ≥ 2° for 95% of pixels.

### <ins>(2) Restricted scan angle</ins>

**Details:** Regardless of the sensor FOV, overlap should be computed for a restricted FOV to ensure that all areas are scanned within a maximum absolute off-nadir scan angle. This threshold depends on the environment:

-   No maximum for savannas, where occlusion is minimal.
-   30° for closed-canopy forests.
-   20° for very tall canopies (heights > 40 m) and/or complex topography (slopes > 30°).
-   15° for flooded forests or forests with extreme topography (slopes > 45°).

**Rationale:** Ground returns become unreliable on forested, steep terrain because slope steepness compounds scan angles to result in high incidence angles; lidar pulses with high off-nadir scan angles are more likely to be occluded by dense vegetation. This problem is mitigated by maintaining full coverage with scan angles ≤ 15° [(Goodwin et al. 2007)](https://www.sciencedirect.com/science/article/pii/S0034425707001496). The risk of occlusion is greater when canopies are very tall and dense and when standing water attenuates pulse energy.

**Assessment criteria:** Within the ROI, the minimum absolute scan angle should be at or below the threshold for 95% of pixels.

### <ins>(3) Minimum pulse density</ins>

**Details:** The pulse density, approximated as the number of 1st returns per m<sup>2</sup> within a 15-m moving window, should be higher than a minimum:

-   10 pulses per m<sup>2</sup> for savannas.
-   15 pulses per m<sup>2</sup> for most forests.
-   25 pulses per m<sup>2</sup> for flooded forests.

**Rationale:** The occlusion problem can be overcome, in part, by very high pulse density to increase the likelihood of canopy penetration even when most pulses are occluded. [Leitold et al. (2015)](https://link.springer.com/article/10.1186/s13021-015-0013-x) suggest that in tropical forests, terrain modeling accuracy degrades at pulse densities below 4 pulses per m<sup>2</sup>.

**Assessment criteria:**

-   Within the ROI, the local density of 1st returns should exceed the threshold for 95% of pixels.
-   Within the ROI, the local density of 1st returns should be ≥ 4 pulses per m<sup>2</sup> for 100% of pixels.

## Problem scenarios


### Example: insufficient top-of-canopy overlap

![Example plot showing a coverage gap at canopy height between two flightlines, despite 15% planned ground overlap](docs/images/example_insufficient_overlap.png)


### Example: insufficient canopy penetration from large scan angles on steep slopes

![Example plot showing a coverage gap at canopy height between two flightlines, despite 15% planned ground overlap](docs/images/example_insufficient_overlap.png)


