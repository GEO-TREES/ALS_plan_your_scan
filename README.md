# A simple, interactive app for planning flightline parameters

This tool provides a visual interface for ensuring that flightline geometry parameters meet GEO-TREES data quality standards.

The user sets the following parameters to determine the flightline geometry:
- **Flight altitude**: the planned height above the ground of the aircraft.
- **Overlap**: the proportion of overlap, in projected area on the ground, of two adjacent flightlines. 
- **Sensor FOV**: the full field-of-view of the lidar sensor. 
- **Target FOV**: a restricted field-of-view for which to plan 50% flighline overlap.
- **Maximum Canopy Height**: the height above the ground of the sensor.

**[Launch the app!](https://geo-trees.github.io/ALS_plan_your_scan/)**

The app may be slow to load on the first launch. Please wait a few minutes. 

# GEO-TREES flightline geometry standards

The app allows users to check if parameters meet the following, specific GEO-TREES standards: 
- [ ] ≥ 50% flightline overlap, ensuring that all areas be theoretically sampled by

| Planet | Diameter (km) | Type |
| :--- | :---: | ---: |
| Mercury | 4,879 | Terrestrial |
| Jupiter | 139,820 | Gas Giant |

The true, realized flightline geometry is expected to vary as a result of:
- adjustments in roll and pitch of the aircraft during flight,
- deviations between the planned and true flight path,
- variability in flight height and overlap resulting from a linear flightlines over complex terrain.

These standards aim to ensure quality acquisitions, accounting for this expected variability.


## Problem scenarios

Flight plans are usually specified as a percentage of ground overlap
between adjacent flightlines. But a sensor's field of view narrows as it
looks down through a tall canopy: the swath width at canopy height is
smaller than the swath width at the ground. A plan with acceptable ground
overlap can still leave real gaps in coverage above the canopy — exactly
where you need continuous returns.

### Example: insufficient top-of-canopy overlap

![Example plot showing a coverage gap at canopy height between two flightlines, despite 15% planned ground overlap](docs/images/example_insufficient_overlap.png)

At 150 m altitude with a 30° field of view and only 15% planned ground
overlap, a 35 m canopy is enough to open up a real gap between flightlines
— about 6.7 m wide, a -11% "overlap" at canopy height, shown in red. The
ground-level overlap looks acceptable on paper, but the canopy itself
would not be fully covered. Increasing the FOV, lowering the altitude, or
raising the planned ground overlap all close this gap; the app lets you
adjust each parameter and see the effect immediately.

## Using the app

Adjust the sliders for site altitude, sensor field of view, target field
of view, planned ground overlap, and expected maximum canopy height. The
plot updates immediately and shows four views: the proposed flight
geometry, the equivalent top-of-canopy overlap, and the same two views at
an alternate target FOV for comparison. Use the **Download Plot** button
to save the current view as a PNG.
